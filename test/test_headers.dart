import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest('KZYqugtbcG0');
    final audio = manifest.audioOnly.withHighestBitrate();
    final url = audio.url.toString();
    print('Testing with Range: bytes=0- ...');
    final r1 = await http.get(Uri.parse(url), headers: {'Range': 'bytes=0-'});
    print('Range bytes=0-: status ${r1.statusCode}, length: ${r1.contentLength}');

    print('Testing HEAD request...');
    final r2 = await http.head(Uri.parse(url));
    print('HEAD status: ${r2.statusCode}');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
