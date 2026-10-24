import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/song.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/album.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/genre.dart';
import '../mock/sample_music_data.dart';
import 'music_api_service.dart';
import 'song_audio_resolver.dart';

/// Comprehensive multi-source music aggregator querying 15+ music APIs & engines
/// with intelligent Arabic normalization, transliteration, deduplication, and streaming audio.
class MultiSourceMusicApiService implements MusicApiService {
  final http.Client _client;

  MultiSourceMusicApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _apiTimeout = Duration(seconds: 6);

  // -------------------------------------------------------------
  // Arabic Normalization & Transliteration Helper
  // -------------------------------------------------------------
  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove Tashkeel/harakat
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static final Map<String, List<String>> _arabicToEnglishTransliterations = {
    'عود البطل': ['oud al batal', 'oud el batal', 'hassan shakosh', 'omar kamal'],
    'بنت الجيران': ['bent el geran', 'bint al geran', 'hassan shakosh'],
    'الغزاله رايقه': ['el ghazala ray2a', 'karim mahmoud abdel aziz'],
    'سطلانه': ['satlana', 'abdelbaset hamouda'],
    'عمرو دياب': ['amr diab'],
    'شيرين': ['sherine', 'sherine abdel wahab'],
    'تامر حسني': ['tamer hosny'],
    'محمد حماقي': ['hamaki', 'mohamed hamaki'],
    'احمد سعد': ['ahmed saad'],
    'ويجز': ['wegz'],
    'مروان بابلو': ['marwan pablo'],
    'حمزه نمره': ['hamza namira'],
    'فيروز': ['fairuz', 'fairouz'],
    'ام كلثوم': ['umm kulthum', 'om kalthoum'],
    'عبد الحليم': ['abdel halim hafez'],
    'نصير شمه': ['naseer shamma'],
    'عمر خيرت': ['omar khairat'],
    'حسين الجسمي': ['hussain al jassmi'],
    'نانسي عجرم': ['nancy ajram'],
    'اليسا': ['elissa'],
    'اصاله': ['assala'],
    'كاظم الساهر': ['kadim al sahir'],
    'ماجد المهندس': ['majid al mohandis'],
  };

  List<String> _buildSearchVariations(String rawQuery) {
    final query = rawQuery.trim();
    final normalized = _normalizeArabic(query);
    final variations = <String>{query};

    if (normalized != query.toLowerCase()) {
      variations.add(normalized);
    }

    // Check for predefined artist/track transliterations
    for (final entry in _arabicToEnglishTransliterations.entries) {
      if (normalized.contains(_normalizeArabic(entry.key)) || entry.key.contains(normalized)) {
        variations.addAll(entry.value);
      }
    }

    // Strip "ال" prefix variation
    if (query.startsWith('ال') && query.length > 2) {
      variations.add(query.substring(2));
    }

    return variations.toList();
  }

  // -------------------------------------------------------------
  // Curated Arabic Verified Catalog (Diverse & Updated Arabic Music)
  // -------------------------------------------------------------
  static final List<Song> _curatedArabicHits = [
    // 1. Tamer Ashour
    const Song(
      id: 'hit_tamer_ashour_haygeely',
      title: 'هيجيلي موجوع',
      artist: 'تامر عاشور',
      artistId: 'artist_tamer_ashour',
      album: 'هيجيلي موجوع',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/bc/5b/a6/bc5ba615-b439-9a1a-28c9-fcb2fadd31f2/3617382720432_cover.jpg/600x600bb.jpg',
      audioUrl: 'https://serv100.albumaty.com/song2022/Albumaty.Com_tamr_aashwr_hygyly_mwgwa.mp3',
      duration: Duration(minutes: 4, seconds: 12),
      genre: 'طرب معاصر',
      playsCount: 55000000,
      releaseYear: '2024',
    ),
    // 2. Hamza Namira
    const Song(
      id: 'hit_hamza_reyah',
      title: 'رياح الحياة',
      artist: 'حمزة نمرة',
      artistId: 'artist_hamza_namira',
      album: 'رايق',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/9e/eb/bd/9eebbd9e-2ceb-0184-fca8-1a08beaf4c9d/artwork.jpg/600x600bb.jpg',
      audioUrl: 'https://serv100.albumaty.com/song2022/Albumaty.Com_hmzh_nmrh_ryah_alhyat.mp3',
      duration: Duration(minutes: 4, seconds: 35),
      genre: 'طرب معاصر',
      playsCount: 42000000,
      releaseYear: '2023',
    ),
    // 3. Wegz
    const Song(
      id: 'hit_el_bakht',
      title: 'البخت',
      artist: 'ويجز',
      artistId: 'artist_wegz',
      album: 'البخت - سينجل',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/e2/07/3b/e2073b69-e9a9-0377-2a37-8eabccbc8ef5/6221216329950.jpg/600x600bb.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_wygz_albkht.mp3',
      duration: Duration(minutes: 3, seconds: 50),
      genre: 'تراب عربي',
      playsCount: 35000000,
      releaseYear: '2022',
    ),
    // 4. Tamer Hosny
    const Song(
      id: 'hit_tamer_naseeny',
      title: 'ناسيني ليه',
      artist: 'تامر حسني',
      artistId: 'artist_tamer',
      album: 'عيش بشوقك',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/52/9a/ab/529aabab-f576-48be-c791-3f658e6149a5/6221117229724.jpg/600x600bb.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/89/9f/de/899fde12-cbcb-916d-8d8d-b83bc28b4934/mzaf_13818730788114474143.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 55),
      genre: 'طرب رومانسي',
      playsCount: 38000000,
      releaseYear: '2018',
    ),
    // 5. Mohamed Hamaki
    const Song(
      id: 'hit_hamaki_adrenaline',
      title: 'أدرينالين',
      artist: 'محمد حماقي',
      artistId: 'artist_hamaki',
      album: 'سينجل 2022',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/f8/65/d9/f865d971-91df-3ac7-b966-c420b8561c58/1144411.jpg/600x600bb.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview112/v4/79/32/da/7932da78-1fc1-3931-c6c0-f3869681dfda/mzaf_10542712012174392451.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 05),
      genre: 'بوب عربي',
      playsCount: 27000000,
      releaseYear: '2022',
    ),
    // 6. Sherine
    const Song(
      id: 'hit_kalam_eneih',
      title: 'كلام عينيه',
      artist: 'شيرين عبد الوهاب',
      artistId: 'artist_sherine',
      album: 'نساي',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/e5ab08f782135c3cc88289ac8a8bf7be/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/67/73/2f/67732f33-bcd6-5927-99de-11eaaf88cb73/mzaf_10287738161216312625.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 58),
      genre: 'طرب معاصر',
      playsCount: 38000000,
      releaseYear: '2018',
    ),
    // 7. Assala
    const Song(
      id: 'hit_assala_fawq',
      title: 'فوق',
      artist: 'أصالة',
      artistId: 'artist_assala',
      album: 'لحقت نفسي',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/9346f66804541490beca47721268cd7c/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/ae/69/bd/ae69bd62-653c-7343-c789-cc5ffbee606a/mzaf_91142661183722088.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 55),
      genre: 'طرب',
      playsCount: 38000000,
      releaseYear: '2023',
    ),

    // Ahmed Saad
    const Song(
      id: 'hit_wasa3_wasa3',
      title: 'وسع وسع',
      artist: 'أحمد سعد',
      artistId: 'artist_ahmed_saad',
      album: 'وسع وسع - سينجل',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/2c/ba/11/2cba117b-c473-3a95-36ab-d4fd3337d902/mzaf_12491533538707426856.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 18),
      genre: 'بوب شعبي',
      playsCount: 22000000,
      releaseYear: '2022',
    ),
    const Song(
      id: 'hit_elyoum_elhelw',
      title: 'إيه اليوم الحلو ده',
      artist: 'أحمد سعد',
      artistId: 'artist_ahmed_saad',
      album: 'فيلم عمهم',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/2ec20135cb3ddcbeb83dae4ab32d3f5f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/56/83/91/56839199-6f6c-31fb-fe49-7d4ead1ca1aa/mzaf_3333502615273490459.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 10),
      genre: 'بوب شعبي',
      playsCount: 29000000,
      releaseYear: '2022',
    ),

    // Wegz
    const Song(
      id: 'hit_el_bakht',
      title: 'البخت',
      artist: 'ويجز',
      artistId: 'artist_wegz',
      album: 'البخت - سينجل',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/2f62c7d86a591bcf1546c8c55bbbcc39/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/e2/b0/1d/e2b01d30-7b5f-d520-4f3e-e1e250899b12/mzaf_2863315495467483634.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 50),
      genre: 'تراب عربي',
      playsCount: 35000000,
      releaseYear: '2022',
    ),
    const Song(
      id: 'hit_wegz_dork_gy',
      title: 'دورك جي',
      artist: 'ويجز',
      artistId: 'artist_wegz',
      album: 'سينجل',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/0c512f03395b278ec87502f7a5d0ff4f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/d3/71/ab/d371ab8d-ee54-de16-806f-cfe9cbd49b8e/mzaf_3509482404735628639.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 40),
      genre: 'تراب عربي',
      playsCount: 26000000,
      releaseYear: '2020',
    ),

    // Tamer Hosny
    const Song(
      id: 'hit_tamer_hormon',
      title: 'هرمون السعادة',
      artist: 'تامر حسني',
      artistId: 'artist_tamer',
      album: 'تاج',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/4d793556d3eb846d6e503b1999e4916d/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview112/v4/a4/48/d7/a448d73e-6098-35bc-7601-622e4969e495/mzaf_11831876887476923435.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 20),
      genre: 'بوب عربي',
      playsCount: 21500000,
      releaseYear: '2023',
    ),
    const Song(
      id: 'hit_tamer_naseeny',
      title: 'ناسيني ليه',
      artist: 'تامر حسني',
      artistId: 'artist_tamer',
      album: 'عيش بشوقك',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/4419f730dd698016636b5070f1f2b7a3/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/89/9f/de/899fde12-cbcb-916d-8d8d-b83bc28b4934/mzaf_13818730788114474143.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 55),
      genre: 'طرب رومانسي',
      playsCount: 38000000,
      releaseYear: '2018',
    ),

    // Mohamed Hamaki
    const Song(
      id: 'hit_hamaki_adrenaline',
      title: 'أدرينالين',
      artist: 'محمد حماقي',
      artistId: 'artist_hamaki',
      album: 'سينجل 2022',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/14a630e5a0536ba8b8c12440711a47f6/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview112/v4/79/32/da/7932da78-1fc1-3931-c6c0-f3869681dfda/mzaf_10542712012174392451.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 05),
      genre: 'بوب عربي',
      playsCount: 27000000,
      releaseYear: '2022',
    ),

    // Cairokee
    const Song(
      id: 'hit_cairokee_bsrah',
      title: 'بسرح وأتوه',
      artist: 'كاريوكي',
      artistId: 'artist_cairokee',
      album: 'روما',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/59aca1990910aa9314c818af8dada52e/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/d8/ca/86/d8ca8630-91b2-b759-a05b-e0c4c463e5d3/mzaf_12082730354540616472.plus.aac.p.m4a',
      duration: Duration(minutes: 4, seconds: 10),
      genre: 'روك عربي',
      playsCount: 18000000,
      releaseYear: '2022',
    ),

    // Mahraganat & Popular
    const Song(
      id: 'hit_oud_el_batal',
      title: 'عود البطل',
      artist: 'حسن شاكوش وعمر كمال',
      artistId: 'artist_shakosh',
      album: 'مهرجانات شعبية',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/f9df9cff5fd0e3799ae2ba0cd8235f05/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/d1/3b/91/d13b913c-1c65-7004-63b9-5c01848ced2e/mzaf_18189965843957578363.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 24),
      genre: 'مهرجانات',
      playsCount: 24800000,
      releaseYear: '2020',
    ),
    const Song(
      id: 'hit_bent_el_geran',
      title: 'بنت الجيران',
      artist: 'حسن شاكوش وعمر كمال',
      artistId: 'artist_shakosh',
      album: 'مهرجانات 2020',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/c644a2d922379a656cbc68e8daec575f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/61/05/53/610553ef-82f9-5b17-6045-499c75918777/mzaf_5817950213956088330.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 15),
      genre: 'مهرجانات',
      playsCount: 31000000,
      releaseYear: '2020',
    ),
    const Song(
      id: 'hit_el_ghazala_ray2a',
      title: 'الغزالة رايقة',
      artist: 'كريم محمود عبد العزيز ومحمد أسامة',
      album: 'فيلم من أجل زيكو',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/7e04cd25dd6eeb937bb8b9912ac5bb7f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/05/7f/5d/057f5d82-30f4-2f6c-1775-6e1d224903a6/mzaf_16715468319058468915.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 12),
      genre: 'شعبي مودرن',
      playsCount: 19500000,
      releaseYear: '2022',
    ),
    const Song(
      id: 'hit_satlana',
      title: 'سطلانة',
      artist: 'عبد الباسط حمودة ومحمود الليثي',
      album: 'فيلم بعد الشر',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/6aed212166a7413068e14fd25d040547/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/f8/09/73/f80973e2-8f0f-39ee-e5ca-bd4e2ab75ab9/mzaf_1126199453768207043.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 40),
      genre: 'شعبي',
      playsCount: 15400000,
      releaseYear: '2023',
    ),

    // Tul8te
    const Song(
      id: 'hit_tul8te_habibi',
      title: 'حبيبي ليه',
      artist: 'توليت (TuL8TE)',
      album: 'كوكتيل غنائي',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/8a0cfa8420e6cf468a60c721bc5bdf3d/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/47/d5/af/47d5afe6-40e3-a32e-926c-5e06fe2466e2/mzaf_16235984847084604246.plus.aac.p.m4a',
      duration: Duration(minutes: 2, seconds: 50),
      genre: 'إندي عربي',
      playsCount: 16500000,
      releaseYear: '2024',
    ),

    // Hussain Al Jassmi
    const Song(
      id: 'hit_jassmi_bnt_el3reed',
      title: 'بالبنط العريض',
      artist: 'حسين الجسمي',
      album: 'سينجل',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/58411a68d1d0550a5400daec653cc049/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/c2/ae/1d/c2ae1d6e-b10a-74b5-0d53-6dfae013a8a1/mzaf_7179156399724832527.plus.aac.p.m4a',
      duration: Duration(minutes: 3, seconds: 40),
      genre: 'بوب عربي',
      playsCount: 52000000,
      releaseYear: '2020',
    ),
  ];

  // -------------------------------------------------------------
  // API 1: Deezer Tracks Search
  // -------------------------------------------------------------
  Future<List<Song>> _searchDeezer(String query) async {
    try {
      final uri = Uri.parse('https://api.deezer.com/search?q=${Uri.encodeComponent(query)}&limit=25');
      final res = await _client.get(uri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];

      return list.map((item) {
        final artistMap = item['artist'] as Map<String, dynamic>? ?? {};
        final albumMap = item['album'] as Map<String, dynamic>? ?? {};
        final preview = item['preview'] as String? ?? '';
        final artwork = albumMap['cover_big'] as String? ??
            albumMap['cover_medium'] as String? ??
            albumMap['cover'] as String? ??
            artistMap['picture_medium'] as String? ??
            'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg';

        return Song(
          id: 'deezer_${item['id']}',
          title: item['title'] as String? ?? 'موسيقى',
          artist: artistMap['name'] as String? ?? 'فنان غير معروف',
          artistId: artistMap['id']?.toString(),
          album: albumMap['title'] as String? ?? 'ألبوم',
          albumId: albumMap['id']?.toString(),
          artworkUrl: artwork,
          audioUrl: preview,
          duration: Duration(seconds: item['duration'] as int? ?? 180),
          genre: 'موسيقى عامة',
          playsCount: item['rank'] as int? ?? 15000,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 2: Deezer Artist Top Tracks Search
  // -------------------------------------------------------------
  Future<List<Song>> _searchDeezerArtistTopTracks(String query) async {
    try {
      final searchUri = Uri.parse('https://api.deezer.com/search/artist?q=${Uri.encodeComponent(query)}&limit=3');
      final res = await _client.get(searchUri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final artists = data['data'] as List<dynamic>? ?? [];
      if (artists.isEmpty) return [];

      final artistId = artists.first['id'];
      final topUri = Uri.parse('https://api.deezer.com/artist/$artistId/top?limit=10');
      final topRes = await _client.get(topUri).timeout(_apiTimeout);
      if (topRes.statusCode != 200) return [];

      final topData = json.decode(topRes.body) as Map<String, dynamic>;
      final list = topData['data'] as List<dynamic>? ?? [];

      return list.map((item) {
        final artistMap = item['artist'] as Map<String, dynamic>? ?? {};
        final albumMap = item['album'] as Map<String, dynamic>? ?? {};
        final preview = item['preview'] as String? ?? '';
        final artwork = albumMap['cover_big'] as String? ??
            albumMap['cover_medium'] as String? ??
            'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg';

        return Song(
          id: 'deezer_artist_top_${item['id']}',
          title: item['title'] as String? ?? '',
          artist: artistMap['name'] as String? ?? '',
          album: albumMap['title'] as String? ?? '',
          artworkUrl: artwork,
          audioUrl: preview,
          duration: Duration(seconds: item['duration'] as int? ?? 180),
          genre: 'موسيقى عربية',
          playsCount: item['rank'] as int? ?? 25000,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 3: Deezer Album Search
  // -------------------------------------------------------------
  Future<List<Album>> _searchDeezerAlbums(String query) async {
    try {
      final uri = Uri.parse('https://api.deezer.com/search/album?q=${Uri.encodeComponent(query)}&limit=15');
      final res = await _client.get(uri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];

      return list.map((item) {
        final artistMap = item['artist'] as Map<String, dynamic>? ?? {};
        final cover = item['cover_big'] as String? ??
            item['cover_medium'] as String? ??
            item['cover'] as String? ??
            'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg';

        return Album(
          id: 'deezer_album_${item['id']}',
          title: item['title'] as String? ?? 'ألبوم',
          artist: artistMap['name'] as String? ?? 'فنان غير معروف',
          artistId: artistMap['id']?.toString(),
          artworkUrl: cover,
          songsCount: item['nb_tracks'] as int? ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 4: Deezer Artists Search
  // -------------------------------------------------------------
  Future<List<Artist>> _searchDeezerArtists(String query) async {
    try {
      final uri = Uri.parse('https://api.deezer.com/search/artist?q=${Uri.encodeComponent(query)}&limit=15');
      final res = await _client.get(uri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];

      return list.map((item) {
        final pic = item['picture_big'] as String? ??
            item['picture_medium'] as String? ??
            item['picture'] as String? ??
            'https://cdn-images.dzcdn.net/images/artist/04381e254ff4ad4c43ac62d7483fea0f/500x500-000000-80-0-0.jpg';

        return Artist(
          id: 'deezer_artist_${item['id']}',
          name: item['name'] as String? ?? 'فنان',
          imageUrl: pic,
          followersCount: item['nb_fan'] as int? ?? 1000,
          monthlyListeners: ((item['nb_fan'] as int? ?? 1000) * 1.5).round(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 5 - 8: Apple Music / iTunes Search by Country (EG, SA, AE, US)
  // -------------------------------------------------------------
  Future<List<Song>> _searchItunesCountry(String query, String country) async {
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&country=$country&media=music&entity=song&limit=20',
      );
      final res = await _client.get(uri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['results'] as List<dynamic>? ?? [];

      return list.map((item) {
        final artwork100 = item['artworkUrl100'] as String? ?? '';
        final artworkHigh = artwork100.replaceAll('100x100bb.jpg', '600x600bb.jpg');
        final preview = item['previewUrl'] as String? ?? '';

        return Song(
          id: 'itunes_${item['trackId']}',
          title: item['trackName'] as String? ?? 'أغنية',
          artist: item['artistName'] as String? ?? 'فنان',
          artistId: item['artistId']?.toString(),
          album: item['collectionName'] as String? ?? 'ألبوم',
          albumId: item['collectionId']?.toString(),
          artworkUrl: artworkHigh.isNotEmpty ? artworkHigh : 'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg',
          audioUrl: preview,
          duration: Duration(milliseconds: item['trackTimeMillis'] as int? ?? 180000),
          genre: item['primaryGenreName'] as String? ?? 'موسيقى عربية',
          releaseYear: (item['releaseDate'] as String?)?.split('-').first,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 9: iTunes Artist Search
  // -------------------------------------------------------------
  Future<List<Artist>> _searchItunesArtists(String query) async {
    // iTunes doesn't provide artist images — use Deezer artist search instead for real photos
    return _searchDeezerArtists(query);
  }

  // -------------------------------------------------------------
  // API 10: iTunes Album Search
  // -------------------------------------------------------------
  Future<List<Album>> _searchItunesAlbums(String query) async {
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=album&limit=10',
      );
      final res = await _client.get(uri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['results'] as List<dynamic>? ?? [];

      return list.map((item) {
        final art = (item['artworkUrl100'] as String? ?? '').replaceAll('100x100bb.jpg', '600x600bb.jpg');
        return Album(
          id: 'itunes_alb_${item['collectionId']}',
          title: item['collectionName'] as String? ?? '',
          artist: item['artistName'] as String? ?? '',
          artistId: item['artistId']?.toString(),
          artworkUrl: art.isNotEmpty ? art : 'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg',
          songsCount: item['trackCount'] as int? ?? 1,
          releaseYear: (item['releaseDate'] as String?)?.split('-').first,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 11: Internet Archive (Arabic Music & Audio Collection)
  // -------------------------------------------------------------
  Future<List<Song>> _searchInternetArchive(String query) async {
    try {
      final qEnc = Uri.encodeComponent('($query) AND mediatype:audio');
      final uri = Uri.parse('https://archive.org/advancedsearch.php?q=$qEnc&fl[]=identifier,title,creator,description,year&rows=15&output=json');
      final res = await _client.get(uri).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final responseObj = data['response'] as Map<String, dynamic>? ?? {};
      final docs = responseObj['docs'] as List<dynamic>? ?? [];

      return docs.map((doc) {
        final id = doc['identifier'] as String? ?? '';
        final title = doc['title'] as String? ?? 'تسجيل صوتي';
        final creator = doc['creator'] as String? ?? 'أرشيف الموسيقى';
        final streamUrl = 'https://archive.org/download/$id/$id.mp3';
        final thumb = 'https://archive.org/services/img/$id';

        return Song(
          id: 'ia_$id',
          title: title,
          artist: creator,
          album: 'أرشيف التراث العربي',
          artworkUrl: thumb,
          audioUrl: streamUrl,
          duration: const Duration(minutes: 4, seconds: 15),
          genre: 'تراث وطرب أصيل',
          releaseYear: doc['year']?.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------
  // API 12: MusicBrainz Recording Search
  // -------------------------------------------------------------
  Future<List<Song>> _searchMusicBrainz(String query) async {
    try {
      final uri = Uri.parse('https://musicbrainz.org/ws/2/recording?query=${Uri.encodeComponent(query)}&fmt=json&limit=10');
      final res = await _client.get(
        uri,
        headers: {'User-Agent': 'MaziktyApp/1.0.0 (contact@mazikty.app)'},
      ).timeout(_apiTimeout);
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final recordings = data['recordings'] as List<dynamic>? ?? [];

      return recordings.map((rec) {
        final artists = rec['artist-credit'] as List<dynamic>? ?? [];
        final artistName = artists.isNotEmpty ? (artists.first['name'] as String? ?? 'فنان') : 'فنان';
        final releases = rec['releases'] as List<dynamic>? ?? [];
        final releaseTitle = releases.isNotEmpty ? (releases.first['title'] as String? ?? 'ألبوم') : 'ألبوم';
        final length = rec['length'] as int? ?? 210000;

        return Song(
          id: 'mb_${rec['id']}',
          title: rec['title'] as String? ?? 'أغنية',
          artist: artistName,
          album: releaseTitle,
          artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg',
          audioUrl: '',
          duration: Duration(milliseconds: length),
          genre: 'موسيقى',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }


  // -------------------------------------------------------------
  // Google & YouTube Live Search Suggestions
  // -------------------------------------------------------------
  static Future<List<String>> fetchGoogleYouTubeSuggestions(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final uri = Uri.parse('https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeComponent(q)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final list = json.decode(res.body);
        if (list is List && list.length >= 2 && list[1] is List) {
          return (list[1] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // -------------------------------------------------------------
  // Direct YouTube Video Metadata Resolver
  // -------------------------------------------------------------
  Future<Song?> _fetchDirectYouTubeSong(String videoId) async {
    try {
      final yt = SongAudioResolver.yt;
      final v = await yt.videos.get(videoId).timeout(const Duration(seconds: 4));
      return Song(
        id: 'yt_${v.id.value}',
        title: v.title,
        artist: v.author,
        album: 'YouTube',
        artworkUrl: v.thumbnails.highResUrl.isNotEmpty
            ? v.thumbnails.highResUrl
            : 'https://img.youtube.com/vi/${v.id.value}/hqdefault.jpg',
        audioUrl: '',
        duration: v.duration ?? const Duration(minutes: 3, seconds: 30),
        genre: 'موسيقى كاملة',
        playsCount: 20000000,
        releaseYear: v.uploadDate?.year.toString(),
      );
    } catch (_) {
      try {
        final oEmbedUri = Uri.parse('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json');
        final res = await _client.get(oEmbedUri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          return Song(
            id: 'yt_$videoId',
            title: data['title'] as String? ?? 'مقطع يوتيوب',
            artist: data['author_name'] as String? ?? 'YouTube',
            album: 'YouTube',
            artworkUrl: data['thumbnail_url'] as String? ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            audioUrl: '',
            duration: const Duration(minutes: 3, seconds: 30),
            genre: 'موسيقى كاملة',
            playsCount: 20000000,
          );
        }
      } catch (_) {}
    }
    return null;
  }

  // -------------------------------------------------------------
  // API: YouTube & YouTube Music Search Engine (100% Full Audio)
  // -------------------------------------------------------------
  Future<List<Song>> _searchYouTube(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 0. Check for direct YouTube URL or 11-char Video ID
    final ytUrlRegExp = RegExp(
        r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})');
    final match = ytUrlRegExp.firstMatch(q);
    if (match != null) {
      final vid = match.group(1);
      if (vid != null) {
        final direct = await _fetchDirectYouTubeSong(vid);
        if (direct != null) return [direct];
      }
    } else if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(q) && (q.contains('-') || q.contains('_') || RegExp(r'\d').hasMatch(q))) {
      final direct = await _fetchDirectYouTubeSong(q);
      if (direct != null) return [direct];
    }

    final songs = <Song>[];
    final seenIds = <String>{};

    // 1. Try ultra-fast InnerTube JSON search (~800ms)
    try {
      final uri = Uri.parse('https://www.youtube.com/youtubei/v1/search');
      final payload = {
        "context": {
          "client": {
            "clientName": "WEB",
            "clientVersion": "2.20240101.00.00",
            "hl": "ar",
            "gl": "EG"
          }
        },
        "query": q
      };

      final res = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final sections = data['contents']?['twoColumnSearchResultsRenderer']
            ?['primaryContents']?['sectionListRenderer']?['contents'] as List?;
        if (sections != null) {
          for (final sec in sections) {
            final items = sec['itemSectionRenderer']?['contents'] as List?;
            if (items != null) {
              for (final item in items) {
                final vr = item['videoRenderer'] ?? item['compactVideoRenderer'];
                if (vr != null) {
                  final videoId = vr['videoId'] as String?;
                  if (videoId == null || videoId.isEmpty || !seenIds.add(videoId)) continue;

                  final fullTitle = vr['title']?['runs']?[0]?['text'] as String? ??
                      vr['title']?['simpleText'] as String? ?? '';
                  final author = vr['ownerText']?['runs']?[0]?['text'] as String? ??
                      vr['shortBylineText']?['runs']?[0]?['text'] as String? ?? 'فنان';
                  final durationText = vr['lengthText']?['simpleText'] as String? ??
                      vr['lengthText']?['runs']?[0]?['text'] as String? ?? '';

                  Duration dur = const Duration(minutes: 3, seconds: 30);
                  if (durationText.isNotEmpty) {
                    final parts = durationText.split(':').map((e) => int.tryParse(e) ?? 0).toList();
                    if (parts.length == 2) {
                      dur = Duration(minutes: parts[0], seconds: parts[1]);
                    } else if (parts.length == 3) {
                      dur = Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
                    }
                  }

                  // Accept any reasonable duration (from 5 seconds up to 12 hours)
                  if (dur.inSeconds >= 5 && dur.inHours <= 12) {
                    String songTitle = fullTitle;
                    String songArtist = author;
                    if (fullTitle.contains(' - ')) {
                      final p = fullTitle.split(' - ');
                      if (p.length >= 2) {
                        songArtist = p[0].replaceAll(RegExp(r'[@#]'), '').trim();
                        songTitle = p.sublist(1).join(' - ').trim();
                      }
                    } else if (fullTitle.contains(' | ')) {
                      final p = fullTitle.split(' | ');
                      if (p.length >= 2) {
                        songTitle = p[0].trim();
                        songArtist = p[1].trim();
                      }
                    }

                    // Gentle cleanup of noise words while preserving title integrity
                    final cleanedTitle = songTitle
                        .replaceAll(RegExp(r'\[(?:Official|Audio|Clip|Video|Music|كليب|فيديو|أغنية|اغنية)[^\]]*\]', caseSensitive: false), '')
                        .replaceAll(RegExp(r'\((?:Official|Audio|Clip|Video|Music|كليب|فيديو|أغنية|اغنية)[^\)]*\)', caseSensitive: false), '')
                        .trim();
                    if (cleanedTitle.isNotEmpty) songTitle = cleanedTitle;

                    songs.add(Song(
                      id: 'yt_$videoId',
                      title: songTitle.isNotEmpty ? songTitle : fullTitle,
                      artist: songArtist.isNotEmpty ? songArtist : author,
                      album: 'YouTube Music',
                      artworkUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                      audioUrl: '',
                      duration: dur,
                      genre: 'موسيقى كاملة',
                      playsCount: 15000000,
                    ));
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to youtube_explode_dart if InnerTube returned few or no results
    if (songs.length < 5) {
      try {
        final yt = SongAudioResolver.yt;
        final searchResults = await yt.search.search(q).timeout(const Duration(seconds: 5));
        for (final v in searchResults.take(15)) {
          if (!seenIds.add(v.id.value)) continue;
          final dur = v.duration ?? const Duration(minutes: 3, seconds: 30);
          if (dur.inSeconds >= 5 && dur.inHours <= 12) {
            final fullTitle = v.title;
            String songTitle = fullTitle;
            String songArtist = v.author;

            if (fullTitle.contains(' - ')) {
              final parts = fullTitle.split(' - ');
              if (parts.length >= 2) {
                songArtist = parts[0].replaceAll(RegExp(r'[@#]'), '').trim();
                songTitle = parts.sublist(1).join(' - ').trim();
              }
            } else if (fullTitle.contains(' | ')) {
              final parts = fullTitle.split(' | ');
              if (parts.length >= 2) {
                songTitle = parts[0].trim();
                songArtist = parts[1].trim();
              }
            }

            final cleanedTitle = songTitle
                .replaceAll(RegExp(r'\[(?:Official|Audio|Clip|Video|Music|كليب|فيديو|أغنية|اغنية)[^\]]*\]', caseSensitive: false), '')
                .replaceAll(RegExp(r'\((?:Official|Audio|Clip|Video|Music|كليب|فيديو|أغنية|اغنية)[^\)]*\)', caseSensitive: false), '')
                .trim();
            if (cleanedTitle.isNotEmpty) songTitle = cleanedTitle;

            songs.add(Song(
              id: 'yt_${v.id.value}',
              title: songTitle.isNotEmpty ? songTitle : v.title,
              artist: songArtist.isNotEmpty ? songArtist : v.author,
              album: 'YouTube Music',
              artworkUrl: v.thumbnails.highResUrl.isNotEmpty
                  ? v.thumbnails.highResUrl
                  : 'https://img.youtube.com/vi/${v.id.value}/hqdefault.jpg',
              audioUrl: '',
              duration: dur,
              genre: 'موسيقى كاملة',
              playsCount: 15000000,
              releaseYear: v.uploadDate?.year.toString(),
            ));
          }
        }
      } catch (_) {}
    }

    return songs;
  }

  // -------------------------------------------------------------
  // Intelligent Relevance Ranking & Deduplication Algorithm
  // -------------------------------------------------------------
  List<Song> _deduplicateAndRank(List<Song> songs, String userQuery) {
    final seen = <String>{};
    final uniqueSongs = <Song>[];
    final normUserQuery = _normalizeArabic(userQuery);

    for (final s in songs) {
      final normTitle = _normalizeArabic(s.title);
      final normArtist = _normalizeArabic(s.artist);
      final key = '$normTitle-$normArtist';

      if (!seen.contains(key) && normTitle.isNotEmpty) {
        seen.add(key);
        uniqueSongs.add(s);
      } else if (s.id.startsWith('yt_')) {
        // Prefer YouTube versions because they guarantee the full song and duration
        final existingIdx = uniqueSongs.indexWhere((existing) =>
            _normalizeArabic(existing.title) == normTitle &&
            _normalizeArabic(existing.artist) == normArtist);
        if (existingIdx != -1 && !uniqueSongs[existingIdx].id.startsWith('yt_')) {
          uniqueSongs[existingIdx] = s;
        }
      }
    }

    // Comprehensive relevance scoring
    int computeScore(Song s) {
      final normTitle = _normalizeArabic(s.title);
      final normArtist = _normalizeArabic(s.artist);
      final combined = '$normTitle $normArtist';
      final reverseCombined = '$normArtist $normTitle';

      int sc = 0;
      // Exact matches
      if (normTitle == normUserQuery) sc += 1200;
      if (normArtist == normUserQuery) sc += 900;
      if (combined == normUserQuery || reverseCombined == normUserQuery) sc += 1100;

      // Starts with
      if (normTitle.startsWith(normUserQuery)) sc += 600;
      if (normArtist.startsWith(normUserQuery)) sc += 450;
      if (combined.startsWith(normUserQuery) || reverseCombined.startsWith(normUserQuery)) sc += 550;

      // Contains
      if (normTitle.contains(normUserQuery)) sc += 350;
      if (normArtist.contains(normUserQuery)) sc += 250;
      if (combined.contains(normUserQuery) || reverseCombined.contains(normUserQuery)) sc += 300;

      // Query words match
      final queryWords = normUserQuery.split(' ').where((w) => w.length > 1);
      int matchedWords = 0;
      for (final w in queryWords) {
        if (normTitle.contains(w) || normArtist.contains(w)) {
          matchedWords++;
        }
      }
      sc += matchedWords * 150;

      // Bonus for YouTube full audio source
      if (s.id.startsWith('yt_')) sc += 80;

      return sc;
    }

    uniqueSongs.sort((a, b) {
      final scoreA = computeScore(a);
      final scoreB = computeScore(b);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return b.playsCount.compareTo(a.playsCount);
    });

    return uniqueSongs;
  }

  // -------------------------------------------------------------
  // 15+ API Parallel Aggregated Search Implementation
  // -------------------------------------------------------------
  @override
  Future<List<Song>> searchSongs(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final variations = _buildSearchVariations(q);
    final normQ = _normalizeArabic(q);

    // 1. Instant check in Curated Arabic Hits & Sample Data
    final localMatches = <Song>[];
    for (final s in [..._curatedArabicHits, ...SampleMusicData.songs]) {
      final normTitle = _normalizeArabic(s.title);
      final normArtist = _normalizeArabic(s.artist);
      final normAlbum = _normalizeArabic(s.album);
      if (normTitle.contains(normQ) ||
          normArtist.contains(normQ) ||
          normAlbum.contains(normQ) ||
          normQ.contains(normTitle)) {
        localMatches.add(s);
      }
    }

    // 2. Query 15+ API endpoints in parallel with variations
    final futures = <Future<List<Song>>>[];

    // Source 0: YouTube & YouTube Music (Guaranteed full songs!)
    futures.add(_searchYouTube(q));
    if (variations.length > 1) {
      futures.add(_searchYouTube(variations[1]));
    }

    // Source 1: Deezer with raw query
    futures.add(_searchDeezer(q));

    // Source 2: Deezer with variations / transliterations
    for (final v in variations.skip(1).take(2)) {
      futures.add(_searchDeezer(v));
    }

    // Source 3: Deezer Artist Top Tracks
    futures.add(_searchDeezerArtistTopTracks(q));

    // Source 4: Apple Music / iTunes Egypt
    futures.add(_searchItunesCountry(q, 'EG'));

    // Source 5: Apple Music / iTunes Saudi Arabia
    futures.add(_searchItunesCountry(q, 'SA'));

    // Source 6: Apple Music / iTunes UAE
    futures.add(_searchItunesCountry(q, 'AE'));

    // Source 7: Apple Music / iTunes Global
    futures.add(_searchItunesCountry(q, 'US'));

    // Source 8: Apple Music / iTunes with Transliterations
    for (final v in variations.skip(1).take(2)) {
      futures.add(_searchItunesCountry(v, 'EG'));
      futures.add(_searchItunesCountry(v, 'US'));
    }

    // Source 9: Internet Archive Arabic Music Collection
    futures.add(_searchInternetArchive(q));

    // Source 10: Internet Archive with variations
    if (variations.length > 1) {
      futures.add(_searchInternetArchive(variations[1]));
    }

    // Source 11: MusicBrainz Recording Search
    futures.add(_searchMusicBrainz(q));

    // Run all APIs concurrently with error resilience
    final results = await Future.wait(
      futures.map((f) => f.catchError((_) => <Song>[])),
    );

    final aggregated = <Song>[...localMatches];
    for (final list in results) {
      aggregated.addAll(list);
    }

    final finalSongs = _deduplicateAndRank(aggregated, q);
    return finalSongs.isNotEmpty ? finalSongs : localMatches;
  }

  @override
  Future<List<Artist>> searchArtists(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final localArtists = SampleMusicData.artists.where((a) {
      final normName = _normalizeArabic(a.name);
      return normName.contains(_normalizeArabic(q));
    }).toList();

    final results = await Future.wait([
      _searchDeezerArtists(q).catchError((_) => <Artist>[]),
      _searchItunesArtists(q).catchError((_) => <Artist>[]),
    ]);

    final aggregated = <Artist>[...localArtists];
    for (final list in results) {
      aggregated.addAll(list);
    }

    final seen = <String>{};
    return aggregated.where((a) => seen.add(_normalizeArabic(a.name))).toList();
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final localAlbums = SampleMusicData.albums.where((al) {
      final normTitle = _normalizeArabic(al.title);
      return normTitle.contains(_normalizeArabic(q));
    }).toList();

    final results = await Future.wait([
      _searchDeezerAlbums(q).catchError((_) => <Album>[]),
      _searchItunesAlbums(q).catchError((_) => <Album>[]),
    ]);

    final aggregated = <Album>[...localAlbums];
    for (final list in results) {
      aggregated.addAll(list);
    }

    final seen = <String>{};
    return aggregated.where((al) => seen.add(_normalizeArabic(al.title))).toList();
  }

  // -------------------------------------------------------------
  // Stable Feed Methods for Discovery & Home Screen (Consistent across Refreshes)
  // -------------------------------------------------------------
  List<Song>? _stableRecentlyPlayed;
  List<Song>? _stableRecommended;
  List<Song>? _stablePopular;
  List<Song>? _stableNewReleases;
  List<Song>? _stableContinueListening;

  bool _isAmrDiab(Song s) {
    final a = s.artist.toLowerCase();
    final t = s.title.toLowerCase();
    return a.contains('عمرو دياب') || a.contains('amr diab') || t.contains('عمرو دياب') || t.contains('amr diab');
  }

  @override
  Future<List<Song>> fetchRecentlyPlayed() async {
    if (_stableRecentlyPlayed != null && _stableRecentlyPlayed!.isNotEmpty) {
      return _stableRecentlyPlayed!;
    }
    _stableRecentlyPlayed = _curatedArabicHits.where((s) => !_isAmrDiab(s)).take(6).toList();
    return _stableRecentlyPlayed!;
  }

  @override
  Future<List<Song>> fetchRecommendedSongs() async {
    if (_stableRecommended != null && _stableRecommended!.isNotEmpty) {
      return _stableRecommended!;
    }
    try {
      final liveTracks = await _searchDeezer('تامر عاشور شيرين حمزة نمرة');
      if (liveTracks.isNotEmpty) {
        final seen = <String>{};
        final combined = <Song>[];
        for (final s in [...liveTracks.take(8), ..._curatedArabicHits]) {
          if (!_isAmrDiab(s) && seen.add(s.id)) {
            combined.add(s);
          }
        }
        _stableRecommended = combined.take(16).toList();
        return _stableRecommended!;
      }
    } catch (_) {}
    _stableRecommended = _curatedArabicHits.where((s) => !_isAmrDiab(s)).take(16).toList();
    return _stableRecommended!;
  }

  @override
  Future<List<Song>> fetchPopularSongs() async {
    if (_stablePopular != null && _stablePopular!.isNotEmpty) {
      return _stablePopular!;
    }
    try {
      final trending = await _searchDeezer('تريند مصر 2024');
      if (trending.isNotEmpty) {
        final seen = <String>{};
        final combined = <Song>[];
        for (final s in [..._curatedArabicHits, ...trending]) {
          if (!_isAmrDiab(s) && seen.add(s.id)) {
            combined.add(s);
          }
        }
        _stablePopular = combined.take(18).toList();
        return _stablePopular!;
      }
    } catch (_) {}
    _stablePopular = _curatedArabicHits.where((s) => !_isAmrDiab(s)).take(18).toList();
    return _stablePopular!;
  }

  @override
  Future<List<Song>> fetchNewReleases() async {
    if (_stableNewReleases != null && _stableNewReleases!.isNotEmpty) {
      return _stableNewReleases!;
    }
    try {
      final itunesNew = await _searchItunesCountry('جديد', 'EG');
      if (itunesNew.isNotEmpty) {
        final seen = <String>{};
        final combined = <Song>[];
        for (final s in [...itunesNew.take(8), ..._curatedArabicHits.reversed]) {
          if (!_isAmrDiab(s) && seen.add(s.id)) {
            combined.add(s);
          }
        }
        _stableNewReleases = combined.take(14).toList();
        return _stableNewReleases!;
      }
    } catch (_) {}
    _stableNewReleases = _curatedArabicHits.where((s) => !_isAmrDiab(s)).take(14).toList();
    return _stableNewReleases!;
  }

  @override
  Future<List<Song>> fetchContinueListening() async {
    if (_stableContinueListening != null && _stableContinueListening!.isNotEmpty) {
      return _stableContinueListening!;
    }
    _stableContinueListening = _curatedArabicHits.where((s) => !_isAmrDiab(s)).skip(2).take(4).toList();
    return _stableContinueListening!;
  }

  @override
  Future<List<Genre>> fetchGenres() async => SampleMusicData.genres;

  @override
  Future<List<Artist>> fetchFeaturedArtists() async {
    // Try to fetch real artist images from Deezer CDN live
    Future<String> deezerArtistImage(String query, String fallback) async {
      try {
        final uri = Uri.parse(
            'https://api.deezer.com/search/artist?q=${Uri.encodeComponent(query)}&limit=1');
        final res = await _client.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final list = data['data'] as List<dynamic>? ?? [];
          if (list.isNotEmpty) {
            final pic = list.first['picture_big'] as String? ??
                list.first['picture_medium'] as String? ??
                fallback;
            if (pic.isNotEmpty && !pic.contains('default')) return pic;
          }
        }
      } catch (_) {}
      return fallback;
    }

    final results = await Future.wait([
      deezerArtistImage('Tamer Ashour', 'https://cdn-images.dzcdn.net/images/artist/9bce0ee0ca1ec88e6a8d72e1d3f6ce8c/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Sherine Abdel Wahab', 'https://cdn-images.dzcdn.net/images/artist/9bce0ee0ca1ec88e6a8d72e1d3f6ce8c/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Tamer Hosny', 'https://cdn-images.dzcdn.net/images/artist/2e3a7c9d5f1b4e6a8c0d2f4b6e8a0c2d/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Mohamed Hamaki', 'https://cdn-images.dzcdn.net/images/artist/7e6e84b1c9e7fb5b0e60d0e3a1d0c8b5/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Wegz', 'https://cdn-images.dzcdn.net/images/artist/8e2f2dc6ee5a4f9c5cc2e5e7b4a5d3f2/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Ahmed Saad', 'https://cdn-images.dzcdn.net/images/artist/ba98ee615c5867d2f5ca252e215c039c/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Cairokee', 'https://cdn-images.dzcdn.net/images/artist/3bce3d93fce7e0a2a36cf34f5f5a7e98/500x500-000000-80-0-0.jpg'),
      deezerArtistImage('Hassan Shakosh', 'https://cdn-images.dzcdn.net/images/artist/ba98ee615c5867d2f5ca252e215c039c/500x500-000000-80-0-0.jpg'),
    ]);

    return [
      Artist(
        id: 'artist_tamer_ashour',
        name: 'تامر عاشور',
        imageUrl: results[0],
        bio: 'فنان ومطرب مصري صاحب الحنجرة الذهبية والأغاني الدرامية والرومانسية المؤثرة.',
        genre: 'طرب معاصر',
        followersCount: 7500000,
        monthlyListeners: 10000000,
      ),
      Artist(
        id: 'artist_sherine',
        name: 'شيرين عبد الوهاب',
        imageUrl: results[1],
        bio: 'صوت مصر وإحساس الوطن العربي.',
        genre: 'طرب معاصر',
        followersCount: 8200000,
        monthlyListeners: 11500000,
      ),
      Artist(
        id: 'artist_tamer',
        name: 'تامر حسني',
        imageUrl: results[2],
        bio: 'نجم الجيل وصاحب أكبر الحفلات في الشرق الأوسط.',
        genre: 'بوب عربي',
        followersCount: 7800000,
        monthlyListeners: 10200000,
      ),
      Artist(
        id: 'artist_hamaki',
        name: 'محمد حماقي',
        imageUrl: results[3],
        bio: 'سوبر ستار البوب العربي وأيقونة الحفلات العصرية.',
        genre: 'بوب عربي',
        followersCount: 6500000,
        monthlyListeners: 9100000,
      ),
      Artist(
        id: 'artist_wegz',
        name: 'ويجز',
        imageUrl: results[4],
        bio: 'رائد التراب والهيب هوب العربي وأحد أكثر الفنانين استماعاً عالمياً.',
        genre: 'تراب عربي',
        followersCount: 5800000,
        monthlyListeners: 8400000,
      ),
      Artist(
        id: 'artist_ahmed_saad',
        name: 'أحمد سعد',
        imageUrl: results[5],
        bio: 'صاحب أقوى صوت شعبي وطربي معاصر وأعلى أغاني تريند.',
        genre: 'بوب شعبي',
        followersCount: 5100000,
        monthlyListeners: 7900000,
      ),
      Artist(
        id: 'artist_cairokee',
        name: 'كاريوكي',
        imageUrl: results[6],
        bio: 'أشهر فرقة روك وإندي عربي تعبر عن نبض الشارع والشباب.',
        genre: 'روك عربي',
        followersCount: 4600000,
        monthlyListeners: 6800000,
      ),
      Artist(
        id: 'artist_shakosh',
        name: 'حسن شاكوش',
        imageUrl: results[7],
        bio: 'مغني مهرجانات وشعبي مصري وصاحب أشهر التريندات العربية.',
        genre: 'مهرجانات',
        followersCount: 4200000,
        monthlyListeners: 6800000,
      ),
    ];
  }

  @override
  Future<List<Playlist>> fetchFeaturedPlaylists() async => SampleMusicData.playlists;

  @override
  Future<Song?> getSongById(String id) async {
    for (final s in [..._curatedArabicHits, ...SampleMusicData.songs]) {
      if (s.id == id) return s;
    }
    // Try fetching from Deezer if it's a deezer track ID
    if (id.startsWith('deezer_')) {
      try {
        final realId = id.replaceFirst('deezer_', '');
        final res = await _client.get(Uri.parse('https://api.deezer.com/track/$realId')).timeout(_apiTimeout);
        if (res.statusCode == 200) {
          final item = json.decode(res.body);
          final artistMap = item['artist'] as Map<String, dynamic>? ?? {};
          final albumMap = item['album'] as Map<String, dynamic>? ?? {};
          return Song(
            id: id,
            title: item['title'] as String? ?? '',
            artist: artistMap['name'] as String? ?? '',
            album: albumMap['title'] as String? ?? '',
            artworkUrl: albumMap['cover_big'] as String? ?? '',
            audioUrl: item['preview'] as String? ?? '',
            duration: Duration(seconds: item['duration'] as int? ?? 180),
            genre: 'موسيقى',
          );
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<Artist?> getArtistById(String id) async {
    for (final a in await fetchFeaturedArtists()) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<List<Song>> getSongsByArtist(String artistId) async {
    final featuredArtists = await fetchFeaturedArtists();
    final artist = featuredArtists.firstWhere(
      (a) => a.id == artistId,
      orElse: () => Artist(id: artistId, name: '', imageUrl: ''),
    );
    final artistName = artist.name.isNotEmpty ? artist.name : artistId;
    final normArtistName = _normalizeArabic(artistName);

    final allSongs = [..._curatedArabicHits, ...SampleMusicData.songs];
    final byId = allSongs.where((s) {
      if (s.artistId == artistId) return true;
      if (normArtistName.isNotEmpty && _normalizeArabic(s.artist).contains(normArtistName)) return true;
      if (normArtistName.isNotEmpty && normArtistName.contains(_normalizeArabic(s.artist))) return true;
      return false;
    }).toList();

    // If we have plenty of curated hits (at least 6), return them directly
    if (byId.length >= 6) return byId;

    // Otherwise, search for more songs of this artist and combine with curated hits
    final searchResults = await searchSongs(artistName);
    final combined = <Song>[...byId];
    final seen = byId.map((s) => _normalizeArabic(s.title)).toSet();

    for (final song in searchResults) {
      final normTitle = _normalizeArabic(song.title);
      if (seen.add(normTitle)) {
        combined.add(song);
      }
    }

    return combined.isNotEmpty ? combined : byId;
  }

  @override
  Future<Album?> getAlbumById(String id) async {
    for (final al in SampleMusicData.albums) {
      if (al.id == id) return al;
    }
    return null;
  }

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    return SampleMusicData.songs.where((s) => s.albumId == albumId).toList();
  }

  @override
  Future<List<Song>> getSongsByGenre(String genreId) async {
    final genre = SampleMusicData.genres.firstWhere(
      (g) => g.id == genreId,
      orElse: () => SampleMusicData.genres.first,
    );
    return searchSongs(genre.name);
  }

  @override
  Future<List<Song>> getRelatedSongs(Song song) async {
    final related = <Song>[];
    final seen = <String>{_normalizeArabic(song.title)};

    // 1. Same artist songs first
    try {
      final artistSongs = await getSongsByArtist(song.artistId ?? song.artist);
      for (final s in artistSongs) {
        final norm = _normalizeArabic(s.title);
        if (seen.add(norm)) {
          related.add(s);
        }
      }
    } catch (_) {}

    // 2. Similar songs by genre or style from Curated Hits
    final normGenre = _normalizeArabic(song.genre);
    final allHits = [..._curatedArabicHits, ...SampleMusicData.songs];
    for (final s in allHits) {
      if (_normalizeArabic(s.genre).contains(normGenre) ||
          normGenre.contains(_normalizeArabic(s.genre)) ||
          _normalizeArabic(s.artist) == _normalizeArabic(song.artist)) {
        final norm = _normalizeArabic(s.title);
        if (seen.add(norm)) {
          related.add(s);
        }
      }
    }

    // 3. Additional popular curated hits to ensure full radio queue
    for (final s in allHits) {
      final norm = _normalizeArabic(s.title);
      if (seen.add(norm)) {
        related.add(s);
      }
      if (related.length >= 15) break;
    }

    return related;
  }

  @override
  Future<List<Playlist>> searchPlaylists(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return [];

    final localMatches = SampleMusicData.curatedPlaylists.where((pl) {
      final nameMatch = pl.name.toLowerCase().contains(query.toLowerCase());
      final descMatch = pl.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final normQuery = _normalizeArabic(rawQuery);
      final normName = _normalizeArabic(pl.name);
      final normDesc = _normalizeArabic(pl.description ?? '');
      final normMatch = normName.contains(normQuery) || normDesc.contains(normQuery);
      return nameMatch || descMatch || normMatch;
    }).toList();

    // Query Deezer live playlists
    try {
      final uri = Uri.parse('https://api.deezer.com/search/playlist?q=${Uri.encodeComponent(query)}&limit=15');
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];
        final remotePlaylists = list.map((item) {
          final pic = item['picture_big'] as String? ??
              item['picture_medium'] as String? ??
              'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg';
          return Playlist(
            id: 'deezer_pl_${item['id']}',
            name: item['title'] as String? ?? 'قائمة تشغيل',
            artworkUrl: pic,
            description: 'قائمة تشغيل من إعداد ديزر (${item['nb_tracks'] ?? 0} مقطع)',
          );
        }).toList();

        final combined = <Playlist>[...localMatches, ...remotePlaylists];
        final seen = <String>{};
        return combined.where((p) => seen.add(p.name.toLowerCase())).toList();
      }
    } catch (_) {}

    return localMatches;
  }
}
