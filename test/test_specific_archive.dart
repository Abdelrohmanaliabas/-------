import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final queries = [
    'الوتر الحساس شيرين',
    'كلام عينيه شيرين',
    'حبه جنة شيرين',
    'مشاعر شيرين',
    'تملي معاك عمرو دياب',
    'البخت ويجز',
    'وسع وسع احمد سعد',
  ];

  for (final q in queries) {
    try {
      final qEnc = Uri.encodeComponent('"$q" OR ($q) AND mediatype:audio');
      final uri = Uri.parse('https://archive.org/advancedsearch.php?q=$qEnc&fl[]=identifier,title,creator,length&rows=3&output=json');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final docs = data['response']['docs'] as List;
        print('Search "$q": found ${docs.length} items');
        for (final d in docs) {
          final id = d['identifier'];
          print('  -> ${d['title']} | https://archive.org/download/$id/$id.mp3');
        }
      }
    } catch (e) {
      print('Err $q: $e');
    }
  }
}
