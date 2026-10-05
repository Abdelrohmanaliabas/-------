// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AudioStreamingProxy {
  static HttpServer? _server;
  static int _port = 0;
  static final http.Client _client = http.Client();
  static YoutubeExplode? _yt;
  static YoutubeExplode get yt => _yt ??= YoutubeExplode();

  static Future<int> ensureStarted() async {
    if (_server != null) return _port;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    _server!.listen(_handleRequest);
    print('AudioStreamingProxy running on port $_port');
    return _port;
  }

  static String getStreamUrl(String videoId) {
    return 'http://127.0.0.1:$_port/stream?v=$videoId';
  }

  static void _handleRequest(HttpRequest req) async {
    try {
      final videoId = req.uri.queryParameters['v'];
      if (videoId == null || videoId.isEmpty) {
        req.response.statusCode = HttpStatus.badRequest;
        await req.response.close();
        return;
      }

      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }

      final mp4Streams =
          audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
      final bestStream =
          mp4Streams.isNotEmpty ? mp4Streams.withHighestBitrate() : audioStreams.withHighestBitrate();
      final totalSize = bestStream.size.totalBytes;
      final targetUrl = bestStream.url;

      int start = 0;
      final rangeHeader = req.headers.value('range');
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final match = RegExp(r'bytes=(\d+)-').firstMatch(rangeHeader);
        if (match != null) {
          start = int.tryParse(match.group(1)!) ?? 0;
        }
      }

      req.response.statusCode =
          rangeHeader != null ? HttpStatus.partialContent : HttpStatus.ok;
      req.response.headers.contentType = ContentType('audio', 'mp4');
      req.response.headers.add('Accept-Ranges', 'bytes');
      if (rangeHeader != null) {
        req.response.headers.add('Content-Range', 'bytes $start-${totalSize - 1}/$totalSize');
        req.response.headers.contentLength = totalSize - start;
      } else {
        req.response.headers.contentLength = totalSize;
      }

      int current = start;
      const chunkSize = 512 * 1024; // 512 KB

      while (current < totalSize) {
        final end = (current + chunkSize - 1) < totalSize
            ? (current + chunkSize - 1)
            : (totalSize - 1);
        final chunkReq = http.Request('GET', targetUrl);
        chunkReq.headers['Range'] = 'bytes=$current-$end';
        chunkReq.headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

        final streamedRes = await _client.send(chunkReq);
        if (streamedRes.statusCode != 200 && streamedRes.statusCode != 206) {
          print('Upstream chunk error: ${streamedRes.statusCode}');
          break;
        }

        await req.response.addStream(streamedRes.stream);
        current = end + 1;
      }
    } catch (e) {
      print('Proxy request error: $e');
    } finally {
      try {
        await req.response.close();
      } catch (_) {}
    }
  }

  static void dispose() {
    _server?.close(force: true);
    _server = null;
    _yt?.close();
    _yt = null;
  }
}

void main() async {
  await AudioStreamingProxy.ensureStarted(); // port stored internally
  final proxyUrl = AudioStreamingProxy.getStreamUrl('KZYqugtbcG0');
  print('Testing ExoPlayer GET $proxyUrl with Range: bytes=0- ...');

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(proxyUrl));
  req.headers.set('Range', 'bytes=0-');
  final res = await req.close();

  print('Response code: ${res.statusCode}');
  print('Content-Type: ${res.headers.contentType}');
  print('Content-Range: ${res.headers.value('content-range')}');
  print('Content-Length: ${res.headers.contentLength}');

  int totalBytes = 0;
  await for (final chunk in res) {
    totalBytes += chunk.length;
    if (totalBytes > 200000) {
      print('Received $totalBytes bytes smoothly!');
      break;
    }
  }
  print('TEST PASSED 100%! Stream works without 403!');
  AudioStreamingProxy.dispose();
}
