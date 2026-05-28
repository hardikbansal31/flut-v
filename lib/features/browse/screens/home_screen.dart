/// Home screen — the main browse view of the media player.
///
/// Composes all UI sections into a single [CustomScrollView] with slivers:
///   1. Hero banner carousel (top, wrapped in RepaintBoundary)
///   2. Continue Watching horizontal row
///   3. Recently Added horizontal row
///   4. Category grids (Movies, TV Shows, Anime, Uncategorized) — true SliverGrids
///
/// Uses a transparent app bar that fades in a background as the user scrolls.
/// Shows a persistent bottom indicator during metadata fetching.
///
/// Each data-driven section is a standalone [ConsumerWidget] so that provider
/// updates only rebuild the section that changed, not the entire tree.
///
/// The category grids use [SliverGrid] via [MediaGrid.buildSlivers] so that
/// cards are lazily built only when they scroll into the viewport, eliminating
/// the performance penalty of `shrinkWrap: true` GridViews.
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only watch providers that affect the scaffold-level layout.
    final isScanning = ref.watch(scanningStateProvider);

    // Listen for metadata errors (side-effect only — not displayed in build).
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      // ── Floating app bar (isolated to avoid whole-tree rebuilds) ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _FadingAppBar(
          scrollController: _scrollController,
          isScanning: isScanning,
        ),
      ),

      // ── Scrollable body — CustomScrollView with slivers ──
      body: CustomScrollView(
        controller: _scrollController,
        slivers: const [
          // 1. Hero banner (isolated behind RepaintBoundary)
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: _HeroBannerSection(),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 28)),

          // 2. Continue Watching
          SliverToBoxAdapter(child: _ContinueWatchingSection()),

          SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 3. Recently Added
          SliverToBoxAdapter(child: _RecentlyAddedSection()),

          // 4–7. Category grids (returns multiple slivers internally)
          _CategoryGridsSliverSection(),

          // ── Empty state ──
          SliverToBoxAdapter(child: _EmptyLibraryPlaceholder()),

          SliverToBoxAdapter(child: SizedBox(height: 48)),

          // ── Footer ──
          _FooterSliver(),
        ],
      ),

      // ── Persistent bottom fetch indicator (own ConsumerWidget) ──
      bottomNavigationBar: const _FetchStatusBar(),
    );
  }
}

// ─── Hero Banner Section ────────────────────────────────────────────────────

/// Watches [allMediaFilesProvider] but caches the [HeroBanner] widget instance.
/// Only recreates the banner when the first 5 item IDs change, preventing
/// the DB stream's frequent emissions (during metadata fetching) from
/// causing unnecessary banner rebuilds.
class _HeroBannerSection extends ConsumerStatefulWidget {
  const _HeroBannerSection();

  @override
  ConsumerState<_HeroBannerSection> createState() =>
      _HeroBannerSectionState();
}

class _HeroBannerSectionState extends ConsumerState<_HeroBannerSection> {
  List<String> _trackedIds = const [];
  Widget _cachedBanner = const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final asyncFiles = ref.watch(allMediaFilesProvider);
    final files = asyncFiles.value;
    if (files == null || files.isEmpty) return const SizedBox.shrink();

    // Only compare IDs — metadata fields (poster, rating, etc.) changing
    // should NOT rebuild the banner.
    final heroFiles = files.take(5).toList();
    final newIds = heroFiles.map((f) => f.id.toString()).toList();

    if (_idsEqual(newIds, _trackedIds)) {
      // Return the exact same widget instance → Flutter skips the subtree.
      return _cachedBanner;
    }

    _trackedIds = newIds;
    final heroItems = heroFiles.map(MediaItem.fromMediaFile).toList();
    _cachedBanner = HeroBanner(
      items: heroItems,
      onPlay: _onPlay,
    );
    return _cachedBanner;
  }

  void _onPlay(MediaItem item) {
    final files = ref.read(allMediaFilesProvider).value;
    if (files != null) {
      final matchingFile =
          files.firstWhere((file) => file.id.toString() == item.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(mediaFile: matchingFile),
        ),
      );
    }
  }

  static bool _idsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─── Continue Watching Section ──────────────────────────────────────────────

/// Watches [continueWatchingFilesProvider] only.
class _ContinueWatchingSection extends ConsumerWidget {
  const _ContinueWatchingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatchingFiles = ref.watch(continueWatchingFilesProvider);
    final continueWatching =
        continueWatchingFiles.map(MediaItem.fromMediaFile).toList();

    if (continueWatching.isEmpty) return const SizedBox.shrink();

    return HorizontalMediaRow(
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
                builder: (context) =>
                    PlayerScreen(mediaFile: continueWatchingFiles[index]),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Recently Added Section ─────────────────────────────────────────────────

/// Watches [recentlyAddedFilesProvider] only.
class _RecentlyAddedSection extends ConsumerWidget {
  const _RecentlyAddedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyAddedAsync = ref.watch(recentlyAddedFilesProvider);
    final recentlyAdded =
        recentlyAddedAsync.value?.map(MediaItem.fromMediaFile).toList() ?? [];

    if (recentlyAdded.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HorizontalMediaRow(
          title: 'Recently Added',
          itemCount: recentlyAdded.length,
          height: 215,
          onSeeAll: () {},
          itemBuilder: (context, index) {
            return MediaCard(
              item: recentlyAdded[index],
              onTap: () {
                // Use ref.read — tap action, not reactive display.
                final files = ref.read(recentlyAddedFilesProvider).value;
                if (files != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlayerScreen(mediaFile: files[index]),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

// ─── Category Grids Sliver Section ──────────────────────────────────────────

/// A custom sliver that watches [allMediaFilesProvider] and produces
/// multiple child slivers — one [MediaGrid.buildSlivers] per category.
///
/// Caches the entire [SliverMainAxisGroup] widget instance and only recreates
/// it when the set of media file IDs changes. This prevents the DB stream's
/// frequent emissions during metadata fetching from rebuilding all visible
/// media cards.
class _CategoryGridsSliverSection extends ConsumerStatefulWidget {
  const _CategoryGridsSliverSection();

  @override
  ConsumerState<_CategoryGridsSliverSection> createState() =>
      _CategoryGridsSliverSectionState();
}

class _CategoryGridsSliverSectionState
    extends ConsumerState<_CategoryGridsSliverSection> {
  String _trackedIdHash = '';
  Widget _cached = const SliverToBoxAdapter(child: SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final allMediaFilesAsync = ref.watch(allMediaFilesProvider);
    final files = allMediaFilesAsync.value;
    if (files == null || files.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Build a lightweight hash of all file IDs. If only metadata fields
    // changed (poster, rating, genres) but the set of files is the same,
    // we skip the rebuild entirely.
    final newIdHash = files.map((f) => f.id).join(',');
    if (newIdHash == _trackedIdHash) {
      return _cached;
    }
    _trackedIdHash = newIdHash;

    final allMediaFiles =
        files.map(MediaItem.fromMediaFile).toList();

    final movieFiles =
        allMediaFiles.where((item) => item.type == MediaType.movie).toList();
    final tvShowFiles =
        allMediaFiles.where((item) => item.type == MediaType.tvShow).toList();
    final animeFiles =
        allMediaFiles.where((item) => item.type == MediaType.anime).toList();
    final uncategorizedFiles = allMediaFiles
        .where((item) => item.type == MediaType.uncategorized)
        .toList();

    // Collect all category slivers into a single list.
    final slivers = <Widget>[];

    if (movieFiles.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'Movies',
        items: movieFiles,
        onSeeAll: () {},
        onItemTap: (index) =>
            _navigateToPlayer(context, movieFiles[index]),
      ).buildSlivers(context));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 36)));
    }

    if (tvShowFiles.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'TV Shows',
        items: tvShowFiles,
        onSeeAll: () {},
        onItemTap: (index) =>
            _navigateToPlayer(context, tvShowFiles[index]),
      ).buildSlivers(context));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 36)));
    }

    if (animeFiles.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'Anime',
        items: animeFiles,
        onSeeAll: () {},
        onItemTap: (index) =>
            _navigateToPlayer(context, animeFiles[index]),
      ).buildSlivers(context));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 36)));
    }

    if (uncategorizedFiles.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'Uncategorized',
        items: uncategorizedFiles,
        onSeeAll: () {},
        onItemTap: (index) =>
            _navigateToPlayer(context, uncategorizedFiles[index]),
      ).buildSlivers(context));
    }

    if (slivers.isEmpty) {
      _cached = const SliverToBoxAdapter(child: SizedBox.shrink());
      return _cached;
    }

    _cached = SliverMainAxisGroup(slivers: slivers);
    return _cached;
  }

  void _navigateToPlayer(BuildContext context, MediaItem item) {
    // Use ref.read — tap action, not reactive display.
    final files = ref.read(allMediaFilesProvider).value;
    if (files != null) {
      final matchingFile =
          files.firstWhere((file) => file.id.toString() == item.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(mediaFile: matchingFile),
        ),
      );
    }
  }
}

// ─── Footer ─────────────────────────────────────────────────────────────────

class _FooterSliver extends StatelessWidget {
  const _FooterSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
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
    );
  }
}

// ─── Empty Library Placeholder ──────────────────────────────────────────────

/// Only watches [allMediaFilesProvider] and [recentlyAddedFilesProvider]
/// to decide whether to show the empty state.
class _EmptyLibraryPlaceholder extends ConsumerWidget {
  const _EmptyLibraryPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMediaFiles = ref.watch(allMediaFilesProvider).value ?? [];
    final recentlyAdded = ref.watch(recentlyAddedFilesProvider).value ?? [];

    if (allMediaFiles.isNotEmpty || recentlyAdded.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
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
    );
  }
}

// ─── Fetch Status Bar ───────────────────────────────────────────────────────

/// Isolated ConsumerWidget that watches [metadataFetchProvider] only.
/// Previously this was inline in the HomeScreen build(), causing the entire
/// home screen to rebuild on every fetch progress tick.
class _FetchStatusBar extends ConsumerWidget {
  const _FetchStatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetchStatus = ref.watch(metadataFetchProvider);

    if (!fetchStatus.isFetching) return const SizedBox.shrink();

    return Container(
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
    );
  }
}

// ─── Fading app bar (own state for scroll-driven opacity) ───────────────────

/// Isolated app bar widget that listens to the scroll controller via a
/// [ValueNotifier] and only rebuilds the background [Container] color.
///
/// The entire child tree (logo, nav items, buttons) is passed as the
/// [ValueListenableBuilder.child] so it is built **once** and reused on
/// every scroll tick — zero child rebuilds.
class _FadingAppBar extends StatefulWidget {
  const _FadingAppBar({
    required this.scrollController,
    required this.isScanning,
  });

  final ScrollController scrollController;
  final bool isScanning;

  @override
  State<_FadingAppBar> createState() => _FadingAppBarState();
}

class _FadingAppBarState extends State<_FadingAppBar> {
  final ValueNotifier<double> _opacity = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _FadingAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _opacity.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final newOpacity = (offset / 200).clamp(0.0, 1.0);
    if ((newOpacity - _opacity.value).abs() > 0.01) {
      _opacity.value = newOpacity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _opacity,
      // ── child is built ONCE and reused on every scroll tick ──
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // App logo — RepaintBoundary caches the ShaderMask rasterisation.
              RepaintBoundary(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [kAccentColor, kProgressFill],
                  ).createShader(bounds),
                  child: const Text(
                    'FluxPlayer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (widget.isScanning) ...[
                const SizedBox(width: 16),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(kAccentColor)),
                ),
              ],
              const Spacer(),
              _NavItem(label: 'Home', isActive: true),
              _NavItem(label: 'Movies'),
              _NavItem(label: 'TV Shows'),
              _NavItem(label: 'Library'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {},
                tooltip: 'Search',
              ),
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
      // ── builder only fires when opacity changes; child is reused ──
      builder: (context, opacity, child) {
        return Container(
          color: kBackgroundColor.withValues(alpha: opacity * 0.95),
          child: child,
        );
      },
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
