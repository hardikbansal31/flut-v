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
  Future<void> scanFolder(LibraryFolder folder) async {
    final dir = Directory(folder.path);
    if (!await dir.exists()) return;

    final existingFiles = await _db.getFilePathsForFolder(folder.id);
    final existingPaths = existingFiles.toSet();
    final scannedPaths = <String>{};

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final path = entity.path;
            scannedPaths.add(path);
            
            final stat = await entity.stat();
            await _db.upsertMediaFile(
              filePath: path,
              fileName: p.basenameWithoutExtension(path),
              fileExtension: ext.substring(1), // remove dot
              fileSizeBytes: stat.size,
              libraryFolderId: folder.id,
              lastModified: stat.modified,
            );
          }
        }
      }

      // Cleanup stale entries
      final stalePaths = existingPaths.difference(scannedPaths);
      for (final path in stalePaths) {
        await _db.removeMediaFileByPath(path);
      }
    } catch (e) {
      // Handle or log error (e.g., permission denied)
    }
  }

  /// Scans all library folders.
  Future<void> scanAllFolders() async {
    final folders = await _db.getAllLibraryFolders();
    for (final folder in folders) {
      await scanFolder(folder);
    }
  }
}
