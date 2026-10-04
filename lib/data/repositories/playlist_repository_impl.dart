import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../mock/sample_music_data.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  static const String _playlistsKey = 'mazikty_playlists';
  final _uuid = const Uuid();

  @override
  Future<List<Playlist>> getUserPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_playlistsKey);

    if (jsonString == null) {
      final initialPlaylists = SampleMusicData.playlists;
      await _savePlaylists(initialPlaylists);
      return initialPlaylists;
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Playlist.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return SampleMusicData.playlists;
    }
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    final playlists = await getUserPlaylists();
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Playlist> createPlaylist(
    String name, {
    String? description,
    String? artworkUrl,
  }) async {
    final playlists = await getUserPlaylists();
    final newPlaylist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      artworkUrl: artworkUrl ??
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      songs: [],
      isCustom: true,
      createdAt: DateTime.now(),
    );

    playlists.insert(0, newPlaylist);
    await _savePlaylists(playlists);
    return newPlaylist;
  }

  @override
  Future<void> renamePlaylist(String playlistId, String newName) async {
    final playlists = await getUserPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      playlists[index] = playlists[index].copyWith(name: newName);
      await _savePlaylists(playlists);
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    final playlists = await getUserPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists(playlists);
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlists = await getUserPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final currentSongs = List<Song>.from(playlists[index].songs);
      if (!currentSongs.any((s) => s.id == song.id)) {
        currentSongs.add(song);
        playlists[index] = playlists[index].copyWith(songs: currentSongs);
        await _savePlaylists(playlists);
      }
    }
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlists = await getUserPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final currentSongs = List<Song>.from(playlists[index].songs);
      currentSongs.removeWhere((s) => s.id == songId);
      playlists[index] = playlists[index].copyWith(songs: currentSongs);
      await _savePlaylists(playlists);
    }
  }

  Future<void> _savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = playlists.map((p) => p.toJson()).toList();
    await prefs.setString(_playlistsKey, jsonEncode(jsonList));
  }
}
