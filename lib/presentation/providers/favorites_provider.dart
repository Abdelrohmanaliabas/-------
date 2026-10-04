import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/favorites_repository.dart';
import 'service_providers.dart';

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final FavoritesRepository _repository;

  FavoritesNotifier(this._repository) : super(const AsyncValue.loading()) {
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
    } else {
      updated = [song.copyWith(isFavorite: true), ...currentList];
    }
    state = AsyncValue.data(updated);

    try {
      await _repository.toggleFavorite(song);
    } catch (e) {
      // Revert if error
      state = AsyncValue.data(currentList);
    }
  }

  bool isFavorite(String songId) {
    return state.value?.any((s) => s.id == songId) ?? false;
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Song>>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repo);
});
