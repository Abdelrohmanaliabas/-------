import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/data/services/listening_history_service.dart';
import 'package:mazikty/data/services/multi_source_music_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ListeningHistoryService records played and completed songs', () async {
    const song1 = Song(
      id: 'test_1',
      title: 'تملي معاك',
      artist: 'عمرو دياب',
      album: 'تملي معاك',
      artworkUrl: 'https://example.com/1.jpg',
      audioUrl: '',
      duration: Duration(minutes: 4),
      genre: 'بوب عربي',
    );

    const song2 = Song(
      id: 'test_2',
      title: 'البخت',
      artist: 'ويجز',
      album: 'البخت',
      artworkUrl: 'https://example.com/2.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3),
      genre: 'تراب عربي',
    );

    // Record played
    await ListeningHistoryService.recordSongPlayed(song1);
    await ListeningHistoryService.recordSongPlayed(song2);

    final recent = await ListeningHistoryService.getRecentlyPlayed();
    expect(recent.length, 2);
    expect(recent.first.id, 'test_2');

    // Record completed
    await ListeningHistoryService.recordSongCompleted(song1);
    final completed = await ListeningHistoryService.getCompletedSongs();
    expect(completed.length, 1);
    expect(completed.first.title, 'تملي معاك');

    final lastPlayed = await ListeningHistoryService.getLastPlayedSong();
    expect(lastPlayed, isNotNull);
  });

  test('getRelatedSongs returns same-artist and similar genre songs', () async {
    final service = MultiSourceMusicApiService();
    const song = Song(
      id: 'hit_tamally_maak',
      title: 'تملي معاك',
      artist: 'عمرو دياب',
      artistId: 'artist_amr_diab',
      album: 'تملي معاك',
      artworkUrl: 'https://example.com/cover.jpg',
      audioUrl: '',
      duration: Duration(minutes: 4, seconds: 30),
      genre: 'بوب عربي',
    );

    final related = await service.getRelatedSongs(song);
    expect(related.isNotEmpty, isTrue);
    // Original song shouldn't be duplicated in the related queue
    expect(related.any((s) => s.title == 'تملي معاك'), isFalse);
    // Should have other songs by Amr Diab or Arabic pop
    expect(related.any((s) => s.artist.contains('عمرو دياب') || s.genre.contains('بوب')), isTrue);
  });
}
