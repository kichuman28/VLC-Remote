import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../providers/vlc_provider.dart';
import 'playlist_editor_screen.dart';

/// Playlists Screen
///
/// Shows all saved playlists and allows creating new ones.
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final playlists = await PlaylistService.getPlaylists();
    setState(() {
      _playlists = playlists;
      _isLoading = false;
    });
  }

  Future<void> _createPlaylist() async {
    final name = await _showNameDialog('New Playlist', '');
    if (name != null && name.isNotEmpty) {
      final playlist = await PlaylistService.createPlaylist(name);
      await _loadPlaylists();
      if (mounted) {
        _openPlaylistEditor(playlist);
      }
    }
  }

  void _openPlaylistEditor(Playlist playlist) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PlaylistEditorScreen(playlist: playlist),
          ),
        )
        .then((_) => _loadPlaylists());
  }

  Future<void> _playPlaylist(Playlist playlist) async {
    if (playlist.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist is empty. Add some videos first.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    
    final provider = context.read<VlcProvider>();
    final uris = playlist.items.map((i) => i.uri).toList();
    await provider.playCustomPlaylist(uris);
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playing ${playlist.name}',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Playlist?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PlaylistService.deletePlaylist(playlist.id);
      await _loadPlaylists();
    }
  }

  Future<String?> _showNameDialog(String title, String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Playlists',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? _buildEmptyState(theme)
              : _buildPlaylistList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlaylist,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Playlist',
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.queue_music_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Playlists Yet',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a playlist to queue your favorite videos',
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

  Widget _buildPlaylistList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _buildPlaylistTile(playlist, theme);
      },
    );
  }

  Widget _buildPlaylistTile(Playlist playlist, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.playlist_play_rounded,
          color: theme.colorScheme.primary,
          size: 26,
        ),
      ),
      title: Text(
        playlist.name,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${playlist.items.length} video${playlist.items.length != 1 ? 's' : ''}',
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          IconButton(
            icon: const Icon(Icons.play_circle_filled_rounded),
            iconSize: 36,
            color: theme.colorScheme.primary,
            onPressed: () => _playPlaylist(playlist),
            tooltip: 'Play',
          ),
          // More options
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _openPlaylistEditor(playlist);
                  break;
                case 'delete':
                  _deletePlaylist(playlist);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text('Edit', style: GoogleFonts.manrope()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Text('Delete', style: GoogleFonts.manrope(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _openPlaylistEditor(playlist),
    );
  }
}
