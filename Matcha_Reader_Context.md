# 🍵 Matcha Reader - Project Context & Master Roadmap

**Lead Developer:** Jhervin Jimenez
**Current Status:** Core Engine Complete (Phase 1)
**Tech Stack:** Flutter, Dart, Google Gemini API

## 📖 What is Matcha Reader? (The Goal)
Matcha Reader is a production-grade, multi-format Manga and Manhwa reading application. The primary goal of the app is to deliver a premium, native reading experience that rivals top-tier industry apps (like Webtoon or Tachiyomi), while remaining compliant with App Store and Google Play Store policies.

Instead of hardcoding illegal or copyrighted scraping sources, Matcha Reader acts as a secure, high-performance "Blank Slate." It uses a **Bring Your Own Repository (BYOR)** architecture, allowing users to input community-driven extension URLs to expand their catalogs safely.

## ✨ Current Features & Architecture (What is already built)
The app is currently a monolithic UI utilizing local device storage, secure encryption, and file management.

1. **Multi-Format Reading Engine:** A dynamic `PageView` and `ListView` engine that allows users to instantly toggle between Vertical Scroll (Webtoons), Right-to-Left (Japanese Manga), and Left-to-Right (Western Comics).
2. **True Offline Downloads:** A custom network interceptor. Users can download chapters byte-by-byte to hidden local storage (`path_provider`). When reading, the app automatically checks the hard drive first and bypasses the internet if the files exist.
3. **AI Discover Engine:** Integrated with Gemini 2.5 Flash. A conversational UI where users ask for recommendations. Uses Regex to extract titles and generate clickable "Smart Links" for instant database querying.
4. **Enterprise Security:** Uses `flutter_secure_storage` to encrypt bookmarks, reading history, and favorites. API keys are hidden from the source code and injected at compile time via environment variables (`--dart-define`).
5. **Advanced Cache Management:** A dedicated settings engine that calculates temporary directory bloat and allows users to wipe RAM, image caches, and secure data to protect their device storage.
6. **Sources (BYOR) UI:** The foundational UI for users to paste and manage third-party repository URLs.

## 🚀 Future Roadmap & Planned Features
These are the architectural upgrades and features planned for the next phases of development:

### 1. The JavaScript Bridge (Extension Engine)
* **Goal:** Upgrade the BYOR UI to actually execute community extensions.
* **Implementation:** Integrate a package like `flutter_js` to create a sandboxed, invisible background web browser. This will parse and run JavaScript extension scripts (similar to Tachiyomi/Mihon) fetched from the URLs users provide, scraping image links and returning standard JSON to the Flutter UI.

### 2. Universal Library Refactor (Data Standardization)
* **Goal:** Allow manga from different external extensions to live side-by-side with default sources in the user's Library.
* **Implementation:** Update the database models and secure storage logic to track a specific `source` tag alongside manga IDs. The reader engine will use this tag to dynamically route network requests to either the default API or the JavaScript Bridge.

### 3. The "Tracker" (Reading History Log)
* **Goal:** Expand the Library tab beyond manual "Favorites."
* **Implementation:** Build a background listener that automatically logs every clicked manga into a "History" database array, rendering a chronological list of everything the user has interacted with, sorted by the date last read.

### 4. UI Polish & Deployment Branding
* **Hero Animations:** Expand the seamless cover-art transitions across all tabs and search results.
* **Branding:** Generate a custom App Icon and native Splash Screen.
* **Distribution Strategy:** Finalize the deployment path—either maintaining the strict BYOR model for official App Store release, or compiling as a standalone `.apk`/`.ipa` for community sideloading.
