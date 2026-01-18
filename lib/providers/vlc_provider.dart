import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vlc_status.dart';
import '../services/vlc_api_service.dart';

/// VLC Provider
/// 
/// Central state management for the VLC Remote app.
/// Handles connection state, status polling, and UI state.
/// 
/// Responsibilities:
/// - Store connection details (IP, port, password)
/// - Manage connection state
/// - Poll VLC status every 1.5 seconds
/// - Pause polling when app is backgrounded
/// - Expose UI-ready state

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class VlcProvider extends ChangeNotifier {
  // ============================================================
  // CONNECTION SETTINGS
  // ============================================================
  
  String _host = '';
  int _port = 8080;
  String _password = '';
  
  String get host => _host;
  int get port => _port;
  String get password => _password;
  bool get hasSettings => _host.isNotEmpty && _password.isNotEmpty;

  // ============================================================
  // CONNECTION STATE
  // ============================================================
  
  ConnectionState _connectionState = ConnectionState.disconnected;
  String _errorMessage = '';
  
  ConnectionState get connectionState => _connectionState;
  String get errorMessage => _errorMessage;
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get isConnecting => _connectionState == ConnectionState.connecting;

  // ============================================================
  // VLC STATUS
  // ============================================================
  
  VlcStatus _status = VlcStatus.empty();
  VlcStatus get status => _status;

  // ============================================================
  // INTERNAL STATE
  // ============================================================
  
  VlcApiService? _apiService;
  Timer? _pollingTimer;
  bool _isPollingActive = true;
  
  /// SharedPreferences keys
  static const String _keyHost = 'vlc_host';
  static const String _keyPort = 'vlc_port';
  static const String _keyPassword = 'vlc_password';
  
  /// Polling interval
  static const Duration _pollingInterval = Duration(milliseconds: 1500);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Loads saved connection settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _host = prefs.getString(_keyHost) ?? '';
      _port = prefs.getInt(_keyPort) ?? 8080;
      _password = prefs.getString(_keyPassword) ?? '';
      notifyListeners();
    } catch (e) {
      // Ignore errors, use defaults
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Saves connection settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHost, _host);
      await prefs.setInt(_keyPort, _port);
      await prefs.setString(_keyPassword, _password);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  // ============================================================
  // CONNECTION MANAGEMENT
  // ============================================================

  /// Updates connection settings
  void updateSettings({
    required String host,
    required int port,
    required String password,
  }) {
    _host = host.trim();
    _port = port;
    _password = password;
    notifyListeners();
  }

  /// Tests connection to VLC without saving or starting polling
  Future<String?> testConnection({
    required String host,
    required int port,
    required String password,
  }) async {
    final testService = VlcApiService(
      host: host.trim(),
      port: port,
      password: password,
    );
    
    try {
      final error = await testService.testConnection();
      return error;
    } finally {
      testService.dispose();
    }
  }

  /// Connects to VLC and starts polling
  Future<void> connect({
    required String host,
    required int port,
    required String password,
  }) async {
    // Update settings
    _host = host.trim();
    _port = port;
    _password = password;
    
    _connectionState = ConnectionState.connecting;
    _errorMessage = '';
    notifyListeners();

    // Create new API service
    _apiService?.dispose();
    _apiService = VlcApiService(
      host: _host,
      port: _port,
      password: _password,
    );

    // Test connection
    try {
      final error = await _apiService!.testConnection();
      if (error != null) {
        _connectionState = ConnectionState.error;
        _errorMessage = error;
        notifyListeners();
        return;
      }
      
      // Save settings on successful connection
      await _saveSettings();
      
      // Mark as connected and start polling
      _connectionState = ConnectionState.connected;
      _errorMessage = '';
      notifyListeners();
      
      _startPolling();
    } catch (e) {
      _connectionState = ConnectionState.error;
      _errorMessage = 'Connection failed';
      notifyListeners();
    }
  }

  /// Disconnects from VLC
  void disconnect() {
    _stopPolling();
    _apiService?.dispose();
    _apiService = null;
    _connectionState = ConnectionState.disconnected;
    _status = VlcStatus.empty();
    notifyListeners();
  }

  // ============================================================
  // POLLING
  // ============================================================

  /// Starts status polling
  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollStatus());
    // Immediate first poll
    _pollStatus();
  }

  /// Stops status polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ============================================================
  // AUDIO, SUBTITLE & SPEED CONTROL
  // ============================================================

  // State persistence to solve UI flickering when VLC doesn't report selection status
  int? _lastSetAudioTrack;
  int? _lastSetSubtitleTrack;

  /// Polls VLC status
  Future<void> _pollStatus() async {
    if (!_isPollingActive || _apiService == null) return;
    
    try {
      var status = await _apiService!.getStatus();
      
      // PERSISTENCE LOGIC:
      // If we recently set a track, but VLC reports -1 (unknown/none) for current track,
      // and our set track exists in the list, then override the status to keep it highlighted.
      
      // Audio Persistence
      if (status.currentAudioTrack == -1 && 
          _lastSetAudioTrack != null && 
          status.audioTracks.any((t) => t.id == _lastSetAudioTrack)) {
        status = status.copyWith(currentAudioTrack: _lastSetAudioTrack);
      } else if (status.currentAudioTrack != -1) {
        // VLC reported a valid track, so we can clear our override (truth has prevailed)
        _lastSetAudioTrack = null; 
      }

      // Subtitle Persistence
      if (status.currentSubtitleTrack == -1 && 
          _lastSetSubtitleTrack != null && 
          status.subtitleTracks.any((t) => t.id == _lastSetSubtitleTrack)) {
        status = status.copyWith(currentSubtitleTrack: _lastSetSubtitleTrack);
      } else if (status.currentSubtitleTrack != -1) {
        // VLC reported a valid track (could be -1 if genuinely disabled, but here we cover check != -1)
        // Actually, if we selected 'Disable' (-1), VLC reporting -1 matches our intent. 
        // If we selected ID 5, and VLC reports -1, we override. 
        // If we selected ID 5, and VLC reports ID 5, we clear.
        if (status.currentSubtitleTrack == _lastSetSubtitleTrack) {
           _lastSetSubtitleTrack = null;
        }
      }

      _status = status;
      
      // Ensure we're still marked as connected
      if (_connectionState != ConnectionState.connected) {
        _connectionState = ConnectionState.connected;
        _errorMessage = '';
      }
      
      notifyListeners();
    } on VlcApiException catch (e) {
      debugPrint('Polling error: ${e.message}');
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  /// Pauses polling when app is backgrounded
  void pausePolling() {
    _isPollingActive = false;
  }

  /// Resumes polling when app is foregrounded
  void resumePolling() {
    _isPollingActive = true;
    // Immediate poll on resume
    if (isConnected) {
      _pollStatus();
    }
  }

  /// Manual refresh of status
  Future<void> refresh() async {
    await _pollStatus();
  }

  // ============================================================
  // CONTROL COMMANDS
  // ============================================================

  /// Toggle play/pause with optimistic UI update
  Future<void> togglePlayPause() async {
    if (_apiService == null) return;
    
    // Optimistic update
    final newState = _status.isPlaying ? 'paused' : 'playing';
    _status = VlcStatus.fromMap({
      'state': newState,
      'volume': _status.volume,
      'time': _status.time,
      'length': _status.length,
      'title': _status.title,
      'fullscreen': _status.fullscreen,
    });
    notifyListeners();
    
    try {
      await _apiService!.togglePlayPause();
    } catch (e) {
      // Revert on failure by polling actual state
      await _pollStatus();
    }
  }

  /// Set volume with debounced API call
  Future<void> setVolume(int percent) async {
    if (_apiService == null) return;
    
    final vlcValue = ((percent / 100) * 256).round().clamp(0, 512);
    
    _status = VlcStatus.fromMap({
      'state': _status.state,
      'volume': vlcValue,
      'time': _status.time,
      'length': _status.length,
      'title': _status.title,
      'fullscreen': _status.fullscreen,
    });
    notifyListeners();
    
    try {
      await _apiService!.setVolume(vlcValue);
    } catch (e) {
      debugPrint('Volume error: $e');
    }
  }

  /// Seek to absolute time
  Future<void> seekTo(int seconds) async {
    if (_apiService != null) {
      await _apiService!.seekTo(seconds);
      _status = _status.copyWith(time: seconds);
      notifyListeners();
    }
  }

  /// Seek forward 10 seconds
  Future<void> seekForward() async {
    if (_apiService == null) return;
    
    final newTime = (_status.time + 10).clamp(0, _status.length);
    _status = VlcStatus.fromMap({
      'state': _status.state,
      'volume': _status.volume,
      'time': newTime,
      'length': _status.length,
      'title': _status.title,
      'fullscreen': _status.fullscreen,
    });
    notifyListeners();
    
    try {
      await _apiService!.seekForward();
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  /// Seek backward 10 seconds
  Future<void> seekBackward() async {
    if (_apiService == null) return;
    
    final newTime = (_status.time - 10).clamp(0, _status.length);
    _status = VlcStatus.fromMap({
      'state': _status.state,
      'volume': _status.volume,
      'time': newTime,
      'length': _status.length,
      'title': _status.title,
      'fullscreen': _status.fullscreen,
    });
    notifyListeners();
    
    try {
      await _apiService!.seekBackward();
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  /// Toggle fullscreen
  Future<void> toggleFullscreen() async {
    if (_apiService == null) return;
    
    try {
      await _apiService!.toggleFullscreen();
      await _pollStatus();
    } catch (e) {
      debugPrint('Fullscreen error: $e');
    }
  }

  /// Play next item in playlist
  Future<void> playNext() async {
    if (_apiService == null) return;
    
    try {
      await _apiService!.playNext();
      await Future.delayed(const Duration(milliseconds: 300));
      await _pollStatus();
    } catch (e) {
      debugPrint('Next error: $e');
    }
  }

  /// Play previous item in playlist
  Future<void> playPrevious() async {
    if (_apiService == null) return;
    
    try {
      await _apiService!.playPrevious();
      await Future.delayed(const Duration(milliseconds: 300));
      await _pollStatus();
    } catch (e) {
      debugPrint('Previous error: $e');
    }
  }

  // ============================================================
  // FILE BROWSING
  // ============================================================

  /// Browse a directory on the VLC host
  Future<List<Map<String, String>>> browseDirectory(String uri) async {
    if (_apiService == null) return [];
    
    try {
      return await _apiService!.browseDirectory(uri);
    } catch (e) {
      debugPrint('Browse error: $e');
      return [];
    }
  }

  /// Search files recursively with streaming
  Future<void> searchFilesStream(
    String startUri, 
    String query, {
    required Function(List<Map<String, String>>) onFound,
    bool Function()? isCancelled,
  }) async {
    if (_apiService == null) return;
    
    try {
      await _apiService!.searchFilesStream(startUri, query, onFound: onFound, isCancelled: isCancelled);
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  /// Search files recursively (Legacy one-shot)
  Future<List<Map<String, String>>> searchFiles(String startUri, String query) async {
    if (_apiService == null) return [];
    
    try {
      return await _apiService!.searchFiles(startUri, query);
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  /// Play a file by URI
  Future<void> playFile(String fileUri) async {
    if (_apiService == null) return;
    
    try {
      await _apiService!.playFile(fileUri);
      await Future.delayed(const Duration(milliseconds: 500));
      await _pollStatus();
    } catch (e) {
      debugPrint('Play file error: $e');
    }
  }

  /// Play a custom playlist
  /// 
  /// Clears VLC's playlist and loads the provided items
  Future<void> playCustomPlaylist(List<String> fileUris, {int startIndex = 0}) async {
    if (_apiService == null || fileUris.isEmpty) return;
    
    try {
      await _apiService!.playCustomPlaylist(fileUris, startIndex: startIndex);
      // Poll to get new status
      await Future.delayed(const Duration(milliseconds: 500));
      await _pollStatus();
    } catch (e) {
      debugPrint('Play playlist error: $e');
    }
  }

  /// Set audio track
  Future<void> setAudioTrack(int trackId) async {
    if (_apiService == null) return;
    
    // Optimistic Update
    _lastSetAudioTrack = trackId;
    _status = _status.copyWith(currentAudioTrack: trackId);
    notifyListeners();
    
    try {
      await _apiService!.setAudioTrack(trackId);
      // We rely on polling to confirm, but our _pollStatus logic will
      // now preserve this selection if VLC returns unknown.
    } catch (e) {
      debugPrint('Audio track error: $e');
    }
  }

  /// Set subtitle track (-1 to disable)
  Future<void> setSubtitleTrack(int trackId) async {
    if (_apiService == null) return;
    
    // Optimistic Update
    _lastSetSubtitleTrack = trackId;
    _status = _status.copyWith(currentSubtitleTrack: trackId);
    notifyListeners();

    try {
      await _apiService!.setSubtitleTrack(trackId);
    } catch (e) {
      debugPrint('Subtitle track error: $e');
    }
  }

  /// Set playback speed
  Future<void> setPlaybackRate(double rate) async {
    if (_apiService == null) return;
    
    // Optimistic Update
    _status = _status.copyWith(rate: rate);
    notifyListeners();

    try {
      await _apiService!.setPlaybackRate(rate);
      // The poll will pick this up quickly
    } catch (e) {
      debugPrint('Playback rate error: $e');
    }
  }

  /// Currently selected aspect ratio (for UI state)
  String _currentAspectRatio = 'default';
  String get currentAspectRatio => _currentAspectRatio;

  /// Set aspect ratio
  Future<void> setAspectRatio(String ratio) async {
    if (_apiService == null) return;
    
    // Optimistic Update
    _currentAspectRatio = ratio;
    notifyListeners();

    try {
      await _apiService!.setAspectRatio(ratio);
    } catch (e) {
      debugPrint('Aspect ratio error: $e');
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _stopPolling();
    _apiService?.dispose();
    super.dispose();
  }
}


