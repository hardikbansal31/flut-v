import 'dart:io';
import 'package:flutter_video/core/database/database.dart';
import 'package:path/path.dart' as p;

class LibraryScannerService {
  final AppDatabase _db;

  LibraryScannerService(this._db);

  static const _supportedExtensions = {
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', 
    '.m4v', '.ts', '.mpg', '.mpeg', '.3gp', '.ogv'
  };

  /// Scans a specific folder recursively and updates the database.
  ///
  /// If the folder no longer exists on disk, all its media entries are removed.
  /// Files that exist on disk are upserted; files that were in the DB but are
  /// no longer on disk are removed (stale entry cleanup).
  Future<void> scanFolder(LibraryFolder folder) async {
    final dir = Directory(folder.path);

    // If the entire folder was deleted from disk, purge all its media entries.
    if (!await dir.exists()) {
      await _db.removeMediaFilesByFolder(folder.id);
      return;
    }

    final existingFiles = await _db.getFilePathsForFolder(folder.id);
    final existingPaths = existingFiles.toSet();
    final scannedPaths = <String>{};

    final companionsBatch = <MediaFilesCompanion>[];

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final path = entity.path;
            scannedPaths.add(path);
            
            try {
              final stat = await entity.stat();
              companionsBatch.add(
                MediaFilesCompanion.insert(
                  filePath: path,
                  fileName: p.basenameWithoutExtension(path),
                  fileExtension: ext.substring(1), // remove dot
                  fileSizeBytes: BigInt.from(stat.size),
                  libraryFolderId: folder.id,
                  lastModified: stat.modified,
                )
              );
            } catch (_) {
              // Individual file stat/insert failed - skip this file but
              // continue scanning the rest.
            }
          }
        }
      }
      
      if (companionsBatch.isNotEmpty) {
        await _db.upsertMediaFilesBatch(companionsBatch);
      }
    } catch (_) {
      // Directory listing failed (permission denied, etc.) - proceed to
      // cleanup with whatever was scanned so far.
    }

    // Always clean up stale entries, even if the scan was partial.
    final stalePaths = existingPaths.difference(scannedPaths);
    for (final path in stalePaths) {
      await _db.removeMediaFileByPath(path);
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
  /// files no longer exist on disk. Does NOT upsert existing files, so it
  /// triggers no unnecessary Drift stream emissions.
  Future<void> pruneFolder(LibraryFolder folder) async {
    final dir = Directory(folder.path);

    if (!await dir.exists()) {
      await _db.removeMediaFilesByFolder(folder.id);
      return;
    }

    final existingPaths = await _db.getFilePathsForFolder(folder.id);
    for (final path in existingPaths) {
      if (!await File(path).exists()) {
        await _db.removeMediaFileByPath(path);
      }
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
