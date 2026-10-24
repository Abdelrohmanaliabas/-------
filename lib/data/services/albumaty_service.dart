import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AlbumatyService {
  AlbumatyService._();

  static final Map<String, int> _singerMap = {
    'عمرو دياب': 123,
    'تامر عاشور': 72,
    'حمزة نمرة': 85,
    'حمزه نمره': 85,
    'ويجز': 1068,
    'تامر حسني': 71,
    'تامر حسنى': 71,
    'محمد حماقي': 155,
    'حماقي': 155,
    'شيرين': 121,
    'شيرين عبد الوهاب': 121,
    'أصالة': 8,
    'اصاله': 8,
    'أحمد سعد': 11,
    'احمد سعد': 11,
    'كايروكي': 134,
    'كاريوكي': 134,
    'بهاء سلطان': 69,
    'حسين الجسمي': 82,
    'إليسا': 6,
    'اليسا': 6,
    'نانسي عجرم': 152,
    'روبي': 106,
    'فضل شاكر': 208,
    'ماجد المهندس': 214,
    'عمر خيرت': 193,
    'حسن شاكوش': 247,
    'عمر كمال': 248,
    'كريم محمود عبد العزيز': 1045,
    'محمود العسيلي': 115,
    'رامي صبري': 60,
    'رامي جمال': 61,
    'مصطفى قمر': 50,
    'إيهاب توفيق': 40,
    'حكيم': 80,
    'أحمد شيبة': 20,
    'رضا البحراوي': 920,
    'عصام صاصا': 950,
    'مسلم': 1080,
    'أنغام': 90,
    'آمال ماهر': 95,
    'جورج وسوف': 110,
    'صابر الرباعي': 112,
    'كاظم الساهر': 200,
    'راغب علامة': 202,
    'وائل كفوري': 203,
    'ملحم زين': 204,
    'نوال الزغبي': 220,
    'ميريام فارس': 221,
    'مروان بابلو': 1069,
    'مروان موسى': 1070,
    'أبيوسف': 1071,
    'سيف مجدي': 960,
  };

  static final Map<String, String> _cache = {};

  static String _normalize(String s) {
    return s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static int _matchScore(String queryTitle, String candidateTitle) {
    if (queryTitle == candidateTitle) return 1000;
    if (candidateTitle.contains(queryTitle)) return 500;
    if (queryTitle.contains(candidateTitle)) return 400;

    const stopWords = {
      'ايه', 'من', 'فيلم', 'مسلسل', 'اغنيه', 'اغنية', 'كليب', 'فيديو',
      'نسخه', 'نسخة', 'الاصليه', 'الاصلية', 'الأصلية', 'ريمكس', 'رسمي', 'رسمية',
      'النسخة', 'كاملة', 'موسيقى'
    };
    final qWords = queryTitle
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toList();
    final cWords = candidateTitle
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toSet();

    if (qWords.isEmpty) return 0;
    int score = 0;
    for (final w in qWords) {
      if (cWords.contains(w) || candidateTitle.contains(w)) {
        score += 10;
      }
    }
    return score;
  }

  /// Resolves direct .mp3 stream URL from Albumaty for Arabic tracks
  static Future<String?> resolveSongMp3(String title, String artist) async {
    final normTitle = _normalize(title);
    final normArtist = _normalize(artist);
    final cacheKey = '${normTitle}_$normArtist';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Identify singer ID from known dictionary
    int? singerId;
    for (final entry in _singerMap.entries) {
      final key = _normalize(entry.key);
      if (normArtist.contains(key) || key.contains(normArtist)) {
        singerId = entry.value;
        break;
      }
    }

    try {
      // 2. If singer not in static map, search Albumaty dynamically
      if (singerId == null && normArtist.isNotEmpty) {
        final searchUrl = Uri.parse('https://www.albumaty.com/search.php?q=${Uri.encodeComponent(normArtist)}');
        final searchRes = await http.get(searchUrl, headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        }).timeout(const Duration(seconds: 4));

        if (searchRes.statusCode == 200) {
          final singerMatch = RegExp(r'<li[^>]*><i class="fas fa-microphone"></i>\s*<a href="https://(?:www\.)?albumaty\.com/singer/(\d+)\.html">').firstMatch(searchRes.body) ??
              RegExp(r'href="https://(?:www\.)?albumaty\.com/singer/(\d+)\.html"').firstMatch(searchRes.body);
          if (singerMatch != null) {
            singerId = int.tryParse(singerMatch.group(1)!);
            if (singerId != null) {
              _singerMap[normArtist] = singerId;
            }
          }
        }
      }

      if (singerId == null) {
        // Direct song title search on Albumaty as last resort
        final songSearchUrl = Uri.parse('https://www.albumaty.com/search.php?q=${Uri.encodeComponent(normTitle)}');
        final songSearchRes = await http.get(songSearchUrl, headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        }).timeout(const Duration(seconds: 4));

        if (songSearchRes.statusCode == 200) {
          final songMatch = RegExp(r'<li[^>]*><i class="fas fa-music"></i>\s*<a href="https://(?:www\.)?albumaty\.com/song/(\d+)\.html">').firstMatch(songSearchRes.body) ??
              RegExp(r'href="https://(?:www\.)?albumaty\.com/song/(\d+)\.html"').firstMatch(songSearchRes.body);
          if (songMatch != null) {
            final directMp3 = await _fetchMp3ForSongId(songMatch.group(1)!);
            if (directMp3 != null) {
              _cache[cacheKey] = directMp3;
              return directMp3;
            }
          }
        }
        return null;
      }

      // 3. Fetch singer's songs catalog
      final singerUrl = Uri.parse('https://www.albumaty.com/singer/$singerId.html');
      final res = await http.get(singerUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode != 200) return null;

      // 4. Match song title in HTML
      final songPattern = RegExp(r'href="https://www\.albumaty\.com/song/(\d+)\.html">\s*([^<]+)<');
      final matches = songPattern.allMatches(res.body);

      String? matchedSongId;
      int bestScore = 0;
      for (final m in matches) {
        final songName = _normalize(m.group(2) ?? '');
        final score = _matchScore(normTitle, songName);
        if (score > bestScore && score >= 20) {
          bestScore = score;
          matchedSongId = m.group(1);
          if (score >= 400) break;
        }
      }

      if (matchedSongId == null) return null;

      final directMp3 = await _fetchMp3ForSongId(matchedSongId);
      if (directMp3 != null) {
        _cache[cacheKey] = directMp3;
        debugPrint('🎧 Albumaty MP3 resolved for "$title": $directMp3');
        return directMp3;
      }
    } catch (e) {
      debugPrint('Albumaty resolve error: $e');
    }
    return null;
  }

  static Future<String?> _fetchMp3ForSongId(String songId) async {
    try {
      final songPageUrl = Uri.parse('https://www.albumaty.com/song/$songId.html');
      final songPageRes = await http.get(songPageUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 4));

      if (songPageRes.statusCode != 200) return null;

      final mp3Match = RegExp(r'(https://serv\d+\.albumaty\.com/[^"\s<>]+\.mp3)').firstMatch(songPageRes.body);
      if (mp3Match != null) {
        return mp3Match.group(1)!;
      }
    } catch (_) {}
    return null;
  }
}
