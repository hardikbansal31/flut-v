/// App-wide dark theme definition.
///
/// Defines color palette, text styles, and component themes for the
/// Netflix-style media player UI. Uses Google Fonts "Inter" for clean,
/// modern typography.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color palette ──────────────────────────────────────────────────────────

/// Deep background used for scaffold & main surfaces.
const Color kBackgroundColor = Color(0xFF0A0A12);

/// Slightly lighter surface for cards, bottom sheets, dialogs.
const Color kSurfaceColor = Color(0xFF14141F);

/// Card overlay / elevated surface.
const Color kCardColor = Color(0xFF1C1C2E);

/// Primary accent — vibrant indigo-violet.
const Color kAccentColor = Color(0xFF7B61FF);

/// Secondary accent — warm amber for ratings, highlights.
const Color kSecondaryAccent = Color(0xFFFFAB40);

/// Progress-bar track (dimmed).
const Color kProgressTrack = Color(0xFF2A2A3E);

/// Progress-bar fill — cyan-teal.
const Color kProgressFill = Color(0xFF00E5FF);

/// Muted text / secondary labels.
const Color kMutedText = Color(0xFF8E8E9A);

/// Subtle border / divider.
const Color kDivider = Color(0xFF222233);

// ─── Semantic Theme Definitions ───────────────────────────────────────────────

class AppTheme {
  static const Color mutedText = kMutedText;
  static const Color accent = kAccentColor;
  static const Color secondaryAccent = kSecondaryAccent;
  static const Color progressFill = kProgressFill;
  static const Color errorSnackbar = Color(0xFFB71C1C); // Colors.red[800]
  static const Color cardShadow = Colors.black;
  static const Color scaffoldBackground = Colors.black;
  static const Color subtitlesDialogBackground = Color(0xFF212121);
}

class AppTextStyles {
  // Common
  static const sectionHeader = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
  static const sectionSubHeader = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
  static const seeAll = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAccentColor);
  static const brandTitle = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5);
  static const fetchStatus = TextStyle(fontSize: 13, color: Colors.white70);
  static const bodyMuted = TextStyle(fontSize: 14, color: kMutedText);
  static const textMutedOnly = TextStyle(color: kMutedText);

  // Cards
  static const cardTitle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3);
  static const cardMeta = TextStyle(fontSize: 10, color: kMutedText);
  static const cardRating = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSecondaryAccent);
  static const ratingBadge = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white);
  static const continueWatchingTitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);

  // Series Detail
  static const seriesTitle = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.2);
  static const seriesMeta = TextStyle(fontSize: 14, color: kMutedText, fontWeight: FontWeight.w500);
  static const seriesRating = TextStyle(fontSize: 14, color: kSecondaryAccent, fontWeight: FontWeight.w600);
  static const overview = TextStyle(fontSize: 14, color: Colors.white70, height: 1.5);
  static const episodeTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
  static const episodeMeta = TextStyle(fontSize: 12, color: kMutedText);
  static const genreTag = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const episodeNumber = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
  static const progressText = TextStyle(fontSize: 12);

  // Hero Banner
  static const genreTagHero = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70);
  static const overviewHero = TextStyle(fontSize: 13, color: Colors.white54, height: 1.5);
  static const buttonText = TextStyle(fontWeight: FontWeight.w600, fontSize: 15);
  static const buttonTextSecondary = TextStyle(fontWeight: FontWeight.w500, fontSize: 14);

  // Settings
  static const settingsSectionHeader = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  // Home Screen
  static const footerTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
  static const footerSubtitle = TextStyle(color: kMutedText, fontSize: 12);
  static const emptyLibraryTitle = TextStyle(fontSize: 18, color: Colors.white70);
  static const navItem = TextStyle(fontSize: 14);
}

// ─── Theme builder ──────────────────────────────────────────────────────────

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
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      // Section headings (e.g. "Continue Watching")
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      // Card titles
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // Metadata / subtitles
      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: kMutedText,
      ),
      // Body text
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
    dividerColor: kDivider,
    iconTheme: const IconThemeData(color: Colors.white70, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}
