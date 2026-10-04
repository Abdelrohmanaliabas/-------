class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String? bio;
  final String? genre;
  final int followersCount;
  final int monthlyListeners;

  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio,
    this.genre,
    this.followersCount = 0,
    this.monthlyListeners = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'bio': bio,
      'genre': genre,
      'followersCount': followersCount,
      'monthlyListeners': monthlyListeners,
    };
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      bio: json['bio'] as String?,
      genre: json['genre'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      monthlyListeners: json['monthlyListeners'] as int? ?? 0,
    );
  }
}
