# 🍵 Matcha Reader

An enterprise-grade, multi-format Manga and Manhwa reader built with Flutter. Matcha Reader combines a sleek UI with advanced local storage management, AI-curated discovery, and a compliance-safe Bring Your Own Repository (BYOR) extension architecture.

**Lead Developer:** Jhervin Jimenez
**Version:** 2.0.0 Pro (Riverpod Architecture)

---

## ✨ Core Features

* **Universal BYOR Extension Engine:** Add third-party JavaScript or JSON repositories to search and read from anywhere on the internet. Executes safely in a headless `InAppWebView` with a custom CORS-bypassing `nativeFetch` bridge.
* **Multi-Format Reading Engine:** Seamlessly toggle between Vertical Scroll (Webtoons), Right-to-Left (Japanese Manga), and Left-to-Right (Western Comics) with dynamic state preservation.
* **True Offline Downloads:** Bypass the internet entirely. Chapters are downloaded byte-by-byte into hidden device storage and read locally via an offline interceptor inside `DownloadService`.
* **AI Discover Engine:** Integrated with Google's Gemini Flash. Features a chat-based UI that recommends titles and generates interactive "Smart Links" using Regex to instantly search the database.
* **Advanced Cache Management:** Calculates temporary image bloat and allows users to wipe RAM and local directory caches with a single tap to protect device storage.
* **Reactive Library Memory:** Utilizes `Riverpod` and `FlutterSecureStorage` to save reading progress, exact scroll/page positions, and favorite titles locally, automatically updating the UI across all tabs in real-time.

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
* `StorageService`: The hardware-backed encryption layer storing user history, favorites, and settings.

### UI Layer
The UI consists of reactive `ConsumerStatefulWidget`s that watch global providers (e.g. `historyProvider`, `favoritesProvider`, `bookmarkProvider`) to render updates instantly without manual state drilling.

---

## 📦 Dependencies

* `flutter_riverpod`: State management and dependency injection.
* `http`: For fetching API data and downloading image bytes.
* `google_generative_ai`: For powering the Discover Engine chat.
* `flutter_secure_storage`: For encrypted local database memory.
* `flutter_inappwebview`: For the headless JavaScript BYOR extension environment.
* `path_provider`: For accessing the device's application documents and temporary directories.
* `html`: For parsing declarative JSON extension selectors.

---

*Built with Flutter. Read responsibly.*
