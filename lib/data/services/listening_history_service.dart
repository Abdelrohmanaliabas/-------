import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/song.dart';

/// Persistent service that tracks songs listened to by the user,
/// both started and completed in full, for real-time Home Screen recommendations.
class ListeningHistoryService {
  ListeningHistoryService._();

  static const String _recentKey = 'mazikty_recent_history';
  static const String _completedKey = 'mazikty_completed_history';
  static const int _maxItems = 30;

  static List<Song>? _recentCache;
  static List<Song>? _completedCache;

  /// Records that a song was started/listened to.
  static Future<void> recordSongPlayed(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getRecentlyPlayed();

      list.removeWhere((s) =>
          s.id == song.id ||
          (s.title.trim().toLowerCase() == song.title.trim().toLowerCase() &&
              s.artist.trim().toLowerCase() == song.artist.trim().toLowerCase()));
      list.insert(0, song);

      if (list.length > _maxItems) {
        list.removeRange(_maxItems, list.length);
      }
      _recentCache = list;

      final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
      await prefs.setString(_recentKey, encoded);
      debugPrint('📝 Recorded played song: "${song.title}"');
    } catch (e) {
      debugPrint('Error recording played song: $e');
    }
  }

  /// Records that a song was listened to completely (or >= 70% of duration).
  static Future<void> recordSongCompleted(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getCompletedSongs();

      list.removeWhere((s) =>
          s.id == song.id ||
          (s.title.trim().toLowerCase() == song.title.trim().toLowerCase() &&
              s.artist.trim().toLowerCase() == song.artist.trim().toLowerCase()));
      list.insert(0, song);

      if (list.length > _maxItems) {
        list.removeRange(_maxItems, list.length);
      }
      _completedCache = list;

      final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
      await prefs.setString(_completedKey, encoded);
      debugPrint('🎉 Recorded completed song: "${song.title}"');
    } catch (e) {
      debugPrint('Error recording completed song: $e');
    }
  }

  /// Returns songs played by user, ordered most recent first.
  static Future<List<Song>> getRecentlyPlayed({int limit = 20}) async {
    if (_recentCache != null) {
      return _recentCache!.take(limit).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        _recentCache = decoded
            .map((item) => Song.fromJson(item as Map<String, dynamic>))
            .toList();
        return _recentCache!.take(limit).toList();
      }
    } catch (e) {
      debugPrint('Error loading recent history: $e');
    }
    return [];
  }

  /// Returns songs that the user listened to completely.
  static Future<List<Song>> getCompletedSongs({int limit = 20}) async {
    if (_completedCache != null) {
      return _completedCache!.take(limit).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_completedKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        _completedCache = decoded
            .map((item) => Song.fromJson(item as Map<String, dynamic>))
            .toList();
        return _completedCache!.take(limit).toList();
      }
    } catch (e) {
      debugPrint('Error loading completed history: $e');
    }
    return [];
  }

  /// Returns the most recent song played or completed (null if none).
  static Future<Song?> getLastPlayedSong() async {
    final recent = await getRecentlyPlayed(limit: 1);
    if (recent.isNotEmpty) return recent.first;
    final completed = await getCompletedSongs(limit: 1);
    if (completed.isNotEmpty) return completed.first;
    return null;
  }
}
