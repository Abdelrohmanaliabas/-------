import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  HttpServer? server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    print('Proxy server bound to port: ${server.port}');

    final manifest = await yt.videos.streamsClient.getManifest('KZYqugtbcG0');
    final audio = manifest.audioOnly.withHighestBitrate();
    final url = audio.url;
    final totalSize = audio.size.totalBytes;
    print('Audio stream URL acquired. Total size: $totalSize bytes');

    // Handle requests
    server.listen((req) async {
      print('Proxy received request: ${req.method} ${req.uri} Range: ${req.headers.value('range')}');
      
      // Determine range
      int start = 0;
      final rangeHeader = req.headers.value('range');
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final parts = rangeHeader.replaceFirst('bytes=', '').split('-');
        start = int.tryParse(parts[0]) ?? 0;
      }

      req.response.statusCode = rangeHeader != null ? HttpStatus.partialContent : HttpStatus.ok;
      req.response.headers.contentType = ContentType('audio', 'mp4');
      req.response.headers.add('Accept-Ranges', 'bytes');
      if (rangeHeader != null) {
        req.response.headers.add('Content-Range', 'bytes $start-${totalSize - 1}/$totalSize');
        req.response.headers.contentLength = totalSize - start;
      } else {
        req.response.headers.contentLength = totalSize;
      }

      final client = http.Client();
      try {
        final chunkSize = 1024 * 1024; // 1MB chunks
        int current = start;
        while (current < totalSize) {
          final end = (current + chunkSize - 1) < totalSize ? (current + chunkSize - 1) : (totalSize - 1);
          final chunkReq = http.Request('GET', url);
          chunkReq.headers['Range'] = 'bytes=$current-$end';
          chunkReq.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
          final chunkRes = await client.send(chunkReq);
          if (chunkRes.statusCode != 200 && chunkRes.statusCode != 206) {
            print('Chunk error at $current-$end: ${chunkRes.statusCode}');
            break;
          }
          await req.response.addStream(chunkRes.stream);
          current = end + 1;
        }
      } catch (e) {
        print('Stream pipe error: $e');
      } finally {
        client.close();
        await req.response.close();
      }
    });

    // Test client: simulate ExoPlayer requesting open-ended Range: bytes=0-
    print('Client connecting to proxy with Range: bytes=0- ...');
    final clientReq = await HttpClient().getUrl(Uri.parse('http://127.0.0.1:${server.port}/stream'));
    clientReq.headers.set('Range', 'bytes=0-');
    final clientRes = await clientReq.close();
    print('Client received response status: ${clientRes.statusCode}, Content-Range: ${clientRes.headers.value('content-range')}');
    int received = 0;
    await for (final chunk in clientRes) {
      received += chunk.length;
      if (received >= 64 * 1024) break; // Read 64KB
    }
    print('SUCCESS! Client read $received bytes without 403!');

  } catch (e, st) {
    print('Test error: $e\n$st');
  } finally {
    await server?.close(force: true);
    yt.close();
  }
}
