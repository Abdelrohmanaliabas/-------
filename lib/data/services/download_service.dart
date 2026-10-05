import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_exceptions.dart';
import '../../domain/models/song.dart';
import 'full_audio_resolver.dart';

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
    if (!song.isDownloadable) {
      throw const DownloadException(message: 'هذه الأغنية غير مصرح بتحميلها للمشاهدة بدون اتصال');
    }

    try {
      _downloadProgress[song.id] = 0.05;
      _progressController.add(_downloadProgress);

      var downloadUrl = song.audioUrl;
      var songDuration = song.duration;

      // Resolve full stream if this is a short preview
      if (song.duration.inSeconds <= 45 ||
          song.audioUrl.contains('preview') ||
          song.audioUrl.contains('soundhelix') ||
          song.audioUrl.contains('youtube.com')) {
        try {
          final resolved = await FullAudioResolver.resolveFullAudioStream(song.title, song.artist);
          if (resolved != null) {
            downloadUrl = resolved.url;
            songDuration = resolved.duration;
          }
        } catch (_) {}
      }

      final dir = await _getDownloadsDirectory();
      // Clean filename
      final sanitizedTitle = song.id.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${dir.path}/$sanitizedTitle.mp3';
      final file = File(filePath);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw DownloadException(
          message: 'فشل تحميل الملف الصوتي (رمز الاستجابة: ${response.statusCode})',
        );
      }

      final contentLength = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          _downloadProgress[song.id] = (received / contentLength).clamp(0.0, 1.0);
          _progressController.add(_downloadProgress);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      _downloadProgress.remove(song.id);
      _progressController.add(_downloadProgress);

      final downloadedSong = song.copyWith(
        isDownloaded: true,
        localFilePath: filePath,
        duration: songDuration,
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
