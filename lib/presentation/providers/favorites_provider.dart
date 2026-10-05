import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/data/services/download_service.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/domain/repositories/favorites_repository.dart';
import 'service_providers.dart';

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final FavoritesRepository _repository;
  final DownloadService _downloadService;

  FavoritesNotifier(this._repository, this._downloadService)
      : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      state = const AsyncValue.loading();
      final songs = await _repository.getFavorites();
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final currentList = state.value ?? [];
    final exists = currentList.any((s) => s.id == song.id);

    List<Song> updated;
    if (exists) {
      updated = currentList.where((s) => s.id != song.id).toList();
      state = AsyncValue.data(updated);
      try {
        await _repository.toggleFavorite(song);
      } catch (e) {
        state = AsyncValue.data(currentList);
      }
    } else {
      // Adding to favorites: also auto-cache for offline availability
      final newFav = song.copyWith(isFavorite: true);
      updated = [newFav, ...currentList];
      state = AsyncValue.data(updated);

      try {
        await _repository.toggleFavorite(song);
        // Start background offline download so it works without web/internet
        _autoCacheSongForOffline(newFav);
      } catch (e) {
        state = AsyncValue.data(currentList);
      }
    }
  }

  Future<void> _autoCacheSongForOffline(Song song) async {
    try {
      final downloaded = await _downloadService.downloadSong(song);
      if (downloaded != null) {
        await _repository.updateFavorite(downloaded);
        final current = state.value ?? [];
        final updated = current.map((s) => s.id == song.id ? downloaded : s).toList();
        state = AsyncValue.data(updated);
        debugPrint('Song "${song.title}" cached offline for favorites playback.');
      }
    } catch (e) {
      debugPrint('Background offline caching skipped for "${song.title}": $e');
    }
  }

  bool isFavorite(String songId) {
    return state.value?.any((s) => s.id == songId) ?? false;
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Song>>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  final downloadService = ref.watch(downloadServiceProvider);
  return FavoritesNotifier(repo, downloadService);
});
