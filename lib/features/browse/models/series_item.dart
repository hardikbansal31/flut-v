/// Grouped TV series data model.
///
/// Represents a single TV series composed of multiple episode [MediaFile]
/// rows from the database. Used by the home screen to display one card
/// per series instead of one card per episode.
library;

import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart' as tmdb;
import 'package:flutter_video/features/browse/models/media_item.dart';

/// A grouped TV series with all its episode files.
class SeriesItem {
  /// Grouping key — TMDB series ID (as string) or fallback title.
  final String groupKey;

  /// Clean series title (e.g. "Attack on Titan").
  final String seriesTitle;

  /// Full poster URL for the series card.
  final String? posterUrl;

  /// Full backdrop URL for the series detail header.
  final String? backdropUrl;

  /// Release year of the series.
  final int? year;

  /// Average TMDB rating.
  final double? rating;

  /// Series-level plot synopsis.
  final String? overview;

  /// Genre tags.
  final List<String> genres;

  /// Media type (tvShow or anime).
  final MediaType type;

  /// All episode files belonging to this series, sorted by season/episode.
  final List<MediaFile> episodes;

  const SeriesItem({
    required this.groupKey,
    required this.seriesTitle,
    this.posterUrl,
    this.backdropUrl,
    this.year,
    this.rating,
    this.overview,
    this.genres = const [],
    this.type = MediaType.tvShow,
    required this.episodes,
  });

  /// The total number of episodes in this series.
  int get episodeCount => episodes.length;

  // ── Season/episode extraction from tmdbTitle ────────────────────────────

  /// Regular expression to extract season and episode from the stored
  /// tmdbTitle format: "Series Name - S02E04 - Episode Name"
  static final _seCodePattern = RegExp(r'S(\d+)E(\d+)');

  /// Extract the episode label (e.g. "S02E04") from a media file's tmdbTitle.
  static String? episodeLabelFor(MediaFile file) {
    if (file.tmdbTitle != null) {
      final match = _seCodePattern.firstMatch(file.tmdbTitle!);
      if (match != null) {
        final s = int.parse(match.group(1)!).toString().padLeft(2, '0');
        final e = int.parse(match.group(2)!).toString().padLeft(2, '0');
        return 'S${s}E$e';
      }
    }
    // Fallback: parse filename for anime/uncategorized without strict tags
    final parsed = FilenameParser.parse(file.fileName);
    if (parsed.season != null && parsed.episode != null) {
      final s = parsed.season!.toString().padLeft(2, '0');
      final e = parsed.episode!.toString().padLeft(2, '0');
      return 'S${s}E$e';
    }
    return null;
  }

  /// Extract the season number from a media file's tmdbTitle.
  static int seasonFor(MediaFile file) {
    if (file.tmdbTitle != null) {
      final match = _seCodePattern.firstMatch(file.tmdbTitle!);
      if (match != null) return int.parse(match.group(1)!);
    }
    // Fallback
    final parsed = FilenameParser.parse(file.fileName);
    return parsed.season ?? 1;
  }

  /// Extract the episode number from a media file's tmdbTitle.
  static int episodeNumberFor(MediaFile file) {
    if (file.tmdbTitle != null) {
      final match = _seCodePattern.firstMatch(file.tmdbTitle!);
      if (match != null) return int.parse(match.group(2)!);
    }
    // Fallback
    final parsed = FilenameParser.parse(file.fileName);
    return parsed.episode ?? 0;
  }

  /// Extract the episode name (after "S02E04 - ") from tmdbTitle.
  static String? episodeNameFor(MediaFile file) {
    final title = file.tmdbTitle;
    if (title == null) return null;
    // Format: "Series Name - S02E04 - Episode Name"
    final match = RegExp(r'- S\d+E\d+ - (.+)$').firstMatch(title);
    return match?.group(1);
  }

  /// Extract the clean series title (before " - S02E04") from tmdbTitle.
  static String seriesTitleFor(MediaFile file) {
    if (file.tmdbTitle != null) {
      final match = RegExp(r'^(.+?)\s*-\s*S\d+E\d+').firstMatch(file.tmdbTitle!);
      if (match != null) return match.group(1)!.trim();
      return file.tmdbTitle!;
    }
    // Fallback: use robust FilenameParser
    return FilenameParser.parse(file.fileName).cleanTitle;
  }

  // ── Grouping ──────────────────────────────────────────────────────────

  /// Groups a list of TV/anime [MediaFile]s into [SeriesItem] objects.
  ///
  /// Groups by [tmdbId] if available (> 0), otherwise by the parsed
  /// series title string. Episodes within each group are sorted by
  /// season, then episode number.
  static List<SeriesItem> groupFiles(List<MediaFile> files) {
    final groups = <String, List<MediaFile>>{};

    for (final file in files) {
      // Determine grouping key
      final key = (file.tmdbId != null && file.tmdbId! > 0)
          ? 'tmdb:${file.tmdbId}'
          : 'title:${seriesTitleFor(file).toLowerCase()}';

      groups.putIfAbsent(key, () => []).add(file);
    }

    final result = <SeriesItem>[];

    for (final entry in groups.entries) {
      final episodeFiles = entry.value;

      // Sort by season, then episode number
      episodeFiles.sort((a, b) {
        final sa = seasonFor(a);
        final sb = seasonFor(b);
        if (sa != sb) return sa.compareTo(sb);
        return episodeNumberFor(a).compareTo(episodeNumberFor(b));
      });

      // Use the first episode's metadata as the series-level data
      final representative = episodeFiles.first;
      final title = seriesTitleFor(representative);

      // Resolve type
      final resolvedType = representative.mediaType == 'anime'
          ? MediaType.anime
          : MediaType.tvShow;

      // Parse genres
      final genreList = representative.genres != null &&
              representative.genres!.isNotEmpty
          ? representative.genres!.split(',').map((g) => g.trim()).toList()
          : <String>[];

      result.add(SeriesItem(
        groupKey: entry.key,
        seriesTitle: title,
        posterUrl: tmdb.posterUrl(representative.posterPath),
        backdropUrl: tmdb.backdropUrl(representative.backdropPath),
        year: representative.releaseYear,
        rating: representative.voteAverage,
        overview: representative.overview,
        genres: genreList,
        type: resolvedType,
        episodes: episodeFiles,
      ));
    }

    // Sort series alphabetically by title
    result.sort((a, b) => a.seriesTitle.compareTo(b.seriesTitle));
    return result;
  }

  /// Get distinct season numbers in this series.
  List<int> get seasons {
    final s = episodes.map(seasonFor).toSet().toList()..sort();
    return s;
  }

  /// Get episodes for a specific season.
  List<MediaFile> episodesForSeason(int season) {
    return episodes.where((f) => seasonFor(f) == season).toList();
  }
}
