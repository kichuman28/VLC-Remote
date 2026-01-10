/// Playlist Model
///
/// Represents a saved playlist with a name and list of media files.
class Playlist {
  /// Unique identifier
  final String id;

  /// Display name for the playlist
  String name;

  /// List of file URIs in the playlist
  final List<PlaylistItem> items;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  DateTime modifiedAt;

  Playlist({
    required this.id,
    required this.name,
    List<PlaylistItem>? items,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create a new empty playlist
  factory Playlist.create(String name) {
    return Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
  }

  /// Add an item to the playlist
  void addItem(PlaylistItem item) {
    items.add(item);
    modifiedAt = DateTime.now();
  }

  /// Remove an item by index
  void removeAt(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      modifiedAt = DateTime.now();
    }
  }

  /// Move an item
  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    modifiedAt = DateTime.now();
  }

  /// Clear all items
  void clear() {
    items.clear();
    modifiedAt = DateTime.now();
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => PlaylistItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  @override
  String toString() => 'Playlist(name: $name, items: ${items.length})';
}

/// Single item in a playlist
class PlaylistItem {
  /// Display name (file name)
  final String name;

  /// Full file URI
  final String uri;

  const PlaylistItem({
    required this.name,
    required this.uri,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
    };
  }

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      name: json['name'] as String,
      uri: json['uri'] as String,
    );
  }

  @override
  String toString() => 'PlaylistItem(name: $name)';
}
