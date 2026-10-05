import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final instances = [
    'https://inv.nadeko.net',
    'https://invidious.nerdvpn.de',
    'https://invidious.jing.rocks',
    'https://vid.puffyan.us',
    'https://yewtu.be',
  ];

  for (final inst in instances) {
    try {
      print('Testing $inst...');
      final uri = Uri.parse('$inst/api/v1/videos/KZYqugtbcG0');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      print('$inst status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final streams = data['adaptiveFormats'] as List? ?? [];
        for (final s in streams) {
          if (s['type']?.toString().contains('audio') == true) {
            print('Found audio format: ${s['container']} - ${s['bitrate']}');
            final audioUrl = s['url'] as String?;
            if (audioUrl != null) {
              print('Stream URL: $audioUrl');
              // Test if audio URL actually plays (HEAD or GET first 100 bytes)
              final testRes = await http.get(Uri.parse(audioUrl), headers: {'Range': 'bytes=0-1024'}).timeout(const Duration(seconds: 3));
              print('Audio stream test status: ${testRes.statusCode} (${testRes.bodyBytes.length} bytes)');
              if (testRes.statusCode == 200 || testRes.statusCode == 206) {
                print('SUCCESS! Fully playable audio stream from $inst');
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Failed $inst: $e');
    }
  }
}
