import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/library/scanner_service.dart';
import 'package:flutter_video/features/library/watcher_service.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';

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

final _allMediaFilesStreamProvider = StreamProvider<List<MediaFile>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMediaFiles();
});

class _StructuralList {
  final List<MediaFile> files;
  _StructuralList(this.files);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _StructuralList) return false;
    if (files.length != other.files.length) return false;
    for (int i = 0; i < files.length; i++) {
      final a = files[i];
      final b = other.files[i];
      if (a.id != b.id || a.tmdbId != b.tmdbId || a.filePath != b.filePath) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => files.length.hashCode;
}

/// Emits only when structural changes happen (files added/removed/metadata matched)
final libraryFilesProvider = Provider<AsyncValue<List<MediaFile>>>((ref) {
  final structList = ref.watch(_allMediaFilesStreamProvider.select((asyncValue) {
    return asyncValue.whenData((files) => _StructuralList(files));
  }));
  return structList.whenData((s) => s.files);
});

/// Narrowly-scoped stream that emits whenever watch progress changes.
final watchProgressProvider = Provider<AsyncValue<List<MediaFile>>>((ref) {
  return ref.watch(_allMediaFilesStreamProvider);
});

// Deprecated: use libraryFilesProvider or watchProgressProvider instead
final allMediaFilesProvider = libraryFilesProvider;

final recentlyAddedFilesProvider = StreamProvider<List<MediaFile>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentlyAdded(limit: 20);
});

// Continue Watching

/// Continue watching provider with TV series grouping.
///
/// For TV/anime files: groups by series (via tmdbId or title) and keeps only
/// the most recently watched episode per series (determined by [lastWatchedAt]).
/// If the most recently watched episode is fully completed, it will suggest the
/// next unwatched episode in the series, if available.
/// For movies: passes through unchanged if partially watched.
///
/// Returns a record of (MediaFile file, SeriesItem? series) pairs so the UI
/// can build the right card and navigate to the right destination.
final continueWatchingProvider = Provider<List<ContinueWatchingEntry>>((ref) {
  final allFiles = ref.watch(watchProgressProvider).value ?? [];

  final result = <ContinueWatchingEntry>[];

  // Separate movies from TV/anime
  final movies = <MediaFile>[];
  final tvFiles = <MediaFile>[];

  for (final file in allFiles) {
    final type = file.mediaType;
    if (type == 'tv' || type == 'anime') {
      tvFiles.add(file);
    } else {
      movies.add(file);
    }
  }

  // Movies: Only include if partially watched
  for (final movie in movies) {
    if (movie.positionMillis == null || movie.durationMillis == null || movie.durationMillis == 0) continue;
    final progress = movie.positionMillis! / movie.durationMillis!;
    if (progress > 0.01 && progress < 0.95) {
      result.add(ContinueWatchingEntry(file: movie));
    }
  }

  // TV/Anime: Group by series
  if (tvFiles.isNotEmpty) {
    final seriesList = SeriesItem.groupFiles(tvFiles);
    for (final series in seriesList) {
      // Find episodes with some watch history
      final watchedEpisodes = series.episodes.where((e) {
        if (e.lastWatchedAt != null) return true;
        if (e.positionMillis != null && e.positionMillis! > 0) return true;
        return false;
      }).toList();

      if (watchedEpisodes.isEmpty) continue;

      // Sort by most recently interacted
      watchedEpisodes.sort((a, b) {
        final aTime = a.lastWatchedAt;
        final bTime = b.lastWatchedAt;
        if (aTime != null && bTime != null) {
          final cmp = bTime.compareTo(aTime);
          if (cmp != 0) return cmp;
          // Tie-breaker: Episode order (highest index first)
          final aIndex = series.episodes.indexWhere((e) => e.id == a.id);
          final bIndex = series.episodes.indexWhere((e) => e.id == b.id);
          return bIndex.compareTo(aIndex);
        }
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        return (b.positionMillis ?? 0).compareTo(a.positionMillis ?? 0);
      });

      final mostRecent = watchedEpisodes.first;

      bool isFullyWatched(MediaFile file) {
        if (file.positionMillis == null || file.durationMillis == null || file.durationMillis == 0) return false;
        return (file.positionMillis! / file.durationMillis!) >= 0.95;
      }

      if (!isFullyWatched(mostRecent)) {
        // If partially watched or barely watched, continue from here
        result.add(ContinueWatchingEntry(file: mostRecent, series: series));
      } else {
        // Fully watched. Find the next episode in the series.
        final currentIndex = series.episodes.indexWhere((e) => e.id == mostRecent.id);
        if (currentIndex != -1 && currentIndex < series.episodes.length - 1) {
          // Scan forward for the first unwatched episode
          for (int i = currentIndex + 1; i < series.episodes.length; i++) {
            if (!isFullyWatched(series.episodes[i])) {
              result.add(ContinueWatchingEntry(
                file: series.episodes[i], 
                series: series,
                overrideSortTime: mostRecent.lastWatchedAt, // Keep the series at the top
              ));
              break;
            }
          }
        }
      }
    }
  }

  // Sort all entries by sortTime descending (most recent first)
  result.sort((a, b) {
    final aTime = a.sortTime;
    final bTime = b.sortTime;
    if (aTime != null && bTime != null) {
      return bTime.compareTo(aTime);
    }
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    // Fallback: higher positionMillis
    return (b.file.positionMillis ?? 0).compareTo(a.file.positionMillis ?? 0);
  });

  return result;
});

/// A continue watching entry - pairs a specific [MediaFile] (the episode to
/// resume) with an optional [SeriesItem] (non-null for TV/anime).
class ContinueWatchingEntry {
  final MediaFile file;
  final SeriesItem? series;
  final DateTime? overrideSortTime;

  const ContinueWatchingEntry({
    required this.file,
    this.series,
    this.overrideSortTime,
  });

  bool get isSeries => series != null;
  DateTime? get sortTime => overrideSortTime ?? file.lastWatchedAt;
}

// Grouped Series

/// Groups all TV/anime files into [SeriesItem] objects for the library grids.
final groupedSeriesProvider = Provider<List<SeriesItem>>((ref) {
  final allFiles = ref.watch(libraryFilesProvider).value ?? [];
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

// Derived Category Providers
final movieFilesProvider = Provider<List<MediaItem>>((ref) {
  final files = ref.watch(libraryFilesProvider).value ?? [];
  return files.map(MediaItem.fromMediaFile).where((item) => item.type == MediaType.movie).toList();
});

final tvSeriesProvider = Provider<List<MediaItem>>((ref) {
  final series = ref.watch(groupedSeriesProvider);
  return series.where((s) => s.type == MediaType.tvShow).map(MediaItem.fromSeriesItem).toList();
});

final animeSeriesProvider = Provider<List<MediaItem>>((ref) {
  final series = ref.watch(groupedSeriesProvider);
  return series.where((s) => s.type == MediaType.anime).map(MediaItem.fromSeriesItem).toList();
});

final uncategorizedFilesProvider = Provider<List<MediaItem>>((ref) {
  final files = ref.watch(libraryFilesProvider).value ?? [];
  return files.map(MediaItem.fromMediaFile).where((item) => item.type == MediaType.uncategorized).toList();
});
