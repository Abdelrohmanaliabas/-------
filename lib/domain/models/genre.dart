class Genre {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final String artworkUrl;

  const Genre({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.artworkUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorHex': colorHex,
      'artworkUrl': artworkUrl,
    };
  }

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorHex: json['colorHex'] as String,
      artworkUrl: json['artworkUrl'] as String,
    );
  }
}
