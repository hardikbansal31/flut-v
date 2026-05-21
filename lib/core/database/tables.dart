/// Drift table definitions for the FluxPlayer database.
///
/// Phase 2 tables:
///   - [LibraryFolders] — user-configured root directories to scan
///   - [MediaFiles] — individual video files discovered by the scanner
library;

import 'package:drift/drift.dart';

// ─── Library Folders ────────────────────────────────────────────────────────

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
}

// ─── Media Files ────────────────────────────────────────────────────────────

/// Stores every video file discovered inside a [LibraryFolder].
/// Each row represents a single playable file on disk.
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

  /// Total duration of the media in milliseconds (Phase 3).
  IntColumn get durationMillis => integer().nullable()();

  /// Last watched position in milliseconds (Phase 3).
  IntColumn get positionMillis => integer().nullable()();
}
