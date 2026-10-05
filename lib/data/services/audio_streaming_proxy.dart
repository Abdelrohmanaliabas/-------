import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Local HTTP proxy that serves YouTube audio streams with transparent byte-range streaming.
/// ExoPlayer connects to http://127.0.0.1:PORT/stream?v=VIDEO_ID
class AudioStreamingProxy {
  AudioStreamingProxy._();

  static HttpServer? _server;
  static int _port = 0;
  static YoutubeExplode? _yt;
  static YoutubeExplode get _ytClient => _yt ??= YoutubeExplode();
  static final http.Client _httpClient = http.Client();

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

  /// Returns the proxy URL for a given YouTube video ID.
  static String getStreamUrl(String videoId) {
    assert(_port > 0, 'AudioStreamingProxy.ensureStarted() must be called first');
    return 'http://127.0.0.1:$_port/stream?v=$videoId';
  }

  /// Pre-fetches and caches the best audio stream info for a video.
  static Future<bool> preloadStream(String videoId) async {
    if (_streamInfoCache.containsKey(videoId)) {
      debugPrint('⚡ Stream already pre-loaded for $videoId');
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

      debugPrint('✅ Pre-loaded stream for $videoId (${_streamInfoCache[videoId]!.container.name} ${_streamInfoCache[videoId]!.bitrate.kiloBitsPerSecond.round()} kbps)');
      return true;
    } catch (e) {
      debugPrint('❌ AudioProxy preload error for v=$videoId: $e');
      return false;
    }
  }

  /// Evicts the cached stream info for a video (e.g. after a playback failure).
  static void evictCache(String videoId) {
    _streamInfoCache.remove(videoId);
  }

  // -------------------------------------------------------------------------
  // Internal request handler
  // -------------------------------------------------------------------------

  static Future<void> _handleRequest(HttpRequest req) async {
    final videoId = req.uri.queryParameters['v'];
    if (videoId == null || videoId.isEmpty) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }

    try {
      // 1. Use pre-loaded stream info if available
      AudioOnlyStreamInfo? bestStream = _streamInfoCache[videoId];
      if (bestStream != null) {
        debugPrint('⚡ Serving pre-loaded stream for $videoId');
      } else {
        debugPrint('⏳ On-demand manifest fetch for $videoId (preload was missed)');
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

      // 2. Prepare upstream HTTP request with exact Range header
      final upstreamReq = http.Request('GET', bestStream.url);
      final rangeHeader = req.headers.value('range');
      if (rangeHeader != null && rangeHeader.isNotEmpty) {
        upstreamReq.headers['Range'] = rangeHeader;
      }
      upstreamReq.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';

      final streamedRes = await _httpClient.send(upstreamReq);

      // 3. Forward status code and streaming headers immediately to ExoPlayer
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

      // 4. Pipe upstream audio chunks to ExoPlayer with zero delay
      await req.response.addStream(streamedRes.stream);
    } catch (e) {
      debugPrint('AudioProxy request error for v=$videoId: $e');
      try {
        req.response.statusCode = HttpStatus.internalServerError;
      } catch (_) {}
    } finally {
      try {
        await req.response.close();
      } catch (_) {}
    }
  }

  static void dispose() {
    _server?.close(force: true);
    _server = null;
    _port = 0;
    _yt?.close();
    _yt = null;
    _streamInfoCache.clear();
  }
}
