import 'package:flutter_test/flutter_test.dart';
import 'package:mazikty/data/services/multi_source_music_service.dart';

void main() {
  test('Search for عود البطل returns results', () async {
    final service = MultiSourceMusicApiService();
    final results = await service.searchSongs('عود البطل');

    expect(results.isNotEmpty, isTrue);
    final firstSong = results.first;
    expect(firstSong.title, contains('عود البطل'));
    expect(firstSong.artworkUrl.isNotEmpty, isTrue);
  });

  test('Search for سعد الصغير returns full-length songs from YouTube and multi-sources', () async {
    final service = MultiSourceMusicApiService();
    final results = await service.searchSongs('سعد الصغير');

    expect(results.isNotEmpty, isTrue);
    expect(results.any((s) => s.id.startsWith('yt_') || s.duration.inMinutes >= 2), isTrue);
  });

  test('Search for gym playlists returns Arabic and English workout playlists', () async {
    final service = MultiSourceMusicApiService();
    
    // Arabic search
    final gymArabic = await service.searchPlaylists('جيم');
    expect(gymArabic.isNotEmpty, isTrue);
    expect(gymArabic.any((pl) => pl.name.contains('جيم')), isTrue);
    expect(gymArabic.first.songs.isNotEmpty, isTrue);

    // English search
    final gymEnglish = await service.searchPlaylists('workout');
    expect(gymEnglish.isNotEmpty, isTrue);
    expect(gymEnglish.any((pl) => pl.name.toLowerCase().contains('workout')), isTrue);
    expect(gymEnglish.first.songs.isNotEmpty, isTrue);
  });
}

