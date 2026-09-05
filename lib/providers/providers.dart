import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';

import '../services/gemini_service.dart';

import '../services/mangadex_service.dart';

// --- Services ---
final mangaDexServiceProvider = Provider((ref) => MangaDexService());

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

  Future<void> toggleFavorite(String id, String title, String imageUrl) async {
    final exists = state.any((fav) => fav['id'] == id);
    if (exists) {
      state = state.where((fav) => fav['id'] != id).toList();
    } else {
      state = [...state, {'id': id, 'title': title, 'imageUrl': imageUrl}];
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

  Future<void> addToHistory(String id, String title, String imageUrl) async {
    var newState = state.where((item) => item['id'] != id).toList();
    newState.insert(0, {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
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
  BookmarkNotifier() : super({'id': null, 'title': null, 'chapter': null}) {
    _load();
  }

  Future<void> _load() async {
    state = await StorageService.loadBookmark();
  }

  Future<void> saveBookmark(String mangaId, String title, String chapter) async {
    state = {'id': mangaId, 'title': title, 'chapter': chapter};
    await StorageService.saveBookmark(mangaId, title, chapter);
  }
}

final geminiServiceProvider = Provider((ref) => GeminiService());
final downloadServiceProvider = Provider((ref) => DownloadService());
