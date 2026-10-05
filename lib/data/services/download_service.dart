import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_exceptions.dart';
import '../../domain/models/song.dart';
import 'song_audio_resolver.dart';

class DownloadService {
  static const String _downloadKey = 'mazikty_downloaded_songs';
  final _progressController = StreamController<Map<String, double>>.broadcast();
  final Map<String, double> _downloadProgress = {};

  Stream<Map<String, double>> get progressStream => _progressController.stream;
  Map<String, double> get currentProgress => Map.unmodifiable(_downloadProgress);

  static Future<String> getExpectedOfflinePath(String songId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = songId.replaceAll(RegExp(r'[^\w\s]+'), '_');
    return '${docsDir.path}/mazikty_offline/$sanitizedTitle.mp3';
  }

  /// Locates an existing offline local audio file for a song by ID, path, or title
  static Future<String?> findOfflinePathForSong(Song song) async {
    try {
      // 1. Explicit localFilePath
      if (song.localFilePath != null && song.localFilePath!.isNotEmpty && File(song.localFilePath!).existsSync()) {
        return song.localFilePath;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${docsDir.path}/mazikty_offline');
      if (!await offlineDir.exists()) return null;

      // 2. By sanitized song ID
      final idSanitized = song.id.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final idPath = '${offlineDir.path}/$idSanitized.mp3';
      if (File(idPath).existsSync()) return idPath;

      // 3. By sanitized title & artist
      final titleArtist = '${song.title}_${song.artist}'.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]+'), '_').trim();
      final titleArtistPath = '${offlineDir.path}/$titleArtist.mp3';
      if (File(titleArtistPath).existsSync()) return titleArtistPath;

      // 4. By sanitized title alone
      final titleOnly = song.title.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]+'), '_').trim();
      final titlePath = '${offlineDir.path}/$titleOnly.mp3';
      if (File(titlePath).existsSync()) return titlePath;
    } catch (_) {}

    return null;
  }

  Future<Directory> _getDownloadsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${docsDir.path}/mazikty_offline');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  Future<List<Song>> getDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_downloadKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      final songs = list.map((item) => Song.fromJson(item as Map<String, dynamic>)).toList();

      // Verify files still exist on disk
      final validSongs = <Song>[];
      for (final song in songs) {
        if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
          validSongs.add(song.copyWith(isDownloaded: true));
        }
      }
      return validSongs;
    } catch (e) {
      debugPrint('Error parsing downloaded songs: $e');
      return [];
    }
  }

  Future<bool> isSongDownloaded(String songId) async {
    final songs = await getDownloadedSongs();
    return songs.any((s) => s.id == songId);
  }

  Future<Song?> downloadSong(Song song) async {
    try {
      _downloadProgress[song.id] = 0.05;
      _progressController.add(_downloadProgress);

      final dir = await _getDownloadsDirectory();
      final sanitizedTitle = song.id.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${dir.path}/$sanitizedTitle.mp3';
      final file = File(filePath);

      // Download audio stream using native streamsClient or chunked HTTP
      final duration = await SongAudioResolver.downloadAudioStreamToFile(
        song,
        file,
        onProgress: (progress) {
          _downloadProgress[song.id] = progress;
          _progressController.add(_downloadProgress);
        },
      );

      _downloadProgress.remove(song.id);
      _progressController.add(_downloadProgress);

      final downloadedSong = song.copyWith(
        isDownloaded: true,
        localFilePath: filePath,
        duration: duration.inSeconds > 0 ? duration : song.duration,
      );

      // Persist in preferences
      await _saveSongToPrefs(downloadedSong);

      return downloadedSong;
    } catch (e) {
      _downloadProgress.remove(song.id);
      _progressController.add(_downloadProgress);
      debugPrint('Download error: $e');
      throw DownloadException(message: 'حدث خطأ أثناء تنزيل "${song.title}": $e');
    }
  }

  Future<void> _saveSongToPrefs(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getDownloadedSongs();
    songs.removeWhere((s) => s.id == song.id);
    songs.insert(0, song);

    final jsonList = songs.map((s) => s.toJson()).toList();
    await prefs.setString(_downloadKey, jsonEncode(jsonList));
  }

  Future<void> deleteDownloadedSong(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getDownloadedSongs();
    final index = songs.indexWhere((s) => s.id == songId);

    if (index >= 0) {
      final song = songs[index];
      if (song.localFilePath != null) {
        final file = File(song.localFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      songs.removeAt(index);
      final jsonList = songs.map((s) => s.toJson()).toList();
      await prefs.setString(_downloadKey, jsonEncode(jsonList));
    }
  }
}
