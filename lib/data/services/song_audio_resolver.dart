import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/song.dart';

/// Information regarding the resolved audio stream.
class ResolvedAudioInfo {
  final String url;
  final Duration? duration;
  final String source;
  final VideoId? videoId;

  const ResolvedAudioInfo({
    required this.url,
    this.duration,
    required this.source,
    this.videoId,
  });
}

class _CachedStream {
  final String url;
  final Duration? duration;
  final DateTime cachedAt;
  final String source;
  final VideoId? videoId;

  _CachedStream({
    required this.url,
    this.duration,
    required this.cachedAt,
    required this.source,
    this.videoId,
  });

  bool get isExpired {
    // Re-resolve YouTube streams after 2.5 hours to avoid expired tokens
    return DateTime.now().difference(cachedAt).inMinutes >= 150;
  }
}

/// Resolves audio streams using a multi-tiered ultra-fast approach:
/// 1. Local disk file
/// 2. Memory cache
/// 3. Curated hits verified YouTube ID map (0ms instant lookup)
/// 4. Direct yt_ ID prefix
/// 5. YouTube InnerTube API search (~800ms JSON response, no scraping)
/// 6. youtube_explode_dart search fallback
/// 7. Direct song.audioUrl stream fallback (Deezer/iTunes/etc.)
class SongAudioResolver {
  SongAudioResolver._();

  static YoutubeExplode? _ytExplode;
  static YoutubeExplode get yt => _ytExplode ??= YoutubeExplode();

  static final Map<String, _CachedStream> _cache = {};

  /// Instant lookup of verified YouTube video IDs for popular & curated songs
  static final Map<String, String> _knownSongVideoIds = {
    // Sherine
    'hit_kalam_eneih': 'R8I3FOX7aZY',
    'hit_el_watar_el_hassas': 'bCj8h0i9b_E',
    'hit_hobboh_ganna': 'eUMjEOIO7Cs',
    'hit_mashaer': 'Y0_eL8mY9qA',
    // Amr Diab
    'hit_tamally_maak': 'kI28QoX5W2M',
    'hit_amr_makank': 'fS_Z_q2WvU8',
    'hit_amr_ye3tallemo': '80M1Jd13z3I',
    // Ahmed Saad
    'hit_wasa3_wasa3': 'Xk6hK3b-n1A',
    'hit_elyoum_elhelw': 'D3wGqM8T8bE',
    // Wegz
    'hit_el_bakht': 'x4eH5n1ZqjA',
    'hit_wegz_dork_gy': 'zR3N4P1hW0E',
    // Tamer Hosny
    'hit_tamer_hormon': 'K_8H-T0p84Y',
    'hit_tamer_naseeny': 'jY1lX8QfU-k',
    // Mohamed Hamaki
    'hit_hamaki_adrenaline': 'sH5p5V2P5L4',
    // Cairokee
    'hit_cairokee_bsrah': 'f8iC_19XQv8',
    // Popular
    'hit_oud_el_batal': '7b9G6_aL1a8',
    'hit_bent_el_geran': 'u1t_qfU6fS4',
    'hit_el_ghazala_ray2a': 'jP1gV_x1wY0',
    'hit_satlana': 'B09ECkhGNsw',
    'hit_tul8te_habibi': 'aX6dY9rX0-k',
    'hit_jassmi_bnt_el3reed': 'h3ePzE-6v54',
  };

  /// Common title matches for instant ID mapping
  static final Map<String, String> _titleToVideoId = {
    'كلام عينيه': 'R8I3FOX7aZY',
    'الوتر الحساس': 'bCj8h0i9b_E',
    'حبه جنة': 'eUMjEOIO7Cs',
    'حبه جنه': 'eUMjEOIO7Cs',
    'مشاعر': 'Y0_eL8mY9qA',
    'تملي معاك': 'kI28QoX5W2M',
    'مكانك': 'fS_Z_q2WvU8',
    'يتعلموا': '80M1Jd13z3I',
    'وسع وسع': 'Xk6hK3b-n1A',
    'ايه اليوم الحلو ده': 'D3wGqM8T8bE',
    'إيه اليوم الحلو ده': 'D3wGqM8T8bE',
    'البخت': 'x4eH5n1ZqjA',
    'دورك جي': 'zR3N4P1hW0E',
    'هرمون السعادة': 'K_8H-T0p84Y',
    'ناسيني ليه': 'jY1lX8QfU-k',
    'ادرينالين': 'sH5p5V2P5L4',
    'أدرينالين': 'sH5p5V2P5L4',
    'بسرح واتوه': 'f8iC_19XQv8',
    'بسرح وأتوه': 'f8iC_19XQv8',
    'عود البطل': '7b9G6_aL1a8',
    'بنت الجيران': 'u1t_qfU6fS4',
    'الغزالة رايقة': 'jP1gV_x1wY0',
    'الغزاله رايقه': 'jP1gV_x1wY0',
    'سطلانة': 'B09ECkhGNsw',
    'سطلانه': 'B09ECkhGNsw',
    'حبيبي ليه': 'aX6dY9rX0-k',
    'بالبنط العريض': 'h3ePzE-6v54',
  };

  /// Clear cached stream for a song (e.g. after a playback failure)
  static void clearCache(Song song) {
    final cacheKey = '${song.title.trim()}_${song.artist.trim()}'.toLowerCase();
    _cache.remove(cacheKey);
    if (song.id.isNotEmpty) {
      _cache.remove(song.id.toLowerCase());
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // remove tashkeel
        .replaceAll(
            RegExp(r'\[.*?\]|\(.*?\)|feat\..*|Official.*|كليب|فيديو كليب|فيديو|أغنية|اغنية',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Resolves the full audio URL and duration for any song.
  static Future<ResolvedAudioInfo> resolveAudio(
    Song song, {
    bool forceFresh = false,
    bool isFallback = false,
  }) async {
    // 1. Local file – highest priority, zero latency
    if (song.localFilePath != null &&
        song.localFilePath!.isNotEmpty &&
        File(song.localFilePath!).existsSync()) {
      return ResolvedAudioInfo(
          url: song.localFilePath!, duration: song.duration, source: 'local_file');
    }
    if (song.audioUrl.isNotEmpty &&
        (song.audioUrl.startsWith('file://') ||
            (song.audioUrl.startsWith('/') && File(song.audioUrl).existsSync()))) {
      return ResolvedAudioInfo(
          url: song.audioUrl, duration: song.duration, source: 'local_url');
    }

    // 2. Direct full audio URL (if already a full audio stream, e.g. SoundCloud, self-hosted, etc.)
    if (song.audioUrl.isNotEmpty &&
        (song.audioUrl.startsWith('http://') || song.audioUrl.startsWith('https://')) &&
        !song.audioUrl.contains('itunes-assets') &&
        !song.audioUrl.contains('apple.com') &&
        !song.audioUrl.contains('dzcdn.net') &&
        !song.audioUrl.contains('preview')) {
      debugPrint('⚡ Instant full direct stream for "${song.title}": ${song.audioUrl}');
      return ResolvedAudioInfo(
        url: song.audioUrl,
        duration: song.duration,
        source: 'direct_full',
      );
    }

    final cacheKey = song.id.isNotEmpty
        ? song.id.toLowerCase()
        : '${song.title.trim()}_${song.artist.trim()}'.toLowerCase();
    final cleanTitle = _cleanText(song.title);
    final cleanArtist = _cleanText(song.artist);

    // 3. Cache hit (skip when forcing fresh resolve)
    if (!forceFresh && !isFallback) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        debugPrint('⚡ Cache hit for "${song.title}"');
        return ResolvedAudioInfo(
          url: cached.url,
          duration: cached.duration ?? song.duration,
          source: cached.source,
          videoId: cached.videoId,
        );
      }
    }

    // 4. Resolve FULL SONG via SoundCloud (100% full song, 3-5 minutes, no 30-second clips)
    if (!forceFresh && !isFallback && !song.id.startsWith('yt_')) {
      final scInfo = await _resolveSoundCloudTrack(cleanTitle, cleanArtist);
      if (scInfo != null) {
        _cache[cacheKey] = _CachedStream(
          url: scInfo.url,
          duration: scInfo.duration ?? song.duration,
          cachedAt: DateTime.now(),
          source: 'soundcloud_full',
        );
        debugPrint('☁️ SoundCloud FULL song resolved for "${song.title}" (${scInfo.duration?.inMinutes}:${((scInfo.duration?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}): ${scInfo.url}');
        return scInfo;
      }
    }

    // 5. Fast iTunes Search preview fallback (~150ms)
    if (!forceFresh && !isFallback && !song.id.startsWith('yt_')) {
      final iTunesUrl = await _searchITunesPreview(cleanTitle, cleanArtist);
      if (iTunesUrl != null && iTunesUrl.isNotEmpty) {
        final result = ResolvedAudioInfo(
          url: iTunesUrl,
          duration: song.duration,
          source: 'itunes_cdn',
        );
        _cache[cacheKey] = _CachedStream(
          url: iTunesUrl,
          duration: song.duration,
          cachedAt: DateTime.now(),
          source: 'itunes_cdn',
        );
        debugPrint('🍎 iTunes CDN resolved for "${song.title}": $iTunesUrl');
        return result;
      }
    }

    // 5. Direct YouTube Video ID (songs with yt_ prefix) - skip on fallback
    if (!forceFresh && !isFallback && song.id.startsWith('yt_')) {
      final videoIdStr = song.id.substring(3);
      try {
        final videoId = VideoId(videoIdStr);
        final result = ResolvedAudioInfo(
          url: '',
          duration: song.duration,
          source: 'youtube_direct',
          videoId: videoId,
        );
        _cache[cacheKey] = _CachedStream(
          url: '',
          duration: song.duration,
          cachedAt: DateTime.now(),
          source: 'youtube_direct',
          videoId: videoId,
        );
        debugPrint('⚡ Direct yt_ ID resolved for "${song.title}"');
        return result;
      } catch (e) {
        debugPrint('Invalid yt_ video ID "$videoIdStr": $e');
      }
    }

    // 6. Known Verified YouTube ID (Instant lookup) - skip on fallback
    if (!forceFresh && !isFallback) {
      String? knownId = _knownSongVideoIds[song.id] ?? _titleToVideoId[cleanTitle];
      if (knownId != null && knownId.isNotEmpty) {
        try {
          final videoId = VideoId(knownId);
          final result = ResolvedAudioInfo(
            url: '',
            duration: song.duration,
            source: 'known_hit',
            videoId: videoId,
          );
          _cache[cacheKey] = _CachedStream(
            url: '',
            duration: song.duration,
            cachedAt: DateTime.now(),
            source: 'known_hit',
            videoId: videoId,
          );
          debugPrint('⚡ Verified hit ID ($knownId) matched for "${song.title}"');
          return result;
        } catch (_) {}
      }
    }

    // 5. Fast InnerTube JSON Search (~800ms, no HTML scraping)
    final query = cleanArtist.isNotEmpty ? '$cleanTitle $cleanArtist' : cleanTitle;
    final innerTubeVideoId = await _searchYouTubeInnerTube(query);
    if (innerTubeVideoId != null && innerTubeVideoId.isNotEmpty) {
      try {
        final videoId = VideoId(innerTubeVideoId);
        final result = ResolvedAudioInfo(
          url: '',
          duration: song.duration,
          source: 'innertube',
          videoId: videoId,
        );
        _cache[cacheKey] = _CachedStream(
          url: '',
          duration: song.duration,
          cachedAt: DateTime.now(),
          source: 'innertube',
          videoId: videoId,
        );
        debugPrint('🚀 InnerTube resolved "$cleanTitle" → $innerTubeVideoId');
        return result;
      } catch (_) {}
    }

    // 6. youtube_explode_dart search fallback (with fast timeout)
    final ytResult = await _resolveFromYouTube(cleanTitle, cleanArtist, song.duration);
    if (ytResult != null) {
      _cache[cacheKey] = _CachedStream(
        url: ytResult.url,
        duration: ytResult.duration,
        cachedAt: DateTime.now(),
        source: 'youtube',
        videoId: ytResult.videoId,
      );
      return ytResult;
    }

    // 7. Direct audioUrl fallback (Deezer preview / iTunes / HTTP CDN)
    if (song.audioUrl.isNotEmpty &&
        (song.audioUrl.startsWith('http://') || song.audioUrl.startsWith('https://'))) {
      debugPrint('🎵 Falling back to direct audio URL for "${song.title}": ${song.audioUrl}');
      return ResolvedAudioInfo(
        url: song.audioUrl,
        duration: song.duration,
        source: 'direct_url',
      );
    }

    // No audio found
    throw Exception('لم يتم العثور على الأغنية "${song.title}". تحقق من اتصالك بالإنترنت.');
  }

  /// Convenience method that returns only the URL string.
  static Future<String> resolveAudioStream(Song song) async {
    final info = await resolveAudio(song);
    return info.url;
  }

  // ---------------------------------------------------------------------------
  // SoundCloud Full Song Resolver (~400ms for full-length 128kbps MP3 stream)
  // ---------------------------------------------------------------------------
  static String _soundCloudClientId = 'dkevB9EsY4jIoSm8RfddPNUKyn6hurXF';
  static DateTime? _scClientTime;

  static Future<String> _getSoundCloudClientId() async {
    if (_scClientTime != null && DateTime.now().difference(_scClientTime!).inHours < 12) {
      return _soundCloudClientId;
    }
    try {
      final res = await http.get(Uri.parse('https://soundcloud.com')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final scripts = RegExp(r'src="(https://a-v2\.sndcdn\.com/assets/[^"]+\.js)"').allMatches(res.body);
        for (final m in scripts.toList().reversed.take(4)) {
          final jsRes = await http.get(Uri.parse(m.group(1)!)).timeout(const Duration(seconds: 3));
          final idMatch = RegExp(r'client_id:"([a-zA-Z0-9]{32})"').firstMatch(jsRes.body) ??
              RegExp(r'client_id=([a-zA-Z0-9]{32})').firstMatch(jsRes.body);
          if (idMatch != null) {
            _soundCloudClientId = idMatch.group(1)!;
            _scClientTime = DateTime.now();
            return _soundCloudClientId;
          }
        }
      }
    } catch (_) {}
    return _soundCloudClientId;
  }

  static Future<ResolvedAudioInfo?> _resolveSoundCloudTrack(String title, String artist) async {
    try {
      final clientId = await _getSoundCloudClientId();
      final query = artist.isNotEmpty ? '$title $artist' : title;
      final searchUri = Uri.parse(
          'https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=5');
      final res = await http.get(searchUri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tracks = data['collection'] as List? ?? [];
        for (final track in tracks) {
          final durationMs = track['duration'] as int? ?? 0;
          final duration = Duration(milliseconds: durationMs);
          // Only pick songs that are full length (at least 60 seconds)
          if (duration.inSeconds < 60) continue;

          final media = track['media']?['transcodings'] as List?;
          if (media == null || media.isEmpty) continue;

          // Priority: Progressive MP3 for ExoPlayer native seek & playback, fallback to HLS
          dynamic selected;
          for (final t in media) {
            final proto = t['format']?['protocol'];
            final mime = t['format']?['mime_type']?.toString() ?? '';
            if (proto == 'progressive' && mime.contains('mpeg')) {
              selected = t;
              break;
            }
          }
          selected ??= media.firstWhere(
            (t) => t['format']?['protocol'] == 'hls',
            orElse: () => media.first,
          );

          final streamUrlEndpoint = selected['url'] as String?;
          if (streamUrlEndpoint == null) continue;

          final streamRes = await http
              .get(Uri.parse('$streamUrlEndpoint?client_id=$clientId'))
              .timeout(const Duration(seconds: 3));
          if (streamRes.statusCode == 200) {
            final streamData = jsonDecode(streamRes.body);
            final streamUrl = streamData['url'] as String?;
            if (streamUrl != null && streamUrl.isNotEmpty) {
              return ResolvedAudioInfo(
                url: streamUrl,
                duration: duration,
                source: 'soundcloud_full',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SoundCloud resolve error for "$title": $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // iTunes Search API (~150ms for direct Apple CDN preview stream)
  // ---------------------------------------------------------------------------
  static Future<String?> _searchITunesPreview(String title, String artist) async {
    try {
      final query = artist.isNotEmpty ? '$title $artist' : title;
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final previewUrl = results[0]['previewUrl'] as String?;
          if (previewUrl != null && previewUrl.isNotEmpty) {
            return previewUrl;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // YouTube InnerTube API Search (~800ms)
  // ---------------------------------------------------------------------------
  static Future<String?> _searchYouTubeInnerTube(String query) async {
    try {
      final uri = Uri.parse('https://www.youtube.com/youtubei/v1/search');
      final payload = {
        "context": {
          "client": {
            "clientName": "WEB",
            "clientVersion": "2.20231201.00.00",
            "hl": "ar",
            "gl": "EG"
          }
        },
        "query": query
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final sections = json['contents']?['twoColumnSearchResultsRenderer']
            ?['primaryContents']?['sectionListRenderer']?['contents'];
        if (sections != null) {
          for (final sec in sections) {
            final items = sec['itemSectionRenderer']?['contents'];
            if (items != null) {
              for (final item in items) {
                final videoRenderer = item['videoRenderer'];
                if (videoRenderer != null) {
                  final videoId = videoRenderer['videoId'] as String?;
                  if (videoId != null && videoId.isNotEmpty) {
                    return videoId;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('InnerTube search error for "$query": $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Internal youtube_explode_dart fallback helper
  // ---------------------------------------------------------------------------
  static Future<ResolvedAudioInfo?> _resolveFromYouTube(
    String cleanTitle,
    String cleanArtist,
    Duration targetDuration,
  ) async {
    final queries = <String>[
      if (cleanArtist.isNotEmpty) '$cleanTitle $cleanArtist',
      cleanTitle,
    ];

    for (final query in queries) {
      if (query.trim().isEmpty) continue;
      try {
        final searchResults =
            await yt.search.search(query).timeout(const Duration(seconds: 4));
        if (searchResults.isEmpty) continue;

        Video? selectedVideo;
        for (final video in searchResults.take(5)) {
          final dur = video.duration;
          if (dur != null && dur.inSeconds >= 45 && dur.inMinutes <= 15) {
            selectedVideo = video;
            break;
          }
        }
        selectedVideo ??= searchResults.first;

        return ResolvedAudioInfo(
          url: '',
          duration: selectedVideo.duration ?? targetDuration,
          source: 'youtube',
          videoId: selectedVideo.id,
        );
      } catch (e) {
        debugPrint('YouTube fallback search error for "$query": $e');
      }
    }
    return null;
  }

  /// Picks the best audio-only stream: prefers MP4/AAC for ExoPlayer compatibility,
  /// falls back to highest-bitrate regardless of container.
  static AudioOnlyStreamInfo _pickBestAudioStream(
      List<AudioOnlyStreamInfo> streams) {
    final mp4Streams =
        streams.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
    return mp4Streams.isNotEmpty
        ? mp4Streams.withHighestBitrate()
        : streams.withHighestBitrate();
  }

  // ---------------------------------------------------------------------------
  // Download helpers (used by DownloadService / FavoritesRepository)
  // ---------------------------------------------------------------------------

  /// Downloads full song audio to a local target file.
  /// Works with both YouTube audio streams and direct HTTP audio URLs.
  static Future<Duration> downloadAudioStreamToFile(
    Song song,
    File targetFile, {
    void Function(double progress)? onProgress,
  }) async {
    final info = await resolveAudio(song);
    final duration = info.duration ?? song.duration;

    VideoId? videoId = info.videoId;
    if (videoId == null && song.id.startsWith('yt_')) {
      try {
        videoId = VideoId(song.id.substring(3));
      } catch (_) {}
    }

    // 1. Direct HTTP stream download (Apple CDN / Deezer / Internet Archive) – ultra fast & reliable
    final directUrl = info.url.isNotEmpty ? info.url : song.audioUrl;
    if (directUrl.isNotEmpty &&
        (directUrl.startsWith('http://') || directUrl.startsWith('https://'))) {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(directUrl));
        final response = await client.send(request).timeout(const Duration(seconds: 20));
        final total = response.contentLength ?? 0;
        var received = 0;
        final sink = targetFile.openWrite();

        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0 && onProgress != null) {
            onProgress((received / total).clamp(0.0, 1.0));
          }
        }
        await sink.flush();
        await sink.close();
        debugPrint('✅ Downloaded "${song.title}" via direct HTTP stream');
        return duration;
      } catch (e) {
        debugPrint('Direct HTTP download error: $e');
        if (targetFile.existsSync()) {
          try {
            targetFile.deleteSync();
          } catch (_) {}
        }
      } finally {
        client.close();
      }
    }

    // 2. YouTube video stream download fallback
    if (videoId != null) {
      try {
        final manifest = await yt.videos.streamsClient
            .getManifest(videoId, requireWatchPage: false)
            .timeout(const Duration(seconds: 15));
        final audioOnlyStreams = manifest.audioOnly;
        if (audioOnlyStreams.isNotEmpty) {
          final bestStream = _pickBestAudioStream(audioOnlyStreams);
          final stream = yt.videos.streamsClient.get(bestStream);
          final sink = targetFile.openWrite();
          var received = 0;
          final total = bestStream.size.totalBytes;

          await for (final chunk in stream) {
            sink.add(chunk);
            received += chunk.length;
            if (total > 0 && onProgress != null) {
              onProgress((received / total).clamp(0.0, 1.0));
            }
          }
          await sink.flush();
          await sink.close();
          debugPrint('✅ Downloaded "${song.title}" via YouTube streamsClient');
          return duration;
        }
      } catch (e) {
        debugPrint('YouTube streamsClient download error for ${videoId.value}: $e');
        // If file was partially written, delete it
        if (targetFile.existsSync()) {
          try {
            targetFile.deleteSync();
          } catch (_) {}
        }
      }
    }

    throw Exception('تعذر تحميل الأغنية "${song.title}". يرجى التحقق من اتصال الإنترنت.');
  }
}
