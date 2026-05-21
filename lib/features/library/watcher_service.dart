import 'dart:async';
import 'dart:io';
import 'package:flutter_video/core/database/database.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

class LibraryWatcherService {
  final AppDatabase _db;
  final Map<int, StreamSubscription> _subscriptions = {};

  LibraryWatcherService(this._db);

  static const _supportedExtensions = {
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', 
    '.m4v', '.ts', '.mpg', '.mpeg', '.3gp', '.ogv'
  };

  void watchFolder(LibraryFolder folder) {
    if (_subscriptions.containsKey(folder.id)) return;

    final dir = Directory(folder.path);
    if (!dir.existsSync()) return;

    final watcher = DirectoryWatcher(folder.path);
    _subscriptions[folder.id] = watcher.events.listen((event) async {
      final ext = p.extension(event.path).toLowerCase();
      if (!_supportedExtensions.contains(ext)) return;

      if (event.type == ChangeType.REMOVE) {
        await _db.removeMediaFileByPath(event.path);
      } else if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
        final file = File(event.path);
        if (await file.exists()) {
          final stat = await file.stat();
          await _db.upsertMediaFile(
            filePath: event.path,
            fileName: p.basenameWithoutExtension(event.path),
            fileExtension: ext.substring(1),
            fileSizeBytes: stat.size,
            libraryFolderId: folder.id,
            lastModified: stat.modified,
          );
        }
      }
    });
  }

  void unwatchFolder(int folderId) {
    _subscriptions[folderId]?.cancel();
    _subscriptions.remove(folderId);
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
