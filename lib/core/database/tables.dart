/// Drift table definitions for the FluxPlayer database.
///
/// Tables:
///   - [LibraryFolders] - user-configured root directories to scan
///   - [MediaFiles] - individual video files discovered by the scanner,
///     with optional TMDB metadata columns
library;

import 'package:drift/drift.dart';

// Library Folders

/// Stores the root directories the user has added to their media library.
/// Each folder is scanned recursively for video files.
class LibraryFolders extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Absolute path to the folder (e.g. `/mnt/media/movies`).
  TextColumn get path => text().unique()();

  /// Optional user-friendly label (e.g. "NAS Movies").
  TextColumn get label => text().nullable()();

  /// When this folder was first added.
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  /// Whether the folder is currently accessible on disk.
  /// When a folder becomes inaccessible (e.g. NAS disconnected, drive
  /// unmounted), this is set to `false` and its media rows are preserved.
  /// Only an explicit "remove folder" action deletes rows.
  BoolColumn get isAvailable =>
      boolean().withDefault(const Constant(true))();

  /// Timestamp of the last time the folder was successfully seen on disk
  /// during a scan or prune operation.
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
}

// Media Files

/// Stores every video file discovered inside a [LibraryFolder].
/// Each row represents a single playable file on disk.
@TableIndex(name: 'idx_media_folder', columns: {#libraryFolderId})
@TableIndex(name: 'idx_media_tmdb', columns: {#tmdbId})
class MediaFiles extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Full absolute path to the file.
  TextColumn get filePath => text().unique()();

  /// Basename without extension (used as display title until TMDB metadata).
  TextColumn get fileName => text()();

  /// File extension without the dot (e.g. `mkv`, `mp4`).
  TextColumn get fileExtension => text()();

  /// File size in bytes.
  Int64Column get fileSizeBytes => int64()();

  /// Foreign key to the parent library folder.
  IntColumn get libraryFolderId =>
      integer().references(LibraryFolders, #id)();

  /// When this file was first discovered by the scanner.
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  /// Last-modified time from the filesystem.
  DateTimeColumn get lastModified => dateTime()();

  /// Total duration of the media in milliseconds.
  IntColumn get durationMillis => integer().nullable()();

  /// Last watched position in milliseconds.
  IntColumn get positionMillis => integer().nullable()();

  /// Timestamp of the last time the user watched this file.
  /// Updated on every pause/stop so the Continue Watching section can
  /// determine the most recently watched episode within a TV series.
  DateTimeColumn get lastWatchedAt => dateTime().nullable()();

  // TMDB metadata columns

  /// TMDB ID for this media. Non-null means metadata has been matched.
  IntColumn get tmdbId => integer().nullable()();

  /// Resolved media type: 'movie', 'tv', 'anime', or 'uncategorized'.
  TextColumn get mediaType => text().nullable()();

  /// TMDB display title (falls back to [fileName] in the UI).
  TextColumn get tmdbTitle => text().nullable()();

  /// Plot synopsis from TMDB.
  TextColumn get overview => text().nullable()();

  /// TMDB poster path (e.g. `/abc123.jpg`). Combine with base URL to get full URL.
  TextColumn get posterPath => text().nullable()();

  /// TMDB backdrop path. Combine with base URL to get full URL.
  TextColumn get backdropPath => text().nullable()();

  /// Release year extracted from TMDB release_date / first_air_date.
  IntColumn get releaseYear => integer().nullable()();

  /// TMDB vote average (0.0-10.0).
  RealColumn get voteAverage => real().nullable()();

  /// Comma-separated genre names (e.g. "Action,Sci-Fi,Drama").
  TextColumn get genres => text().nullable()();

  /// Original language code from TMDB (e.g. "en", "ja").
  TextColumn get originalLanguage => text().nullable()();

  /// Whether this file's metadata was manually overridden by the user.
  /// If true, auto-scans and library refresh will not touch this file.
  BoolColumn get metadataOverridden =>
      boolean().withDefault(const Constant(false))();

  /// Status of TMDB metadata resolution: 'pending', 'matched', 'notFound', 'error'.
  TextColumn get metadataStatus =>
      text().withDefault(const Constant('pending'))();

  /// Timestamp of the last metadata fetch attempt.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Season number if this file is part of a TV or anime series.
  IntColumn get seasonNumber => integer().nullable()();

  /// Episode number if this file is part of a TV or anime series.
  IntColumn get episodeNumber => integer().nullable()();

  /// Title of the series if this file is part of a TV or anime series.
  TextColumn get seriesTitle => text().nullable()();
}

// Watch Progress

/// Stores playback progress for media files in an isolated table.
/// Kept separate from [MediaFiles] so periodic progress writes do not
/// re-emit the entire library media files stream.
class WatchProgresses extends Table {
  /// Foreign key to the media file being tracked.
  IntColumn get fileId =>
      integer().references(MediaFiles, #id, onDelete: KeyAction.cascade)();

  /// Last watched position in milliseconds.
  IntColumn get positionMillis => integer().nullable()();

  /// Total duration of the media in milliseconds.
  IntColumn get durationMillis => integer().nullable()();

  /// Timestamp of the last time the user watched this file.
  DateTimeColumn get lastWatchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {fileId};
}
