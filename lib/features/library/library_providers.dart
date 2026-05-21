import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/database/database.dart';
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

final continueWatchingFilesProvider = Provider<List<MediaFile>>((ref) {
  final allFiles = ref.watch(allMediaFilesProvider).value ?? [];
  return allFiles.where((file) {
    if (file.positionMillis == null || file.durationMillis == null) return false;
    if (file.durationMillis == 0) return false;
    final progress = file.positionMillis! / file.durationMillis!;
    return progress > 0.01 && progress < 0.95;
  }).toList();
});
