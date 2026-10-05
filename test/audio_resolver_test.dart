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

  test('SongAudioResolver resolves full song for Sherine Hobboh Ganna', () async {
    const song = Song(
      id: 'hit_hobboh_ganna',
      title: 'حبه جنة',
      artist: 'شيرين عبد الوهاب',
      album: 'نساي',
      artworkUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/1f/13/c7/1f13c703-bdfc-70d3-155a-d59fe39dcb10/mzaf_2169797306176369190.plus.aac.p.m4a',
      duration: Duration(minutes: 4, seconds: 15),
      genre: 'طرب رومانسي',
    );

    final resolved = await SongAudioResolver.resolveAudio(song);
    expect(resolved.source, 'soundcloud_full');
    expect(resolved.url, isNotEmpty);
    expect(resolved.duration!.inSeconds, greaterThan(120)); // Full song, NOT 30 seconds!
    expect(resolved.videoId, isNull);
  });
}
