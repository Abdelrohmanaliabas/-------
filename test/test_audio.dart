import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Testing YouTube search...');
    final res = await yt.search.search('نصير شمة');
    print('Search result count: ${res.length}');
    if (res.isNotEmpty) {
      final video = res.first;
      print('First video: ${video.title} (${video.id})');
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final audioOnly = manifest.audioOnly;
      print('Audio streams: ${audioOnly.length}');
      if (audioOnly.isNotEmpty) {
        final streamUrl = audioOnly.withHighestBitrate().url;
        print('Audio URL: $streamUrl');
        print('Testing HTTP GET on stream URL...');
        final resp = await http.get(streamUrl, headers: {'User-Agent': 'Mozilla/5.0'});
        print('Stream HTTP status: ${resp.statusCode}, content length: ${resp.bodyBytes.length}');
      }
    }
  } catch (e, stack) {
    print('Error: $e\n$stack');
  } finally {
    yt.close();
  }

  // Also test soundhelix
  try {
    print('\nTesting SoundHelix URL...');
    final resp = await http.head(Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
    print('SoundHelix status: ${resp.statusCode}');
  } catch (e) {
    print('SoundHelix error: $e');
  }
}
