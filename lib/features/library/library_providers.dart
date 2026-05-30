import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/library/scanner_service.dart';
import 'package:flutter_video/features/library/watcher_service.dart';

// Provides the singleton instance of the database
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in ProviderScope');
});

// Scanner service provider
final libraryScannerProvider = Provider<LibraryScannerService>((ref) {
  final db = ref.watch(databaseProvider);
  return LibraryScannerService(db);
});

// Watcher service provider
final libraryWatcherProvider = Provider<LibraryWatcherService>((ref) {
  final db = ref.watch(databaseProvider);
  final watcherService = LibraryWatcherService(db);
  
  ref.onDispose(() {
    watcherService.dispose();
  });
  
  // Automatically watch all folders when they change
  ref.listen<AsyncValue<List<LibraryFolder>>>(
    libraryFoldersProvider,
    (previous, next) {
      final folders = next.value ?? [];
      final currentIds = folders.map((f) => f.id).toSet();
      
      final previousIds = previous?.value?.map((f) => f.id).toSet() ?? {};
      
      // Stop watching removed folders
      final removed = previousIds.difference(currentIds);
      for (final id in removed) {
        watcherService.unwatchFolder(id);
      }
      
      // Start watching new folders
      for (final folder in folders) {
        watcherService.watchFolder(folder);
      }
    },
    fireImmediately: true,
  );
  
  return watcherService;
});

class ScanningState extends Notifier<bool> {
  @override
  bool build() => false;

  void setScanning(bool isScanning) => state = isScanning;
}

final scanningStateProvider = NotifierProvider<ScanningState, bool>(ScanningState.new);

// Streams
final libraryFoldersProvider = StreamProvider<List<LibraryFolder>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllLibraryFolders();
});

final allMediaFilesProvider = StreamProvider<List<MediaFile>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMediaFiles();
});

final recentlyAddedFilesProvider = StreamProvider<List<MediaFile>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentlyAdded(limit: 20);
});

// ─── Continue Watching ────────────────────────────────────────────────────

/// Continue watching provider with TV series grouping.
///
/// For TV/anime files: groups by series (via tmdbId or title) and keeps only
/// the most recently watched episode per series (determined by [lastWatchedAt]).
/// For movies: passes through unchanged.
///
/// Returns a record of (MediaFile file, SeriesItem? series) pairs so the UI
/// can build the right card and navigate to the right destination.
final continueWatchingProvider = Provider<List<ContinueWatchingEntry>>((ref) {
  final allFiles = ref.watch(allMediaFilesProvider).value ?? [];

  // Filter for in-progress files
  final inProgress = allFiles.where((file) {
    if (file.positionMillis == null || file.durationMillis == null) return false;
    if (file.durationMillis == 0) return false;
    final progress = file.positionMillis! / file.durationMillis!;
    return progress > 0.01 && progress < 0.95;
  }).toList();

  final result = <ContinueWatchingEntry>[];

  // Separate movies from TV/anime
  final movies = <MediaFile>[];
  final tvFiles = <MediaFile>[];

  for (final file in inProgress) {
    final type = file.mediaType;
    if (type == 'tv' || type == 'anime') {
      tvFiles.add(file);
    } else {
      movies.add(file);
    }
  }

  // Movies pass through as individual entries
  for (final movie in movies) {
    result.add(ContinueWatchingEntry(file: movie));
  }

  // Group TV/anime by series
  if (tvFiles.isNotEmpty) {
    final seriesList = SeriesItem.groupFiles(tvFiles);
    for (final series in seriesList) {
      // Pick the most recently watched episode by lastWatchedAt,
      // with positionMillis as fallback for pre-migration data
      final episodes = series.episodes.toList();
      episodes.sort((a, b) {
        final aTime = a.lastWatchedAt;
        final bTime = b.lastWatchedAt;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime); // Most recent first
        }
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        // Fallback: higher positionMillis = more recently interacted
        return (b.positionMillis ?? 0).compareTo(a.positionMillis ?? 0);
      });
      final mostRecent = episodes.first;
      result.add(ContinueWatchingEntry(file: mostRecent, series: series));
    }
  }

  // Sort all entries by lastWatchedAt descending (most recent first)
  result.sort((a, b) {
    final aTime = a.file.lastWatchedAt;
    final bTime = b.file.lastWatchedAt;
    if (aTime != null && bTime != null) {
      return bTime.compareTo(aTime);
    }
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    return 0;
  });

  return result;
});

/// A continue watching entry — pairs a specific [MediaFile] (the episode to
/// resume) with an optional [SeriesItem] (non-null for TV/anime).
class ContinueWatchingEntry {
  final MediaFile file;
  final SeriesItem? series;

  const ContinueWatchingEntry({required this.file, this.series});

  bool get isSeries => series != null;
}

// ─── Grouped Series ───────────────────────────────────────────────────────

/// Groups all TV/anime files into [SeriesItem] objects for the library grids.
final groupedSeriesProvider = Provider<List<SeriesItem>>((ref) {
  final allFiles = ref.watch(allMediaFilesProvider).value ?? [];
  final tvAnimeFiles = allFiles.where((f) {
    final type = f.mediaType;
    return type == 'tv' || type == 'anime';
  }).toList();

  return SeriesItem.groupFiles(tvAnimeFiles);
});

// Keep the old provider as a backwards-compatibility alias.
// Any code still using it will continue to work.
final continueWatchingFilesProvider = Provider<List<MediaFile>>((ref) {
  return ref.watch(continueWatchingProvider).map((e) => e.file).toList();
});
