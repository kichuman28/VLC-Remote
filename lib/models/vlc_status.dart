/// VLC Status Model
///
/// Represents the current state of VLC Media Player as returned by
/// the /requests/status.xml endpoint. Contains media info, playback
/// state, volume, and timing information.
class VlcStatus {
  /// Current playback state: 'playing', 'paused', 'stopped'
  final String state;
  
  /// Current volume level (0-512 in VLC, we normalize to percentage)
  final int volume;
  
  /// Current playback position in seconds
  final int time;
  
  /// Total duration of current media in seconds
  final int length;
  
  /// Title of currently playing media
  final String title;
  
  /// Whether fullscreen mode is active
  final bool fullscreen;

  /// Current playback rate (1.0 = normal speed)
  final double rate;

  /// Available audio tracks
  final List<MediaTrack> audioTracks;

  /// Current audio track ID
  final int currentAudioTrack;

  /// Available subtitle tracks
  final List<MediaTrack> subtitleTracks;

  /// Current subtitle track ID (-1 = disabled)
  final int currentSubtitleTrack;
  
  /// Whether VLC is currently playing (convenience getter)
  bool get isPlaying => state == 'playing';
  
  /// Whether media is loaded (convenience getter)
  bool get hasMedia => length > 0 || time > 0 || state == 'playing' || state == 'paused';
  
  /// Progress as percentage (0.0 to 1.0)
  double get progress => length > 0 ? time / length : 0.0;
  
  /// Volume as percentage (0 to 100)
  /// VLC uses 0-512 scale where 256 = 100%
  int get volumePercent => ((volume / 256) * 100).round().clamp(0, 200);
  
  /// Formatted current time (MM:SS or HH:MM:SS)
  String get formattedTime => _formatDuration(time);
  
  /// Formatted total duration (MM:SS or HH:MM:SS)
  String get formattedLength => _formatDuration(length);
  
  /// Formatted time display "MM:SS / MM:SS"
  String get timeDisplay => '$formattedTime / $formattedLength';

  /// Playback speed as percentage string
  String get speedDisplay {
    if (rate == 1.0) return 'Normal';
    return '${rate.toStringAsFixed(2)}x';
  }

  const VlcStatus({
    required this.state,
    required this.volume,
    required this.time,
    required this.length,
    required this.title,
    required this.fullscreen,
    this.rate = 1.0,
    this.audioTracks = const [],
    this.currentAudioTrack = -1,
    this.subtitleTracks = const [],
    this.currentSubtitleTrack = -1,
  });

  /// Creates an empty/initial status when no connection exists
  factory VlcStatus.empty() {
    return const VlcStatus(
      state: 'stopped',
      volume: 256,
      time: 0,
      length: 0,
      title: 'Not Connected',
      fullscreen: false,
    );
  }

  /// Creates VlcStatus from parsed XML data map
  factory VlcStatus.fromMap(Map<String, dynamic> map) {
    return VlcStatus(
      state: map['state'] as String? ?? 'stopped',
      volume: map['volume'] as int? ?? 256,
      time: map['time'] as int? ?? 0,
      length: map['length'] as int? ?? 0,
      title: map['title'] as String? ?? 'Unknown',
      fullscreen: map['fullscreen'] as bool? ?? false,
      rate: map['rate'] as double? ?? 1.0,
      audioTracks: map['audioTracks'] as List<MediaTrack>? ?? const [],
      currentAudioTrack: map['currentAudioTrack'] as int? ?? -1,
      subtitleTracks: map['subtitleTracks'] as List<MediaTrack>? ?? const [],
      currentSubtitleTrack: map['currentSubtitleTrack'] as int? ?? -1,
    );
  }

  VlcStatus copyWith({
    String? state,
    int? volume,
    int? time,
    int? length,
    String? title,
    bool? fullscreen,
    double? rate,
    List<MediaTrack>? audioTracks,
    int? currentAudioTrack,
    List<MediaTrack>? subtitleTracks,
    int? currentSubtitleTrack,
  }) {
    return VlcStatus(
      state: state ?? this.state,
      volume: volume ?? this.volume,
      time: time ?? this.time,
      length: length ?? this.length,
      title: title ?? this.title,
      fullscreen: fullscreen ?? this.fullscreen,
      rate: rate ?? this.rate,
      audioTracks: audioTracks ?? this.audioTracks,
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      currentSubtitleTrack: currentSubtitleTrack ?? this.currentSubtitleTrack,
    );
  }

  /// Formats seconds into human-readable duration
  static String _formatDuration(int seconds) {
    if (seconds < 0) return '0:00';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'VlcStatus(state: $state, volume: $volumePercent%, time: $formattedTime, length: $formattedLength, title: $title)';
  }
}

/// Represents an audio or subtitle track
class MediaTrack {
  final int id;
  final String name;

  const MediaTrack({
    required this.id,
    required this.name,
  });

  @override
  String toString() => 'MediaTrack(id: $id, name: $name)';
}
