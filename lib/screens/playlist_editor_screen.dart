import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/playlist.dart';
import '../models/file_item.dart';
import '../services/playlist_service.dart';
import '../providers/vlc_provider.dart';

/// Playlist Editor Screen
///
/// Edit a playlist - add, remove, reorder items.
class PlaylistEditorScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistEditorScreen({super.key, required this.playlist});

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends State<PlaylistEditorScreen> {
  late Playlist _playlist;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  Future<void> _savePlaylist() async {
    await PlaylistService.updatePlaylist(_playlist);
  }

  Future<void> _addFromBrowser() async {
    final result = await Navigator.of(context).push<List<PlaylistItem>>(
      MaterialPageRoute(
        builder: (_) => const _FilePickerScreen(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        for (final item in result) {
          _playlist.addItem(item);
        }
      });
      await _savePlaylist();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _playlist.removeAt(index);
    });
    _savePlaylist();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _playlist.moveItem(oldIndex, newIndex);
    });
    _savePlaylist();
  }

  Future<void> _playPlaylist() async {
    if (_playlist.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add some videos first',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    
    final provider = context.read<VlcProvider>();
    final uris = _playlist.items.map((i) => i.uri).toList();
    await provider.playCustomPlaylist(uris);
    
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Future<void> _renamePlaylist() async {
    final controller = TextEditingController(text: _playlist.name);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Rename Playlist',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(),
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _playlist.name = newName;
      });
      await _savePlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _renamePlaylist,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _playlist.name,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled_rounded),
            iconSize: 32,
            color: theme.colorScheme.primary,
            onPressed: _playPlaylist,
            tooltip: 'Play All',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _playlist.items.isEmpty
          ? _buildEmptyState(theme)
          : _buildItemsList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFromBrowser,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Videos',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Playlist is empty',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Videos" to browse and add files',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _playlist.items.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final item = _playlist.items[index];
        return _buildItemTile(item, index, theme);
      },
    );
  }

  Widget _buildItemTile(PlaylistItem item, int index, ThemeData theme) {
    return Dismissible(
      key: Key('${item.uri}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _removeItem(index),
      child: ListTile(
        key: ValueKey('tile_${item.uri}_$index'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle_rounded),
        ),
      ),
    );
  }
}

/// Simple file picker for adding to playlists
class _FilePickerScreen extends StatefulWidget {
  const _FilePickerScreen();

  @override
  State<_FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<_FilePickerScreen> {
  List<FileItem> _items = [];
  List<FileItem> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  
  String _currentPath = 'file:///C:/';
  final List<String> _pathStack = [];
  
  // Use a map to store selected items so we don't lose them when changing folders
  final Map<String, FileItem> _selectedItems = {};

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isSearchingFiles = false; // Deep search active?
  bool _searchCancelled = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<VlcProvider>();
    try {
      final rawItems = await provider.browseDirectory(path);

      final items = rawItems.map((m) => FileItem.fromMap(m)).toList();
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _items = items;
        _filteredItems = items;
        _currentPath = path;
        _isLoading = false;
      });
    } catch(e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load folder';
      });
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), _performSearch);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _filteredItems = _items;
      });
      return;
    }

    setState(() {
      _searchQuery = query.toLowerCase();
      _isSearchingFiles = true;
      _searchCancelled = false;
      _filteredItems = []; // Start fresh
    });

    final provider = context.read<VlcProvider>();
    try {
      await provider.searchFilesStream(
        'file:///C:/', 
        query,
        onFound: (batch) {
           if (!mounted) return;
           final newItems = batch.map((m) => FileItem.fromMap(m)).toList();
           setState(() {
             _filteredItems.addAll(newItems);
             _filteredItems.sort((a, b) {
                if (a.isDirectory && !b.isDirectory) return -1;
                if (!a.isDirectory && b.isDirectory) return 1;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
             });
           });
        },
        isCancelled: () => _searchCancelled,
      );
    } finally {
      if (mounted) setState(() => _isSearchingFiles = false);
    }
  }

  void _stopSearch() {
    _searchCancelled = true;
    setState(() => _isSearchingFiles = false);
  }

  void _toggleSearch() {
     if (_isSearchingFiles) {
       _stopSearch();
       return;
     }

    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _filteredItems = _items;
      }
    });
  }

  void _navigateTo(String path) {
    if (_searchQuery.isNotEmpty) {
      // Clear search when navigating into a folder
       _searchController.clear();
    }
    _pathStack.add(_currentPath);
    _loadDirectory(path);
  }

  void _goBack() {
    if (_isSearching) {
      _toggleSearch();
      return;
    }

    if (_pathStack.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final previous = _pathStack.removeLast();
    _loadDirectory(previous);
  }

  void _toggleSelection(FileItem item) {
    setState(() {
      if (_selectedItems.containsKey(item.path)) {
        _selectedItems.remove(item.path);
      } else {
        _selectedItems[item.path] = item;
      }
    });
  }

  void _confirmSelection() {
    final selected = _selectedItems.values
        .map((i) => PlaylistItem(name: i.name, uri: i.path))
        .toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determines if we show search UI
    Widget titleWidget;
    if (_isSearching) {
      titleWidget = Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.manrope(fontSize: 15),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search PC to add...',
            hintStyle: GoogleFonts.manrope(
              fontSize: 15, 
              color: theme.colorScheme.onSurfaceVariant
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      );
    } else {
      titleWidget = Text(
        'Select Videos',
        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: titleWidget,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchingFiles 
                  ? Icons.stop_circle_outlined
                  : (_isSearching ? Icons.close_rounded : Icons.search_rounded)
            ),
            onPressed: _toggleSearch,
            color: _isSearchingFiles ? theme.colorScheme.error : null,
          ),
          if (_selectedItems.isNotEmpty && !_isSearching)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Add ${_selectedItems.length}',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: (_selectedItems.isNotEmpty && _isSearching) 
         ? FloatingActionButton.extended(
             onPressed: _confirmSelection,
             label: Text('Add ${_selectedItems.length}'),
             icon: const Icon(Icons.check),
           )
         : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
     if (_isLoading) return const Center(child: CircularProgressIndicator());
     
     if (_isSearchingFiles && _filteredItems.isEmpty) {
        return Column(
          children: [
            const LinearProgressIndicator(),
            Padding(
               padding: const EdgeInsets.all(16),
               child: Text('Searching C:/... Items found: ${_filteredItems.length}'),
            )
          ],
        );
     }
     
     // Common list builder
     final itemsToShow = _filteredItems;

     if (itemsToShow.isEmpty) {
       return const Center(child: Text('No videos found'));
     }

     return Column(
       children: [
         if (_isSearchingFiles) ...[
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Deep searching... Found ${itemsToShow.length} items. Tap stop to finish.'),
            ),
         ],
         Expanded(
           child: ListView.builder(
              itemCount: itemsToShow.length,
              itemBuilder: (context, index) {
                final item = itemsToShow[index];
                return _buildFileTile(item, theme);
              },
            ),
         ),
       ],
     );
  }

  Widget _buildFileTile(FileItem item, ThemeData theme) {
    if (item.isDirectory) {
      return ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB020).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.folder_rounded,
            color: Color(0xFFFFB020),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _navigateTo(item.path),
      );
    }

    if (!item.isMedia) {
      return const SizedBox.shrink();
    }

    final isSelected = _selectedItems.containsKey(item.path);

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? Icons.check_rounded : Icons.movie_rounded,
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        item.name,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w500,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.formattedSize,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => _toggleSelection(item),
    );
  }
}
