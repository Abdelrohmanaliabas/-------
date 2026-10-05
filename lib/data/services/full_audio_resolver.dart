import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ResolvedAudioInfo {
  final String url;
  final Duration duration;

  const ResolvedAudioInfo({
    required this.url,
    required this.duration,
  });
}

class FullAudioResolver {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, ResolvedAudioInfo> _cache = {};

  static String _cleanQuery(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Resolves the full-length (100% complete) audio stream for any song title & artist.
  static Future<ResolvedAudioInfo?> resolveFullAudioStream(String title, String artist) async {
    final key = '${title.trim().toLowerCase()}_${artist.trim().toLowerCase()}';
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final cleanTitle = _cleanQuery(title);
      final cleanArtist = _cleanQuery(artist);
      final searchQueries = [
        '$cleanTitle $cleanArtist',
        cleanTitle,
      ];

      for (final query in searchQueries) {
        if (query.isEmpty) continue;
        try {
          final searchResult = await _yt.search.search(query).timeout(const Duration(seconds: 4));
          for (final video in searchResult.take(3)) {
            // Avoid overly short videos or 10+ hour compilations if possible
            final dur = video.duration ?? Duration.zero;
            if (dur.inSeconds >= 60 && dur.inHours < 1) {
              final manifest = await _yt.videos.streamsClient.getManifest(video.id).timeout(const Duration(seconds: 3));
              final audioStreams = manifest.audioOnly;
              if (audioStreams.isNotEmpty) {
                final bestStream = audioStreams.withHighestBitrate();
                final info = ResolvedAudioInfo(
                  url: bestStream.url.toString(),
                  duration: dur,
                );
                _cache[key] = info;
                return info;
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error resolving full audio for $title - $artist: $e');
    }
    return null;
  }

  static void dispose() {
    _yt.close();
  }
}
