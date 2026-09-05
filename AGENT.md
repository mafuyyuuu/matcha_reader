# 🤖 AGENT.md — Matcha Reader AI Development Guide

> This document provides context for any AI coding assistant (Gemini, Copilot, Claude, etc.)
> working on the Matcha Reader codebase. Read this before making changes.

---

## 📌 Project Identity

| Field | Value |
|-------|-------|
| **App Name** | Matcha Reader |
| **Developer** | Jhervin Jimenez |
| **Framework** | Flutter (Dart) |
| **Min SDK** | Dart ^3.11.5 |
| **Target Platforms** | Android, iOS (primary), Web/Desktop (secondary) |
| **Architecture** | Currently monolithic — all code in `lib/main.dart` (~2,551 lines) |
| **State Management** | None (raw `setState` only) |
| **Database** | `FlutterSecureStorage` (encrypted key-value store) |
| **APIs** | MangaDex REST API, Google Gemini 2.5 Flash |

---

## 📂 Current File Structure

```
matcha_reader/
├── lib/
│   └── main.dart              ← ENTIRE APP (2,551 lines, 15 classes)
├── Matcha_Reader_Context.md   ← Original project vision & roadmap
├── README.md                  ← Setup guide & feature overview
├── PROGRESS.md                ← Feature completion tracker & known issues
├── AGENT.md                   ← THIS FILE — AI assistant context
├── pubspec.yaml               ← Dependencies & Flutter config
├── analysis_options.yaml      ← Lint rules
├── android/                   ← Android platform code
├── ios/                       ← iOS platform code
└── test/                      ← Empty (no tests exist)
```

---

## 🧱 Class Map (What's Inside `main.dart`)

```
main()
└── MatchaReader (MaterialApp)
    └── HomeScreen (BottomNavigationBar shell)
        ├── Tab 0: HomeView
        │   ├── MangaCard (reusable)
        │   └── AICuratedCard (static/hardcoded)
        ├── Tab 1: DiscoverView
        │   └── ChatBubble (reusable)
        ├── Tab 2: LibraryView
        ├── Tab 3: SourcesView
        └── Tab 4: SettingsView

Push-navigated screens:
├── MangaDetailsView → MangaReaderView
└── SearchResultsView

Data model:
└── Manga (id, title, imageUrl, source)

Dead code:
└── ProfileView (defined but never used)
```

---

## 🔑 Key Architecture Decisions (Current)

### 1. BYOR (Bring Your Own Repository)
The app intentionally ships as a "blank slate" with only MangaDex as a default source.
Users paste extension URLs that are either:
- **JSON declarative** — config with CSS selectors for HTML scraping
- **JavaScript** — executed in a headless `InAppWebView` with a CORS bypass via `nativeFetch` handler

**Important:** The JS bridge overrides `window.fetch` to route through Dart's `http` package, bypassing browser CORS restrictions.

### 2. Offline-First Reading
The reader checks local storage before making network requests:
```
1. Check getApplicationDocumentsDirectory()/downloads/{mangaId}/{chapterId}/
2. If files exist → load from disk (offline mode)
3. If not → fetch from MangaDex at-home API → render from network
```

### 3. Secure Storage as Database
All persistent data is stored as JSON strings in `FlutterSecureStorage`:
| Key | Content |
|-----|---------|
| `last_read_manga_id` | String — manga ID of last read |
| `last_read_manga_title` | String — title of last read |
| `last_read_chapter` | String — chapter number of last read |
| `scroll_position_{mangaId}` | String — pixel offset or page index |
| `my_favorites` | JSON array of `{id, title, imageUrl}` maps |
| `reading_history` | JSON array of `{id, title, imageUrl, timestamp}` maps (max 50) |
| `recent_searches` | JSON array of strings (max 10) |
| `user_repos` | JSON array of `{url, name, type}` maps |

### 4. API Key Security
The Gemini API key is injected at compile time:
```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```
Accessed via `String.fromEnvironment('GEMINI_API_KEY')`.

---

## 🎨 Design System (Informal)

The app uses a consistent matcha-green palette but without centralized theme constants:

| Color | Hex | Usage |
|-------|-----|-------|
| Matcha Green (primary) | `#7EA185` | Buttons, accents, icons, progress bars |
| Dark Forest | `#2C362F` | Headings, primary text |
| Sage Text | `#4A5750` | Body text, descriptions |
| Muted Sage | `#8B998E` | Subtitles, hints, inactive icons |
| Soft Mint BG | `#E1EBE3` | Card backgrounds, input fields |
| Paper White | `#FAFCFA` | Scaffold background |

---

## ⚠️ Critical Context for AI Assistants

### Things NOT to break:
1. **The offline interceptor** — The order of `check local → fetch network` in `_fetchInitialChapter()` and `_loadNextChapter()` is critical. Downloaded chapters MUST be served from disk.
2. **The CORS bypass handler** — The `nativeFetch` JavaScript handler in `SearchResultsView._searchExtension()` and `SourcesView._addRepo()` enables extensions to make cross-origin requests. Do not remove it.
3. **The scroll position save/restore flow** — `_hasRestoredPosition` flag prevents saving stale positions during initial load. The `_handleSafeJump()` method clamps saved positions to avoid jumping past `maxScrollExtent`.
4. **Secure storage key names** — Other parts of the app read these keys. Changing key names will orphan persisted data.

### Things that ARE safe to refactor:
1. Breaking `main.dart` into multiple files — nothing depends on it being monolithic
2. Extracting API calls into service classes
3. Moving hardcoded colors into a theme file
4. Replacing `setState` with Provider/Riverpod/BLoC
5. Replacing `FlutterSecureStorage` JSON blobs with Isar/Hive/SQLite
6. Removing the dead `ProfileView` class
7. Making `AICuratedCard` dynamic instead of hardcoded

### Patterns to follow when adding code:
- Use haptic feedback (`HapticFeedback.lightImpact()`) on interactive elements
- Use the matcha green color `Color(0xFF7EA185)` for accents
- Use Hero animations with tag `'cover_$mangaId'` for cover art transitions
- Show `SnackBar` for user-facing success/error feedback
- Use `mounted` checks before `setState` in async callbacks

---

## 🚀 Recommended Refactor Path (Priority Order)

### Phase A: Structural Foundation
1. **Split `main.dart`** into proper folder hierarchy:
   ```
   lib/
   ├── main.dart
   ├── app.dart                    ← MaterialApp + theme
   ├── core/
   │   ├── theme/
   │   │   ├── app_colors.dart     ← Centralized color constants
   │   │   └── app_theme.dart      ← ThemeData configuration
   │   ├── constants/
   │   │   └── api_constants.dart   ← MangaDex base URLs, endpoints
   │   └── utils/
   │       └── date_formatter.dart
   ├── models/
   │   ├── manga.dart              ← Manga model (with fromJson/toJson)
   │   ├── chapter.dart            ← Chapter model
   │   └── extension_repo.dart     ← Repository model
   ├── services/
   │   ├── mangadex_service.dart   ← All MangaDex API calls
   │   ├── storage_service.dart    ← FlutterSecureStorage abstraction
   │   ├── download_service.dart   ← Chapter download logic
   │   ├── gemini_service.dart     ← AI chat session management
   │   └── extension_service.dart  ← JS/JSON extension bridge
   ├── screens/
   │   ├── home/
   │   │   ├── home_view.dart
   │   │   └── widgets/
   │   │       ├── manga_card.dart
   │   │       └── ai_curated_card.dart
   │   ├── discover/
   │   │   ├── discover_view.dart
   │   │   └── widgets/
   │   │       └── chat_bubble.dart
   │   ├── library/
   │   │   └── library_view.dart
   │   ├── sources/
   │   │   └── sources_view.dart
   │   ├── settings/
   │   │   └── settings_view.dart
   │   ├── details/
   │   │   └── manga_details_view.dart
   │   ├── reader/
   │   │   └── manga_reader_view.dart
   │   └── search/
   │       └── search_results_view.dart
   └── navigation/
       └── home_screen.dart        ← Bottom nav shell
   ```

### Phase B: Data Layer
2. Create proper **data models** with `fromJson()` / `toJson()` serialization
3. Wrap `FlutterSecureStorage` in a **`StorageService`** abstraction
4. Extract all `http.get()` calls into **`MangaDexService`**

### Phase C: State Management
5. Adopt **Riverpod** or **Provider** for reactive state
6. Eliminate `.then((_) => _loadData())` refresh patterns
7. Create shared state for favorites, history, bookmarks

### Phase D: Quality
8. Add **unit tests** for services and models
9. Add **widget tests** for key screens
10. Implement proper **error handling** (custom exceptions, user-facing error states)

---

## 🔌 External Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.6.0 | HTTP client for API calls |
| `google_generative_ai` | ^0.4.7 | Gemini AI chat integration |
| `flutter_secure_storage` | ^9.2.4 | Encrypted local key-value store |
| `path_provider` | ^2.1.5 | Device directory access for downloads |
| `flutter_inappwebview` | ^6.1.5 | Headless browser for JS extension execution |
| `html` | ^0.15.6 | HTML DOM parsing for JSON-type extensions |
| `url_launcher` | ^6.3.2 | Opening external URLs |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

---

## 🌐 API Endpoints Used

### MangaDex (No auth required)
| Endpoint | Used In |
|----------|---------|
| `GET /manga?limit=5&includes[]=cover_art&order[followedCount]=desc` | `HomeScreen.fetchTrendingManga()` |
| `GET /manga?title={query}&includes[]=cover_art&order[relevance]=desc` | `SearchResultsView._performSearch()` |
| `GET /manga/{id}?includes[]=author` | `MangaDetailsView._fetchDetails()` |
| `GET /manga/{id}/feed?translatedLanguage[]=en&order[chapter]=asc` | `MangaDetailsView._fetchDetails()` |
| `GET /at-home/server/{chapterId}` | `MangaReaderView`, `MangaDetailsView._downloadChapter()` |

### Google Gemini
| Model | Used In |
|-------|---------|
| `gemini-2.5-flash` | `DiscoverView` — chat-based recommendations |

---

*This document should be updated whenever significant architectural changes are made.*
