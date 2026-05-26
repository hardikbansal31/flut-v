/// Filename parser for extracting clean titles and years from media filenames.
///
/// Handles common patterns like:
///   - `Blade.Runner.2049.2017.1080p.BluRay.x264.mkv` → ("Blade Runner 2049", 2017)
///   - `[SubGroup] Attack on Titan S04E01 [1080p].mkv` → ("Attack on Titan S04E01", null)
///   - `The_Batman_(2022)_WEB-DL.mp4` → ("The Batman", 2022)
library;

/// Result of parsing a media filename.
class ParsedFilename {
  final String cleanTitle;
  final int? year;

  const ParsedFilename({required this.cleanTitle, this.year});

  @override
  String toString() => 'ParsedFilename("$cleanTitle", year: $year)';
}

/// Parses video filenames to extract a clean title and optional year.
class FilenameParser {
  FilenameParser._();

  // Matches a 4-digit year in range 1900–2099
  static final _yearPattern = RegExp(r'[\(\[\.\s_]((?:19|20)\d{2})[\)\]\.\s_$]');

  // Matches a year at the very end of the string
  static final _yearEndPattern = RegExp(r'[\(\[\.\s_]((?:19|20)\d{2})$');

  // Resolution tags
  static final _resolutionPattern = RegExp(
    r'\b(480[pi]|576[pi]|720p|1080[pi]|2160p|4[Kk]|UHD)\b',
    caseSensitive: false,
  );

  // Source / quality tags
  static final _sourcePattern = RegExp(
    r'\b(BluRay|Blu-Ray|BDRip|BRRip|WEB-?DL|WEB-?Rip|WEBRip|HDRip|DVDRip|DVDR|DVDScr|HDTV|PDTV|HDCam|CAMRip|TS|TC|TELESYNC|R5|SCR|REMUX|PROPER|REPACK|AMZN|NF|HMAX|DSNP|ATVP|iTunes)\b',
    caseSensitive: false,
  );

  // Codec tags
  static final _codecPattern = RegExp(
    r'\b([xXhH]\.?264|[xXhH]\.?265|HEVC|AVC|VP9|AV1|AAC|DTS|DDP?\.?[257]\.?[01]?|FLAC|Atmos|TrueHD|AC3|EAC3|OPUS|10bit|HDR10?\+?|DV|DoVi)\b',
    caseSensitive: false,
  );

  // Group tags in brackets: [SubGroup], (YIFY), {TAG}
  static final _groupBracketPattern = RegExp(r'[\[\(\{][^\]\)\}]*[\]\)\}]');

  // Common filler words/tags to strip
  static final _fillerPattern = RegExp(
    r"\b(EXTENDED|UNRATED|DIRECTORS\.CUT|Director's\.Cut|THEATRICAL|IMAX|REMASTERED|COMPLETE|PROPER|FINAL|LIMITED|INTERNAL|MULTI|DUAL|DUBBED|SUBBED|ANNIVERSARY|ANNIV|EDITION|SPECIAL|ULTIMATE|DELUXE|CRITERION|STEELBOOK|RESTORED|COLLECTOR'S|COLLECTORS|3D|2D)\b",
    caseSensitive: false,
  );

  // Ordinal numbers (e.g. 25th, 10th)
  static final _ordinalPattern = RegExp(
    r'\b\d+(st|nd|rd|th)\b',
    caseSensitive: false,
  );

  // Season/Episode patterns — keep these in the title for TV detection
  static final _seasonEpisodePattern = RegExp(
    r'[Ss]\d{1,2}[Ee]\d{1,2}',
  );

  /// Parse a filename (without extension) into a clean title and optional year.
  static ParsedFilename parse(String filename) {
    var working = filename;

    // 1. Try to extract year before we strip brackets (year might be in parens)
    int? year;
    
    // Check for year in parentheses/brackets first: (2017) or [2017]
    final bracketYearMatch = RegExp(r'[\(\[]((?:19|20)\d{2})[\)\]]').firstMatch(working);
    if (bracketYearMatch != null) {
      year = int.parse(bracketYearMatch.group(1)!);
    }

    // 2. Strip group tags in brackets, but preserve S01E02 style markers
    // Save season/episode info if present
    final seMatch = _seasonEpisodePattern.firstMatch(working);
    final seasonEpisode = seMatch?.group(0);

    working = working.replaceAll(_groupBracketPattern, ' ');

    // 3. Strip resolution, source, codec, filler tags
    working = working.replaceAll(_resolutionPattern, ' ');
    working = working.replaceAll(_sourcePattern, ' ');
    working = working.replaceAll(_codecPattern, ' ');
    working = working.replaceAll(_fillerPattern, ' ');
    working = working.replaceAll(_ordinalPattern, ' ');

    // 4. If we didn't find a year in brackets, try to find it in the cleaned string
    if (year == null) {
      // Try to find year pattern
      final yearMatch = _yearPattern.firstMatch(working) ??
          _yearEndPattern.firstMatch(working);
      if (yearMatch != null) {
        year = int.parse(yearMatch.group(1)!);
        // Remove the year and everything after it (usually noise)
        final yearIndex = working.indexOf(yearMatch.group(0)!);
        working = working.substring(0, yearIndex);
      }
    } else {
      // Remove the year from the title since we already extracted it
      working = working.replaceAll(RegExp(r'[\(\[]?' + year.toString() + r'[\)\]]?'), ' ');
    }

    // 5. Replace dots, underscores, hyphens with spaces
    working = working.replaceAll(RegExp(r'[._]'), ' ');
    // Replace multiple hyphens (but keep single ones for compound words)
    working = working.replaceAll(RegExp(r'\s*-\s*'), ' ');

    // 6. Re-add season/episode if it was present and got stripped
    if (seasonEpisode != null && !working.contains(seasonEpisode)) {
      working = '$working $seasonEpisode';
    }

    // 7. Clean up whitespace
    working = working.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 8. If we end up with an empty string, fall back to the original
    if (working.isEmpty) {
      working = filename.replaceAll(RegExp(r'[._]'), ' ').trim();
    }

    return ParsedFilename(cleanTitle: working, year: year);
  }
}
