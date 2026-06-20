/// Metadata orchestration service.
///
/// Coordinates filename parsing -> TMDB search -> type resolution -> DB write.
/// Processes files sequentially with rate-limit awareness.
///
/// For TV episodes, uses a three-step lookup:
///   1. Search for the show via /search/tv
///   2. Fetch episode details via /tv/{id}/season/{s}/episode/{e}
///   3. Fetch season poster as fallback if episode has no still
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
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
  /// Parses the filename and routes to either TV or movie lookup.
  Future<void> fetchForFile(MediaFile file) async {
    debugPrint('[MetadataService] Fetching metadata for: "${file.fileName}"');
    final parsed = FilenameParser.parse(file.fileName);

    if (parsed.isTvShow) {
      debugPrint('[MetadataService] Parsed TV: title="${parsed.cleanTitle}" '
          'S${parsed.season!.toString().padLeft(2, '0')}'
          'E${parsed.episode!.toString().padLeft(2, '0')}');
      await _fetchTvMetadata(file, parsed);
    } else {
      debugPrint('[MetadataService] Parsed as: title="${parsed.cleanTitle}", '
          'year=${parsed.year}');
      await _fetchMovieMetadata(file, parsed);
    }
  }

  // Movie metadata (existing logic, unchanged)

  /// Fetch metadata for a movie file using multi-search.
  Future<void> _fetchMovieMetadata(MediaFile file, ParsedFilename parsed) async {
    TmdbSearchResult? result;
    try {
      // Try with year first for more accurate results
      if (parsed.year != null) {
        debugPrint('[MetadataService] Searching TMDB with year: '
            '"${parsed.cleanTitle}" (${parsed.year})');
        result = await _client.searchMulti(parsed.cleanTitle, year: parsed.year);
      }
      // If no result with year, try without
      if (result == null) {
        debugPrint('[MetadataService] Searching TMDB without year: '
            '"${parsed.cleanTitle}"');
        result = await _client.searchMulti(parsed.cleanTitle);
      }
    } on TmdbRateLimitException catch (e) {
      debugPrint('[MetadataService] Rate limit hit: ${e.retryAfterSeconds}s');
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Rate limited. Waiting ${e.retryAfterSeconds}s...',
      ));
      rethrow;
    } on TmdbAuthException {
      debugPrint('[MetadataService] Auth failure: Invalid TMDB API key');
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Invalid TMDB API key. Please check Settings.',
      ));
      rethrow;
    }

    if (result == null) {
      debugPrint('[MetadataService] No TMDB match found for: '
          '"${parsed.cleanTitle}"');
      await _db.markAsUncategorized(file.id);
      return;
    }

    debugPrint('[MetadataService] TMDB Match found: "${result.title}" '
        '(ID: ${result.id}, Type: ${result.mediaType})');

    final resolvedType = _resolveMediaType(result);
    final genreString = _client.resolveGenres(result.genreIds);

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

  // TV metadata (new three-step lookup)

  /// Fetch metadata for a TV episode file.
  ///
  /// Three-step TMDB lookup:
  ///   1. `/search/tv` for the series
  ///   2. `/tv/{id}/season/{s}/episode/{e}` for episode details
  ///   3. `/tv/{id}/season/{s}` for season poster fallback
  Future<void> _fetchTvMetadata(MediaFile file, ParsedFilename parsed) async {
    final season = parsed.season!;
    final episode = parsed.episode!;
    final seCode = 'S${season.toString().padLeft(2, '0')}'
        'E${episode.toString().padLeft(2, '0')}';

    // Step 1: Search for the TV series

    TmdbSearchResult? seriesResult;
    try {
      // Try English first
      debugPrint('[MetadataService] Searching TMDB TV: "${parsed.cleanTitle}"');
      seriesResult = await _client.searchTv(parsed.cleanTitle);

      // Fix 4: If no English results, retry with Japanese
      if (seriesResult == null) {
        debugPrint('[MetadataService] No English match, retrying with ja-JP: '
            '"${parsed.cleanTitle}"');
        seriesResult = await _client.searchTv(
          parsed.cleanTitle,
          language: 'ja-JP',
        );
      }
    } on TmdbRateLimitException catch (e) {
      debugPrint('[MetadataService] Rate limit hit: ${e.retryAfterSeconds}s');
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Rate limited. Waiting ${e.retryAfterSeconds}s...',
      ));
      rethrow;
    } on TmdbAuthException {
      debugPrint('[MetadataService] Auth failure: Invalid TMDB API key');
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Invalid TMDB API key. Please check Settings.',
      ));
      rethrow;
    }

    if (seriesResult == null) {
      debugPrint('[MetadataService] No TMDB TV match found for: '
          '"${parsed.cleanTitle}"');
      await _db.markAsUncategorized(file.id);
      return;
    }

    final seriesId = seriesResult.id;
    debugPrint('[MetadataService] TMDB series match: "${seriesResult.title}" '
        '(id: $seriesId)');

    // Step 2: Fetch episode details

    TmdbEpisodeResult? episodeResult;
    try {
      episodeResult = await _client.fetchEpisodeDetails(
        seriesId,
        season,
        episode,
      );
    } on TmdbRateLimitException {
      rethrow;
    } on TmdbAuthException {
      rethrow;
    } catch (e) {
      debugPrint('[MetadataService] Failed to fetch episode details for '
          '$seCode: $e');
      // Continue with series-level data only
    }

    // Step 3: Fetch season poster as fallback

    String? backdropPath = episodeResult?.stillPath;

    if (backdropPath == null) {
      try {
        final seasonResult = await _client.fetchSeasonDetails(
          seriesId,
          season,
        );
        backdropPath = seasonResult?.posterPath;
      } catch (e) {
        debugPrint('[MetadataService] Failed to fetch season poster for '
            'season $season: $e');
        // Use series backdrop as last resort
        backdropPath = seriesResult.backdropPath;
      }
    }

    // Build display title

    final episodeName = episodeResult?.name;
    final displayTitle = episodeName != null && episodeName.isNotEmpty
        ? '${seriesResult.title} - $seCode - $episodeName'
        : '${seriesResult.title} - $seCode';

    // Resolve type and genres

    final resolvedType = _resolveMediaType(seriesResult);
    final genreString = _client.resolveGenres(seriesResult.genreIds);

    // Write to database

    await _db.updateMetadata(
      fileId: file.id,
      tmdbId: seriesId,
      resolvedMediaType: resolvedType,
      tmdbTitle: displayTitle,
      overview: episodeResult?.overview ?? seriesResult.overview,
      posterPath: seriesResult.posterPath,
      backdropPath: backdropPath,
      releaseYear: episodeResult?.airYear ?? seriesResult.releaseYear,
      voteAverage: episodeResult?.voteAverage ?? seriesResult.voteAverage,
      genres: genreString.isNotEmpty ? genreString : null,
      originalLanguage: seriesResult.originalLanguage,
    );

    debugPrint('[MetadataService] Episode metadata saved: $seCode - '
        '"${episodeName ?? "unknown"}"');
  }

  // Batch processing

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
        // Invalid API key - stop the entire fetch
        _emitStatus(MetadataFetchStatus(
          isFetching: false,
          totalFiles: unmatched.length,
          processedFiles: i,
          errorMessage: 'Invalid TMDB API key. Please check Settings.',
        ));
        return;
      } catch (e) {
        debugPrint('[MetadataService] Error fetching metadata for '
            '"${unmatched[i].fileName}": $e');
        // Network error or other - mark this file as uncategorized, continue
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
