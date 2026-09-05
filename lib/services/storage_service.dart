import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // --- Raw access (for backward compatibility) ---
  static Future<String?> read(String key) => _storage.read(key: key);
  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  static Future<void> delete(String key) => _storage.delete(key: key);
  static Future<void> deleteAll() => _storage.deleteAll();

  // --- Storage Keys ---
  static const String keyLastReadMangaId = 'last_read_manga_id';
  static const String keyLastReadMangaTitle = 'last_read_manga_title';
  static const String keyLastReadChapter = 'last_read_chapter';
  static const String keyMyFavorites = 'my_favorites';
  static const String keyReadingHistory = 'reading_history';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyUserRepos = 'user_repos';
  static String scrollPositionKey(String mangaId) => 'scroll_position_$mangaId';

  // --- Typed helpers ---
  static Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final String? json = await _storage.read(key: key);
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> writeJsonList(String key, List<dynamic> list) async {
    await _storage.write(key: key, value: jsonEncode(list));
  }

  // --- Bookmark ---
  static Future<Map<String, String?>> loadBookmark() async {
    return {
      'id': await _storage.read(key: keyLastReadMangaId),
      'title': await _storage.read(key: keyLastReadMangaTitle),
      'chapter': await _storage.read(key: keyLastReadChapter),
    };
  }

  static Future<void> saveBookmark(
      String mangaId, String title, String chapter) async {
    await _storage.write(key: keyLastReadMangaId, value: mangaId);
    await _storage.write(key: keyLastReadMangaTitle, value: title);
    await _storage.write(key: keyLastReadChapter, value: chapter);
  }

  // --- Favorites ---
  static Future<List<Map<String, dynamic>>> loadFavorites() async {
    return readJsonList(keyMyFavorites);
  }

  static Future<void> saveFavorites(List<dynamic> favorites) async {
    await writeJsonList(keyMyFavorites, favorites);
  }

  // --- History ---
  static Future<List<Map<String, dynamic>>> loadHistory() async {
    return readJsonList(keyReadingHistory);
  }

  static Future<void> saveHistory(List<dynamic> history) async {
    await writeJsonList(keyReadingHistory, history);
  }

  // --- Recent Searches ---
  static Future<List<String>> loadRecentSearches() async {
    final String? json = await _storage.read(key: keyRecentSearches);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json));
  }

  static Future<void> saveRecentSearches(List<String> searches) async {
    await _storage.write(key: keyRecentSearches, value: jsonEncode(searches));
  }

  // --- Repos ---
  static Future<List<Map<String, dynamic>>> loadRepos() async {
    return readJsonList(keyUserRepos);
  }

  static Future<void> saveRepos(List<dynamic> repos) async {
    await writeJsonList(keyUserRepos, repos);
  }
}
