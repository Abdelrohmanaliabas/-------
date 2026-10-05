import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest('KZYqugtbcG0');
    final audio = manifest.audioOnly.withHighestBitrate();
    final url = audio.url;
    print('Host: ${url.host}');
    print('Query params: ${url.queryParameters.keys}');
    for (int size in [1000, 10000, 100000, 500000, 1000000]) {
      final res = await http.get(url, headers: {
        'Range': 'bytes=0-$size',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      });
      print('Chunk 0-$size: status ${res.statusCode}');
    }
  } finally {
    yt.close();
  }
}
