/// FluxPlayer SQLite database powered by Drift.
///
/// Aggregates all table definitions and exposes typed query methods
/// for library folders and media files. Uses `drift_flutter` for
/// cross-platform database initialization.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_video/core/database/tables.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';

part 'database.g.dart';

@DriftDatabase(tables: [LibraryFolders, MediaFiles, WatchProgresses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Named constructor for testing / overrides.
  AppDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fluxplayer');
  }

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(mediaFiles, mediaFiles.durationMillis);
          await m.addColumn(mediaFiles, mediaFiles.positionMillis);
        }
        if (from < 3) {
          await m.addColumn(mediaFiles, mediaFiles.tmdbId);
          await m.addColumn(mediaFiles, mediaFiles.mediaType);
          await m.addColumn(mediaFiles, mediaFiles.tmdbTitle);
          await m.addColumn(mediaFiles, mediaFiles.overview);
          await m.addColumn(mediaFiles, mediaFiles.posterPath);
          await m.addColumn(mediaFiles, mediaFiles.backdropPath);
          await m.addColumn(mediaFiles, mediaFiles.releaseYear);
          await m.addColumn(mediaFiles, mediaFiles.voteAverage);
          await m.addColumn(mediaFiles, mediaFiles.genres);
          await m.addColumn(mediaFiles, mediaFiles.originalLanguage);
        }
        if (from < 4) {
          await m.addColumn(mediaFiles, mediaFiles.lastWatchedAt);
        }
        if (from < 5) {
          final columns = await customSelect("PRAGMA table_info('media_files');")
              .map((row) => row.read<String>('name'))
              .get();
          if (!columns.contains('metadata_overridden')) {
            await m.addColumn(mediaFiles, mediaFiles.metadataOverridden);
          }
        }
        if (from < 6) {
          await m.addColumn(libraryFolders, libraryFolders.isAvailable);
          await m.addColumn(libraryFolders, libraryFolders.lastSeenAt);
          // Backfill: all existing folders are assumed available with
          // lastSeenAt = now so pre-upgrade data is preserved.
          await customStatement(
            "UPDATE library_folders SET is_available = 1, last_seen_at = strftime('%s', 'now') * 1000"
          );
        }
        if (from < 7) {
          await m.addColumn(mediaFiles, mediaFiles.metadataStatus);
          await m.addColumn(mediaFiles, mediaFiles.lastAttemptAt);
          // Migrate existing rows:
          // - tmdbId = -1 becomes 'notFound'
          // - tmdbId IS NOT NULL AND tmdbId > 0 becomes 'matched'
          // - otherwise 'pending'
          // Clear -1 sentinel from tmdb_id to NULL
          await customStatement('''
            UPDATE media_files SET 
              metadata_status = CASE 
                WHEN tmdb_id = -1 THEN 'notFound'
                WHEN tmdb_id IS NOT NULL AND tmdb_id > 0 THEN 'matched'
                ELSE 'pending'
              END,
              last_attempt_at = CASE
                WHEN tmdb_id IS NOT NULL THEN strftime('%s', 'now') * 1000
                ELSE NULL
              END,
              tmdb_id = CASE WHEN tmdb_id = -1 THEN NULL ELSE tmdb_id END
          ''');
        }
        if (from < 8) {
          await m.addColumn(mediaFiles, mediaFiles.seasonNumber);
          await m.addColumn(mediaFiles, mediaFiles.episodeNumber);
          await m.addColumn(mediaFiles, mediaFiles.seriesTitle);
          await customStatement('DROP INDEX IF EXISTS idx_media_filepath;');

          // Backfill existing rows by parsing existing tmdbTitle / fileName once:
          final rows = await customSelect(
            'SELECT id, file_name, tmdb_title, media_type FROM media_files',
          ).get();

          for (final row in rows) {
            final id = row.read<int>('id');
            final fileName = row.read<String>('file_name');
            final tmdbTitle = row.readNullable<String>('tmdb_title');
            final mediaType = row.readNullable<String>('media_type');

            if (mediaType == 'tv' || mediaType == 'anime') {
              int? season;
              int? episode;
              String? showTitle;

              if (tmdbTitle != null) {
                final seMatch = RegExp(r'S(\d+)E(\d+)').firstMatch(tmdbTitle);
                if (seMatch != null) {
                  season = int.tryParse(seMatch.group(1)!);
                  episode = int.tryParse(seMatch.group(2)!);
                }
                final titleMatch =
                    RegExp(r'^(.+?)\s*-\s*S\d+E\d+').firstMatch(tmdbTitle);
                if (titleMatch != null) {
                  showTitle = titleMatch.group(1)!.trim();
                }
              }

              // Fallback to FilenameParser
              if (season == null || episode == null || showTitle == null) {
                final parsed = FilenameParser.parse(fileName);
                season ??= parsed.season;
                episode ??= parsed.episode;
                showTitle ??= parsed.cleanTitle;
              }

              await customStatement(
                'UPDATE media_files SET season_number = ?, episode_number = ?, series_title = ? WHERE id = ?',
                [season, episode, showTitle, id],
              );
            }
          }
        }
        if (from < 9) {
          await m.createTable(watchProgresses);
          // Migrate existing watch progress values from media_files:
          await customStatement('''
            INSERT OR IGNORE INTO watch_progresses (file_id, position_millis, duration_millis, last_watched_at)
            SELECT id, position_millis, duration_millis, last_watched_at
            FROM media_files
            WHERE position_millis IS NOT NULL OR last_watched_at IS NOT NULL;
          ''');
        }
      },
    );
  }

  // Library Folder queries

  /// Watch all library folders, ordered by when they were added.
  Stream<List<LibraryFolder>> watchAllLibraryFolders() {
    return (select(libraryFolders)
          ..orderBy([(t) => OrderingTerm.asc(t.addedAt)]))
        .watch();
  }

  /// Get all library folders synchronously.
  Future<List<LibraryFolder>> getAllLibraryFolders() {
    return (select(libraryFolders)
          ..orderBy([(t) => OrderingTerm.asc(t.addedAt)]))
        .get();
  }

  /// Insert a new library folder. Returns the inserted row's id.
  Future<int> insertLibraryFolder(String path, {String? label}) {
    return into(libraryFolders).insert(
      LibraryFoldersCompanion.insert(
        path: path,
        label: Value(label),
      ),
    );
  }

  /// Delete a library folder and all its associated media files atomically.
  Future<void> removeLibraryFolder(int folderId) async {
    await transaction(() async {
      await removeMediaFilesByFolder(folderId);
      await (delete(libraryFolders)..where((t) => t.id.equals(folderId))).go();
    });
  }

  /// Mark a library folder as unavailable (drive disconnected, path missing).
  /// Preserves all media rows and their watch progress.
  Future<void> markFolderUnavailable(int folderId) async {
    await (update(libraryFolders)..where((t) => t.id.equals(folderId))).write(
      const LibraryFoldersCompanion(
        isAvailable: Value(false),
      ),
    );
  }

  /// Mark a library folder as available and update its last-seen timestamp.
  Future<void> markFolderAvailable(int folderId) async {
    await (update(libraryFolders)..where((t) => t.id.equals(folderId))).write(
      LibraryFoldersCompanion(
        isAvailable: const Value(true),
        lastSeenAt: Value(DateTime.now()),
      ),
    );
  }

  // Media File queries

  /// Watch all media files, ordered by filename.
  Stream<List<MediaFile>> watchAllMediaFiles() {
    return (select(mediaFiles)
          ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
        .watch();
  }

  /// Watch recently added files (most recent first), with an optional limit.
  Stream<List<MediaFile>> watchRecentlyAdded({int limit = 20}) {
    return (select(mediaFiles)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])
          ..limit(limit))
        .watch();
  }

  /// Get the count of media files for a specific folder.
  Future<int> countFilesInFolder(int folderId) async {
    final query = selectOnly(mediaFiles)
      ..addColumns([mediaFiles.id.count()])
      ..where(mediaFiles.libraryFolderId.equals(folderId));
    final result = await query.getSingle();
    return result.read(mediaFiles.id.count()) ?? 0;
  }

  /// Upsert a media file. If a file with the same path already exists,
  /// update its metadata; otherwise insert a new row.
  Future<void> upsertMediaFile({
    required String filePath,
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    required int libraryFolderId,
    required DateTime lastModified,
  }) {
    // Note: Do not overwrite durationMillis and positionMillis if updating.
    final companion = MediaFilesCompanion.insert(
      filePath: filePath,
      fileName: fileName,
      fileExtension: fileExtension,
      fileSizeBytes: BigInt.from(fileSizeBytes),
      libraryFolderId: libraryFolderId,
      lastModified: lastModified,
    );
    return into(mediaFiles).insert(
      companion,
      onConflict: DoUpdate(
        (old) => companion,
        target: [mediaFiles.filePath],
      ),
    );
  }

  /// Bulk upsert multiple media files using a single batch transaction.
  Future<void> upsertMediaFilesBatch(List<MediaFilesCompanion> companions) async {
    await batch((b) {
      for (final companion in companions) {
        b.insert(
          mediaFiles,
          companion,
          onConflict: DoUpdate(
            (old) => companion,
            target: [mediaFiles.filePath],
          ),
        );
      }
    });
  }

  /// Updates the watch progress for a specific file.
  Future<void> updateWatchProgress(int fileId, int positionMillis, int durationMillis) async {
    final now = DateTime.now();
    await into(watchProgresses).insertOnConflictUpdate(
      WatchProgressesCompanion(
        fileId: Value(fileId),
        positionMillis: Value(positionMillis),
        durationMillis: Value(durationMillis),
        lastWatchedAt: Value(now),
      ),
    );
    // Keep media_files in sync without blocking the stream optimization
    await (update(mediaFiles)..where((t) => t.id.equals(fileId))).write(
      MediaFilesCompanion(
        positionMillis: Value(positionMillis),
        durationMillis: Value(durationMillis),
        lastWatchedAt: Value(now),
      ),
    );
  }

  /// Batch marks a list of files as watched.
  Future<void> markAsWatched(List<int> fileIds) async {
    if (fileIds.isEmpty) return;
    final now = DateTime.now();
    for (final id in fileIds) {
      await customStatement('''
        INSERT INTO watch_progresses (file_id, position_millis, duration_millis, last_watched_at)
        SELECT id, 
               CASE WHEN duration_millis IS NULL OR duration_millis = 0 THEN 1 ELSE duration_millis END,
               duration_millis,
               ?
        FROM media_files WHERE id = ?
        ON CONFLICT(file_id) DO UPDATE SET
          position_millis = excluded.position_millis,
          last_watched_at = excluded.last_watched_at
      ''', [now.millisecondsSinceEpoch, id]);
    }
    await (update(mediaFiles)..where((t) => t.id.isIn(fileIds))).write(
      MediaFilesCompanion.custom(
        positionMillis: const CustomExpression('CASE WHEN duration_millis IS NULL OR duration_millis = 0 THEN 1 ELSE duration_millis END'),
        lastWatchedAt: Variable(now),
      ),
    );
  }

  /// Batch marks a list of files as unwatched.
  Future<void> markAsUnwatched(List<int> fileIds) async {
    if (fileIds.isEmpty) return;
    await (delete(watchProgresses)..where((t) => t.fileId.isIn(fileIds))).go();
    await (update(mediaFiles)..where((t) => t.id.isIn(fileIds))).write(
      const MediaFilesCompanion(
        positionMillis: Value(0),
        lastWatchedAt: Value(null),
      ),
    );
  }

  /// Watch all watch progress records from the isolated [watchProgresses] table.
  Stream<List<WatchProgresse>> watchAllWatchProgress() {
    return select(watchProgresses).watch();
  }

  /// Remove a single media file by its path.
  Future<void> removeMediaFileByPath(String path) async {
    await (delete(mediaFiles)..where((t) => t.filePath.equals(path))).go();
  }

  /// Bulk remove media files by their paths using chunked isIn.
  Future<void> removeMediaFilesByPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    const chunkSize = 100;
    for (var i = 0; i < paths.length; i += chunkSize) {
      final chunk = paths.skip(i).take(chunkSize).toList();
      await (delete(mediaFiles)..where((t) => t.filePath.isIn(chunk))).go();
    }
  }

  /// Remove all media files belonging to a specific library folder.
  Future<void> removeMediaFilesByFolder(int folderId) async {
    await (delete(mediaFiles)
          ..where((t) => t.libraryFolderId.equals(folderId)))
        .go();
  }

  /// Get all file paths for a folder (used during scan to detect stale entries).
  /// Uses selectOnly to avoid loading and deserializing unused columns.
  Future<List<String>> getFilePathsForFolder(int folderId) async {
    final query = selectOnly(mediaFiles)
      ..addColumns([mediaFiles.filePath])
      ..where(mediaFiles.libraryFolderId.equals(folderId));
    final rows = await query.get();
    return rows.map((r) => r.read(mediaFiles.filePath)!).toList();
  }

  /// Get a map of filePath -> (size, modified) for all files in a folder.
  /// Allows the scanner to skip unchanged files without rewriting database rows.
  Future<Map<String, ({BigInt size, DateTime modified})>> getFileStatMapForFolder(int folderId) async {
    final query = selectOnly(mediaFiles)
      ..addColumns([mediaFiles.filePath, mediaFiles.fileSizeBytes, mediaFiles.lastModified])
      ..where(mediaFiles.libraryFolderId.equals(folderId));
    final rows = await query.get();
    return {
      for (final r in rows)
        r.read(mediaFiles.filePath)!: (
          size: r.read(mediaFiles.fileSizeBytes)!,
          modified: r.read(mediaFiles.lastModified)!,
        ),
    };
  }

  // Metadata queries

  /// Get media files that need TMDB metadata lookup, excluding manually overridden files.
  /// Does not re-query 'notFound' files unless they exceed [notFoundBackoff] (default 7 days).
  /// Pending files and files in 'error' state are always queried.
  Future<List<MediaFile>> getUnmatchedMediaFiles({
    Duration notFoundBackoff = const Duration(days: 7),
  }) {
    final cutoff = DateTime.now().subtract(notFoundBackoff);
    return (select(mediaFiles)
          ..where((t) =>
              t.metadataOverridden.equals(false) &
              (t.metadataStatus.isNull() |
                  t.metadataStatus.equals('pending') |
                  t.metadataStatus.equals('error') |
                  (t.metadataStatus.equals('notFound') &
                      (t.lastAttemptAt.isNull() |
                          t.lastAttemptAt.isSmallerOrEqualValue(cutoff))))))
        .get();
  }

  /// Get all media files eligible for full refresh (all files not manually overridden).
  Future<List<MediaFile>> getAllRefreshableMediaFiles() {
    return (select(mediaFiles)
          ..where((t) => t.metadataOverridden.equals(false)))
        .get();
  }

  /// Update TMDB metadata for a specific media file.
  Future<void> updateMetadata({
    required int fileId,
    required int tmdbId,
    required String resolvedMediaType,
    String? tmdbTitle,
    String? overview,
    String? posterPath,
    String? backdropPath,
    int? releaseYear,
    double? voteAverage,
    String? genres,
    String? originalLanguage,
    bool? metadataOverridden,
    int? seasonNumber,
    int? episodeNumber,
    String? seriesTitle,
  }) async {
    await (update(mediaFiles)..where((t) => t.id.equals(fileId))).write(
      MediaFilesCompanion(
        tmdbId: Value(tmdbId),
        mediaType: Value(resolvedMediaType),
        tmdbTitle: Value(tmdbTitle),
        overview: Value(overview),
        posterPath: Value(posterPath),
        backdropPath: Value(backdropPath),
        releaseYear: Value(releaseYear),
        voteAverage: Value(voteAverage),
        genres: Value(genres),
        originalLanguage: Value(originalLanguage),
        metadataStatus: const Value('matched'),
        lastAttemptAt: Value(DateTime.now()),
        seasonNumber: Value(seasonNumber),
        episodeNumber: Value(episodeNumber),
        seriesTitle: Value(seriesTitle),
        metadataOverridden: metadataOverridden != null
            ? Value(metadataOverridden)
            : const Value.absent(),
      ),
    );
  }

  /// Mark a file as notFound (TMDB search completed but no match was found).
  Future<void> markAsNotFound(int fileId) async {
    await (update(mediaFiles)..where((t) => t.id.equals(fileId))).write(
      MediaFilesCompanion(
        tmdbId: const Value(null),
        mediaType: const Value('uncategorized'),
        metadataStatus: const Value('notFound'),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark a file as error (transient network or server failure).
  /// Preserves any existing metadata so failed refreshes don't lose data.
  Future<void> markAsError(int fileId) async {
    await (update(mediaFiles)..where((t) => t.id.equals(fileId))).write(
      MediaFilesCompanion(
        metadataStatus: const Value('error'),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deprecated: use [markAsNotFound] instead.
  Future<void> markAsUncategorized(int fileId) => markAsNotFound(fileId);

  /// Clear all metadata (for re-fetch), preserving files marked with metadataOverridden.
  Future<void> clearAllMetadata() async {
    await (update(mediaFiles)
          ..where((t) => t.metadataOverridden.equals(false)))
        .write(
      const MediaFilesCompanion(
        tmdbId: Value(null),
        mediaType: Value(null),
        tmdbTitle: Value(null),
        overview: Value(null),
        posterPath: Value(null),
        backdropPath: Value(null),
        releaseYear: Value(null),
        voteAverage: Value(null),
        genres: Value(null),
        originalLanguage: Value(null),
      ),
    );
  }
}

/// Extension providing domain helpers on [MediaFile].
extension MediaFileX on MediaFile {
  /// Whether this file is part of a TV or anime series.
  bool get isSeries => mediaType == 'tv' || mediaType == 'anime';
}
