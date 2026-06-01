/// Filename parser for extracting clean titles, years, and TV episode info
/// from media filenames.
///
/// Handles common patterns like:
///   - `Blade.Runner.2049.2017.1080p.BluRay.x264.mkv` → (title: "Blade Runner 2049", year: 2017)
///   - `[SubGroup] Attack on Titan S04E01 [1080p].mkv` → (title: "Attack on Titan", S04E01)
///   - `The_Batman_(2022)_WEB-DL.mp4` → (title: "The Batman", year: 2022)
///   - `[HorribleSubs] My Hero Academia - 15 [720p].mkv` → (title: "My Hero Academia", S01E15)
library;

/// Result of parsing a media filename.
class ParsedFilename {
  final String cleanTitle;
  final int? year;
  final int? season;
  final int? episode;

  /// True when a season/episode pair was extracted (standard or absolute).
  bool get isTvShow => season != null && episode != null;

  const ParsedFilename({
    required this.cleanTitle,
    this.year,
    this.season,
    this.episode,
  });

  @override
  String toString() =>
      'ParsedFilename("$cleanTitle", year: $year, S${season}E$episode)';
}

/// Parses video filenames to extract a clean title, optional year, and
/// optional season/episode numbers.
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

  // ── TV episode patterns ───────────────────────────────────────────────────

  /// Standard season/episode code: S02E01, S2E4 (case-insensitive).
  static final _sxxExxPattern = RegExp(
    r'[Ss](\d{1,2})[Ee](\d{1,2})',
  );

  /// Alternative season × episode code: 2x04, 03x12.
  static final _crossPattern = RegExp(
    r'(\d{1,2})[xX](\d{2,3})',
  );

  /// Parse a filename (without extension) into a clean title, optional year,
  /// and optional season/episode numbers.
  static ParsedFilename parse(String filename) {
    var working = filename;

    // ── Step 0: Strip file extension ───────────────────────────────────────
    final extPattern = RegExp(r'\.(mkv|mp4|avi|mov|wmv|flv|webm|m4v|ts)$', caseSensitive: false);
    working = working.replaceAll(extPattern, '');

    // ── Step 1: Extract season/episode BEFORE any other stripping ─────────

    int? season;
    int? episode;

    // Try SxxExx first (most specific)
    var seMatch = _sxxExxPattern.firstMatch(working);
    if (seMatch != null) {
      season = int.parse(seMatch.group(1)!);
      episode = int.parse(seMatch.group(2)!);
      // Truncate title at the SxxExx token — everything before it is the title
      working = working.substring(0, seMatch.start);
    } else {
      // Try NxNN format: 2x04, 03x12
      final crossMatch = _crossPattern.firstMatch(working);
      if (crossMatch != null) {
        season = int.parse(crossMatch.group(1)!);
        episode = int.parse(crossMatch.group(2)!);
        working = working.substring(0, crossMatch.start);
      }
    }

    // ── Step 2: Extract year before we strip brackets ────────────────────

    int? year;

    // Check for year in parentheses/brackets first: (2017) or [2017]
    final bracketYearMatch = RegExp(r'[\(\[]((?:19|20)\d{2})[\)\]]').firstMatch(working);
    if (bracketYearMatch != null) {
      year = int.parse(bracketYearMatch.group(1)!);
    }

    // ── Step 3: Strip bracketed groups ───────────────────────────────────

    working = working.replaceAll(_groupBracketPattern, ' ');

    // ── Step 4: Strip resolution, source, codec, filler tags ────────────

    working = working.replaceAll(_resolutionPattern, ' ');
    working = working.replaceAll(_sourcePattern, ' ');
    working = working.replaceAll(_codecPattern, ' ');
    working = working.replaceAll(_fillerPattern, ' ');
    working = working.replaceAll(_ordinalPattern, ' ');

    // ── Step 5: Try year extraction from cleaned string if not found ────

    if (year == null) {
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

    // ── Step 6: Replace dots, underscores, hyphens with spaces ──────────

    working = working.replaceAll(RegExp(r'[._]'), ' ');
    working = working.replaceAll(RegExp(r'\s*-\s*'), ' ');

    // ── Step 7: Try absolute episode number if no SxxExx was found ──────
    //
    // Patterns like "Naruto - 135" or "My Hero Academia - 15".
    // We do this AFTER dot/underscore replacement so "Title - 15" is clean.

    if (season == null && episode == null) {
      // Look for a trailing number that looks like an absolute episode.
      // Match a standalone number at the very end of the cleaned string.
      final absMatch = RegExp(r'\s+(\d{1,4})\s*$').firstMatch(working);
      if (absMatch != null) {
        final candidateEp = int.parse(absMatch.group(1)!);
        // Sanity check: must be >= 1 and the number shouldn't look like a year
        if (candidateEp >= 1 && candidateEp <= 9999 &&
            !(candidateEp >= 1900 && candidateEp <= 2099)) {
          season = 1;
          episode = candidateEp;
          working = working.substring(0, absMatch.start);
          print('[FilenameParser] Warning: absolute episode number ($candidateEp) '
              'detected, assuming season 1');
        }
      }
    }

    // ── Step 8: Final cleanup ───────────────────────────────────────────

    // Remove any remaining trailing dots, dashes, underscores, whitespace
    working = working.replaceAll(RegExp(r'[\s._-]+$'), '');
    working = working.replaceAll(RegExp(r'^[\s._-]+'), '');
    working = working.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If we end up with an empty string, fall back to the original
    if (working.isEmpty) {
      working = filename.replaceAll(RegExp(r'[._]'), ' ').trim();
    }

    return ParsedFilename(
      cleanTitle: working,
      year: year,
      season: season,
      episode: episode,
    );
  }
}
