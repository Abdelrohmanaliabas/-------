import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final queries = ['الوتر الحساس', 'El Watar El Hassas', 'Sherine El Watar', 'شيرين 2018', 'شيرين نساي'];
  for (final q in queries) {
    final qEnc = Uri.encodeComponent('($q) AND mediatype:audio');
    final uri = Uri.parse('https://archive.org/advancedsearch.php?q=$qEnc&fl[]=identifier,title&rows=5&output=json');
    final res = await http.get(uri).timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final docs = data['response']['docs'] as List;
      print('Q "$q": ${docs.length} results');
      for (final d in docs) {
        print('  - ${d['title']} -> https://archive.org/download/${d['identifier']}/${d['identifier']}.mp3');
      }
    }
  }
}
