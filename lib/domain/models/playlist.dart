import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String artworkUrl;
  final List<Song> songs;
  final bool isCustom;
  final DateTime? createdAt;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.artworkUrl,
    this.songs = const [],
    this.isCustom = true,
    this.createdAt,
  });

  int get songsCount => songs.length;

  Duration get totalDuration => songs.fold(
        Duration.zero,
        (prev, s) => prev + s.duration,
      );

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUrl,
    List<Song>? songs,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      songs: songs ?? this.songs,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'artworkUrl': artworkUrl,
      'songs': songs.map((s) => s.toJson()).toList(),
      'isCustom': isCustom,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      artworkUrl: json['artworkUrl'] as String? ?? '',
      songs: (json['songs'] as List<dynamic>?)
              ?.map((item) => Song.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      isCustom: json['isCustom'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
