# 🍵 Matcha Reader

An enterprise-grade, multi-format Manga and Manhwa reader built with Flutter. Matcha Reader combines a sleek UI with advanced local storage management, AI-curated discovery, and a compliance-safe Bring Your Own Repository (BYOR) extension architecture rivaling Tachimanga and Tachiyomi.

**Lead Developer:** Jhervin Jimenez
**Version:** 3.0.0 Pro (The Aggregator Engine)

---

## ✨ Core Features

* **Global Extension Store:** Browse and 1-tap install community-built web scrapers directly from a centralized JSON catalog.
* **Concurrent Global Search:** Search for a title once, and Matcha Reader simultaneously queries MangaDex and every installed extension, streaming the results grouped by source.
* **Library Sync & Tracking:** Pull-to-refresh your library to check all favorited manga for new chapters, instantly surfacing unread badges (`+2 New`). Toggle automatic background syncing in Settings.
* **Aggressive Pre-fetching:** Implements `cached_network_image` to silently cache the next 3 pages into memory while you read, guaranteeing zero buffering on poor connections.
* **Universal Offline Downloads:** Bypass the internet entirely. Chapters are downloaded byte-by-byte into hidden device storage and read locally via an offline interceptor inside `DownloadService`.
* **AI Discover Engine:** Integrated with Google's Gemini Flash. Features a chat-based UI that recommends titles and generates interactive "Smart Links" using Regex to instantly search the database.

---

## 🚀 Getting Started

### Prerequisites
To run this project, you will need to have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Dart SDK
* Android Studio / Xcode (for emulation and building)
* A valid [Google Gemini API Key](https://aistudio.google.com/app/apikey)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/matcha_reader.git
cd matcha_reader
```

**2. Fetch Flutter dependencies**
```bash
flutter pub get
```

**3. Configure the Gemini API Key**
For security, the API key is not hardcoded. You must provide your Google Generative AI key as a build-time variable:
```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_key_here
```

---

## 🏗️ Architecture Overview

The app follows a modern, decoupled architecture using **Riverpod** for state management and dependency injection.

### Services Layer
* `MangaDexService`: Handles all API routing and data mapping for the default MangaDex integration.
* `ExtensionService`: The Universal JS Engine. Evaluates third-party scripts in a headless webview.
* `DownloadService`: The Offline Interceptor. Checks local disk for pages before making network requests.
* `GeminiService`: Handles the Generative AI connection and chat state.
* `StorageService`: The hardware-backed encryption layer storing user history, favorites, settings, and unread counts.

### UI Layer
The UI consists of reactive `ConsumerStatefulWidget`s that watch global providers (e.g. `historyProvider`, `favoritesProvider`, `bookmarkProvider`, `appSettingsProvider`) to render updates instantly without manual state drilling.

---

## 🔌 Extension Development

Extensions are written in standard JavaScript and parse the DOM of target websites. They must implement the following methods:
* `getExtensionInfo()`
* `searchManga(query)`
* `getMangaDetails(id)`
* `getMangaChapters(id)`
* `getChapterPages(chapterId)`

Place your scripts in a GitHub repository alongside an `index.json` catalog file, and Matcha Reader will dynamically load them into the global store.

---

*Built with Flutter. Read responsibly.*
