/// FluxPlayer SQLite database powered by Drift.
///
/// Aggregates all table definitions and exposes typed query methods
/// for library folders and media files. Uses `drift_flutter` for
/// cross-platform database initialization.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_video/core/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [LibraryFolders, MediaFiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Named constructor for testing / overrides.
  AppDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fluxplayer');
  }

  @override
  int get schemaVersion => 4;

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
      },
    );
  }

  // ─── Library Folder queries ─────────────────────────────────────────────

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

  /// Delete a library folder and all its associated media files.
  Future<void> removeLibraryFolder(int folderId) async {
    // Delete child media files first.
    await (delete(mediaFiles)
          ..where((t) => t.libraryFolderId.equals(folderId)))
        .go();
    // Then delete the folder row.
    await (delete(libraryFolders)..where((t) => t.id.equals(folderId))).go();
  }

  // ─── Media File queries ─────────────────────────────────────────────────

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
    return into(mediaFiles).insertOnConflictUpdate(
      MediaFilesCompanion.insert(
        filePath: filePath,
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: BigInt.from(fileSizeBytes),
        libraryFolderId: libraryFolderId,
        lastModified: lastModified,
      ),
    );
  }

  /// Updates the watch progress for a specific file.
  ///
  /// Also stamps [lastWatchedAt] so the Continue Watching section can
  /// determine which episode was interacted with most recently.
  Future<void> updateWatchProgress(int fileId, int positionMillis, int durationMillis) async {
    await (update(mediaFiles)..where((t) => t.id.equals(fileId))).write(
      MediaFilesCompanion(
        positionMillis: Value(positionMillis),
        durationMillis: Value(durationMillis),
        lastWatchedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Remove a single media file by its path.
  Future<void> removeMediaFileByPath(String path) async {
    await (delete(mediaFiles)..where((t) => t.filePath.equals(path))).go();
  }

  /// Remove all media files belonging to a specific library folder.
  Future<void> removeMediaFilesByFolder(int folderId) async {
    await (delete(mediaFiles)
          ..where((t) => t.libraryFolderId.equals(folderId)))
        .go();
  }

  /// Get all file paths for a folder (used during scan to detect stale entries).
  Future<List<String>> getFilePathsForFolder(int folderId) async {
    final query = select(mediaFiles)
      ..where((t) => t.libraryFolderId.equals(folderId));
    final rows = await query.get();
    return rows.map((r) => r.filePath).toList();
  }

  // ─── Phase 4: Metadata queries ──────────────────────────────────────────

  /// Get all media files that have not been matched to TMDB yet (or failed previously).
  Future<List<MediaFile>> getUnmatchedMediaFiles() {
    return (select(mediaFiles)
          ..where((t) => t.tmdbId.isNull() | t.tmdbId.equals(-1)))
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
      ),
    );
  }

  /// Mark a file as uncategorized (no TMDB match found).
  /// Sets tmdbId to -1 so it won't be retried automatically.
  Future<void> markAsUncategorized(int fileId) async {
    await (update(mediaFiles)..where((t) => t.id.equals(fileId))).write(
      const MediaFilesCompanion(
        tmdbId: Value(-1),
        mediaType: Value('uncategorized'),
      ),
    );
  }

  /// Clear all metadata (for re-fetch).
  Future<void> clearAllMetadata() async {
    await (update(mediaFiles)).write(
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
