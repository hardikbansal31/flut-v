/// Data model for a single media item displayed in the browse UI.
///
/// During Phase 1 this is populated with hardcoded dummy data.
/// Later phases will build these from SQLite + TMDB metadata.
library;

import 'package:flutter_video/core/database/database.dart';

/// The broad type of content.
enum MediaType { movie, tvShow }

/// A single media entry for the browse UI.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.posterGradientColors,
    this.backdropGradientColors,
    this.year,
    this.rating,
    this.overview,
    this.genres = const [],
    this.type = MediaType.movie,
    this.durationMinutes = 120,
    this.watchedMinutes = 0,
  });

  /// Unique identifier (will map to DB id later).
  final String id;

  /// Display title.
  final String title;

  /// Two colors used to render a gradient poster placeholder.
  /// Replaced by real poster URLs in Phase 4.
  final List<int> posterGradientColors;

  /// Optional two colors for the hero backdrop gradient.
  final List<int>? backdropGradientColors;

  /// Release year.
  final int? year;

  /// TMDB-style rating out of 10.
  final double? rating;

  /// Short plot synopsis.
  final String? overview;

  /// Genre tags.
  final List<String> genres;

  /// Movie or TV show.
  final MediaType type;

  /// Total runtime in minutes (for progress calculation).
  final int durationMinutes;

  /// Minutes watched so far (0 = not started).
  final int watchedMinutes;

  /// Fraction watched, 0.0–1.0.
  double get progress =>
      durationMinutes > 0 ? (watchedMinutes / durationMinutes).clamp(0, 1) : 0;

  /// Creates a MediaItem from a scanned MediaFile (Phase 2).
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

    return MediaItem(
      id: file.id.toString(),
      title: file.fileName,
      posterGradientColors: [color1, color2],
      type: MediaType.movie, // default until Phase 4
      durationMinutes: durationMillis > 0 ? (durationMillis / 60000).round() : 120,
      watchedMinutes: positionMillis > 0 ? (positionMillis / 60000).round() : 0,
    );
  }
}
