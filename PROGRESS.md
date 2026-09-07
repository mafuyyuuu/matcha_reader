# 🍵 Matcha Reader - The Ultimate Roadmap

This document tracks all implemented features, technical debt, and the step-by-step roadmap for refactoring and completing the Matcha Reader Flutter application.

**Current Phase: Project Complete 🎉**

---

## ✅ Core Features Inventory (Implemented)

### Manga Reader Core
| Feature | Status | Notes |
|---------|--------|-------|
| Vertical Webtoon reading mode | ✅ Done | Default list view |
| Horizontal LTR/RTL modes | ✅ Done | PageView |
| Auto-load next chapter | ✅ Done | Triggers at 1500px from bottom (vertical) or 2 pages from end (horizontal) |
| Pre-fetching | ✅ Done | `cached_network_image` integration, caches next 3 pages into memory automatically |
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
| Gemini Flash integration | ✅ Done | Chat session with context memory |
| Conversational chat UI | ✅ Done | Styled bubbles with AI avatar |
| Regex title extraction | ✅ Done | Parses `**Title**` from AI responses |
| Smart Link action chips | ✅ Done | Clickable chips → instant MangaDex search |
| API key injection via `--dart-define` | ✅ Done | Compile-time security |

### Library & Sync
| Feature | Status | Notes |
|---------|--------|-------|
| Favorites (add/remove) | ✅ Done | Heart FAB on detail view, persisted in secure storage |
| Favorites grid display | ✅ Done | 2-column grid with cover art |
| Pull-to-refresh Sync | ✅ Done | Pings sources for new chapters and updates unread badge |
| Auto-update on launch | ✅ Done | Toggleable in Settings |
| Reading history (auto-tracked) | ✅ Done | Logs every opened manga, capped at 50 entries |
| "Recently Viewed" strip | ✅ Done | Chronological in Library tab |
| Universal Continue Reading | ✅ Done | Persists manga ID, title, chapter number, and extension source |

### Search
| Feature | Status | Notes |
|---------|--------|-------|
| Concurrent Global Search | ✅ Done | Queries MangaDex + all extensions simultaneously using `Future.wait` |
| Grouped Results UI | ✅ Done | Search results split into rows based on their extension source |
| Recent searches (persisted) | ✅ Done | Saved to secure storage, capped at 10 |

### BYOR Extension System
| Feature | Status | Notes |
|---------|--------|-------|
| Central Extension Store | ✅ Done | Fetches `index.json` from global GitHub repository |
| 1-Tap Install/Uninstall | ✅ Done | Adds extensions from the Store UI to `extensionsProvider` |
| JavaScript headless execution | ✅ Done | `flutter_inappwebview` with CORS bypass via `nativeFetch` handler |
| Custom Router | ✅ Done | `MangaDetailsView` routes data fetching to the exact extension the manga belongs to |

### Cache & Settings
| Feature | Status | Notes |
|---------|--------|-------|
| Cache size calculator | ✅ Done | Scans temp directory recursively |
| Clear cache (files + RAM) | ✅ Done | Nuclear wipe without destroying user data |
| Data Wipe | ✅ Done | Erases all History, Bookmarks, Downloads, and Extensions |

---

## 🏗️ Phase E — The Tachimanga Ecosystem (COMPLETE)
| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| 1. Extension Repository Hosted | ✅ Done | HIGH | Created `matcha_extensions` local repo with `index.json`, Asura, Aqua, Manganato |
| 2. Extension Store UI | ✅ Done | HIGH | Transformed `SourcesView` into an app store for repos |
| 3. Concurrent Global Search | ✅ Done | HIGH | `SearchResultsView` fires `Future.wait` across all sources |
| 4. Library Sync & Auto-Updates | ✅ Done | HIGH | Pull-to-refresh adds unread `+X` badges. Added toggle in Settings |
| 5. Reader Pre-fetching | ✅ Done | HIGH | `cached_network_image` loads next 3 pages into memory automatically |

---

*Last reviewed: September 8, 2026*
