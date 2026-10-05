import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final queries = ['شيرين', 'عمرو دياب', 'تامر حسني', 'أحمد سعد', 'ويجز'];
  for (final q in queries) {
    try {
      final qEnc = Uri.encodeComponent('($q) AND mediatype:audio');
      final uri = Uri.parse('https://archive.org/advancedsearch.php?q=$qEnc&fl[]=identifier,title,creator,length&rows=5&output=json');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final docs = data['response']['docs'] as List;
        print('Query "$q" returned ${docs.length} archive tracks:');
        for (final doc in docs) {
          final id = doc['identifier'];
          final title = doc['title'];
          print('  - $title | https://archive.org/download/$id/$id.mp3');
        }
      }
    } catch (e) {
      print('Error on $q: $e');
    }
  }
}
