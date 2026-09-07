import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/mangadex_service.dart';
import '../services/download_service.dart';
import '../services/extension_service.dart';
import '../services/gemini_service.dart';

// --- Services ---
final mangaDexServiceProvider = Provider((ref) => MangaDexService());
final downloadServiceProvider = Provider((ref) => DownloadService());
final extensionServiceProvider = Provider((ref) => ExtensionService());
final geminiServiceProvider = Provider((ref) => GeminiService());

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
      state = [...state, {'id': id, 'title': title, 'imageUrl': imageUrl, 'source': source}];
    }
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
    await StorageService.saveBookmark(mangaId, title, chapter, source: source); // We will update saveBookmark as well
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
    if (!state.any((r) => r['url'] == repo['url'])) {
      state = [...state, repo];
      await StorageService.saveRepos(state);
    }
  }

  Future<void> removeRepo(String url) async {
    state = state.where((r) => r['url'] != url).toList();
    await StorageService.saveRepos(state);
  }
}
