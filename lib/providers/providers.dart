import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/mangadex_service.dart';
import '../services/download_service.dart';
import '../services/extension_service.dart';
import '../services/gemini_service.dart';
export 'settings_provider.dart';

// --- Services ---
final mangaDexServiceProvider = Provider((ref) => MangaDexService());
final downloadServiceProvider = Provider((ref) => DownloadService());
final extensionServiceProvider = Provider((ref) => ExtensionService());
final geminiServiceProvider = Provider((ref) => GeminiService());

// --- Store Provider ---
final extensionStoreProvider = FutureProvider<List<dynamic>>((ref) async {
  // Use a local file URI for now since it's on desktop, or a raw github link if provided
  try {
    final response = await http.get(Uri.parse('https://raw.githubusercontent.com/jhervin/matcha_extensions/main/index.json'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
  } catch (e) {
    // Fallback to local file for testing purposes if network fails
    
    final file = File('/Users/jhervin/Desktop/matcha_extensions/index.json');
    if (await file.exists()) {
       return jsonDecode(await file.readAsString()) as List<dynamic>;
    }
  }
  return [];
});

// --- State Providers ---
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Map<String, dynamic>>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await StorageService.loadFavorites();
  }

  Future<void> toggleFavorite(String id, String title, String imageUrl, {String source = 'MangaDex'}) async {
    final exists = state.any((fav) => fav['id'] == id && fav['source'] == source);
    if (exists) {
      state = state.where((fav) => !(fav['id'] == id && fav['source'] == source)).toList();
    } else {
      state = [...state, {'id': id, 'title': title, 'imageUrl': imageUrl, 'source': source, 'unreadCount': 0}];
    }
    await StorageService.saveFavorites(state);
  }

  Future<void> updateUnreadCount(String id, String source, int count) async {
    state = state.map((fav) {
      if (fav['id'] == id && fav['source'] == source) {
        return {...fav, 'unreadCount': count};
      }
      return fav;
    }).toList();
    await StorageService.saveFavorites(state);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<Map<String, dynamic>>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  HistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await StorageService.loadHistory();
  }

  Future<void> addToHistory(String id, String title, String imageUrl, {String source = 'MangaDex'}) async {
    var newState = state.where((item) => !(item['id'] == id && item['source'] == source)).toList();
    newState.insert(0, {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'source': source,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    if (newState.length > 50) newState = newState.sublist(0, 50);
    state = newState;
    await StorageService.saveHistory(state);
  }
}

final bookmarkProvider = StateNotifierProvider<BookmarkNotifier, Map<String, String?>>((ref) {
  return BookmarkNotifier();
});

class BookmarkNotifier extends StateNotifier<Map<String, String?>> {
  BookmarkNotifier() : super({'id': null, 'title': null, 'chapter': null, 'source': 'MangaDex'}) {
    _load();
  }

  Future<void> _load() async {
    state = await StorageService.loadBookmark();
  }

  Future<void> saveBookmark(String mangaId, String title, String chapter, {String source = 'MangaDex'}) async {
    state = {'id': mangaId, 'title': title, 'chapter': chapter, 'source': source};
    await StorageService.saveBookmark(mangaId, title, chapter, source: source);
  }
}

final extensionsProvider = StateNotifierProvider<ExtensionsNotifier, List<Map<String, dynamic>>>((ref) {
  return ExtensionsNotifier();
});

class ExtensionsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ExtensionsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await StorageService.loadRepos();
  }

  Future<void> addRepo(Map<String, dynamic> repo) async {
    if (!state.any((r) => r['url'] == repo['url'] || r['name'] == repo['name'])) {
      state = [...state, repo];
      await StorageService.saveRepos(state);
    }
  }

  Future<void> removeRepo(String urlOrName) async {
    state = state.where((r) => r['url'] != urlOrName && r['name'] != urlOrName).toList();
    await StorageService.saveRepos(state);
  }
}
