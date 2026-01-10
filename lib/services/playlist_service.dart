import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';

/// Playlist Service
///
/// Manages saving and loading playlists to local storage.
class PlaylistService {
  static const String _storageKey = 'vlc_playlists';

  /// Get all saved playlists
  static Future<List<Playlist>> getPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      return [];
    }
  }

  /// Save all playlists
  static Future<void> savePlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = playlists.map((p) => p.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  /// Add a new playlist
  static Future<Playlist> createPlaylist(String name) async {
    final playlists = await getPlaylists();
    final newPlaylist = Playlist.create(name);
    playlists.add(newPlaylist);
    await savePlaylists(playlists);
    return newPlaylist;
  }

  /// Update an existing playlist
  static Future<void> updatePlaylist(Playlist playlist) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = playlist;
      await savePlaylists(playlists);
    }
  }

  /// Delete a playlist
  static Future<void> deletePlaylist(String id) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == id);
    await savePlaylists(playlists);
  }

  /// Get a single playlist by ID
  static Future<Playlist?> getPlaylist(String id) async {
    final playlists = await getPlaylists();
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
