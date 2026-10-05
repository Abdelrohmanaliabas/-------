import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Local HTTP proxy that serves YouTube audio streams via youtube_explode_dart.
/// ExoPlayer connects to http://127.0.0.1:PORT/stream?v=VIDEO_ID
/// The proxy fetches the stream using YT's native auth — avoiding 403 errors.
class AudioStreamingProxy {
  AudioStreamingProxy._();

  static HttpServer? _server;
  static int _port = 0;
  static YoutubeExplode? _yt;
  static YoutubeExplode get _ytClient => _yt ??= YoutubeExplode();

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

  static Future<void> _handleRequest(HttpRequest req) async {
    final videoId = req.uri.queryParameters['v'];
    if (videoId == null || videoId.isEmpty) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }

    try {
      // Fetch stream manifest via youtube_explode_dart — handles all YouTube auth internally
      final manifest = await _ytClient.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 20));

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }

      // Prefer MP4/AAC for maximum ExoPlayer compatibility
      final mp4Streams = audioStreams
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();
      final bestStream = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : audioStreams.withHighestBitrate();

      final totalSize = bestStream.size.totalBytes;
      final isRangeRequest = req.headers.value('range') != null;

      // Parse Range header
      int start = 0;
      int end = totalSize > 0 ? totalSize - 1 : 0;
      if (isRangeRequest) {
        final rangeHeader = req.headers.value('range')!;
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
        if (match != null) {
          start = int.tryParse(match.group(1)!) ?? 0;
          final endStr = match.group(2) ?? '';
          end = endStr.isNotEmpty ? (int.tryParse(endStr) ?? end) : end;
        }
      }

      // Set response headers
      req.response.statusCode =
          isRangeRequest ? HttpStatus.partialContent : HttpStatus.ok;

      final contentType = bestStream.container.name.toLowerCase() == 'mp4'
          ? ContentType('audio', 'mp4')
          : ContentType('audio', 'webm');
      req.response.headers.contentType = contentType;
      req.response.headers.add('Accept-Ranges', 'bytes');

      if (totalSize > 0) {
        req.response.headers.add('Content-Range', 'bytes $start-$end/$totalSize');
        req.response.headers.contentLength = end - start + 1;
      }

      // Stream audio using youtube_explode_dart's native stream client
      // This is the key: it handles YouTube auth/signature/throttling automatically
      final ytStream = _ytClient.videos.streamsClient.get(bestStream);

      int bytesWritten = 0;
      int bytesToSkip = start;
      final bytesToWrite = end - start + 1;

      await for (final chunk in ytStream) {
        List<int> data = chunk;

        // Handle byte skipping for range requests
        if (bytesToSkip > 0) {
          if (chunk.length <= bytesToSkip) {
            bytesToSkip -= chunk.length;
            continue;
          }
          data = chunk.sublist(bytesToSkip);
          bytesToSkip = 0;
        }

        // Trim to the requested range
        if (totalSize > 0) {
          final remaining = bytesToWrite - bytesWritten;
          if (remaining <= 0) break;
          if (data.length > remaining) {
            data = data.sublist(0, remaining);
          }
        }

        req.response.add(data);
        bytesWritten += data.length;

        if (totalSize > 0 && bytesWritten >= bytesToWrite) break;
      }

      await req.response.flush();
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
  }
}
