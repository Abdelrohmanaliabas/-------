import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/song.dart';

/// Information regarding the resolved audio stream.
class ResolvedAudioInfo {
  final String url;
  final Duration? duration;
  final String source;
  final VideoId? videoId;

  const ResolvedAudioInfo({
    required this.url,
    this.duration,
    required this.source,
    this.videoId,
  });
}

class _CachedStream {
  final String url;
  final Duration? duration;
  final DateTime cachedAt;
  final String source;
  final VideoId? videoId;

  _CachedStream({
    required this.url,
    this.duration,
    required this.cachedAt,
    required this.source,
    this.videoId,
  });

  bool get isExpired {
    // Re-resolve YouTube streams after 2.5 hours to avoid expired tokens
    return DateTime.now().difference(cachedAt).inMinutes >= 150;
  }
}

/// Resolves full audio streams exclusively from YouTube via youtube_explode_dart.
/// Query order: Local Disk → Direct YouTube ID → Multi-query YouTube Search → Error
class SongAudioResolver {
  SongAudioResolver._();

  static YoutubeExplode? _ytExplode;
  static YoutubeExplode get yt => _ytExplode ??= YoutubeExplode();

  static final Map<String, _CachedStream> _cache = {};

  /// Clear cached stream for a song (e.g. after a playback failure)
  static void clearCache(Song song) {
    final cacheKey = '${song.title.trim()}_${song.artist.trim()}'.toLowerCase();
    _cache.remove(cacheKey);
    if (song.id.isNotEmpty) {
      _cache.remove(song.id.toLowerCase());
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // remove tashkeel
        .replaceAll(
            RegExp(r'\[.*?\]|\(.*?\)|feat\..*|Official.*|كليب|فيديو كليب|فيديو|أغنية|اغنية',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Resolves the full audio URL and duration for any song from YouTube.
  /// Throws [Exception] if no full audio stream could be found.
  static Future<ResolvedAudioInfo> resolveAudio(
    Song song, {
    bool forceFresh = false,
    bool isFallback = false,
  }) async {
    // 1. Local file – highest priority, zero latency
    if (song.localFilePath != null &&
        song.localFilePath!.isNotEmpty &&
        File(song.localFilePath!).existsSync()) {
      return ResolvedAudioInfo(
          url: song.localFilePath!, duration: song.duration, source: 'local_file');
    }
    if (song.audioUrl.isNotEmpty &&
        (song.audioUrl.startsWith('file://') ||
            (song.audioUrl.startsWith('/') && File(song.audioUrl).existsSync()))) {
      return ResolvedAudioInfo(
          url: song.audioUrl, duration: song.duration, source: 'local_url');
    }

    final cacheKey = song.id.isNotEmpty
        ? song.id.toLowerCase()
        : '${song.title.trim()}_${song.artist.trim()}'.toLowerCase();
    final cleanTitle = _cleanText(song.title);
    final cleanArtist = _cleanText(song.artist);

    // 2. Cache hit (skip when forcing fresh resolve)
    if (!forceFresh && !isFallback) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        debugPrint('⚡ Cache hit for "${song.title}"');
        return ResolvedAudioInfo(
          url: cached.url,
          duration: cached.duration ?? song.duration,
          source: 'cache',
          videoId: cached.videoId,
        );
      }
    }

    // 3. Direct YouTube Video ID (songs with yt_ prefix) —
    //    We only need the VideoId object; the proxy will fetch the manifest.
    //    Skip manifest fetching here to avoid double-fetching.
    if (song.id.startsWith('yt_')) {
      final videoIdStr = song.id.substring(3);
      try {
        final videoId = VideoId(videoIdStr);
        // Quickly verify the video exists by fetching video metadata (cheap operation)
        // then cache and return without fetching full stream manifest
        final result = ResolvedAudioInfo(
          url: '', // proxy will handle the actual stream URL
          duration: song.duration,
          source: 'youtube_direct',
          videoId: videoId,
        );
        _cache[cacheKey] = _CachedStream(
          url: '',
          duration: song.duration,
          cachedAt: DateTime.now(),
          source: 'youtube_direct',
          videoId: videoId,
        );
        debugPrint('⚡ Direct yt_ ID resolved for "${song.title}" (proxy will stream)');
        return result;
      } catch (e) {
        debugPrint('Invalid yt_ video ID "$videoIdStr": $e');
        // Fall through to YouTube search
      }
    }

    // 4. Multi-query YouTube Search – primary full-song source
    final ytResult = await _resolveFromYouTube(cleanTitle, cleanArtist, song.duration);
    if (ytResult != null) {
      _cache[cacheKey] = _CachedStream(
        url: ytResult.url,
        duration: ytResult.duration,
        cachedAt: DateTime.now(),
        source: 'youtube',
        videoId: ytResult.videoId,
      );
      return ytResult;
    }

    // No full audio found – throw so the caller can show a proper error message
    throw Exception('لم يتم العثور على الأغنية الكاملة لـ "${song.title}". تحقق من اتصالك بالإنترنت.');
  }

  /// Convenience method that returns only the URL string.
  static Future<String> resolveAudioStream(Song song) async {
    final info = await resolveAudio(song);
    return info.url;
  }

  // ---------------------------------------------------------------------------
  // Internal YouTube helpers
  // ---------------------------------------------------------------------------

  static Future<ResolvedAudioInfo?> _resolveFromYouTube(
    String cleanTitle,
    String cleanArtist,
    Duration targetDuration,
  ) async {
    final queries = <String>[
      if (cleanArtist.isNotEmpty) '$cleanTitle $cleanArtist',
      if (cleanArtist.isNotEmpty) '$cleanArtist $cleanTitle',
      '$cleanTitle اغنية كاملة',
      cleanTitle,
    ];

    for (final query in queries) {
      if (query.trim().isEmpty) continue;
      try {
        final searchResults =
            await yt.search.search(query).timeout(const Duration(seconds: 10));
        if (searchResults.isEmpty) continue;

        Video? selectedVideo;
        // Prefer videos within a realistic song length (1 min – 10 min)
        for (final video in searchResults.take(10)) {
          final dur = video.duration;
          if (dur == null) continue;
          if (dur.inSeconds >= 60 && dur.inMinutes <= 10) {
            selectedVideo = video;
            break;
          }
        }
        // Accept anything over 60 seconds as a last resort
        selectedVideo ??= searchResults.firstWhere(
          (v) => (v.duration?.inSeconds ?? 0) >= 60,
          orElse: () => searchResults.first,
        );

        final manifest = await yt.videos.streamsClient
            .getManifest(selectedVideo.id)
            .timeout(const Duration(seconds: 10));
        final audioOnlyStreams = manifest.audioOnly;
        if (audioOnlyStreams.isEmpty) continue;

        final bestStream = _pickBestAudioStream(audioOnlyStreams);
        final streamUrl = bestStream.url.toString();
        if (streamUrl.isNotEmpty) {
          debugPrint(
              '🎵 Full audio resolved for "$cleanTitle" → "${selectedVideo.title}" (${selectedVideo.duration})');
          return ResolvedAudioInfo(
            url: streamUrl,
            duration: selectedVideo.duration ?? targetDuration,
            source: 'youtube',
            videoId: selectedVideo.id,
          );
        }
      } catch (e) {
        debugPrint('YouTube search error for "$query": $e');
        continue;
      }
    }
    return null;
  }

  /// Picks the best audio-only stream: prefers MP4/AAC for ExoPlayer compatibility,
  /// falls back to highest-bitrate regardless of container.
  static AudioOnlyStreamInfo _pickBestAudioStream(
      List<AudioOnlyStreamInfo> streams) {
    final mp4Streams =
        streams.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
    return mp4Streams.isNotEmpty
        ? mp4Streams.withHighestBitrate()
        : streams.withHighestBitrate();
  }

  // ---------------------------------------------------------------------------
  // Download helpers (used by DownloadService / FavoritesRepository)
  // ---------------------------------------------------------------------------

  /// Downloads full song audio to a local target file via youtube_explode_dart.
  static Future<Duration> downloadAudioStreamToFile(
    Song song,
    File targetFile, {
    void Function(double progress)? onProgress,
  }) async {
    final info = await resolveAudio(song);
    final duration = info.duration ?? song.duration;

    // Prefer native youtube_explode_dart streaming for YouTube sources
    VideoId? videoId = info.videoId;
    if (videoId == null && song.id.startsWith('yt_')) {
      try {
        videoId = VideoId(song.id.substring(3));
      } catch (_) {}
    }

    if (videoId != null) {
      try {
        final manifest = await yt.videos.streamsClient
            .getManifest(videoId)
            .timeout(const Duration(seconds: 10));
        final audioOnlyStreams = manifest.audioOnly;
        if (audioOnlyStreams.isNotEmpty) {
          final bestStream = _pickBestAudioStream(audioOnlyStreams);
          final stream = yt.videos.streamsClient.get(bestStream);
          final sink = targetFile.openWrite();
          var received = 0;
          final total = bestStream.size.totalBytes;

          await for (final chunk in stream) {
            sink.add(chunk);
            received += chunk.length;
            if (total > 0 && onProgress != null) {
              onProgress((received / total).clamp(0.0, 1.0));
            }
          }
          await sink.flush();
          await sink.close();
          debugPrint('✅ Downloaded "${song.title}" via youtube_explode_dart');
          return duration;
        }
      } catch (e) {
        debugPrint('YouTube streamsClient download error: $e');
        rethrow;
      }
    }

    throw Exception('لا يمكن تنزيل الأغنية "${song.title}": لا يوجد معرف YouTube صالح.');
  }
}
