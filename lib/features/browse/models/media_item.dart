/// Data model for a single media item displayed in the browse UI.
///
/// In Phase 4, populated from SQLite with cached TMDB metadata.
/// Falls back to filename-based display when metadata is unavailable.
library;

import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart' as tmdb;

/// The broad type of content.
enum MediaType { movie, tvShow, anime, uncategorized }

/// A single media entry for the browse UI.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.posterGradientColors,
    this.backdropGradientColors,
    this.posterUrl,
    this.backdropUrl,
    this.year,
    this.rating,
    this.overview,
    this.genres = const [],
    this.type = MediaType.uncategorized,
    this.durationMinutes = 120,
    this.watchedMinutes = 0,
    this.episodeLabel,
  });

  /// Unique identifier (maps to DB id).
  final String id;

  /// Display title (TMDB title or filename fallback).
  final String title;

  /// Two colors used to render a gradient poster placeholder.
  /// Used as fallback when no poster image is available.
  final List<int> posterGradientColors;

  /// Optional two colors for the hero backdrop gradient.
  final List<int>? backdropGradientColors;

  /// Full URL to the TMDB poster image, or null if not available.
  final String? posterUrl;

  /// Full URL to the TMDB backdrop image, or null if not available.
  final String? backdropUrl;

  /// Release year.
  final int? year;

  /// TMDB rating out of 10.
  final double? rating;

  /// Short plot synopsis.
  final String? overview;

  /// Genre tags.
  final List<String> genres;

  /// Media type category.
  final MediaType type;

  /// Total runtime in minutes (for progress calculation).
  final int durationMinutes;

  /// Minutes watched so far (0 = not started).
  final int watchedMinutes;

  /// Optional episode label (e.g. "S02E04") for continue watching cards.
  final String? episodeLabel;

  /// Fraction watched, 0.0–1.0.
  double get progress =>
      durationMinutes > 0 ? (watchedMinutes / durationMinutes).clamp(0, 1) : 0;

  /// Creates a MediaItem from a scanned MediaFile with optional TMDB metadata.
  factory MediaItem.fromMediaFile(MediaFile file) {
    // Generate a deterministic color pair based on the filename hash
    final hash = file.fileName.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    final color1 = 0xFF000000 | (r << 16) | (g << 8) | b;
    final color2 = 0xFF000000 | ((255 - r) << 16) | ((255 - g) << 8) | ((255 - b));
    
    final durationMillis = file.durationMillis ?? 0;
    final positionMillis = file.positionMillis ?? 0;

    // Resolve media type from DB string
    final resolvedType = _parseMediaType(file.mediaType);

    // Parse genres from comma-separated string
    final genreList = file.genres != null && file.genres!.isNotEmpty
        ? file.genres!.split(',').map((g) => g.trim()).toList()
        : <String>[];

    return MediaItem(
      id: file.id.toString(),
      title: file.tmdbTitle ?? file.fileName,
      posterGradientColors: [color1, color2],
      posterUrl: tmdb.posterUrl(file.posterPath),
      backdropUrl: tmdb.backdropUrl(file.backdropPath),
      year: file.releaseYear,
      rating: file.voteAverage,
      overview: file.overview,
      genres: genreList,
      type: resolvedType,
      durationMinutes: durationMillis > 0 ? (durationMillis / 60000).round() : 120,
      watchedMinutes: positionMillis > 0 ? (positionMillis / 60000).round() : 0,
    );
  }

  /// Creates a MediaItem from a [SeriesItem] for series-level display.
  ///
  /// Used in grids and rows where we show one card per series.
  /// Optionally includes an [episodeLabel] and watch progress from a
  /// specific episode (e.g. for Continue Watching).
  factory MediaItem.fromSeriesItem(
    SeriesItem series, {
    MediaFile? currentEpisode,
  }) {
    final hash = series.seriesTitle.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    final color1 = 0xFF000000 | (r << 16) | (g << 8) | b;
    final color2 =
        0xFF000000 | ((255 - r) << 16) | ((255 - g) << 8) | ((255 - b));

    int durationMinutes = 120;
    int watchedMinutes = 0;
    String? epLabel;

    if (currentEpisode != null) {
      final dur = currentEpisode.durationMillis ?? 0;
      final pos = currentEpisode.positionMillis ?? 0;
      durationMinutes = dur > 0 ? (dur / 60000).round() : 120;
      watchedMinutes = pos > 0 ? (pos / 60000).round() : 0;
      epLabel = SeriesItem.episodeLabelFor(currentEpisode);
    }

    return MediaItem(
      id: series.groupKey,
      title: series.seriesTitle,
      posterGradientColors: [color1, color2],
      posterUrl: series.posterUrl,
      backdropUrl: series.backdropUrl,
      year: series.year,
      rating: series.rating,
      overview: series.overview,
      genres: series.genres,
      type: series.type,
      durationMinutes: durationMinutes,
      watchedMinutes: watchedMinutes,
      episodeLabel: epLabel,
    );
  }

  /// Parse a DB media type string to our enum.
  static MediaType _parseMediaType(String? dbType) {
    switch (dbType) {
      case 'movie':
        return MediaType.movie;
      case 'tv':
        return MediaType.tvShow;
      case 'anime':
        return MediaType.anime;
      default:
        return MediaType.uncategorized;
    }
  }
}
