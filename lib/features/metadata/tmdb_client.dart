/// Thin HTTP client for the TMDB (The Movie Database) API v3.
///
/// All methods require a valid TMDB API key (v3 auth).
/// Image base URLs are constants — use [posterUrl] and [backdropUrl]
/// helpers to build full image URLs from paths.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Image URL constants ────────────────────────────────────────────────────

/// Base URL for poster images (w500 = 500px wide, good for cards).
const String kTmdbPosterBase = 'https://image.tmdb.org/t/p/w500';

/// Base URL for backdrop images (w1280 = 1280px wide, good for hero banners).
const String kTmdbBackdropBase = 'https://image.tmdb.org/t/p/w1280';

/// Build a full poster URL from a TMDB poster path.
String? posterUrl(String? path) => path != null ? '$kTmdbPosterBase$path' : null;

/// Build a full backdrop URL from a TMDB backdrop path.
String? backdropUrl(String? path) => path != null ? '$kTmdbBackdropBase$path' : null;

// ─── Data classes ───────────────────────────────────────────────────────────

/// A search result from TMDB's multi-search endpoint.
class TmdbSearchResult {
  final int id;

  /// 'movie' or 'tv' (we ignore 'person' results).
  final String mediaType;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final List<int> genreIds;
  final String? originalLanguage;

  const TmdbSearchResult({
    required this.id,
    required this.mediaType,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0,
    this.genreIds = const [],
    this.originalLanguage,
  });

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    final type = json['media_type'] as String? ?? 'movie';
    return TmdbSearchResult(
      id: json['id'] as int,
      mediaType: type,
      title: (type == 'tv'
              ? json['name'] as String?
              : json['title'] as String?) ??
          'Unknown',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: (type == 'tv'
              ? json['first_air_date'] as String?
              : json['release_date'] as String?),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      originalLanguage: json['original_language'] as String?,
    );
  }

  /// Extract year from release_date string (e.g. "2017-10-06" → 2017).
  int? get releaseYear {
    if (releaseDate == null || releaseDate!.length < 4) return null;
    return int.tryParse(releaseDate!.substring(0, 4));
  }
}

// ─── Exception types ────────────────────────────────────────────────────────

/// Thrown when the TMDB API returns a rate limit response (HTTP 429).
class TmdbRateLimitException implements Exception {
  final int retryAfterSeconds;
  TmdbRateLimitException(this.retryAfterSeconds);

  @override
  String toString() => 'TMDB rate limited. Retry after ${retryAfterSeconds}s.';
}

/// Thrown when the TMDB API key is invalid (HTTP 401).
class TmdbAuthException implements Exception {
  @override
  String toString() => 'Invalid TMDB API key. Please check your key in Settings.';
}

/// Thrown for other TMDB API errors.
class TmdbApiException implements Exception {
  final int statusCode;
  final String message;
  TmdbApiException(this.statusCode, this.message);

  @override
  String toString() => 'TMDB API error ($statusCode): $message';
}

// ─── Genre map ──────────────────────────────────────────────────────────────

/// TMDB genre IDs → names. Combined movie + TV genres.
/// Hardcoded because these change extremely rarely.
const Map<int, String> kTmdbGenres = {
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
  // TV-specific
  10759: 'Action & Adventure',
  10762: 'Kids',
  10763: 'News',
  10764: 'Reality',
  10765: 'Sci-Fi & Fantasy',
  10766: 'Soap',
  10767: 'Talk',
  10768: 'War & Politics',
};

/// The TMDB genre ID for Animation.
const int kAnimationGenreId = 16;

// ─── Client ─────────────────────────────────────────────────────────────────

/// TMDB API v3 client.
class TmdbClient {
  final String apiKey;
  final http.Client _http;

  static const _baseUrl = 'https://api.themoviedb.org/3';

  TmdbClient({required this.apiKey, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  /// Search for movies and TV shows with a single query.
  ///
  /// Returns the first movie or TV result, or null if nothing found.
  /// Ignores 'person' results.
  Future<TmdbSearchResult?> searchMulti(String query, {int? year}) async {
    final params = {
      'api_key': apiKey,
      'query': query,
      'include_adult': 'false',
      if (year != null) 'year': year.toString(),
    };

    final uri = Uri.parse('$_baseUrl/search/multi').replace(queryParameters: params);
    final response = await _request(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];

    // Filter out person results, take the first movie or tv result
    for (final result in results) {
      final type = result['media_type'] as String?;
      if (type == 'movie' || type == 'tv') {
        return TmdbSearchResult.fromJson(result as Map<String, dynamic>);
      }
    }

    return null;
  }

  /// Resolve genre IDs to a comma-separated string of genre names.
  String resolveGenres(List<int> genreIds) {
    return genreIds
        .map((id) => kTmdbGenres[id])
        .where((name) => name != null)
        .join(',');
  }

  /// Perform an HTTP GET with error handling.
  Future<http.Response> _request(Uri uri) async {
    final response = await _http.get(uri);

    switch (response.statusCode) {
      case 200:
        return response;
      case 401:
        throw TmdbAuthException();
      case 429:
        final retryAfter = int.tryParse(
                response.headers['retry-after'] ?? '10') ??
            10;
        throw TmdbRateLimitException(retryAfter);
      default:
        throw TmdbApiException(response.statusCode, response.body);
    }
  }

  /// Dispose the HTTP client.
  void dispose() {
    _http.close();
  }
}
