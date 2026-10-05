import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Searching...');
    final search = await yt.search.search('شيرين الوتر الحساس');
    for (final v in search.take(5)) {
      print('Video: ${v.title} | Duration: ${v.duration} | ID: ${v.id}');
    }
    final first = search.first;
    print('Getting manifest for ${first.id}...');
    final manifest = await yt.videos.streamsClient.getManifest(first.id);
    final audioStreams = manifest.audioOnly;
    print('Found ${audioStreams.length} audio streams');
    for (final s in audioStreams) {
      print('Stream: ${s.container} | ${s.bitrate} | ${s.size}');
    }
    final best = audioStreams.withHighestBitrate();
    print('Testing streamsClient.get for 10KB...');
    final stream = yt.videos.streamsClient.get(best);
    int count = 0;
    await for (final chunk in stream) {
      count += chunk.length;
      if (count > 20000) break;
    }
    print('Successfully read $count bytes!');
  } catch (e, st) {
    print('Error: $e\n$st');
  } finally {
    yt.close();
  }
}
