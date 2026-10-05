import 'package:flutter_test/flutter_test.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/data/services/song_audio_resolver.dart';

void main() {
  test('SongAudioResolver resolves authentic full stream for popular Arabic songs', () async {
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

    final resolved = await SongAudioResolver.resolveAudio(song);
    expect(resolved.url, isNotEmpty);
    expect(resolved.url.contains('soundhelix'), isFalse);
    expect(resolved.url.startsWith('http'), isTrue);
    expect(resolved.duration, isNotNull);
    expect(resolved.duration!.inSeconds, greaterThan(60));
  });

  test('SongAudioResolver resolves Wegz song to full audio stream', () async {
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

    final resolved = await SongAudioResolver.resolveAudio(song);
    expect(resolved.url, isNotEmpty);
    expect(resolved.url.contains('soundhelix'), isFalse);
    expect(resolved.url.startsWith('http'), isTrue);
    expect(resolved.duration, isNotNull);
    expect(resolved.duration!.inSeconds, greaterThan(60));
  });
}
