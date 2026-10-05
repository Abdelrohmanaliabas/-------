import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://archive.org/download/06.ElWatarElHassas/06.ElWatarElHassas.mp3';
  final res = await http.get(Uri.parse(url), headers: {'Range': 'bytes=0-1000'});
  print('Archive.org El Watar El Hassas status: ${res.statusCode}');
  print('Headers: ${res.headers}');
}
