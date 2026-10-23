// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:mazikty/data/services/multi_source_music_service.dart';

void main() {
  test('MultiSourceMusicApiService E2E search testing', () async {
    final api = MultiSourceMusicApiService();

    final queriesToTest = [
      'عمرو دياب مكانك',
      'سورة الكهف ماهر المعيقلي',
      'Eminem Lose Yourself',
      'https://www.youtube.com/watch?v=69jK7Z1kisM',
      'مهرجان سطلانه',
      'تامر عاشور هيجيلي موجوع',
    ];

    for (final q in queriesToTest) {
      final songs = await api.searchSongs(q);
      expect(songs.isNotEmpty, true, reason: 'Failed to find songs for query: "$q"');
      print('Query: "$q" -> found ${songs.length} songs. Top match: "${songs.first.title}" by "${songs.first.artist}" [${songs.first.id}]');
    }

    final suggestions = await MultiSourceMusicApiService.fetchGoogleYouTubeSuggestions('شيرين');
    expect(suggestions.isNotEmpty, true);
    print('Google/YouTube Suggestions for "شيرين": ${suggestions.take(5).toList()}');

    final playlists = await api.searchPlaylists('عمرو دياب');
    expect(playlists.isNotEmpty, true);
    print('Playlists for "عمرو دياب": ${playlists.take(3).map((p) => p.name).toList()}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
