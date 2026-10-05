import 'package:flutter_test/flutter_test.dart';
import 'package:mazikty/data/services/multi_source_music_service.dart';

void main() {
  test('Search for عود البطل returns results', () async {
    final service = MultiSourceMusicApiService();
    final results = await service.searchSongs('عود البطل');

    expect(results.isNotEmpty, isTrue);
    final firstSong = results.first;
    expect(firstSong.title, contains('عود البطل'));
    expect(firstSong.audioUrl.isNotEmpty, isTrue);
    expect(firstSong.artworkUrl.isNotEmpty, isTrue);
  });
}
