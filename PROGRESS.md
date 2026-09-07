# 🍵 Matcha Reader - The Ultimate Roadmap

This document tracks all implemented features, technical debt, and the step-by-step roadmap for refactoring and completing the Matcha Reader Flutter application.

**Current Phase: Project Complete 🎉**

---

## ✅ Core Features Inventory (Implemented)

### Manga Reader Core
| Feature | Status | Notes |
|---------|--------|-------|
| Vertical Webtoon reading mode | ✅ Done | Default list view |
| Horizontal Left-to-Right (LTR) mode | ✅ Done | PageView |
| Horizontal Right-to-Left (RTL) mode | ✅ Done | PageView with reverse |
| Auto-load next chapter | ✅ Done | Triggers at 1500px from bottom (vertical) or 2 pages from end (horizontal) |
| Chapter dividers | ✅ Done | Visual "Chapter X" separator between chapters |
| Show/hide UI on tap | ✅ Done | Toggles AppBar visibility |

### Offline Downloads
| Feature | Status | Notes |
|---------|--------|-------|
| Download chapters byte-by-byte | ✅ Done | Saves to `getApplicationDocumentsDirectory()/downloads/` |
| Offline interceptor (local-first reads) | ✅ Done | Checks disk before network for every chapter load |
| Download status indicator per chapter | ✅ Done | Shows ✓ icon for downloaded chapters in detail view |
| Duplicate download prevention | ✅ Done | Skips if chapter folder already has files |

### AI Discover Engine
| Feature | Status | Notes |
|---------|--------|-------|
| Gemini 2.5 Flash integration | ✅ Done | Chat session with context memory |
| Conversational chat UI | ✅ Done | Styled bubbles with AI avatar |
| Regex title extraction | ✅ Done | Parses `**Title**` from AI responses |
| Smart Link action chips | ✅ Done | Clickable chips → instant MangaDex search |
| Quick prompt buttons | ✅ Done | 3 pre-built genre prompts |
| API key injection via `--dart-define` | ✅ Done | Compile-time security |

### Library & Persistence
| Feature | Status | Notes |
|---------|--------|-------|
| Favorites (add/remove) | ✅ Done | Heart FAB on detail view, persisted in secure storage |
| Favorites grid display | ✅ Done | 2-column grid with cover art |
| Reading history (auto-tracked) | ✅ Done | Logs every opened manga, capped at 50 entries |
| "Recently Viewed" horizontal strip | ✅ Done | Chronological in Library tab |
| Continue Reading bookmark | ✅ Done | Persists manga ID, title, chapter number, and source |
| Scroll/page position persistence | ✅ Done | Saves exact pixel offset (vertical) or page index (horizontal) |

### Search
| Feature | Status | Notes |
|---------|--------|-------|
| MangaDex full-text search | ✅ Done | API query with cover art includes |
| Recent searches (persisted) | ✅ Done | Saved to secure storage, capped at 10 |
| Recent searches dropdown with filter | ✅ Done | Filters as user types |
| Infinite scroll pagination | ✅ Done | Loads 15 results at a time with `_offset` |

### BYOR Extension System
| Feature | Status | Notes |
|---------|--------|-------|
| Add/remove repository URLs | ✅ Done | Validated, saved to secure storage |
| JSON Declarative extensions | ✅ Done | Parses `selectors` config to scrape HTML |
| JavaScript headless extensions | ✅ Done | `flutter_inappwebview` with CORS bypass via `nativeFetch` handler |
| Extension validation on install | ✅ Done | Fetches URL, checks JS `getExtensionInfo()` or JSON structure |
| Universal hybrid search | ✅ Done | Merges MangaDex + all extension results |

### Cache & Settings
| Feature | Status | Notes |
|---------|--------|-------|
| Cache size calculator | ✅ Done | Scans temp directory recursively |
| Clear cache (files + RAM) | ✅ Done | Nuclear wipe without destroying user data |
| About section (version, developer) | ✅ Done | Static display |

### UI & Polish
| Feature | Status | Notes |
|---------|--------|-------|
| Hero animations (cover art transitions) | ✅ Done | On MangaCard → MangaDetailsView |
| Haptic feedback on interactions | ✅ Done | Light, medium, heavy impacts contextually |
| Custom matcha green color theme | ✅ Done | Consistent `Color(0xFF7EA185)` palette via `AppColors` |
| SliverAppBar with cover art | ✅ Done | Parallax scroll on detail view |

---

## 🏗️ Phase A — Structural Foundation (COMPLETE)
| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Split `main.dart` into files | ✅ Done | CRITICAL | Split 2.5k lines into 22 modular files |
| Data Models | ✅ Done | HIGH | `Manga` and `Chapter` models with JSON serialization |
| `StorageService` Abstraction | ✅ Done | HIGH | Wraps `FlutterSecureStorage` |
| Theme & API Constants | ✅ Done | HIGH | Centralized `AppColors`, `AppTheme`, and `ApiConstants` |
| Dynamic Greeting | ✅ Done | LOW | Time-aware "Good Morning/Afternoon/Evening" |
| Remove Dead Code | ✅ Done | LOW | Deleted unused `ProfileView` |

---

## ⚡ Phase B — The Reactive Foundation (COMPLETE)
| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Add `flutter_riverpod` | ✅ Done | HIGH | Core state management library |
| Extract `MangaDexService` | ✅ Done | HIGH | Move all `http` calls out of UI |
| Extract `DownloadService` | ✅ Done | HIGH | Isolate file system and offline interceptor logic |
| Extract `GeminiService` | ✅ Done | MEDIUM | Move chat session state out of `DiscoverView` |
| Global Providers (History/Favs) | ✅ Done | HIGH | Reactive library updates without `.then(() => _loadData())` |

---

## 🔌 Phase C — The Universal Engine (COMPLETE)
| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Isolate JS Bridge (`ExtensionService`) | ✅ Done | HIGH | Move headless webview out of `SearchResultsView` |
| Universal Data Router | ✅ Done | CRITICAL | Dynamic routing for `MangaDetailsView` based on source |
| Universal Chapter Fetching | ✅ Done | CRITICAL | `MangaReaderView` can load from extensions, not just MangaDex |
| Universal Library Tagging | ✅ Done | HIGH | Extensions exist safely in Favorites/History side-by-side |

---

## 🎨 Phase D — Production Polish (COMPLETE)
| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Upgrade deprecated syntax | ✅ Done | HIGH | Updated `.withOpacity` to `.withValues` |
| Remove unused code | ✅ Done | HIGH | Removed all unused imports and variables generated during refactor |
| 100% Clean Analyze | ✅ Done | CRITICAL | `flutter analyze` returns zero issues |

---

## 📊 Codebase Statistics

| Metric | Value |
|--------|-------|
| Total Dart files | 27 |
| Data model classes | 2 (`Manga`, `Chapter`) |
| Services | 4 (`StorageService`, `MangaDexService`, `ExtensionService`, `DownloadService`, `GeminiService`) |
| State management solution | Riverpod 2.6.1 |
| Test coverage | 0% (Next step for future) |
| Dependencies | 8 (http, flutter_riverpod, google_generative_ai, flutter_secure_storage, path_provider, flutter_inappwebview, html, url_launcher) |

---

*Last reviewed: September 8, 2026*
