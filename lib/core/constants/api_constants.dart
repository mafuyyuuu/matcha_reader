class ApiConstants {
  ApiConstants._();

  static const String mangaDexBase = 'https://api.mangadex.org';
  static const String mangaDexCovers = 'https://uploads.mangadex.org/covers';

  static String trendingManga({int limit = 5}) =>
      '$mangaDexBase/manga?limit=$limit&includes[]=cover_art&order[followedCount]=desc&availableTranslatedLanguage[]=en';

  static String searchManga(String query, {int limit = 15, int offset = 0}) =>
      '$mangaDexBase/manga?title=$query&includes[]=cover_art&order[relevance]=desc&limit=$limit&offset=$offset';

  static String mangaDetails(String mangaId) =>
      '$mangaDexBase/manga/$mangaId?includes[]=author';

  static String mangaFeed(String mangaId) =>
      '$mangaDexBase/manga/$mangaId/feed?translatedLanguage[]=en&order[chapter]=asc&limit=100';

  static String atHomeServer(String chapterId) =>
      '$mangaDexBase/at-home/server/$chapterId';

  static String coverUrl(String mangaId, String fileName) =>
      '$mangaDexCovers/$mangaId/$fileName';

  static const String fallbackImageUrl =
      'https://images.unsplash.com/photo-1618331835717-801e976710b2';
}
