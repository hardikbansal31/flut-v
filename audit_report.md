# Performance and Correctness Audit Report

Below is the read-only audit report covering the entire codebase, grouped by your requested categories and sorted by severity. 

> [!IMPORTANT]
> This is a read-only report. No code has been modified yet. Please review the findings below and let me know which issues you'd like me to fix and in what order.

### 1. Provider/State Architecture Issues

| File | Issue | User Impact | Severity |
| :--- | :--- | :--- | :--- |
| `library_providers.dart` (Line 13) | **Overly broad scope:** `allMediaFilesProvider` listens directly to the Drift stream `watchAllMediaFiles()`. Drift emits a new list whenever *any* row in the table changes. | **Lag / Battery Drain:** Every time the video player updates your watch progress (every few seconds), the entire home screen, library screen, and all cards rebuild simultaneously. | **Critical** |
| `library_providers.dart` (Line 63) | **Expensive recomputations:** `groupedSeriesProvider` re-runs the regex to parse filenames (e.g., season/episode extraction) for *every* file, every time the files list updates. | **Lag / Stutters:** Navigating back to the home screen can stutter because hundreds of regex operations run on the main thread when watch progress updates. | **Moderate** |

### 2. Database and Query Inefficiency

| File | Issue | User Impact | Severity |
| :--- | :--- | :--- | :--- |
| `database.dart` (Lines 168-184) | **N+1 Query Pattern:** `markAsWatched` uses a `for` loop to fetch and update each file individually, rather than using a single `WHERE id IN (...)` batch update. | **Lag:** Marking an entire season as watched will freeze the app briefly as it makes 24 separate round-trips to the database. | **Critical** |
| `scanner_service.dart` (Lines 34-57) | **Unbatched Inserts:** The library scanner uses a `for` loop to insert files one by one into the database. | **Lag:** Scanning a new folder with 1,000 files executes 1,000 separate DB writes, also triggering 1,000 UI rebuilds (due to the provider issue above). | **Critical** |
| `tables.dart` (Lines 33-60) | **Missing Indexes:** The `MediaFiles` table lacks indexes on `libraryFolderId`, `filePath`, and `tmdbId`. | **Battery Drain / Slow Loads:** Database queries have to scan every single row to find unmatched files or files in a specific folder. | **Moderate** |

### 3. File I/O and Scanning

| File | Issue | User Impact | Severity |
| :--- | :--- | :--- | :--- |
| `watcher_service.dart` (Lines 25-45) | **Redundant Watcher Events:** The file watcher immediately fires a DB upsert on every `MODIFY` event without debouncing. | **Lag / High CPU:** Downloading or copying a large video file into the library folder emits hundreds of events per second, spamming the database and UI. | **Moderate** |
| `scanner_service.dart` (Line 91) | **Synchronous IO checks in loop:** `pruneFolder` awaits `File(path).exists()` in a loop over all files. | **Slow Scanning:** While non-blocking, checking thousands of files sequentially is slow and delays the pruning process significantly. | **Minor** |

### 4. Race Conditions and Async Bugs

| File | Issue | User Impact | Severity |
| :--- | :--- | :--- | :--- |
| `player_screen.dart` (Line 338) | **Context used across async gaps:** `PopScope` calls `await _saveWatchProgress()` and then `Navigator.of(context).pop()`. | **Crash / Warnings:** If the screen is already popped by a swipe gesture, using `context` after the async gap will throw a "don't use context across async gaps" error. | **Moderate** |

### 5. Image and Memory Handling

| File | Issue | User Impact | Severity |
| :--- | :--- | :--- | :--- |
| `library_providers.dart` (Line 13) | **Large objects in memory:** `allMediaFilesProvider` caches all `MediaFile` objects in memory endlessly. | **Memory Bloat:** For massive libraries (10k+ files), keeping the full parsed list in memory permanently consumes excessive RAM. | **Moderate** |
| `media_detail_screen.dart` (Line 231) | **Missing Cache Dimension:** `CachedNetworkImage` for the poster image uses `memCacheWidth` but forgets `memCacheHeight`. | **Memory Spike:** The image decoder may allocate more memory than strictly necessary since the height constraint is unbound. | **Minor** |

### 6. Unnecessary Widget Rebuilds

| File | Issue | User Impact | Severity |
| :--- | :--- | :--- | :--- |
| `home_screen.dart` (Lines 545-546) | **Redundant Provider Watches:** Some sections of the UI `watch` the entire `allMediaFilesProvider` list even when they only need to display a specific subset or category. | **Jank:** Triggers excessive widget tree diffing for sections of the screen that haven't actually changed. | **Moderate** |

### 7. Scroll and List Performance
*No critical issues found. The app correctly utilizes lazy-loading lists (`ListView.separated`, `GridView.builder`) in most places, avoiding rendering off-screen elements.*
