import '../models/song.dart';

abstract class FavoritesRepository {
  Future<List<Song>> getFavorites();
  Future<bool> isFavorite(String songId);
  Future<void> addFavorite(Song song);
  Future<void> updateFavorite(Song song);
  Future<void> removeFavorite(String songId);
  Future<void> toggleFavorite(Song song);
}
