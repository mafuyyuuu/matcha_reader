import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/manga.dart';
import '../models/chapter.dart';

class MangaDexService {
  Future<List<Manga>> fetchTrendingManga() async {
    final url = Uri.parse(ApiConstants.trendingManga());
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Failed to fetch trending manga');

    final data = jsonDecode(response.body);
    return _parseMangaList(data['data']);
  }

  Future<List<Manga>> searchManga(String query, {int limit = 15, int offset = 0}) async {
    final mdUrl = Uri.parse(ApiConstants.searchManga(query, limit: limit, offset: offset));
    final response = await http.get(mdUrl);
    
    if (response.statusCode != 200) throw Exception('Search failed');
    final data = jsonDecode(response.body);
    return _parseMangaList(data['data']);
  }

  Future<Map<String, dynamic>> fetchMangaDetails(String mangaId) async {
    final detailUrl = Uri.parse(ApiConstants.mangaDetails(mangaId));
    final response = await http.get(detailUrl);
    if (response.statusCode != 200) throw Exception('Failed to fetch details');
    
    final detailData = jsonDecode(response.body);
    final attrs = detailData['data']['attributes'];
    
    String authorName = "Unknown Author";
    for (var rel in detailData['data']['relationships']) {
      if (rel['type'] == 'author') {
        authorName = rel['attributes']['name'] ?? "Unknown Author";
        break;
      }
    }

    return {
      'description': attrs['description']['en'] ?? "No description available.",
      'author': authorName,
      'status': (attrs['status'] ?? "Unknown").toString().toUpperCase(),
      'year': (attrs['year'] ?? "N/A").toString(),
    };
  }

  Future<List<Chapter>> fetchMangaChapters(String mangaId) async {
    final chapterUrl = Uri.parse(ApiConstants.mangaFeed(mangaId));
    final response = await http.get(chapterUrl);
    if (response.statusCode != 200) throw Exception('Failed to fetch chapters');
    
    final chapterData = jsonDecode(response.body);
    final List rawChapters = chapterData['data'];
    
    Set<String> uniqueNumSet = {};
    List<Chapter> uniqueList = [];
    
    for (var chap in rawChapters) {
      String? num = chap['attributes']['chapter'];
      String id = chap['id'];
      String? publishDate = chap['attributes']['publishAt'];
      
      String formattedDate = "Unknown Date";
      if (publishDate != null) {
        try {
          final date = DateTime.parse(publishDate);
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          formattedDate = "${months[date.month - 1]} ${date.day}, ${date.year}";
        } catch (e) {
          // keep default
        }
      }

      if (num != null && !uniqueNumSet.contains(num)) {
        uniqueNumSet.add(num);
        uniqueList.add(Chapter(id: id, number: num, date: formattedDate));
      }
    }
    return uniqueList;
  }

  Future<List<String>> fetchChapterPages(String chapterId) async {
    final url = Uri.parse(ApiConstants.atHomeServer(chapterId));
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Failed to fetch chapter pages');
    
    final data = jsonDecode(response.body);
    if (data['chapter'] != null && data['chapter']['data'] != null) {
      final baseUrl = data['baseUrl'];
      final hash = data['chapter']['hash'];
      final List fileNames = data['chapter']['data'];
      
      return fileNames.map((f) => '$baseUrl/data/$hash/$f').toList();
    }
    throw Exception('No images hosted');
  }

  List<Manga> _parseMangaList(List<dynamic> data) {
    List<Manga> tempManga = [];
    for (var item in data) {
      final id = item['id'];
      final titleMap = item['attributes']['title'] as Map<String, dynamic>;
      final title = titleMap['en'] ?? titleMap.values.first;

      String fileName = '';
      for (var rel in item['relationships']) {
        if (rel['type'] == 'cover_art') {
          fileName = rel['attributes']['fileName'] ?? '';
          break;
        }
      }

      tempManga.add(Manga(
        id: id,
        title: title.toString(),
        imageUrl: fileName.isNotEmpty
            ? ApiConstants.coverUrl(id, fileName)
            : ApiConstants.fallbackImageUrl,
        source: 'MangaDex',
      ));
    }
    return tempManga;
  }
}
