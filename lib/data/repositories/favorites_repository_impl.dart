import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../mock/sample_music_data.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  static const String _favoritesKey = 'mazikty_favorites';

  @override
  Future<List<Song>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoritesKey);

    if (jsonString == null) {
      // First-time setup: initialize with sample favorites
      final initialFavorites = SampleMusicData.songs.where((s) => s.isFavorite).toList();
      await _saveFavorites(initialFavorites);
      return initialFavorites;
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) {
        final song = Song.fromJson(item as Map<String, dynamic>).copyWith(isFavorite: true);
        // Verify local file exists for offline readiness
        if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
          return song.copyWith(isDownloaded: true);
        }
        return song;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> isFavorite(String songId) async {
    final favorites = await getFavorites();
    return favorites.any((s) => s.id == songId);
  }

  @override
  Future<void> addFavorite(Song song) async {
    final favorites = await getFavorites();
    if (!favorites.any((s) => s.id == song.id)) {
      favorites.insert(0, song.copyWith(isFavorite: true));
      await _saveFavorites(favorites);
    }
  }

  @override
  Future<void> updateFavorite(Song song) async {
    final favorites = await getFavorites();
    final index = favorites.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      favorites[index] = song.copyWith(isFavorite: true);
      await _saveFavorites(favorites);
    }
  }

  @override
  Future<void> removeFavorite(String songId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((s) => s.id == songId);
    await _saveFavorites(favorites);
  }

  @override
  Future<void> toggleFavorite(Song song) async {
    final favorite = await isFavorite(song.id);
    if (favorite) {
      await removeFavorite(song.id);
    } else {
      await addFavorite(song);
    }
  }

  Future<void> _saveFavorites(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = songs.map((s) => s.toJson()).toList();
    await prefs.setString(_favoritesKey, jsonEncode(jsonList));
  }
}
