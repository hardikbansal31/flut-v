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
