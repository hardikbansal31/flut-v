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
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart';
import 'package:http/http.dart' as http;

/// Known alias table for recurring franchise / spin-off / reboot collisions.
const Map<String, int> knownTitleOverrides = {
  'bleach thousand-year blood war': 213669,
  'bleach thousand year blood war': 213669,
  'bleach tybw': 213669,
  'bleach sennen kessen hen': 213669,
  'bleach': 30984,
  'avatar the last airbender': 246, // animated series
  'avatar': 246,
  'one piece': 37854, // animated series
  'fullmetal alchemist brotherhood': 31911,
  'fma brotherhood': 31911,
  'fullmetal alchemist': 406,
  'hunter x hunter': 46298, // 2011 series
};

/// Normalizes a title or token string for comparison.
String normalizeTitle(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Extracts folder-level context (e.g. show directory name) from a file path.
///
/// Skips season directories (e.g. "Season 1", "S01", "Specials") to find
/// the parent show directory.
String? extractShowFolderName(String filePath) {
  final normalized = filePath.replaceAll(r'\', '/');
  final parts = normalized.split('/');
  if (parts.length < 2) return null;

  // Drop the filename itself
  final dirParts = parts.sublist(0, parts.length - 1);
  if (dirParts.isEmpty) return null;

  // Pattern for season or special subfolders
  final seasonDirPattern = RegExp(
    r'^(season\s*\d+|s\d+|specials|extra[s]?)$',
    caseSensitive: false,
  );

  int idx = dirParts.length - 1;
  while (idx >= 0 && seasonDirPattern.hasMatch(dirParts[idx].trim())) {
    idx--;
  }

  if (idx < 0) return null;
  final candidate = dirParts[idx].trim();
  if (candidate.isEmpty) return null;
  return candidate;
}

/// Score a TMDB TV candidate based on title similarity, anime/live-action
/// signals from filename/folder, and release year proximity.
double scoreTvCandidate({
  required TmdbSearchResult candidate,
  required String query,
  required String rawFileName,
  String? folderName,
  int? targetYear,
}) {
  double score = 0.0;
  final normQuery = normalizeTitle(query);
  final normCandTitle = normalizeTitle(candidate.title);

  // 1. Exact or partial title match
  if (normCandTitle == normQuery) {
    score += 100.0;
  } else if (normCandTitle.startsWith(normQuery) || normQuery.startsWith(normCandTitle)) {
    score += 50.0;
  } else if (normCandTitle.contains(normQuery) || normQuery.contains(normCandTitle)) {
    score += 30.0;
  }

  // Length discrepancy penalty
  final lenDiff = (normCandTitle.length - normQuery.length).abs();
  score -= (lenDiff * 0.5).clamp(0.0, 20.0);

  // 2. Anime vs live-action context signals
  final combinedContext = '${folderName ?? ''} $rawFileName'.toLowerCase();

  final hasBracketGroup = RegExp(r'\[[^\]]+\]').hasMatch(rawFileName);
  final hasAnimeKeywords = RegExp(
    r'\b(anime|dub|sub|subbed|dubbed|dual[\s_-]?audio|fansub|raws?)\b',
    caseSensitive: false,
  ).hasMatch(combinedContext);
  final isAnimeContext = hasBracketGroup || hasAnimeKeywords;

  final hasLiveActionKeywords = RegExp(
    r'\b(remux|web-?dl|bluray|live[\s_-]?action)\b',
    caseSensitive: false,
  ).hasMatch(combinedContext);
  final isLiveActionContext = hasLiveActionKeywords && !isAnimeContext;

  final isCandAnimation = candidate.genreIds.contains(kAnimationGenreId);
  final isCandAnime = isCandAnimation &&
      (candidate.originCountry.contains('JP') || candidate.originalLanguage == 'ja');

  if (isAnimeContext) {
    if (isCandAnime) {
      score += 50.0;
    } else if (isCandAnimation) {
      score += 30.0;
    } else if (candidate.originCountry.contains('JP')) {
      score += 25.0;
    } else {
      score -= 40.0; // Deprioritize non-animated entries for anime files
    }
  } else if (isLiveActionContext) {
    if (isCandAnimation) {
      score -= 40.0; // Deprioritize animated results for live-action files
    } else {
      score += 20.0;
    }
  }

  // 3. Year matching
  if (targetYear != null && candidate.releaseYear != null) {
    final diff = (candidate.releaseYear! - targetYear).abs();
    if (diff == 0) {
      score += 50.0;
    } else if (diff == 1) {
      score += 25.0;
    } else {
      score -= (diff * 10.0).clamp(0.0, 40.0);
    }
  }

  // 4. Rating tie-breaker
  score += (candidate.voteAverage * 0.5);

  return score;
}

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

  /// In-memory cache for TV series search results to avoid redundant API hits for multi-episode scans.
  final Map<String, TmdbSearchResult?> _tvSearchCache = {};

  /// Re-entrancy guard to ensure concurrent fetch runs are prevented / awaited.
  Future<void>? _activeFetch;

  MetadataService({required AppDatabase db, required TmdbClient client})
      : _db = db,
        _client = client;

  /// Fetch metadata for a single media file.
  ///
  /// Parses the filename and routes to either TV or movie lookup.
  Future<void> fetchForFile(MediaFile file) async {
    if (file.metadataOverridden) {
      developer.log(
        'Skipping file "${file.fileName}" (manually overridden)',
        name: 'MetadataService',
      );
      return;
    }

    developer.log(
      'Fetching metadata for: "${file.fileName}"',
      name: 'MetadataService',
    );
    final parsed = FilenameParser.parse(file.fileName);

    if (parsed.isTvShow) {
      developer.log(
        'Parsed TV: title="${parsed.cleanTitle}" '
        'S${parsed.season!.toString().padLeft(2, '0')}'
        'E${parsed.episode!.toString().padLeft(2, '0')}',
        name: 'MetadataService',
      );
      await _fetchTvMetadata(file, parsed);
    } else {
      developer.log(
        'Parsed as: title="${parsed.cleanTitle}", year=${parsed.year}',
        name: 'MetadataService',
      );
      await _fetchMovieMetadata(file, parsed);
    }
  }

  // Movie metadata

  /// Fetch metadata for a movie file using multi-search.
  Future<void> _fetchMovieMetadata(MediaFile file, ParsedFilename parsed) async {
    TmdbSearchResult? result;
    try {
      // Try with year first for more accurate results
      if (parsed.year != null) {
        developer.log(
          'Searching TMDB with year: "${parsed.cleanTitle}" (${parsed.year})',
          name: 'MetadataService',
        );
        result = await _client.searchMulti(parsed.cleanTitle, year: parsed.year);
      }
      // If no result with year, try without
      if (result == null) {
        developer.log(
          'Searching TMDB without year: "${parsed.cleanTitle}"',
          name: 'MetadataService',
        );
        result = await _client.searchMulti(parsed.cleanTitle);
      }
    } on TmdbRateLimitException catch (e) {
      developer.log(
        'Rate limit hit: ${e.retryAfterSeconds}s',
        name: 'MetadataService',
        level: 900,
      );
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Rate limited. Waiting ${e.retryAfterSeconds}s...',
      ));
      rethrow;
    } on TmdbAuthException {
      developer.log(
        'Auth failure: Invalid TMDB API key',
        name: 'MetadataService',
        level: 900,
      );
      _emitStatus(_currentStatus.copyWith(
        errorMessage: 'Invalid TMDB API key. Please check Settings.',
      ));
      rethrow;
    }

    if (result == null) {
      developer.log(
        'No TMDB match found for: "${parsed.cleanTitle}"',
        name: 'MetadataService',
      );
      await _db.markAsNotFound(file.id);
      return;
    }

    developer.log(
      'TMDB Match found: "${result.title}" (ID: ${result.id}, Type: ${result.mediaType})',
      name: 'MetadataService',
    );

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

  // TV metadata (three-step lookup with folder context & scoring)

  /// Fetch metadata for a TV episode file.
  ///
  /// Three-step TMDB lookup:
  ///   1. `/search/tv` for the series with folder context and scoring
  ///   2. `/tv/{id}/season/{s}/episode/{e}` for episode details
  ///   3. `/tv/{id}/season/{s}` for season poster fallback
  Future<void> _fetchTvMetadata(MediaFile file, ParsedFilename parsed) async {
    final season = parsed.season!;
    final episode = parsed.episode!;
    final seCode = 'S${season.toString().padLeft(2, '0')}'
        'E${episode.toString().padLeft(2, '0')}';

    // Step 1: Search for the TV series
    TmdbSearchResult? seriesResult;

    // Folder-level context extraction
    final folderName = extractShowFolderName(file.filePath);
    final cleanFolderTitle = folderName != null
        ? FilenameParser.parse(folderName).cleanTitle
        : null;

    // Check knownTitleOverrides
    int? overrideTmdbId;
    if (cleanFolderTitle != null && cleanFolderTitle.isNotEmpty) {
      overrideTmdbId = knownTitleOverrides[normalizeTitle(cleanFolderTitle)];
    }
    overrideTmdbId ??= knownTitleOverrides[normalizeTitle(parsed.cleanTitle)];

    if (overrideTmdbId != null) {
      developer.log(
        'Known title override matched: $overrideTmdbId',
        name: 'MetadataService',
      );
      final cacheKey = 'override:$overrideTmdbId';
      if (_tvSearchCache.containsKey(cacheKey)) {
        seriesResult = _tvSearchCache[cacheKey];
      } else {
        try {
          seriesResult = await _client.fetchTvDetails(overrideTmdbId);
          _tvSearchCache[cacheKey] = seriesResult;
        } on TmdbRateLimitException catch (e) {
          _emitStatus(_currentStatus.copyWith(
            errorMessage: 'Rate limited. Waiting ${e.retryAfterSeconds}s...',
          ));
          rethrow;
        } on TmdbAuthException {
          _emitStatus(_currentStatus.copyWith(
            errorMessage: 'Invalid TMDB API key. Please check Settings.',
          ));
          rethrow;
        } catch (e) {
          developer.log(
            'Failed to fetch override series: $e',
            name: 'MetadataService',
            level: 800,
          );
        }
      }
    }

    if (seriesResult == null) {
      // Primary query: folder name weighted over filename
      final primaryQuery = (cleanFolderTitle != null && cleanFolderTitle.isNotEmpty)
          ? cleanFolderTitle
          : parsed.cleanTitle;

      // Include release year in cache key to avoid collisions across different adaptations/reboots
      final cacheKey =
          '${primaryQuery.toLowerCase().trim()}:${parsed.year ?? ''}';

      if (_tvSearchCache.containsKey(cacheKey)) {
        developer.log(
          'TV search cache hit for: "$cacheKey"',
          name: 'MetadataService',
        );
        seriesResult = _tvSearchCache[cacheKey];
      } else {
        try {
          developer.log(
            'Searching TMDB TV (limit 5): "$primaryQuery"',
            name: 'MetadataService',
          );
          List<TmdbSearchResult> candidates =
              await _client.searchTvList(primaryQuery, limit: 5);

          // Fallback to parsed filename cleanTitle if folder search returned nothing
          if (candidates.isEmpty && primaryQuery != parsed.cleanTitle) {
            developer.log(
              'Folder query returned 0 results, retrying filename: "${parsed.cleanTitle}"',
              name: 'MetadataService',
            );
            candidates = await _client.searchTvList(parsed.cleanTitle, limit: 5);
          }

          // Fallback to Japanese language query if still empty
          if (candidates.isEmpty) {
            developer.log(
              'No English match, retrying with ja-JP: "$primaryQuery"',
              name: 'MetadataService',
            );
            candidates = await _client.searchTvList(primaryQuery, language: 'ja-JP', limit: 5);
          }

          if (candidates.isNotEmpty) {
            // Score candidates
            final scored = candidates.map((c) {
              final score = scoreTvCandidate(
                candidate: c,
                query: primaryQuery,
                rawFileName: file.fileName,
                folderName: folderName,
                targetYear: parsed.year,
              );
              return MapEntry(c, score);
            }).toList();

            scored.sort((a, b) => b.value.compareTo(a.value));
            seriesResult = scored.first.key;
            developer.log(
              'Best TV candidate: "${seriesResult.title}" (score: ${scored.first.value})',
              name: 'MetadataService',
            );
          }

          _tvSearchCache[cacheKey] = seriesResult;
        } on TmdbRateLimitException catch (e) {
          developer.log(
            'Rate limit hit: ${e.retryAfterSeconds}s',
            name: 'MetadataService',
            level: 900,
          );
          _emitStatus(_currentStatus.copyWith(
            errorMessage: 'Rate limited. Waiting ${e.retryAfterSeconds}s...',
          ));
          rethrow;
        } on TmdbAuthException {
          developer.log(
            'Auth failure: Invalid TMDB API key',
            name: 'MetadataService',
            level: 900,
          );
          _emitStatus(_currentStatus.copyWith(
            errorMessage: 'Invalid TMDB API key. Please check Settings.',
          ));
          rethrow;
        }
      }
    }

    if (seriesResult == null) {
      developer.log(
        'No TMDB TV match found for: "${parsed.cleanTitle}"',
        name: 'MetadataService',
      );
      await _db.markAsNotFound(file.id);
      return;
    }

    final seriesId = seriesResult.id;
    developer.log(
      'TMDB series match: "${seriesResult.title}" (id: $seriesId)',
      name: 'MetadataService',
    );

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
      developer.log(
        'Failed to fetch episode details for $seCode: $e',
        name: 'MetadataService',
        level: 800,
      );
      // Continue with series-level data only
    }

    // Step 3: Fetch season poster as fallback.
    // Use series backdrop as fallback whenever season poster is null,
    // or request returns null/404 or throws.
    String? backdropPath = episodeResult?.stillPath;

    if (backdropPath == null) {
      try {
        final seasonResult = await _client.fetchSeasonDetails(
          seriesId,
          season,
        );
        backdropPath = seasonResult?.posterPath;
      } catch (e) {
        developer.log(
          'Failed to fetch season poster for season $season: $e',
          name: 'MetadataService',
          level: 800,
        );
      }
      backdropPath ??= seriesResult.backdropPath;
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
      seasonNumber: season,
      episodeNumber: episode,
      seriesTitle: seriesResult.title,
    );

    developer.log(
      'Episode metadata saved: $seCode - "${episodeName ?? "unknown"}"',
      name: 'MetadataService',
    );
  }

  // Batch processing

  /// Fetch metadata for all unmatched files in the library.
  /// Uses a re-entrancy guard to avoid overlapping runs.
  Future<void> fetchAllUnmatched() async {
    if (_activeFetch != null) return _activeFetch!;
    final future = _runFetch(isRefresh: false);
    _activeFetch = future;
    try {
      await future;
    } finally {
      _activeFetch = null;
    }
  }

  /// Re-fetch metadata for all library files without clearing beforehand.
  /// Overwrites in place so failed requests leave existing metadata intact.
  Future<void> refreshAll() async {
    if (_activeFetch != null) return _activeFetch!;
    final future = _runFetch(isRefresh: true);
    _activeFetch = future;
    try {
      await future;
    } finally {
      _activeFetch = null;
    }
  }

  Future<void> _runFetch({required bool isRefresh}) async {
    _tvSearchCache.clear();
    final files = isRefresh
        ? await _db.getAllRefreshableMediaFiles()
        : await _db.getUnmatchedMediaFiles();

    if (files.isEmpty) return;

    _emitStatus(MetadataFetchStatus(
      isFetching: true,
      totalFiles: files.length,
      processedFiles: 0,
    ));

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        await fetchForFile(file);
      } on TmdbRateLimitException catch (e) {
        // Wait for the rate limit to expire, then retry this file
        await Future<void>.delayed(Duration(seconds: e.retryAfterSeconds + 1));
        try {
          await fetchForFile(file);
        } on TmdbAuthException {
          _emitStatus(MetadataFetchStatus(
            isFetching: false,
            totalFiles: files.length,
            processedFiles: i,
            errorMessage: 'Invalid TMDB API key. Please check Settings.',
          ));
          return;
        } catch (err) {
          developer.log(
            'Retry failed for "${file.fileName}": $err',
            name: 'MetadataService',
            level: 800,
          );
          await _db.markAsError(file.id);
        }
      } on TmdbAuthException {
        // Invalid API key - stop the entire fetch
        _emitStatus(MetadataFetchStatus(
          isFetching: false,
          totalFiles: files.length,
          processedFiles: i,
          errorMessage: 'Invalid TMDB API key. Please check Settings.',
        ));
        return;
      } on SocketException catch (e) {
        developer.log(
          'Network socket error for "${file.fileName}": ${e.message}',
          name: 'MetadataService',
          level: 800,
        );
        await _db.markAsError(file.id);
        _emitStatus(_currentStatus.copyWith(
          errorMessage: 'Network error connecting to TMDB. If TMDB is blocked in your region, '
              'try setting a custom TMDB API Base URL in Settings.',
        ));
      } on http.ClientException catch (e) {
        developer.log(
          'HTTP client error for "${file.fileName}": ${e.message}',
          name: 'MetadataService',
          level: 800,
        );
        await _db.markAsError(file.id);
        _emitStatus(_currentStatus.copyWith(
          errorMessage: 'Network error connecting to TMDB: ${e.message}',
        ));
      } on HandshakeException catch (e) {
        developer.log(
          'TLS handshake error for "${file.fileName}": ${e.message}',
          name: 'MetadataService',
          level: 800,
        );
        await _db.markAsError(file.id);
        _emitStatus(_currentStatus.copyWith(
          errorMessage: 'Secure connection to TMDB failed (TLS handshake error).',
        ));
      } on TimeoutException catch (e) {
        developer.log(
          'Timeout fetching metadata for "${file.fileName}": ${e.message}',
          name: 'MetadataService',
          level: 800,
        );
        await _db.markAsError(file.id);
        _emitStatus(_currentStatus.copyWith(
          errorMessage: 'TMDB request timed out.',
        ));
      } on TmdbApiException catch (e) {
        developer.log(
          'TMDB API error (${e.statusCode}) for "${file.fileName}": ${e.message}',
          name: 'MetadataService',
          level: 800,
        );
        if (e.statusCode >= 500) {
          await _db.markAsError(file.id);
        } else {
          await _db.markAsNotFound(file.id);
        }
      } catch (e) {
        developer.log(
          'Unexpected error fetching metadata for "${file.fileName}": $e',
          name: 'MetadataService',
          level: 800,
        );
        await _db.markAsError(file.id);
        _emitStatus(_currentStatus.copyWith(
          errorMessage: 'Error fetching metadata: $e',
        ));
      }

      _emitStatus(MetadataFetchStatus(
        isFetching: true,
        totalFiles: files.length,
        processedFiles: i + 1,
      ));

      // Rate-limit delay (skip on last item)
      if (i < files.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    _emitStatus(MetadataFetchStatus(
      isFetching: false,
      totalFiles: files.length,
      processedFiles: files.length,
    ));
  }

  /// Manually override metadata for a list of episode files belonging to a series.
  Future<void> overrideSeriesMetadata({
    required List<MediaFile> episodes,
    required TmdbSearchResult selectedShow,
  }) async {
    if (episodes.isEmpty) return;

    final resolvedType = _resolveMediaType(selectedShow);
    final genreString = _client.resolveGenres(selectedShow.genreIds);

    // If a movie was selected for a series
    if (selectedShow.mediaType == 'movie') {
      for (final ep in episodes) {
        await _db.updateMetadata(
          fileId: ep.id,
          tmdbId: selectedShow.id,
          resolvedMediaType: 'movie',
          tmdbTitle: selectedShow.title,
          overview: selectedShow.overview,
          posterPath: selectedShow.posterPath,
          backdropPath: selectedShow.backdropPath,
          releaseYear: selectedShow.releaseYear,
          voteAverage: selectedShow.voteAverage,
          genres: genreString.isNotEmpty ? genreString : null,
          originalLanguage: selectedShow.originalLanguage,
          metadataOverridden: true,
        );
      }
      return;
    }

    // Otherwise, it's a TV series
    for (final episodeFile in episodes) {
      final season = SeriesItem.seasonFor(episodeFile);
      final epNum = SeriesItem.episodeNumberFor(episodeFile);
      final seCode =
          'S${season.toString().padLeft(2, '0')}E${epNum.toString().padLeft(2, '0')}';

      TmdbEpisodeResult? episodeResult;
      try {
        episodeResult = await _client.fetchEpisodeDetails(
          selectedShow.id,
          season,
          epNum,
        );
      } catch (e) {
        developer.log(
          'Failed to fetch episode details for $seCode: $e',
          name: 'MetadataService',
          level: 800,
        );
      }

      String? backdropPath = episodeResult?.stillPath;
      if (backdropPath == null) {
        try {
          final seasonResult = await _client.fetchSeasonDetails(
            selectedShow.id,
            season,
          );
          backdropPath = seasonResult?.posterPath;
        } catch (e) {
          developer.log(
            'Failed to fetch season poster for season $season: $e',
            name: 'MetadataService',
            level: 800,
          );
        }
        backdropPath ??= selectedShow.backdropPath;
      }

      final episodeName = episodeResult?.name;
      final displayTitle = episodeName != null && episodeName.isNotEmpty
          ? '${selectedShow.title} - $seCode - $episodeName'
          : '${selectedShow.title} - $seCode';

      await _db.updateMetadata(
        fileId: episodeFile.id,
        tmdbId: selectedShow.id,
        resolvedMediaType: resolvedType,
        tmdbTitle: displayTitle,
        overview: episodeResult?.overview ?? selectedShow.overview,
        posterPath: selectedShow.posterPath,
        backdropPath: backdropPath,
        releaseYear: episodeResult?.airYear ?? selectedShow.releaseYear,
        voteAverage: episodeResult?.voteAverage ?? selectedShow.voteAverage,
        genres: genreString.isNotEmpty ? genreString : null,
        originalLanguage: selectedShow.originalLanguage,
        seasonNumber: season,
        episodeNumber: epNum,
        seriesTitle: selectedShow.title,
        metadataOverridden: true,
      );
    }
  }

  /// Manually override metadata for a single media file.
  Future<void> overrideFileMetadata({
    required MediaFile file,
    required TmdbSearchResult selectedResult,
  }) async {
    final resolvedType = _resolveMediaType(selectedResult);
    final genreString = _client.resolveGenres(selectedResult.genreIds);

    if (selectedResult.mediaType == 'tv') {
      final parsed = FilenameParser.parse(file.fileName);
      final season = parsed.season ?? 1;
      final episode = parsed.episode ?? 1;
      final seCode =
          'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}';

      TmdbEpisodeResult? episodeResult;
      try {
        episodeResult = await _client.fetchEpisodeDetails(
          selectedResult.id,
          season,
          episode,
        );
      } catch (e) {
        developer.log(
          'Failed to fetch episode details for $seCode: $e',
          name: 'MetadataService',
          level: 800,
        );
      }

      final episodeName = episodeResult?.name;
      final displayTitle = episodeName != null && episodeName.isNotEmpty
          ? '${selectedResult.title} - $seCode - $episodeName'
          : '${selectedResult.title} - $seCode';

      await _db.updateMetadata(
        fileId: file.id,
        tmdbId: selectedResult.id,
        resolvedMediaType: resolvedType,
        tmdbTitle: displayTitle,
        overview: episodeResult?.overview ?? selectedResult.overview,
        posterPath: selectedResult.posterPath,
        backdropPath: episodeResult?.stillPath ?? selectedResult.backdropPath,
        releaseYear: episodeResult?.airYear ?? selectedResult.releaseYear,
        voteAverage: episodeResult?.voteAverage ?? selectedResult.voteAverage,
        genres: genreString.isNotEmpty ? genreString : null,
        originalLanguage: selectedResult.originalLanguage,
        seasonNumber: season,
        episodeNumber: episode,
        seriesTitle: selectedResult.title,
        metadataOverridden: true,
      );
    } else {
      await _db.updateMetadata(
        fileId: file.id,
        tmdbId: selectedResult.id,
        resolvedMediaType: 'movie',
        tmdbTitle: selectedResult.title,
        overview: selectedResult.overview,
        posterPath: selectedResult.posterPath,
        backdropPath: selectedResult.backdropPath,
        releaseYear: selectedResult.releaseYear,
        voteAverage: selectedResult.voteAverage,
        genres: genreString.isNotEmpty ? genreString : null,
        originalLanguage: selectedResult.originalLanguage,
        metadataOverridden: true,
      );
    }
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
