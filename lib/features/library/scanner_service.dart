import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_video/core/database/database.dart';
import 'package:path/path.dart' as p;

class LibraryScannerService {
  final AppDatabase _db;

  LibraryScannerService(this._db);

  static const supportedExtensions = {
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', 
    '.m4v', '.ts', '.mpg', '.mpeg', '.3gp', '.ogv'
  };

  /// Scans a specific folder recursively and updates the database.
  ///
  /// Performance optimizations:
  ///   - Loads existing path -> (size, mtime) once.
  ///   - Stats files in bounded-concurrency chunks of 50.
  ///   - Skips files whose size and modified timestamp are unchanged.
  ///   - Deletes stale rows in bulk using chunked `isIn`.
  ///   - If directory listing throws, preserves all existing entries.
  Future<void> scanFolder(LibraryFolder folder) async {
    final dir = Directory(folder.path);

    // If the folder is missing, mark it unavailable but keep all data.
    if (!await dir.exists()) {
      await _db.markFolderUnavailable(folder.id);
      developer.log(
        'Folder not found, marked unavailable: ${folder.path}',
        name: 'LibraryScannerService',
      );
      return;
    }

    // Folder exists — mark it available.
    await _db.markFolderAvailable(folder.id);

    final existingStats = await _db.getFileStatMapForFolder(folder.id);
    final scannedPaths = <String>{};
    final candidateFiles = <File>[];
    bool listingCompleted = false;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            scannedPaths.add(entity.path);
            candidateFiles.add(entity);
          }
        }
      }
      listingCompleted = true;
    } on FileSystemException catch (e) {
      developer.log(
        'Directory listing failed for ${folder.path}: ${e.message}. '
        'Skipping prune to prevent data loss.',
        name: 'LibraryScannerService',
        level: 900,
      );
    }

    // Stat files in bounded-concurrency chunks (50 at a time)
    final companionsBatch = <MediaFilesCompanion>[];
    const statChunkSize = 50;

    for (var i = 0; i < candidateFiles.length; i += statChunkSize) {
      final chunk = candidateFiles.skip(i).take(statChunkSize).toList();
      final stats = await Future.wait(
        chunk.map((file) async {
          try {
            final stat = await file.stat();
            return (file: file, stat: stat);
          } on FileSystemException catch (e) {
            developer.log(
              'Failed to stat file, skipping: ${file.path} — ${e.message}',
              name: 'LibraryScannerService',
              level: 800,
            );
            return null;
          }
        }),
      );

      for (final result in stats) {
        if (result == null) continue;
        final file = result.file;
        final stat = result.stat;
        final path = file.path;
        final existing = existingStats[path];

        // Skip rows whose size and lastModified are unchanged!
        if (existing != null &&
            existing.size == BigInt.from(stat.size) &&
            existing.modified == stat.modified) {
          continue;
        }

        final ext = p.extension(path).toLowerCase();
        companionsBatch.add(
          MediaFilesCompanion.insert(
            filePath: path,
            fileName: p.basenameWithoutExtension(path),
            fileExtension: ext.substring(1),
            fileSizeBytes: BigInt.from(stat.size),
            libraryFolderId: folder.id,
            lastModified: stat.modified,
          ),
        );
      }
    }

    // Only write changed or newly added rows
    if (companionsBatch.isNotEmpty) {
      await _db.upsertMediaFilesBatch(companionsBatch);
    }

    // Only prune stale entries if the listing completed successfully
    if (listingCompleted) {
      final stalePaths = existingStats.keys
          .toSet()
          .difference(scannedPaths)
          .toList();
      if (stalePaths.isNotEmpty) {
        await _db.removeMediaFilesByPaths(stalePaths);
      }
    }
  }

  /// Scans all library folders (full upsert + prune).
  Future<void> scanAllFolders() async {
    final folders = await _db.getAllLibraryFolders();
    for (final folder in folders) {
      await scanFolder(folder);
    }
  }

  /// Lightweight prune for a single folder: only removes DB entries whose
  /// files no longer exist on disk.
  Future<void> pruneFolder(LibraryFolder folder) async {
    final dir = Directory(folder.path);

    if (!await dir.exists()) {
      await _db.markFolderUnavailable(folder.id);
      developer.log(
        'Folder not found during prune, marked unavailable: ${folder.path}',
        name: 'LibraryScannerService',
      );
      return;
    }

    // Folder exists — mark available.
    await _db.markFolderAvailable(folder.id);

    final existingPaths = await _db.getFilePathsForFolder(folder.id);
    
    // Batch existence checks (concurrency of ~50 to avoid exhausting file descriptors)
    final missingPaths = <String>[];
    const batchSize = 50;
    
    for (var i = 0; i < existingPaths.length; i += batchSize) {
      final batch = existingPaths.skip(i).take(batchSize).toList();
      final existenceResults = await Future.wait(
        batch.map((path) => File(path).exists())
      );
      
      for (var j = 0; j < batch.length; j++) {
        if (!existenceResults[j]) {
          missingPaths.add(batch[j]);
        }
      }
    }
    
    if (missingPaths.isNotEmpty) {
      await _db.removeMediaFilesByPaths(missingPaths);
    }
  }

  /// Prunes all library folders - removes DB entries for files that no
  /// longer exist on disk. Much cheaper than [scanAllFolders] because it
  /// never writes unchanged rows (no stream spam).
  Future<void> pruneDeletedFiles() async {
    final folders = await _db.getAllLibraryFolders();
    for (final folder in folders) {
      await pruneFolder(folder);
    }
  }
}
