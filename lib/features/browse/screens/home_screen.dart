/// Home screen — the main browse view of the media player.
///
/// Composes all UI sections into a single scrollable view:
///   1. Hero banner carousel (top)
///   2. Continue Watching horizontal row
///   3. Recently Added horizontal row
///   4. Category grids (Movies, TV Shows, Anime, Uncategorized)
///
/// Uses a transparent app bar that fades in a background as the user scrolls.
/// Shows a persistent bottom indicator during metadata fetching.
library;

import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/settings/library_management_screen.dart';
import 'package:flutter_video/features/player/screens/player_screen.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:flutter_video/features/metadata/metadata_providers.dart';
import 'package:flutter_video/features/metadata/metadata_service.dart';
import 'package:flutter_video/features/browse/widgets/continue_watching_card.dart';
import 'package:flutter_video/features/browse/widgets/hero_banner.dart';
import 'package:flutter_video/features/browse/widgets/horizontal_media_row.dart';
import 'package:flutter_video/features/browse/widgets/media_card.dart';
import 'package:flutter_video/features/browse/widgets/media_grid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Opacity of the app bar background (0 = transparent, 1 = solid).
  double _appBarOpacity = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Fade in the app bar background over the first 200 px of scroll.
    final offset = _scrollController.offset;
    final opacity = (offset / 200).clamp(0.0, 1.0);
    if ((opacity - _appBarOpacity).abs() > 0.01) {
      setState(() => _appBarOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentlyAddedAsync = ref.watch(recentlyAddedFilesProvider);
    final allMediaFilesAsync = ref.watch(allMediaFilesProvider);
    final continueWatchingFiles = ref.watch(continueWatchingFilesProvider);
    final isScanning = ref.watch(scanningStateProvider);
    final fetchStatus = ref.watch(metadataFetchProvider);

    // Show error snackbar when metadata fetch errors occur
    ref.listen<MetadataFetchStatus>(metadataFetchProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final recentlyAdded = recentlyAddedAsync.value?.map(MediaItem.fromMediaFile).toList() ?? [];
    final allMediaFiles = allMediaFilesAsync.value?.map(MediaItem.fromMediaFile).toList() ?? [];
    final continueWatching = continueWatchingFiles.map(MediaItem.fromMediaFile).toList();
    final heroItems = allMediaFiles.take(5).toList();

    final movieFiles = allMediaFiles.where((item) => item.type == MediaType.movie).toList();
    final tvShowFiles = allMediaFiles.where((item) => item.type == MediaType.tvShow).toList();
    final animeFiles = allMediaFiles.where((item) => item.type == MediaType.anime).toList();
    final uncategorizedFiles = allMediaFiles.where((item) => item.type == MediaType.uncategorized).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      // ── Floating app bar ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: kBackgroundColor.withValues(alpha: _appBarOpacity * 0.95),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // App logo / title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [kAccentColor, kProgressFill],
                    ).createShader(bounds),
                    child: const Text(
                      'FluxPlayer',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white, // masked by gradient
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (isScanning) ...[
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(kAccentColor)),
                    ),
                  ],
                  const Spacer(),
                  // Nav items (placeholder for now)
                  _NavItem(label: 'Home', isActive: true),
                  _NavItem(label: 'Movies'),
                  _NavItem(label: 'TV Shows'),
                  _NavItem(label: 'Library'),
                  const SizedBox(width: 16),
                  // Search icon
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {},
                    tooltip: 'Search',
                  ),
                  // Settings icon
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LibraryManagementScreen(),
                        ),
                      );
                    },
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Scrollable body ──
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero banner
            if (heroItems.isNotEmpty) ...[
              HeroBanner(
                items: heroItems,
                onPlay: (item) {
                  final files = allMediaFilesAsync.value;
                  if (files != null) {
                    final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(mediaFile: matchingFile),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 28),
            ],

            // 2. Continue Watching (Real Data)
            if (continueWatching.isNotEmpty)
              HorizontalMediaRow(
                title: 'Continue Watching',
                itemCount: continueWatching.length,
                height: 145,
                onSeeAll: () {},
                itemBuilder: (context, index) {
                  return ContinueWatchingCard(
                    item: continueWatching[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(mediaFile: continueWatchingFiles[index]),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 32),

            // 3. Recently Added (Real Data)
            if (recentlyAdded.isNotEmpty)
              HorizontalMediaRow(
                title: 'Recently Added',
                itemCount: recentlyAdded.length,
                height: 215,
                onSeeAll: () {},
                itemBuilder: (context, index) {
                  return MediaCard(
                    item: recentlyAdded[index],
                    onTap: () {
                      final files = recentlyAddedAsync.value;
                      if (files != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerScreen(mediaFile: files[index]),
                          ),
                        );
                      }
                    },
                  );
                },
              ),

            if (recentlyAdded.isNotEmpty) const SizedBox(height: 36),

            // 4. Movies grid
            if (movieFiles.isNotEmpty)
              MediaGrid(
                title: 'Movies',
                items: movieFiles,
                onSeeAll: () {},
                onItemTap: (index) {
                  final item = movieFiles[index];
                  final files = allMediaFilesAsync.value;
                  if (files != null) {
                    final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(mediaFile: matchingFile),
                      ),
                    );
                  }
                },
              ),

            if (movieFiles.isNotEmpty) const SizedBox(height: 36),

            // 5. TV Shows grid
            if (tvShowFiles.isNotEmpty)
              MediaGrid(
                title: 'TV Shows',
                items: tvShowFiles,
                onSeeAll: () {},
                onItemTap: (index) {
                  final item = tvShowFiles[index];
                  final files = allMediaFilesAsync.value;
                  if (files != null) {
                    final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(mediaFile: matchingFile),
                      ),
                    );
                  }
                },
              ),

            if (tvShowFiles.isNotEmpty) const SizedBox(height: 36),

            // 6. Anime grid
            if (animeFiles.isNotEmpty)
              MediaGrid(
                title: 'Anime',
                items: animeFiles,
                onSeeAll: () {},
                onItemTap: (index) {
                  final item = animeFiles[index];
                  final files = allMediaFilesAsync.value;
                  if (files != null) {
                    final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(mediaFile: matchingFile),
                      ),
                    );
                  }
                },
              ),

            if (animeFiles.isNotEmpty) const SizedBox(height: 36),

            // 7. Uncategorized grid
            if (uncategorizedFiles.isNotEmpty)
              MediaGrid(
                title: 'Uncategorized',
                items: uncategorizedFiles,
                onSeeAll: () {},
                onItemTap: (index) {
                  final item = uncategorizedFiles[index];
                  final files = allMediaFilesAsync.value;
                  if (files != null) {
                    final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(mediaFile: matchingFile),
                      ),
                    );
                  }
                },
              ),

            if (allMediaFiles.isEmpty && recentlyAdded.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open, size: 64, color: kMutedText),
                      const SizedBox(height: 16),
                      const Text(
                        'Your library is empty',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LibraryManagementScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentColor,
                        ),
                        child: const Text('Add Library Folders'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 48),

            // ── Footer ──
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [kAccentColor, kProgressFill],
                      ).createShader(bounds),
                      child: const Text(
                        'FluxPlayer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your media, beautifully organized.',
                      style: TextStyle(color: kMutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Persistent bottom fetch indicator ──
      bottomNavigationBar: fetchStatus.isFetching
          ? Container(
              color: kSurfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(kAccentColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Fetching metadata\u2026 ${fetchStatus.remainingFiles} remaining',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${fetchStatus.processedFiles}/${fetchStatus.totalFiles}',
                      style: const TextStyle(
                        color: kMutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ─── Small nav-bar item ─────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({required this.label, this.isActive = false});
  final String label;
  final bool isActive;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
              color: widget.isActive
                  ? Colors.white
                  : _hovering
                      ? Colors.white70
                      : kMutedText,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.isActive ? 16 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
