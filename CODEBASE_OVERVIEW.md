# Penguin Codebase & Architecture Overview

This document provides an architectural overview and breakdown of the **Penguin** media player project.

---

## 1. Project Overview & Philosophy

**Penguin** is a beautiful, cross-platform media player with a Netflix-style UI, built with Flutter. Inspired by iOS's Infuse app, it resolves local library paths, fetches metadata, and organizes media files without requiring a server or complicated setup.

- **Zero-Config Scanning:** Point the app to a local directory; it automatically indexes videos, parses show/movie filenames, and resolves TV show & anime hierarchies.
- **Privacy-First:** All library data, watch history, and TMDB keys remain stored locally on the device (SQLite and `shared_preferences`).
- **High-Performance Playback:** Built on top of `media_kit` (libmpv) with hardware acceleration, HiDPI sub-pixel rendering, and native ASS/SSA subtitle rendering.

---

## 2. Technology Stack & Key Libraries

| Layer | Technology / Package | Purpose |
|---|---|---|
| **Framework** | [Flutter](https://flutter.dev/) (Dart) | Cross-platform UI & app lifecycle |
| **State Management** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | Reactive state, data-fetching streams, and scoped rebuild isolation |
| **Database** | [Drift](https://pub.dev/packages/drift) (`drift_flutter`, SQLite) | Local relational storage for folders, media files, watch progress, and TMDB metadata |
| **Playback Engine** | [media_kit](https://pub.dev/packages/media_kit) (`libmpv`, `media_kit_video`) | Hardware-accelerated decoding, libass subtitle rendering, track selection |
| **Metadata** | [TMDB API v3](https://developer.themoviedb.org/docs) (`http`) | Posters, backdrops, synopses, ratings, release dates, and genres |
| **File Monitoring** | [watcher](https://pub.dev/packages/watcher) | Live file addition, modification, and deletion detection |
| **UI & Theming** | [google_fonts](https://pub.dev/packages/google_fonts) (`Outfit` & `Inter`), [phosphoricons_flutter](https://pub.dev/packages/phosphoricons_flutter) | Dark-mode design system with responsive sliver grids and micro-interactions |
| **Desktop Integration** | [window_manager](https://pub.dev/packages/window_manager) | Fullscreen management and window lifecycle |

---

## 3. Architecture & Codebase Map

- [lib/main.dart](file:///home/hardik/projects/flut-v/lib/main.dart): Application entry point. Initializes services (media_kit, window_manager) and sets up the root Drift database & Riverpod container.
- [lib/app.dart](file:///home/hardik/projects/flut-v/lib/app.dart): MaterialApp configuration, dark theme setup, and global keyboard shortcuts (e.g., Ctrl+Q/Cmd+Q to quit and save state).
- [lib/core/database/tables.dart](file:///home/hardik/projects/flut-v/lib/core/database/tables.dart): Defines Drift table schemas for `LibraryFolders` and `MediaFiles`.
- [lib/core/database/database.dart](file:///home/hardik/projects/flut-v/lib/core/database/database.dart): Drift database class containing migrations (v1-v4) and operations for folders, files, watch progress, and TMDB metadata.
- [lib/core/settings/library_management_screen.dart](file:///home/hardik/projects/flut-v/lib/core/settings/library_management_screen.dart): UI for adding/removing folders, configuring the TMDB API key, and setting a custom proxy base URL.
- [lib/core/theme/app_theme.dart](file:///home/hardik/projects/flut-v/lib/core/theme/app_theme.dart): Defines color palettes, Outfit/Inter text styles, and semantic themes.
- [lib/features/browse/models/media_item.dart](file:///home/hardik/projects/flut-v/lib/features/browse/models/media_item.dart): UI data model translating scanned media files and TMDB metadata into cards/grids.
- [lib/features/browse/models/series_item.dart](file:///home/hardik/projects/flut-v/lib/features/browse/models/series_item.dart): Groups individual episode files into series structures for row/grid display.
- [lib/features/browse/screens/home_screen.dart](file:///home/hardik/projects/flut-v/lib/features/browse/screens/home_screen.dart): Main dashboard displaying a featured hero banner, Continue Watching, Recently Added, and categorised grids (Movies, TV Shows, Anime, Uncategorized) using lazy-loaded slivers.
- [lib/features/browse/screens/media_detail_screen.dart](file:///home/hardik/projects/flut-v/lib/features/browse/screens/media_detail_screen.dart): Info display containing backdrop image, ratings, synopsis, and season/episode list with interactive watch progress toggles.
- [lib/features/browse/screens/category_screen.dart](file:///home/hardik/projects/flut-v/lib/features/browse/screens/category_screen.dart): Displays dedicated media lists for specific categories or full library listings.
- [lib/features/library/scanner_service.dart](file:///home/hardik/projects/flut-v/lib/features/library/scanner_service.dart): Handles filesystem scanning, database indexing, and startup pruning of missing files.
- [lib/features/library/watcher_service.dart](file:///home/hardik/projects/flut-v/lib/features/library/watcher_service.dart): Employs a debounced directory watcher to monitor file additions, modifications, and removals in real-time.
- [lib/features/library/library_providers.dart](file:///home/hardik/projects/flut-v/lib/features/library/library_providers.dart): Manages Riverpod states for continue watching files, series groupings, and category filters.
- [lib/features/metadata/filename_parser.dart](file:///home/hardik/projects/flut-v/lib/features/metadata/filename_parser.dart): Normalizes messy filenames into clean titles, release years, season indices, and episode numbers.
- [lib/features/metadata/tmdb_client.dart](file:///home/hardik/projects/flut-v/lib/features/metadata/tmdb_client.dart): High-performance client that communicates with TMDB API v3 endpoints (including retry mechanisms and rate-limiting).
- [lib/features/metadata/metadata_service.dart](file:///home/hardik/projects/flut-v/lib/features/metadata/metadata_service.dart): Orchestrates sequential TMDB query routines (including Japanese anime translation fallbacks and TV season-level poster fallbacks).
- [lib/features/player/screens/player_screen.dart](file:///home/hardik/projects/flut-v/lib/features/player/screens/player_screen.dart): Custom video player implementing keyboard mappings, subtitle tracks dialog, audio tracks dialog, physical scale corrections, and persistence triggers.

---

## 4. Key Workflows & Implementation Highlights

### 1. Folder Scanning & Hot Watching
- **Scanner Service:** [LibraryScannerService](file:///home/hardik/projects/flut-v/lib/features/library/scanner_service.dart) recursively scans directory trees for 13+ video extensions (`.mkv`, `.mp4`, `.webm`, `.avi`, etc.), inserts files via batched Drift transactions, and cleans up stale entries for files removed on disk.
- **Watcher Service:** [LibraryWatcherService](file:///home/hardik/projects/flut-v/lib/features/library/watcher_service.dart) runs a background `DirectoryWatcher` with a 500ms debounce to track new/modified/deleted files without visual stutter.
- **Startup Pruning:** On application start, [HomeScreen](file:///home/hardik/projects/flut-v/lib/features/browse/screens/home_screen.dart) invokes `pruneDeletedFiles()`, which validates database entries without running a heavy folder-wide scan, preserving system performance.

### 2. Filename Parsing & TMDB Metadata
- **Parser Engine:** [FilenameParser](file:///home/hardik/projects/flut-v/lib/features/metadata/filename_parser.dart) uses strict regex matching to strip tags like `[SubGroup]`, quality flags `1080p`, codecs `HEVC`, and captures `SxxExx` or absolute episode digits (e.g. `- 15`).
- **Orchestration:** [MetadataService](file:///home/hardik/projects/flut-v/lib/features/metadata/metadata_service.dart):
  - **Movies:** Performs multi-search (initially with release year, then falling back to a plain title match).
  - **TV / Anime:** Conducts a three-step query:
    1. `/search/tv` (falls back to `ja-JP` Japanese language queries for missing English hits).
    2. `/tv/{id}/season/{s}/episode/{e}` for specific episode names, summaries, and backdrop stills.
    3. `/tv/{id}/season/{s}` for season-level posters if episode-specific still assets are absent.
  - Automatically identifies Anime by combining the Animation genre `16` and the Japanese original language code `ja`.

### 3. Smart "Continue Watching" & Series Grouping
- Grouped series states are computed reactively in [library_providers.dart](file:///home/hardik/projects/flut-v/lib/features/library/library_providers.dart).
  - Combines multiple episode files under a unified series ID or title.
  - Finds the most recently watched episode per series.
  - If the last episode was watched to completion ($\ge 95\%$), the feed automatically advances to propose the **next unwatched episode** in the series timeline.

### 4. Video Player & Subtitle Rendering
- **Player Screen:** [PlayerScreen](file:///home/hardik/projects/flut-v/lib/features/player/screens/player_screen.dart):
  - **Native Subtitles:** Uses `libass: true` and sets `sub-ass-override=no` to render stylistic fansub titles (ASS/SSA formats) exactly as styled.
  - **HiDPI Rendering:** Resizes the mpv render texture to match the physical resolution of the host device to prevent composited blur.
  - **Keyboard Controls:** `Space`/`P` (Play/Pause), `M` (Mute), `C` (Subtitles track swap), Arrow Keys (seek $\pm 10\text{s}$ or adjust volume $\pm 10\%$), `0-9` (seek percentage), `F` (Fullscreen), `Esc` (Exit).
  - **State Preservation:** Watch states are persisted to SQLite during pause, screen unmount, or application closure.
