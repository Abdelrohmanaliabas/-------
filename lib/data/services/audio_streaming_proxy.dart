import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/song.dart';
import 'download_service.dart';
import 'song_audio_resolver.dart';

/// Local HTTP proxy that serves YouTube audio streams and local cached songs with transparent byte-range streaming.
/// ExoPlayer connects to:
/// - http://127.0.0.1:PORT/stream?v=VIDEO_ID
/// - http://127.0.0.1:PORT/play?id=SONG_ID
class AudioStreamingProxy {
  AudioStreamingProxy._();

  static HttpServer? _server;
  static int _port = 0;
  static YoutubeExplode? _yt;
  static YoutubeExplode get _ytClient => _yt ??= YoutubeExplode();
  static final http.Client _httpClient = http.Client();

  // Registry of current active queue songs: songId → Song
  static final Map<String, Song> _songsRegistry = {};

  // Pre-loaded stream info cache: videoId → best AudioOnlyStreamInfo
  static final Map<String, AudioOnlyStreamInfo> _streamInfoCache = {};

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Starts the proxy if not already running. Returns the port number.
  static Future<int> ensureStarted() async {
    if (_server != null && _port > 0) return _port;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    _server!.listen(_handleRequest, onError: (e) {
      debugPrint('AudioProxy server error: $e');
    });
    debugPrint('🎵 AudioStreamingProxy started on port $_port');
    return _port;
  }

  /// Register a list of songs into the active proxy registry.
  static void registerSongs(Iterable<Song> songs) {
    for (final song in songs) {
      _songsRegistry[song.id] = song;
    }
  }

  /// Returns the proxy URL for a given YouTube video ID.
  static String getStreamUrl(String videoId) {
    assert(_port > 0, 'AudioStreamingProxy.ensureStarted() must be called first');
    return 'http://127.0.0.1:$_port/stream?v=$videoId';
  }

  /// Returns the proxy URL for a given Song.
  static String getSongStreamUrl(Song song) {
    assert(_port > 0, 'AudioStreamingProxy.ensureStarted() must be called first');
    _songsRegistry[song.id] = song;
    return 'http://127.0.0.1:$_port/play?id=${Uri.encodeComponent(song.id)}';
  }

  /// Pre-fetches and caches the best audio stream info for a video.
  static Future<bool> preloadStream(String videoId) async {
    if (_streamInfoCache.containsKey(videoId)) {
      return true;
    }
    try {
      debugPrint('🔄 Pre-loading stream manifest for $videoId…');
      final manifest = await _ytClient.videos.streamsClient
          .getManifest(videoId, requireWatchPage: false)
          .timeout(const Duration(seconds: 15));

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        debugPrint('⚠️ No audio streams found for $videoId');
        return false;
      }

      final mp4Streams = audioStreams
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();
      _streamInfoCache[videoId] = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : audioStreams.withHighestBitrate();

      debugPrint('✅ Pre-loaded stream for $videoId (${_streamInfoCache[videoId]!.container.name})');
      return true;
    } catch (e) {
      debugPrint('❌ AudioProxy preload error for v=$videoId: $e');
      return false;
    }
  }

  /// Pre-loads audio for a song in background.
  static Future<void> preloadSong(Song song) async {
    _songsRegistry[song.id] = song;
    try {
      final offline = await DownloadService.findOfflinePathForSong(song);
      if (offline != null && File(offline).existsSync()) {
        return;
      }
      final resolved = await SongAudioResolver.resolveAudio(song);
      final vId = resolved.videoId?.value ?? (song.id.startsWith('yt_') ? song.id.substring(3) : null);
      if (vId != null && vId.isNotEmpty) {
        await preloadStream(vId);
      }
    } catch (_) {}
  }

  /// Evicts the cached stream info for a video.
  static void evictCache(String videoId) {
    _streamInfoCache.remove(videoId);
  }

  // -------------------------------------------------------------------------
  // Internal request handler
  // -------------------------------------------------------------------------

  static Future<void> _handleRequest(HttpRequest req) async {
    try {
      if (req.uri.path == '/play') {
        final songId = req.uri.queryParameters['id'];
        if (songId == null || songId.isEmpty) {
          req.response.statusCode = HttpStatus.badRequest;
          await req.response.close();
          return;
        }

        final song = _songsRegistry[songId] ??
            Song(
              id: songId,
              title: 'Unknown',
              artist: 'Unknown',
              album: '',
              artworkUrl: '',
              audioUrl: '',
              genre: 'عام',
              duration: Duration.zero,
            );

        // 1. Check local offline file
        final offlinePath = await DownloadService.findOfflinePathForSong(song);
        if (offlinePath != null) {
          final file = File(offlinePath);
          if (await file.exists()) {
            await _serveLocalFile(req, file);
            return;
          }
        }

        // 2. Resolve audio
        final resolved = await SongAudioResolver.resolveAudio(song);
        final vId = resolved.videoId?.value ??
            (song.id.startsWith('yt_') ? song.id.substring(3) : null);

        if (vId != null && vId.isNotEmpty) {
          await _serveYouTubeStream(req, vId);
          return;
        }

        if (resolved.url.isNotEmpty &&
            (resolved.url.startsWith('http://') || resolved.url.startsWith('https://'))) {
          await _pipeRemoteUrl(req, resolved.url);
          return;
        }

        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }

      // Default route: /stream?v=VIDEO_ID
      final videoId = req.uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) {
        await _serveYouTubeStream(req, videoId);
        return;
      }

      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
    } catch (e) {
      debugPrint('AudioProxy request error: $e');
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {}
    }
  }

  static Future<void> _serveLocalFile(HttpRequest req, File file) async {
    final length = await file.length();
    final rangeHeader = req.headers.value('range');

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = (parts.length > 1 && parts[1].isNotEmpty)
          ? int.tryParse(parts[1]) ?? (length - 1)
          : (length - 1);
      final clampedEnd = end.clamp(start, length - 1);
      final contentLength = clampedEnd - start + 1;

      req.response.statusCode = HttpStatus.partialContent;
      req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      req.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$clampedEnd/$length');
      req.response.headers.set(HttpHeaders.contentLengthHeader, contentLength.toString());
      req.response.headers.set(HttpHeaders.contentTypeHeader, 'audio/mpeg');

      await req.response.addStream(file.openRead(start, clampedEnd + 1));
    } else {
      req.response.statusCode = HttpStatus.ok;
      req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      req.response.headers.set(HttpHeaders.contentLengthHeader, length.toString());
      req.response.headers.set(HttpHeaders.contentTypeHeader, 'audio/mpeg');
      await req.response.addStream(file.openRead());
    }
    await req.response.close();
  }

  static Future<void> _serveYouTubeStream(HttpRequest req, String videoId) async {
    AudioOnlyStreamInfo? bestStream = _streamInfoCache[videoId];
    if (bestStream == null) {
      debugPrint('⏳ On-demand manifest fetch for $videoId');
      final manifest = await _ytClient.videos.streamsClient
          .getManifest(videoId, requireWatchPage: false)
          .timeout(const Duration(seconds: 15));

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }

      final mp4Streams = audioStreams
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();
      bestStream = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : audioStreams.withHighestBitrate();
      _streamInfoCache[videoId] = bestStream;
    }

    await _pipeRemoteUrl(req, bestStream.url.toString());
  }

  static Future<void> _pipeRemoteUrl(HttpRequest req, String targetUrl) async {
    final upstreamReq = http.Request('GET', Uri.parse(targetUrl));
    final rangeHeader = req.headers.value('range');
    if (rangeHeader != null && rangeHeader.isNotEmpty) {
      upstreamReq.headers['Range'] = rangeHeader;
    }
    upstreamReq.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';

    final streamedRes = await _httpClient.send(upstreamReq);
    req.response.statusCode = streamedRes.statusCode;
    streamedRes.headers.forEach((name, value) {
      final lower = name.toLowerCase();
      if (lower == 'content-type' ||
          lower == 'content-length' ||
          lower == 'content-range' ||
          lower == 'accept-ranges') {
        req.response.headers.set(name, value);
      }
    });

    await req.response.addStream(streamedRes.stream);
    await req.response.close();
  }

  static void dispose() {
    _server?.close(force: true);
    _server = null;
    _port = 0;
    _yt?.close();
    _yt = null;
    _streamInfoCache.clear();
    _songsRegistry.clear();
  }
}
