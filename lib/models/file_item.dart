/// FileItem Model
///
/// Represents a file or folder in VLC's browse response.
class FileItem {
  /// File or folder name
  final String name;

  /// Full path/URI to the item
  final String path;

  /// Whether this is a directory
  final bool isDirectory;

  /// File size in bytes (0 for directories)
  final int size;

  /// File extension (empty for directories)
  final String extension;

  /// Whether this is a video file
  bool get isVideo {
    const videoExtensions = [
      'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm',
      'm4v', 'mpg', 'mpeg', 'ts', 'm2ts', 'vob', '3gp'
    ];
    return videoExtensions.contains(extension.toLowerCase());
  }

  /// Whether this is an audio file
  bool get isAudio {
    const audioExtensions = ['mp3', 'flac', 'wav', 'aac', 'm4a', 'ogg', 'wma'];
    return audioExtensions.contains(extension.toLowerCase());
  }

  /// Whether this is a media file (video or audio)
  bool get isMedia => isVideo || isAudio;

  /// Formatted file size
  String get formattedSize {
    if (isDirectory) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.extension = '',
  });

  /// Create from VLC browse XML attributes
  factory FileItem.fromMap(Map<String, String> map) {
    final name = map['name'] ?? 'Unknown';
    final path = map['uri'] ?? map['path'] ?? '';
    final type = map['type'] ?? 'file';
    final size = int.tryParse(map['size'] ?? '0') ?? 0;

    String extension = '';
    if (type != 'dir' && name.contains('.')) {
      extension = name.split('.').last;
    }

    return FileItem(
      name: name,
      path: path,
      isDirectory: type == 'dir',
      size: size,
      extension: extension,
    );
  }

  @override
  String toString() => 'FileItem(name: $name, isDir: $isDirectory)';
}
