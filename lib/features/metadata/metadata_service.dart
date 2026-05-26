/// Metadata orchestration service.
///
/// Coordinates filename parsing → TMDB search → type resolution → DB write.
/// Processes files sequentially with rate-limit awareness.
library;

import 'dart:async';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart';

/// Status of an ongoing metadata fetch operation.
class MetadataFetchStatus {
  final bool isFetching;
  final int totalFiles;
  final int processedFiles;
  final String? errorMessage;

  const MetadataFetchStatus({
    this.isFetching = false,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.errorMessage,
  });

  int get remainingFiles => totalFiles - processedFiles;

  MetadataFetchStatus copyWith({
    bool? isFetching,
    int? totalFiles,
    int? processedFiles,
    String? errorMessage,
  }) {
    return MetadataFetchStatus(
      isFetching: isFetching ?? this.isFetching,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      errorMessage: errorMessage,
    );
  }

  static const idle = MetadataFetchStatus();
}

/// Orchestrates TMDB metadata fetching for media files.
class MetadataService {
  final AppDatabase _db;
  final TmdbClient _client;

  /// Stream controller to broadcast fetch status updates.
  final _statusController = StreamController<MetadataFetchStatus>.broadcast();

  /// Stream of fetch status updates for UI consumption.
  Stream<MetadataFetchStatus> get statusStream => _statusController.stream;

  MetadataFetchStatus _currentStatus = MetadataFetchStatus.idle;
  MetadataFetchStatus get currentStatus => _currentStatus;

  MetadataService({required AppDatabase db, required TmdbClient client})
      : _db = db,
        _client = client;

  /// Fetch metadata for a single media file.
  ///
  /// 1. Parse the filename to extract a clean title and year.
  /// 2. Search TMDB using multi-search.
  /// 3. Resolve the media type (movie/tv/anime/uncategorized).
  /// 4. Write metadata to the database.
  Future<void> fetchForFile(MediaFile file) async {
    print('[MetadataService] Fetching metadata for: "${file.fileName}"');
    final parsed = FilenameParser.parse(file.fileName);
    print('[MetadataService] Parsed as: title="${parsed.cleanTitle}", year=${parsed.year}');

    // Search TMDB
    TmdbSearchResult? result;
    try {
      // Try with year first for more accurate results
      if (parsed.year != null) {
        print('[MetadataService] Searching TMDB with year: "${parsed.cleanTitle}" (${parsed.year})');
        result = await _client.searchMulti(parsed.cleanTitle, year: parsed.year);
      }
      // If no result with year, try without
      if (result == null) {
        print('[MetadataService] Searching TMDB without year: "${parsed.cleanTitle}"');
        result = await _client.searchMulti(parsed.cleanTitle);
      }
    } on TmdbRateLimitException catch (e) {
      print('[MetadataService] Rate limit hit: ${e.retryAfterSeconds}s');
      // Re-throw for the caller to handle with retry logic
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Rate limited. Waiting ${e.retryAfterSeconds}s...',
      ));
      rethrow;
    } on TmdbAuthException {
      print('[MetadataService] Auth failure: Invalid TMDB API key');
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Invalid TMDB API key. Please check Settings.',
      ));
      rethrow;
    }

    if (result == null) {
      print('[MetadataService] No TMDB match found for: "${parsed.cleanTitle}"');
      // No match found — mark as uncategorized
      await _db.markAsUncategorized(file.id);
      return;
    }

    print('[MetadataService] TMDB Match found: "${result.title}" (ID: ${result.id}, Type: ${result.mediaType})');

    // Resolve media type
    final resolvedType = _resolveMediaType(result);

    // Build genre string
    final genreString = _client.resolveGenres(result.genreIds);

    // Write to database
    await _db.updateMetadata(
      fileId: file.id,
      tmdbId: result.id,
      resolvedMediaType: resolvedType,
      tmdbTitle: result.title,
      overview: result.overview,
      posterPath: result.posterPath,
      backdropPath: result.backdropPath,
      releaseYear: result.releaseYear,
      voteAverage: result.voteAverage,
      genres: genreString.isNotEmpty ? genreString : null,
      originalLanguage: result.originalLanguage,
    );
  }

  /// Fetch metadata for all unmatched files in the library.
  ///
  /// Processes sequentially with a ~250ms delay between requests
  /// to stay within TMDB rate limits. Handles rate limit errors
  /// gracefully with automatic retry.
  Future<void> fetchAllUnmatched() async {
    final unmatched = await _db.getUnmatchedMediaFiles();
    if (unmatched.isEmpty) return;

    _emitStatus(MetadataFetchStatus(
      isFetching: true,
      totalFiles: unmatched.length,
      processedFiles: 0,
    ));

    for (var i = 0; i < unmatched.length; i++) {
      try {
        await fetchForFile(unmatched[i]);
      } on TmdbRateLimitException catch (e) {
        // Wait for the rate limit to expire, then retry this file
        await Future<void>.delayed(Duration(seconds: e.retryAfterSeconds + 1));
        try {
          await fetchForFile(unmatched[i]);
        } catch (_) {
          // If it still fails, mark as uncategorized and move on
          await _db.markAsUncategorized(unmatched[i].id);
        }
      } on TmdbAuthException {
        // Invalid API key — stop the entire fetch
        _emitStatus(MetadataFetchStatus(
          isFetching: false,
          totalFiles: unmatched.length,
          processedFiles: i,
          errorMessage: 'Invalid TMDB API key. Please check Settings.',
        ));
        return;
      } catch (e) {
        print('[MetadataService] Error fetching metadata for "${unmatched[i].fileName}": $e');
        // Network error or other — mark this file as uncategorized, continue
        await _db.markAsUncategorized(unmatched[i].id);
        _emitStatus(_currentStatus.copyWith(
          errorMessage: 'Error fetching metadata: $e',
        ));
      }

      _emitStatus(MetadataFetchStatus(
        isFetching: true,
        totalFiles: unmatched.length,
        processedFiles: i + 1,
      ));

      // Rate-limit delay (skip on last item)
      if (i < unmatched.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    _emitStatus(MetadataFetchStatus(
      isFetching: false,
      totalFiles: unmatched.length,
      processedFiles: unmatched.length,
    ));
  }

  /// Clear all metadata and re-fetch everything.
  Future<void> refreshAll() async {
    await _db.clearAllMetadata();
    await fetchAllUnmatched();
  }

  /// Resolve a TMDB search result to our internal media type.
  ///
  /// Anime = Animation genre (16) + Japanese original language.
  String _resolveMediaType(TmdbSearchResult result) {
    final isAnimation = result.genreIds.contains(kAnimationGenreId);
    final isJapanese = result.originalLanguage == 'ja';

    if (isAnimation && isJapanese) {
      return 'anime';
    }

    return result.mediaType == 'tv' ? 'tv' : 'movie';
  }

  void _emitStatus(MetadataFetchStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }
}
