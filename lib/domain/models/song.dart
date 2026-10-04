class Song {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final String album;
  final String? albumId;
  final String artworkUrl;
  final String audioUrl;
  final Duration duration;
  final String genre;
  final bool isFavorite;
  final bool isDownloadable;
  final bool isDownloaded;
  final String? localFilePath;
  final int playsCount;
  final String? releaseYear;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    required this.album,
    this.albumId,
    required this.artworkUrl,
    required this.audioUrl,
    required this.duration,
    required this.genre,
    this.isFavorite = false,
    this.isDownloadable = true,
    this.isDownloaded = false,
    this.localFilePath,
    this.playsCount = 0,
    this.releaseYear,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    String? artworkUrl,
    String? audioUrl,
    Duration? duration,
    String? genre,
    bool? isFavorite,
    bool? isDownloadable,
    bool? isDownloaded,
    String? localFilePath,
    int? playsCount,
    String? releaseYear,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloadable: isDownloadable ?? this.isDownloadable,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
      playsCount: playsCount ?? this.playsCount,
      releaseYear: releaseYear ?? this.releaseYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'album': album,
      'albumId': albumId,
      'artworkUrl': artworkUrl,
      'audioUrl': audioUrl,
      'durationMs': duration.inMilliseconds,
      'genre': genre,
      'isFavorite': isFavorite,
      'isDownloadable': isDownloadable,
      'isDownloaded': isDownloaded,
      'localFilePath': localFilePath,
      'playsCount': playsCount,
      'releaseYear': releaseYear,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      artistId: json['artistId'] as String?,
      album: json['album'] as String? ?? '',
      albumId: json['albumId'] as String?,
      artworkUrl: json['artworkUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      genre: json['genre'] as String? ?? 'عام',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDownloadable: json['isDownloadable'] as bool? ?? true,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localFilePath: json['localFilePath'] as String?,
      playsCount: json['playsCount'] as int? ?? 0,
      releaseYear: json['releaseYear'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
