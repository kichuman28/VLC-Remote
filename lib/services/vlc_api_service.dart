import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import '../models/vlc_status.dart';
import '../utils/basic_auth.dart';

/// VLC API Service
///
/// Handles all HTTP communication with VLC's Web Interface.
/// Implements the supported VLC commands and status polling.
///
/// VLC Web Interface runs on `http://<ip>:8080` by default.
class VlcApiService {
  final String host;
  final int port;
  final String password;
  
  /// HTTP client with timeout for network operations
  final http.Client _client = http.Client();
  
  /// Connection timeout for API calls
  static const Duration _timeout = Duration(seconds: 5);

  VlcApiService({
    required this.host,
    required this.port,
    required this.password,
  });

  /// Base URL for VLC API
  String get _baseUrl => 'http://$host:$port';

  /// Auth headers for all requests
  Map<String, String> get _headers => BasicAuth.getHeaders(password);

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }

  // ============================================================
  // STATUS ENDPOINT
  // ============================================================

  /// Fetches current VLC status from /requests/status.xml
  /// 
  /// Returns [VlcStatus] on success, throws [VlcApiException] on failure
  Future<VlcStatus> getStatus() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/requests/status.xml'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseStatusXml(response.body);
      } else if (response.statusCode == 401) {
        throw VlcApiException('Wrong password. Check VLC Web Interface settings.');
      } else {
        throw VlcApiException('VLC returned error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw VlcApiException('Connection timed out. Is VLC running?');
    } on http.ClientException catch (e) {
      throw VlcApiException(_friendlyNetworkError(e.message));
    } catch (e) {
      if (e is VlcApiException) rethrow;
      throw VlcApiException('Cannot reach VLC. Check IP address and network.');
    }
  }

  /// Parses VLC's status.xml response into VlcStatus
  /// Parses VLC's status.xml response into VlcStatus
  VlcStatus _parseStatusXml(String xmlString) {
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final root = document.rootElement;

      // Extract basic status fields
      final state = _getXmlText(root, 'state') ?? 'stopped';
      final volume = int.tryParse(_getXmlText(root, 'volume') ?? '256') ?? 256;
      final time = int.tryParse(_getXmlText(root, 'time') ?? '0') ?? 0;
      final length = int.tryParse(_getXmlText(root, 'length') ?? '0') ?? 0;
      final fullscreen = _getXmlText(root, 'fullscreen') == 'true';
      final rate = double.tryParse(_getXmlText(root, 'rate') ?? '1.0') ?? 1.0;

      // Extract title from information/category/meta
      String title = 'No Media';
      List<MediaTrack> audioTracks = [];
      int currentAudioTrack = -1;
      List<MediaTrack> subtitleTracks = [];
      int currentSubtitleTrack = -1;

      try {
        final information = root.findElements('information').firstOrNull;
        if (information != null) {
          for (final category in information.findElements('category')) {
            final categoryName = category.getAttribute('name');
            
            if (categoryName == 'meta') {
              // Extract title
              for (final info in category.findElements('info')) {
                final infoName = info.getAttribute('name');
                if (infoName == 'title' || infoName == 'filename') {
                  final text = info.innerText.trim();
                  if (text.isNotEmpty) {
                    title = text;
                    break;
                  }
                }
              }
            }
          }
        }
      } catch (_) {
        // If parsing fails, keep default values
      }

      // Parse audio and subtitle tracks
      // We use findAllElements to find track info wherever it may be nested
      try {
        // Audio tracks
        // Look for 'audiostreams' anywhere in the status
        
        // Try standard location first or deep search
        final audioTrackInfos = root.findAllElements('audiostreams');
        for (final audioTrackInfo in audioTrackInfos) {
          final streams = audioTrackInfo.findElements('stream');
          if (streams.isNotEmpty) {
            for (final stream in streams) {
              final id = int.tryParse(stream.getAttribute('streamindex') ?? '-1') ?? -1;
              final name = stream.getAttribute('name') ?? 'Track $id';
              final selected = stream.getAttribute('selected') == 'selected';
              if (id >= 0) {
                audioTracks.add(MediaTrack(id: id, name: name));
                if (selected) currentAudioTrack = id;
              }
            }
          }
        }

        // Subtitle tracks
        bool foundSubtitle = false;
        final subtitleTrackInfos = root.findAllElements('subtitlestreams');
        
        if (subtitleTrackInfos.isNotEmpty) {
          // Add "Off" option for subtitles if we found the section
          // Only add 'Off' once
          if (subtitleTracks.isEmpty) {
             subtitleTracks.add(const MediaTrack(id: -1, name: 'Off'));
          }
          foundSubtitle = true;
          
          for (final subtitleTrackInfo in subtitleTrackInfos) {
            for (final stream in subtitleTrackInfo.findElements('stream')) {
              final id = int.tryParse(stream.getAttribute('streamindex') ?? '-1') ?? -1;
              final name = stream.getAttribute('name') ?? 'Track $id';
              final selected = stream.getAttribute('selected') == 'selected';
              if (id >= 0) {
                // Avoid duplicates
                if (!subtitleTracks.any((t) => t.id == id)) {
                  subtitleTracks.add(MediaTrack(id: id, name: name));
                }
                if (selected) currentSubtitleTrack = id;
              }
            }
          }
          
          if (currentSubtitleTrack == -1 && foundSubtitle) {
             currentSubtitleTrack = -1;
          }
        }
      } catch (_) {
        // Track parsing failed, continue with empty lists
      }

      return VlcStatus.fromMap({
        'state': state,
        'volume': volume,
        'time': time,
        'length': length,
        'title': title,
        'fullscreen': fullscreen,
        'rate': rate,
        'audioTracks': audioTracks,
        'currentAudioTrack': currentAudioTrack,
        'subtitleTracks': subtitleTracks,
        'currentSubtitleTrack': currentSubtitleTrack,
      });
    } catch (e) {
      throw VlcApiException('Failed to parse VLC response');
    }
  }

  /// Helper to get text content of an XML element
  String? _getXmlText(xml.XmlElement parent, String elementName) {
    try {
      final element = parent.findElements(elementName).firstOrNull;
      return element?.innerText;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CONTROL COMMANDS
  // ============================================================

  /// Sends a command to VLC
  Future<void> _sendCommand(String command, [Map<String, String>? params]) async {
    final queryParams = {'command': command, ...?params};
    final uri = Uri.parse('$_baseUrl/requests/status.xml')
        .replace(queryParameters: queryParams);

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 401) {
        throw VlcApiException('Wrong password');
      } else if (response.statusCode != 200) {
        throw VlcApiException('Command failed');
      }
    } on TimeoutException {
      throw VlcApiException('Connection timed out');
    } on http.ClientException {
      throw VlcApiException('Network error');
    } catch (e) {
      if (e is VlcApiException) rethrow;
      throw VlcApiException('Command failed');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    await _sendCommand('pl_pause');
  }

  /// Set volume (0-512 scale, where 256 = 100%)
  /// 
  /// [value] should be 0-512
  Future<void> setVolume(int value) async {
    await _sendCommand('volume', {'val': value.toString()});
  }

  /// Seek by relative amount
  /// 
  /// [seconds] Positive or negative seconds to seek
  Future<void> seekRelative(int seconds) async {
    final sign = seconds >= 0 ? '+' : '';
    await _sendCommand('seek', {'val': '$sign${seconds}s'});
  }

  /// Seek to absolute time in seconds
  Future<void> seekTo(int seconds) async {
    await _sendCommand('seek', {'val': '${seconds}'});
  }

  /// Seek forward 10 seconds
  Future<void> seekForward() async {
    await seekRelative(10);
  }

  /// Seek backward 10 seconds
  Future<void> seekBackward() async {
    await seekRelative(-10);
  }

  /// Toggle fullscreen mode
  Future<void> toggleFullscreen() async {
    await _sendCommand('fullscreen');
  }

  /// Play next item in playlist
  Future<void> playNext() async {
    await _sendCommand('pl_next');
  }

  /// Play previous item in playlist
  Future<void> playPrevious() async {
    await _sendCommand('pl_previous');
  }

  // ============================================================
  // AUDIO, SUBTITLE & SPEED CONTROL
  // ============================================================

  /// Set audio track by ID
  Future<void> setAudioTrack(int trackId) async {
    await _sendCommand('audio_track', {'val': trackId.toString()});
  }

  /// Set subtitle track by ID (-1 to disable)
  Future<void> setSubtitleTrack(int trackId) async {
    await _sendCommand('subtitle_track', {'val': trackId.toString()});
  }

  /// Set playback rate (1.0 = normal, 0.5 = half speed, 2.0 = double speed)
  Future<void> setPlaybackRate(double rate) async {
    await _sendCommand('rate', {'val': rate.toString()});
  }

  // ============================================================
  // FILE BROWSING
  // ============================================================

  /// Browse a directory on the VLC host machine
  /// 
  /// [uri] File URI to browse, e.g., "file:///C:/" or "file:///home/"
  /// Returns list of files and folders
  Future<List<Map<String, String>>> browseDirectory(String uri) async {
    try {
      final encodedUri = Uri.encodeComponent(uri);
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/requests/browse.xml?uri=$encodedUri'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseBrowseXml(response.body);
      } else if (response.statusCode == 401) {
        throw VlcApiException('Wrong password');
      } else {
        throw VlcApiException('Failed to browse directory');
      }
    } on TimeoutException {
      throw VlcApiException('Connection timed out');
    } catch (e) {
      if (e is VlcApiException) rethrow;
      throw VlcApiException('Failed to browse files');
    }
  }

  /// Helper for recursive search with streaming results
  /// 
  /// [onFound] Callback for each batch of found files
  Future<void> searchFilesStream(
    String startUri, 
    String query, {
    required Function(List<Map<String, String>>) onFound,
    bool Function()? isCancelled,
  }) async {
    final lowercaseQuery = query.toLowerCase();
    
    // Config
    final int maxDepth = 20; // Deep search
    final int maxConcurrency = 5; // Parallel requests
    
    // Priority Queue-ish: We process folders in this order
    // 0: High Priority (Users, Movies, etc)
    // 1: Normal
    // 2: Low Priority (System)
    final queues = <int, List<MapEntry<String, int>>>{
      0: [],
      1: [],
      2: [],
    };
    
    queues[0]!.add(MapEntry(startUri, 0));
    
    final processedUris = <String>{};
    int activeRequests = 0;
    
    // Smart filters
    bool isLikelyMediaFolder(String name) {
      final n = name.toLowerCase();
      return n.contains('user') || n.contains('movie') || n.contains('video') || 
             n.contains('download') || n.contains('music') || n.contains('desktop');
    }
    
    bool isSystemFolder(String name) {
      final n = name.toLowerCase();
      return n.contains('windows') || n.contains('program files') || 
             n.contains('appdata') || n.contains('programdata') || n.contains('\$recycle');
    }

    // Process loop
    while (true) {
      if (isCancelled?.call() ?? false) break;

      // Check if we are done
      if (queues[0]!.isEmpty && queues[1]!.isEmpty && queues[2]!.isEmpty && activeRequests == 0) {
        break;
      }
      
      // Get next folder to browse
      MapEntry<String, int>? next;
      if (queues[0]!.isNotEmpty) next = queues[0]!.removeAt(0);
      else if (queues[1]!.isNotEmpty) next = queues[1]!.removeAt(0);
      else if (queues[2]!.isNotEmpty && queues[0]!.isEmpty && queues[1]!.isEmpty) next = queues[2]!.removeAt(0);
      
      if (next == null) {
        // Wait for active requests to finish spawning new work
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      }

      final currentUri = next.key;
      final currentDepth = next.value;

      if (processedUris.contains(currentUri)) continue;
      processedUris.add(currentUri);
      
      // Concurrency control
      while (activeRequests >= maxConcurrency) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      activeRequests++;
      
      // Launch request (don't await immediately to allow parallelism)
      browseDirectory(currentUri).then((items) {
        if (isCancelled?.call() ?? false) return;

        final newMatches = <Map<String, String>>[];
        
        for (final item in items) {
          final isDir = item['type'] == 'dir';
          final name = item['name'] ?? '';
          final path = item['uri'] ?? '';
          
          if (name == '.' || name == '..') continue;

          // Check match
          if (name.toLowerCase().contains(lowercaseQuery)) {
             newMatches.add(item);
          }
          
          if (isDir && currentDepth < maxDepth) {
            int priority = 1; // Normal
            if (isLikelyMediaFolder(name)) priority = 0;
            else if (isSystemFolder(name)) priority = 2;
            
            queues[priority]!.add(MapEntry(path, currentDepth + 1));
          }
        }
        
        if (newMatches.isNotEmpty) {
          onFound(newMatches);
        }
      }).catchError((_) {
        // Ignore errors
      }).whenComplete(() {
        activeRequests--;
      });
    }
  }

  // Legacy support for non-streaming (deprecated but kept for compatibility if needed)
  Future<List<Map<String, String>>> searchFiles(String startUri, String query) async {
    final results = <Map<String, String>>[];
    await searchFilesStream(startUri, query, onFound: (batch) {
      results.addAll(batch);
    });
    return results;
  }

  /// Parse browse.xml response
  List<Map<String, String>> _parseBrowseXml(String xmlString) {
    final List<Map<String, String>> items = [];
    
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final root = document.rootElement;

      for (final element in root.findElements('element')) {
        final Map<String, String> item = {};
        
        for (final attr in element.attributes) {
          item[attr.localName] = attr.value;
        }
        
        if (item.isNotEmpty && item['name'] != null) {
          items.add(item);
        }
      }
    } catch (e) {
      // Return empty list on parse error
    }
    
    return items;
  }

  /// Play a file by its URI
  /// 
  /// [fileUri] Full file URI, e.g., "file:///C:/Movies/video.mp4"
  Future<void> playFile(String fileUri) async {
    try {
      final encodedUri = Uri.encodeComponent(fileUri);
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/requests/status.xml?command=in_play&input=$encodedUri'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        throw VlcApiException('Wrong password');
      } else if (response.statusCode != 200) {
        throw VlcApiException('Failed to play file');
      }
    } on TimeoutException {
      throw VlcApiException('Connection timed out');
    } catch (e) {
      if (e is VlcApiException) rethrow;
      throw VlcApiException('Failed to play file');
    }
  }

  /// Add a file to playlist and play
  Future<void> addToPlaylistAndPlay(String fileUri) async {
    await playFile(fileUri);
  }

  // ============================================================
  // PLAYLIST MANAGEMENT
  // ============================================================

  /// Clear VLC's playlist
  Future<void> clearPlaylist() async {
    await _sendCommand('pl_empty');
  }

  /// Add a file to playlist without playing
  Future<void> enqueueFile(String fileUri) async {
    try {
      final encodedUri = Uri.encodeComponent(fileUri);
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/requests/status.xml?command=in_enqueue&input=$encodedUri'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        throw VlcApiException('Wrong password');
      } else if (response.statusCode != 200) {
        throw VlcApiException('Failed to add to playlist');
      }
    } on TimeoutException {
      throw VlcApiException('Connection timed out');
    } catch (e) {
      if (e is VlcApiException) rethrow;
      throw VlcApiException('Failed to add to playlist');
    }
  }

  /// Load and play a custom playlist
  /// 
  /// Clears VLC's current playlist, adds all items, and starts playing
  Future<void> playCustomPlaylist(List<String> fileUris) async {
    if (fileUris.isEmpty) return;

    // Clear existing playlist
    await clearPlaylist();

    // Add first item and play it
    await playFile(fileUris.first);

    // Enqueue remaining items
    for (int i = 1; i < fileUris.length; i++) {
      await enqueueFile(fileUris[i]);
    }
  }

  // ============================================================
  // CONNECTION TEST
  // ============================================================

  /// Tests connection to VLC
  /// 
  /// Returns null on success, error message on failure
  Future<String?> testConnection() async {
    try {
      await getStatus();
      return null; // Success
    } on VlcApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Cannot connect to VLC';
    }
  }

  /// Converts network errors to friendly messages
  String _friendlyNetworkError(String message) {
    if (message.contains('Connection refused')) {
      return 'VLC not running or Web Interface not enabled';
    }
    if (message.contains('No route to host') || 
        message.contains('Network is unreachable')) {
      return 'Cannot reach device. Check your network connection.';
    }
    if (message.contains('Connection reset')) {
      return 'Connection interrupted. Try again.';
    }
    return 'Network error. Check IP address and ensure VLC is running.';
  }
}

/// Custom exception for VLC API errors
/// 
/// Contains user-friendly error messages
class VlcApiException implements Exception {
  final String message;
  
  VlcApiException(this.message);
  
  @override
  String toString() => message;
}


