import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/vlc_provider.dart';
import '../models/file_item.dart';

/// File Browser Screen
///
/// Allows browsing files on the VLC host and opening them.
class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  List<FileItem> _items = [];
  List<FileItem> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  
  // Navigation stack for back button
  final List<String> _pathStack = [];
  String _currentPath = '';

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isSearchingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadRootDrives();
    // Use debounce for search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Timer? _debounceTimer;

  bool _searchCancelled = false;

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performSearch();
    });
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
      _filteredItems = []; // Clear previous results
    });

    final provider = context.read<VlcProvider>();
    try {
      // Use streaming search
      await provider.searchFilesStream(
        'file:///C:/', // Always search C root as requested
        query,
        onFound: (batch) {
          if (!mounted) return;
          
          final newItems = batch.map((m) => FileItem.fromMap(m)).toList();
          setState(() {
            _filteredItems.addAll(newItems);
            // Re-sort
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
      if (mounted) {
        setState(() {
          _isSearchingFiles = false;
        });
      }
    }
  }

  void _stopSearch() {
    _searchCancelled = true;
    setState(() {
      _isSearchingFiles = false;
    });
  }

  void _toggleSearch() {
    // If currently searching deep, stop it first
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

  /// Load root drives (Windows) or home directory (Linux/macOS)
  Future<void> _loadRootDrives() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<VlcProvider>();
    
    // Start with common paths - try C: drive first for Windows
    // VLC uses file:/// URI format
    String startPath = 'file:///C:/';
    
    try {
      final items = await provider.browseDirectory(startPath);
      
      if (items.isEmpty) {
        // Try root for Linux/macOS
        startPath = 'file:///';
        final rootItems = await provider.browseDirectory(startPath);
        _setItems(rootItems, startPath);
      } else {
        _setItems(items, startPath);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to browse files';
      });
    }
  }

  void _setItems(List<Map<String, String>> rawItems, String path) {
    final items = rawItems.map((m) => FileItem.fromMap(m)).toList();
    
    // Sort: directories first, then by name
    items.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    setState(() {
      _items = items;
      _currentPath = path;
      _isLoading = false;
      _error = null;
      _filteredItems = items;
    });
  }

  Future<void> _navigateTo(String path) async {
    // Save current path for back navigation
    _pathStack.add(_currentPath);
    
    // Clear search when navigating
    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<VlcProvider>();
    
    try {
      final items = await provider.browseDirectory(path);
      _setItems(items, path);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to open folder';
      });
      // Remove from stack since navigation failed
      if (_pathStack.isNotEmpty) {
        _pathStack.removeLast();
      }
    }
  }

  Future<void> _goBack() async {
    // If searching, close search first
    if (_isSearching) {
      _toggleSearch();
      return;
    }

    if (_pathStack.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final previousPath = _pathStack.removeLast();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<VlcProvider>();
    
    try {
      final items = await provider.browseDirectory(previousPath);
      _setItems(items, previousPath);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to go back';
      });
    }
  }

  Future<void> _playFile(FileItem item) async {
    HapticFeedback.mediumImpact();
    
    final provider = context.read<VlcProvider>();
    await provider.playFile(item.path);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onItemTap(FileItem item) {
    if (item.isDirectory) {
      _navigateTo(item.path);
    } else if (item.isMedia) {
      _playFile(item);
    }
  }

  String _getDisplayPath() {
    // Convert file URI to readable path
    String display = _currentPath
        .replaceFirst('file:///', '')
        .replaceAll('%20', ' ');
    
    if (display.isEmpty) display = '/';
    return display;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: _isSearching
            ? Container(
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
                    hintText: 'Search PC...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              )
            : Text(
                'Browse Files',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchingFiles 
                  ? Icons.stop_circle_outlined 
                  : (_isSearching ? Icons.close_rounded : Icons.search_rounded)
            ),
            onPressed: _toggleSearch,
            color: _isSearchingFiles ? theme.colorScheme.error : null,
            tooltip: _isSearchingFiles ? 'Stop' : (_isSearching ? 'Close' : 'Search'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayPath(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_searchQuery.isNotEmpty && !_isLoading)
                  Text(
                    '${_filteredItems.length} results',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Header for search status (shown above list)
    Widget? searchHeader;
    if (_isSearchingFiles) {
       searchHeader = Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           const LinearProgressIndicator(),
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Text(
               'Deep searching C:/... Found ${_filteredItems.length} items (tap stop button to finish)',
               style: GoogleFonts.manrope(
                 fontSize: 12,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
             ),
           ),
         ],
       );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.manrope(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadRootDrives,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty && !_isSearchingFiles) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty 
                  ? Icons.search_off_rounded 
                  : Icons.folder_open_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No matches found'
                  : 'Empty folder',
              style: GoogleFonts.manrope(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try checking spelling or deeper folders',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        if (searchHeader != null) searchHeader,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _searchController.clear();
              await _navigateTo(_currentPath);
            },
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return _buildFileItem(item, theme);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(FileItem item, ThemeData theme) {
    // Determine icon and colors
    IconData icon;
    Color iconColor;
    
    if (item.isDirectory) {
      icon = Icons.folder_rounded;
      iconColor = const Color(0xFFFFB020);
    } else if (item.isVideo) {
      icon = Icons.movie_rounded;
      iconColor = theme.colorScheme.primary;
    } else if (item.isAudio) {
      icon = Icons.music_note_rounded;
      iconColor = const Color(0xFF00D4AA);
    } else {
      icon = Icons.insert_drive_file_rounded;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    final isPlayable = item.isMedia;

    // Highlight search matches
    Widget titleWidget;
    if (_searchQuery.isNotEmpty) {
      titleWidget = _buildHighlightedText(
        item.name,
        _searchQuery,
        theme,
        isPlayable || item.isDirectory,
      );
    } else {
      titleWidget = Text(
        item.name,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isPlayable || item.isDirectory
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: titleWidget,
      subtitle: item.isDirectory
          ? null
          : Text(
              item.formattedSize,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: item.isDirectory
          ? Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : isPlayable
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Play',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              : null,
      onTap: (item.isDirectory || isPlayable) ? () => _onItemTap(item) : null,
    );
  }

  /// Build text with highlighted search matches
  Widget _buildHighlightedText(
    String text,
    String query,
    ThemeData theme,
    bool isPrimary,
  ) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (!lowerText.contains(lowerQuery)) {
      return Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isPrimary
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    int start = 0;
    
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ));
      
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isPrimary
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
