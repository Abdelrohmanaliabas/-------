class Album {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final String artworkUrl;
  final String? releaseYear;
  final int songsCount;
  final String? genre;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    required this.artworkUrl,
    this.releaseYear,
    this.songsCount = 0,
    this.genre,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'artworkUrl': artworkUrl,
      'releaseYear': releaseYear,
      'songsCount': songsCount,
      'genre': genre,
    };
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      artistId: json['artistId'] as String?,
      artworkUrl: json['artworkUrl'] as String,
      releaseYear: json['releaseYear'] as String?,
      songsCount: json['songsCount'] as int? ?? 0,
      genre: json['genre'] as String?,
    );
  }
}
