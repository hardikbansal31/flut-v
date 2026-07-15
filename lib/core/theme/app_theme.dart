/// App-wide dark theme definition.
///
/// Defines color palette, text styles, and component themes for the
/// Netflix-style media player UI. Uses Google Fonts "Inter" for clean,
/// modern typography.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color palette

/// Deep background used for scaffold & main surfaces.
const Color kBackgroundColor = Color(0xFF0A0A0F);

/// Slightly lighter surface for cards, bottom sheets, dialogs.
const Color kSurfaceColor = Color(0xFF13131A);

/// Card overlay / elevated surface.
const Color kCardColor = Color(0xFF13131A);

/// Primary accent - vibrant indigo-violet.
const Color kAccentColor = Color(0xFFE8556D);

/// Secondary accent - warm amber for ratings, highlights.
const Color kSecondaryAccent = Color(0xFFFFAB40);

/// Progress-bar track (dimmed).
const Color kProgressTrack = Color(0xFF2A2A3E);

/// Progress-bar fill - cyan-teal.
const Color kProgressFill = Color(0xFF00E5FF);

/// Muted text / secondary labels.
const Color kMutedText = Color(0xFF8E8E9A);

/// Subtle border / divider.
const Color kDivider = Color(0xFF222233);

// Semantic Theme Definitions

class AppTheme {
  static const Color mutedText = kMutedText;
  static const Color accent = kAccentColor;
  static const Color secondaryAccent = kSecondaryAccent;
  static const Color progressFill = kProgressFill;
  static const Color progressTrack = kProgressTrack;
  
  // Standardized palette
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint = Colors.white54;
  
  static const Color backgroundBlack = Colors.black;
  static const Color surface = kSurfaceColor;
  static const Color card = kCardColor;
  static const Color transparent = Colors.transparent;
  
  static const Color errorSnackbar = Color(0xFFB71C1C);
  static const Color shadow = Colors.black;
  static const Color scaffoldBackground = Colors.black;
  static const Color subtitlesDialogBackground = Color(0xFF212121);
  
  // Specific opacity fallbacks generated during refactor
  static const Color backgroundBlack26 = Colors.black26;
  static const Color textPrimary10 = Colors.white10;
  static const Color textPrimary12 = Colors.white12;
  static const Color textPrimary24 = Colors.white24;
  static const Color textPrimary38 = Colors.white38;
}

class AppTextStyles {
  // Common
  static final TextStyle sectionHeader = GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700);
  static final TextStyle sectionSubHeader = GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700);
  static final TextStyle seeAll = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: kAccentColor);
  static final TextStyle brandTitle = GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5);
  static final TextStyle fetchStatus = GoogleFonts.inter(fontSize: 13, color: Colors.white70);
  static final TextStyle bodyMuted = GoogleFonts.inter(fontSize: 14, color: kMutedText);
  static final TextStyle textMutedOnly = GoogleFonts.inter(color: kMutedText);

  // Cards
  static final TextStyle cardTitle = GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3);
  static final TextStyle cardMeta = GoogleFonts.inter(fontSize: 10, color: kMutedText);
  static final TextStyle cardRating = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: kSecondaryAccent);
  static final TextStyle ratingBadge = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white);
  static final TextStyle continueWatchingTitle = GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);

  // Series Detail
  static final TextStyle seriesTitle = GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.2);
  static final TextStyle seriesMeta = GoogleFonts.inter(fontSize: 14, color: kMutedText, fontWeight: FontWeight.w500);
  static final TextStyle seriesRating = GoogleFonts.inter(fontSize: 14, color: kSecondaryAccent, fontWeight: FontWeight.w600);
  static final TextStyle overview = GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5);
  static final TextStyle episodeTitle = GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
  static final TextStyle episodeMeta = GoogleFonts.inter(fontSize: 12, color: kMutedText);
  static final TextStyle genreTag = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
  static final TextStyle episodeNumber = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700);
  static final TextStyle progressText = GoogleFonts.inter(fontSize: 12);

  // Hero Banner
  static final TextStyle genreTagHero = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70);
  static final TextStyle overviewHero = GoogleFonts.inter(fontSize: 13, color: Colors.white54, height: 1.5);
  static final TextStyle buttonText = GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15);
  static final TextStyle buttonTextSecondary = GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14);

  // Settings
  static final TextStyle settingsSectionHeader = GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700);

  // Home Screen
  static final TextStyle footerTitle = GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
  static final TextStyle footerSubtitle = GoogleFonts.inter(color: kMutedText, fontSize: 12);
  static final TextStyle emptyLibraryTitle = GoogleFonts.outfit(fontSize: 18, color: Colors.white70);
  static final TextStyle navItem = GoogleFonts.inter(fontSize: 14);
}

// Theme builder

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme,
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackgroundColor,
    canvasColor: kSurfaceColor,
    cardColor: kCardColor,
    colorScheme: const ColorScheme.dark(
      primary: kAccentColor,
      secondary: kSecondaryAccent,
      surface: kSurfaceColor,
      onSurface: Colors.white,
    ),
    textTheme: textTheme.copyWith(
      // Hero title
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      // Section headings (e.g. "Continue Watching")
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      // Card titles
      titleMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // Metadata / subtitles
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: kMutedText,
      ),
      // Body text
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
    dividerColor: kDivider,
    iconTheme: const IconThemeData(color: Colors.white70, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}
