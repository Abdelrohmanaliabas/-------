import 'package:flutter_test/flutter_test.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/data/services/song_audio_resolver.dart';

void main() {
  test('SongAudioResolver resolves authentic streams for popular Arabic songs', () async {
    const song = Song(
      id: 'test_amr_diab',
      title: 'تملي معاك',
      artist: 'عمرو دياب',
      album: 'تملي معاك',
      artworkUrl: 'https://example.com/cover.jpg',
      audioUrl: '', // empty or dummy
      duration: Duration(minutes: 4),
      genre: 'بوب عربي',
    );

    final resolvedUrl = await SongAudioResolver.resolveAudioStream(song);
    expect(resolvedUrl, isNotEmpty);
    expect(resolvedUrl.contains('soundhelix'), isFalse);
    expect(resolvedUrl.startsWith('http'), isTrue);
  });

  test('SongAudioResolver resolves instant catalog tracks', () async {
    const song = Song(
      id: 'test_wegz',
      title: 'البخت',
      artist: 'ويجز',
      album: 'البخت',
      artworkUrl: 'https://example.com/cover.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3),
      genre: 'تراب عربي',
    );

    final resolvedUrl = await SongAudioResolver.resolveAudioStream(song);
    expect(resolvedUrl, isNotEmpty);
    expect(resolvedUrl.contains('soundhelix'), isFalse);
    expect(resolvedUrl.contains('itunes.apple.com'), isTrue);
  });
}
