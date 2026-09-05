class Manga {
  final String id;
  final String title;
  final String imageUrl;
  final String source;

  Manga({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.source = 'MangaDex',
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      source: (json['source'] as String?) ?? 'MangaDex',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'source': source,
  };
}
