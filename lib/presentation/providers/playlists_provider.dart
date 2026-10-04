import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/playlist_repository.dart';
import 'service_providers.dart';

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final PlaylistRepository _repository;

  PlaylistsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    try {
      state = const AsyncValue.loading();
      final playlists = await _repository.getUserPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Playlist?> createPlaylist(
    String name, {
    String? description,
    String? artworkUrl,
  }) async {
    try {
      final newPl = await _repository.createPlaylist(
        name,
        description: description,
        artworkUrl: artworkUrl,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([newPl, ...current]);
      return newPl;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    try {
      await _repository.renamePlaylist(playlistId, newName);
      final current = state.value ?? [];
      final updated = current.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(name: newName);
        }
        return p;
      }).toList();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _repository.deletePlaylist(playlistId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((p) => p.id != playlistId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    try {
      await _repository.addSongToPlaylist(playlistId, song);
      final current = state.value ?? [];
      final updated = current.map((p) {
        if (p.id == playlistId) {
          final songs = List<Song>.from(p.songs);
          if (!songs.any((s) => s.id == song.id)) {
            songs.add(song);
          }
          return p.copyWith(songs: songs);
        }
        return p;
      }).toList();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _repository.removeSongFromPlaylist(playlistId, songId);
      final current = state.value ?? [];
      final updated = current.map((p) {
        if (p.id == playlistId) {
          final songs = p.songs.where((s) => s.id != songId).toList();
          return p.copyWith(songs: songs);
        }
        return p;
      }).toList();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return PlaylistsNotifier(repo);
});
