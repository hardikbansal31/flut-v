/// Hardcoded dummy data for Phase 1.
///
/// Provides realistic-looking media items for every section of the home
/// screen: hero banner, Continue Watching, Recently Added, Movies, TV Shows.
/// Each item uses a unique gradient pair for its poster placeholder.
library;

import 'package:flutter_video/features/browse/models/media_item.dart';

// ─── Hero Banner Items ──────────────────────────────────────────────────────

/// Items that cycle in the top hero carousel.
final List<MediaItem> heroBannerItems = [
  const MediaItem(
    id: 'hero-1',
    title: 'Blade Runner 2049',
    posterGradientColors: [0xFF0D47A1, 0xFF1A237E],
    backdropGradientColors: [0xFF0D47A1, 0xFF000A1F],
    year: 2017,
    rating: 8.0,
    overview:
        'Officer K, a new blade runner for the LAPD, unearths a long-buried '
        'secret that has the potential to plunge what\'s left of society into '
        'chaos and leads him on a quest to find Rick Deckard.',
    genres: ['Sci-Fi', 'Thriller', 'Drama'],
    type: MediaType.movie,
    durationMinutes: 163,
  ),
  const MediaItem(
    id: 'hero-2',
    title: 'Dune: Part Two',
    posterGradientColors: [0xFFE65100, 0xFF3E2723],
    backdropGradientColors: [0xFFE65100, 0xFF1A0A00],
    year: 2024,
    rating: 8.3,
    overview:
        'Paul Atreides unites with the Fremen while on a warpath of revenge '
        'against the conspirators who destroyed his family.',
    genres: ['Sci-Fi', 'Adventure', 'Drama'],
    type: MediaType.movie,
    durationMinutes: 166,
  ),
  const MediaItem(
    id: 'hero-3',
    title: 'Severance',
    posterGradientColors: [0xFF1B5E20, 0xFF0D1B0F],
    backdropGradientColors: [0xFF1B5E20, 0xFF050D05],
    year: 2022,
    rating: 8.7,
    overview:
        'Mark leads a team of office workers whose memories have been '
        'surgically divided between their work and personal lives.',
    genres: ['Thriller', 'Drama', 'Sci-Fi'],
    type: MediaType.tvShow,
    durationMinutes: 55,
  ),
];

// ─── Continue Watching ──────────────────────────────────────────────────────

/// Items the user has partially watched. Each has a non-zero watchedMinutes.
final List<MediaItem> continueWatchingItems = [
  const MediaItem(
    id: 'cw-1',
    title: 'Interstellar',
    posterGradientColors: [0xFF1A237E, 0xFF311B92],
    year: 2014,
    rating: 8.7,
    genres: ['Sci-Fi', 'Drama'],
    durationMinutes: 169,
    watchedMinutes: 102,
  ),
  const MediaItem(
    id: 'cw-2',
    title: 'Breaking Bad S05E14',
    posterGradientColors: [0xFF33691E, 0xFF1B5E20],
    year: 2013,
    rating: 9.5,
    genres: ['Crime', 'Drama'],
    type: MediaType.tvShow,
    durationMinutes: 55,
    watchedMinutes: 31,
  ),
  const MediaItem(
    id: 'cw-3',
    title: 'The Batman',
    posterGradientColors: [0xFF880E4F, 0xFF4A0028],
    year: 2022,
    rating: 7.8,
    genres: ['Action', 'Crime'],
    durationMinutes: 176,
    watchedMinutes: 88,
  ),
  const MediaItem(
    id: 'cw-4',
    title: 'Oppenheimer',
    posterGradientColors: [0xFFBF360C, 0xFF4E342E],
    year: 2023,
    rating: 8.3,
    genres: ['Drama', 'History'],
    durationMinutes: 180,
    watchedMinutes: 45,
  ),
  const MediaItem(
    id: 'cw-5',
    title: 'Arcane S02E03',
    posterGradientColors: [0xFF4A148C, 0xFF1A237E],
    year: 2024,
    rating: 9.0,
    genres: ['Animation', 'Action'],
    type: MediaType.tvShow,
    durationMinutes: 42,
    watchedMinutes: 20,
  ),
];

// ─── Recently Added ─────────────────────────────────────────────────────────

final List<MediaItem> recentlyAddedItems = [
  const MediaItem(
    id: 'ra-1',
    title: 'Poor Things',
    posterGradientColors: [0xFF00695C, 0xFF004D40],
    year: 2023,
    rating: 8.0,
    genres: ['Comedy', 'Drama', 'Sci-Fi'],
    durationMinutes: 141,
  ),
  const MediaItem(
    id: 'ra-2',
    title: 'Killers of the Flower Moon',
    posterGradientColors: [0xFF8D6E63, 0xFF3E2723],
    year: 2023,
    rating: 7.6,
    genres: ['Crime', 'Drama', 'History'],
    durationMinutes: 206,
  ),
  const MediaItem(
    id: 'ra-3',
    title: 'The Zone of Interest',
    posterGradientColors: [0xFF455A64, 0xFF263238],
    year: 2023,
    rating: 7.4,
    genres: ['Drama', 'History', 'War'],
    durationMinutes: 105,
  ),
  const MediaItem(
    id: 'ra-4',
    title: 'Past Lives',
    posterGradientColors: [0xFF5C6BC0, 0xFF283593],
    year: 2023,
    rating: 7.9,
    genres: ['Drama', 'Romance'],
    durationMinutes: 106,
  ),
  const MediaItem(
    id: 'ra-5',
    title: 'The Holdovers',
    posterGradientColors: [0xFFA1887F, 0xFF5D4037],
    year: 2023,
    rating: 7.9,
    genres: ['Comedy', 'Drama'],
    durationMinutes: 133,
  ),
  const MediaItem(
    id: 'ra-6',
    title: 'Anatomy of a Fall',
    posterGradientColors: [0xFF78909C, 0xFF37474F],
    year: 2023,
    rating: 7.7,
    genres: ['Drama', 'Thriller'],
    durationMinutes: 152,
  ),
];

// ─── Movies Collection ──────────────────────────────────────────────────────

final List<MediaItem> moviesItems = [
  const MediaItem(
    id: 'mv-1',
    title: 'Inception',
    posterGradientColors: [0xFF0277BD, 0xFF01579B],
    year: 2010,
    rating: 8.8,
    genres: ['Action', 'Sci-Fi', 'Thriller'],
    durationMinutes: 148,
  ),
  const MediaItem(
    id: 'mv-2',
    title: 'Parasite',
    posterGradientColors: [0xFF558B2F, 0xFF33691E],
    year: 2019,
    rating: 8.5,
    genres: ['Thriller', 'Drama', 'Comedy'],
    durationMinutes: 132,
  ),
  const MediaItem(
    id: 'mv-3',
    title: 'Mad Max: Fury Road',
    posterGradientColors: [0xFFEF6C00, 0xFFE65100],
    year: 2015,
    rating: 8.1,
    genres: ['Action', 'Sci-Fi'],
    durationMinutes: 120,
  ),
  const MediaItem(
    id: 'mv-4',
    title: 'Everything Everywhere All at Once',
    posterGradientColors: [0xFFAD1457, 0xFF880E4F],
    year: 2022,
    rating: 7.8,
    genres: ['Action', 'Comedy', 'Sci-Fi'],
    durationMinutes: 139,
  ),
  const MediaItem(
    id: 'mv-5',
    title: 'The Grand Budapest Hotel',
    posterGradientColors: [0xFFD81B60, 0xFF6A1B9A],
    year: 2014,
    rating: 8.1,
    genres: ['Comedy', 'Drama', 'Adventure'],
    durationMinutes: 100,
  ),
  const MediaItem(
    id: 'mv-6',
    title: 'Whiplash',
    posterGradientColors: [0xFFF9A825, 0xFFF57F17],
    year: 2014,
    rating: 8.5,
    genres: ['Drama', 'Music'],
    durationMinutes: 107,
  ),
  const MediaItem(
    id: 'mv-7',
    title: 'Arrival',
    posterGradientColors: [0xFF546E7A, 0xFF37474F],
    year: 2016,
    rating: 7.9,
    genres: ['Drama', 'Sci-Fi'],
    durationMinutes: 116,
  ),
  const MediaItem(
    id: 'mv-8',
    title: 'The Social Network',
    posterGradientColors: [0xFF1565C0, 0xFF0D47A1],
    year: 2010,
    rating: 7.8,
    genres: ['Drama'],
    durationMinutes: 120,
  ),
];

// ─── TV Shows Collection ────────────────────────────────────────────────────

final List<MediaItem> tvShowsItems = [
  const MediaItem(
    id: 'tv-1',
    title: 'Chernobyl',
    posterGradientColors: [0xFF616161, 0xFF424242],
    year: 2019,
    rating: 9.4,
    genres: ['Drama', 'History', 'Thriller'],
    type: MediaType.tvShow,
    durationMinutes: 60,
  ),
  const MediaItem(
    id: 'tv-2',
    title: 'The Bear',
    posterGradientColors: [0xFF6D4C41, 0xFF4E342E],
    year: 2022,
    rating: 8.6,
    genres: ['Comedy', 'Drama'],
    type: MediaType.tvShow,
    durationMinutes: 30,
  ),
  const MediaItem(
    id: 'tv-3',
    title: 'Shogun',
    posterGradientColors: [0xFFC62828, 0xFF8E0000],
    year: 2024,
    rating: 8.7,
    genres: ['Drama', 'War', 'History'],
    type: MediaType.tvShow,
    durationMinutes: 60,
  ),
  const MediaItem(
    id: 'tv-4',
    title: 'Dark',
    posterGradientColors: [0xFF263238, 0xFF1A1A2E],
    year: 2017,
    rating: 8.8,
    genres: ['Sci-Fi', 'Thriller', 'Mystery'],
    type: MediaType.tvShow,
    durationMinutes: 60,
  ),
  const MediaItem(
    id: 'tv-5',
    title: 'Andor',
    posterGradientColors: [0xFF3949AB, 0xFF1A237E],
    year: 2022,
    rating: 8.4,
    genres: ['Action', 'Drama', 'Sci-Fi'],
    type: MediaType.tvShow,
    durationMinutes: 45,
  ),
  const MediaItem(
    id: 'tv-6',
    title: 'Fallout',
    posterGradientColors: [0xFF827717, 0xFF558B2F],
    year: 2024,
    rating: 8.0,
    genres: ['Sci-Fi', 'Drama', 'Action'],
    type: MediaType.tvShow,
    durationMinutes: 55,
  ),
  const MediaItem(
    id: 'tv-7',
    title: 'True Detective',
    posterGradientColors: [0xFF4E342E, 0xFF3E2723],
    year: 2014,
    rating: 8.9,
    genres: ['Crime', 'Drama', 'Mystery'],
    type: MediaType.tvShow,
    durationMinutes: 60,
  ),
  const MediaItem(
    id: 'tv-8',
    title: 'The Last of Us',
    posterGradientColors: [0xFF2E7D32, 0xFF1B5E20],
    year: 2023,
    rating: 8.8,
    genres: ['Drama', 'Action', 'Adventure'],
    type: MediaType.tvShow,
    durationMinutes: 55,
  ),
];
