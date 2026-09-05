# 🍵 Matcha Reader

An enterprise-grade, multi-format Manga and Manhwa reader built with Flutter. Matcha Reader combines a sleek UI with advanced local storage management, AI-curated discovery, and a compliance-safe Bring Your Own Repository (BYOR) extension architecture.

**Lead Developer:** Jhervin Jimenez
**Version:** 1.0.0 Pro

---

## ✨ Core Features

* **Multi-Format Reading Engine:** Seamlessly toggle between Vertical Scroll (Webtoons), Right-to-Left (Japanese Manga), and Left-to-Right (Western Comics) with dynamic state preservation.
* **True Offline Downloads:** Bypass the internet entirely. Chapters are downloaded byte-by-byte into hidden device storage and read locally via an offline interceptor.
* **AI Discover Engine:** Integrated with Google's Gemini 1.5 Flash. Features a chat-based UI that recommends titles and generates interactive "Smart Links" using Regex to instantly search the database.
* **Advanced Cache Management:** Calculates temporary image bloat and allows users to wipe RAM and local directory caches with a single tap to protect device storage.
* **BYOR Extension UI:** A "Blank Slate" source manager that allows users to add community-driven repository URLs, ensuring App Store and Play Store compliance while maintaining extensibility.
* **Persistent Library Memory:** Utilizes `FlutterSecureStorage` to save reading progress, exact scroll/page positions, and favorite titles locally with hardware-backed encryption.

---

## 🚀 Getting Started

### Prerequisites
To run this project, you will need to have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.19.0 or higher recommended)
* Dart SDK
* Android Studio / Xcode (for emulation and building)
* A valid [Google Gemini API Key](https://aistudio.google.com/app/apikey)

### Installation

**1. Clone the repository**
```bash
git clone [https://github.com/yourusername/matcha_reader.git](https://github.com/yourusername/matcha_reader.git)
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

**4. Run the app**
```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_key_here
```

## 🛡️ Security & Production

To maintain the security of this project:

1.  **API Keys:** Never commit API keys to version control. This project uses `--dart-define` to inject keys at build time.
2.  **Secure Storage:** The project includes `flutter_secure_storage` for encrypted local data. Use this instead of `shared_preferences` for sensitive information.
3.  **Obfuscation:** For release builds, always obfuscate your code to prevent reverse-engineering:
    ```bash
    flutter build apk --obfuscate --split-debug-info=./debug_info
    ```
4.  **SSL Pinning:** For production, consider implementing SSL pinning to prevent Man-in-the-Middle (MitM) attacks on the MangaDex API.

## 🚀 Production Build

When you are ready to distribute your app, use these commands to ensure maximum security:

### Android (APK)
```bash
flutter build apk --obfuscate --split-debug-info=./debug_info --dart-define=GEMINI_API_KEY=your_key
```

### iOS (IPA)
```bash
flutter build ipa --obfuscate --split-debug-info=./debug_info --dart-define=GEMINI_API_KEY=your_key
```

---

## 📦 Dependencies

This project relies on the following core Flutter packages:
* `http`: For fetching MangaDex API data and downloading image bytes.
* `google_generative_ai`: For powering the Discover Engine chat.
* `flutter_secure_storage`: For encrypted local database memory (bookmarks, favorites, repos, scroll positions).
* `path_provider`: For accessing the device's application documents and temporary directories.

To install them manually, run:
```bash
flutter pub add http google_generative_ai flutter_secure_storage path_provider
```

---

## 🏗️ Architecture Overview

The app is currently structured with a bottom navigation root managing 5 primary views:

1. **HomeView:** Displays trending API data and dynamically renders a "Continue Reading" card based on local storage.
2. **DiscoverView:** A conversational UI communicating with Gemini AI, featuring Regex-powered action chips.
3. **LibraryView:** A grid-based rendering of saved JSON data tracking the user's favorited manga.
4. **SourcesView:** The UI layer for adding and managing external extension URLs.
5. **SettingsView:** The file-system manager calculating and wiping directory cache.
6. **MangaReaderView:** The core engine utilizing both `ListView.builder` and `PageView` with an offline fallback interceptor.

---

## 🔮 Future Roadmap

* **Phase 2: JavaScript Bridge:** Implementing `flutter_js` to parse community extension scripts added via the Sources tab.
* **Source Standardization:** Refactoring the database models to track `source` tags alongside manga IDs for universal library compatibility.
* **Hero Animations:** Expanding the custom transition routing across all tabs.

---

*Built with Flutter. Read responsibly.*