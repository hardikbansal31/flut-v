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
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/settings/library_management_screen.dart';
import 'package:flutter_video/features/player/screens/player_screen.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/browse/screens/media_detail_screen.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:flutter_video/features/metadata/metadata_providers.dart';
import 'package:flutter_video/features/metadata/metadata_service.dart';
import 'package:flutter_video/features/browse/widgets/continue_watching_card.dart';
import 'package:flutter_video/features/browse/widgets/hero_banner.dart';
import 'package:flutter_video/features/browse/widgets/horizontal_media_row.dart';
import 'package:flutter_video/features/browse/widgets/media_grid.dart';
import 'package:flutter_video/features/browse/screens/category_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Prune DB entries for files deleted while the app was closed.
    // Uses the lightweight pruneDeletedFiles() which only does DB deletes
    // for missing files — no upserts, so no unnecessary Drift stream
    // emissions and zero GPU overhead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pruneOnStartup();
      // Eagerly initialise the file-system watcher so live deletions are
      // detected while the app is running.
      ref.read(libraryWatcherProvider);
    });
  }

  Future<void> _pruneOnStartup() async {
    final scanner = ref.read(libraryScannerProvider);
    await scanner.pruneDeletedFiles();
  }

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
            backgroundColor: AppTheme.errorSnackbar,
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
          _RecentlyAddedSection(),

          // 4–7. Category grids (returns multiple slivers internally)
          _CategoryGridsSliverSection(),

          // ── Empty state ──
          SliverToBoxAdapter(child: _EmptyLibraryPlaceholder()),

          SliverToBoxAdapter(child: SizedBox(height: 48)),
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

    final allSeries = ref.watch(groupedSeriesProvider);

    final allMediaItems = files.map(MediaItem.fromMediaFile).toList();
    final movieItems = allMediaItems.where((item) => item.type == MediaType.movie).toList();
    final tvSeries = allSeries.where((s) => s.type == MediaType.tvShow).toList();
    final animeSeries = allSeries.where((s) => s.type == MediaType.anime).toList();
    final uncategorizedItems = allMediaItems.where((item) => item.type == MediaType.uncategorized).toList();

    final aggregatedItems = <MediaItem>[];
    aggregatedItems.addAll(movieItems);
    aggregatedItems.addAll(tvSeries.map((s) => MediaItem.fromSeriesItem(s)));
    aggregatedItems.addAll(animeSeries.map((s) => MediaItem.fromSeriesItem(s)));
    aggregatedItems.addAll(uncategorizedItems);

    final heroItems = aggregatedItems.take(5).toList();
    final newIds = heroItems.map((f) => f.id.toString()).toList();

    if (_idsEqual(newIds, _trackedIds)) {
      return _cachedBanner;
    }

    _trackedIds = newIds;
    _cachedBanner = HeroBanner(
      items: heroItems,
      onPlay: _onPlay,
      onMoreInfo: _onMoreInfo,
    );
    return _cachedBanner;
  }

  void _onPlay(MediaItem item) {
    final files = ref.read(allMediaFilesProvider).value;
    final seriesList = ref.read(groupedSeriesProvider);
    
    if (item.type == MediaType.movie || item.type == MediaType.uncategorized) {
      if (files != null) {
        final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(mediaFile: matchingFile),
          ),
        );
      }
    } else {
      final matchingSeries = seriesList.firstWhere((s) => s.groupKey == item.id);
      final firstEp = matchingSeries.episodes.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(mediaFile: firstEp),
        ),
      );
    }
  }

  void _onMoreInfo(MediaItem item) {
    final files = ref.read(allMediaFilesProvider).value;
    final seriesList = ref.read(groupedSeriesProvider);

    if (item.type == MediaType.movie || item.type == MediaType.uncategorized) {
      if (files != null) {
        final matchingFile = files.firstWhere((file) => file.id.toString() == item.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailScreen(mediaFile: matchingFile),
          ),
        );
      }
    } else {
      final matchingSeries = seriesList.firstWhere((s) => s.groupKey == item.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(series: matchingSeries),
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

/// Watches [continueWatchingProvider] and groups TV episodes by series.
/// Shows one card per series (most recently watched episode) and one per movie.
class _ContinueWatchingSection extends ConsumerWidget {
  const _ContinueWatchingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(continueWatchingProvider);
    if (entries.isEmpty) return const SizedBox.shrink();

    // Build MediaItems for display
    final items = entries.map((entry) {
      if (entry.isSeries) {
        return MediaItem.fromSeriesItem(
          entry.series!,
          currentEpisode: entry.file,
        );
      }
      return MediaItem.fromMediaFile(entry.file);
    }).toList();

    return HorizontalMediaRow(
      title: 'Continue Watching',
      itemCount: items.length,
      height: 145,
      onSeeAll: () {},
      itemBuilder: (context, index) {
        final entry = entries[index];
        final item = items[index];

        // For series: the item already contains episodeLabel from MediaItem.fromSeriesItem
        final displayItem = item;

        return ContinueWatchingCard(
          item: displayItem,
          onTap: () {
            // Always navigate to the specific episode for playback
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayerScreen(mediaFile: entry.file),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Recently Added Section ─────────────────────────────────────────────────

/// Watches [recentlyAddedFilesProvider] and groups TV/anime into series cards.
class _RecentlyAddedSection extends ConsumerWidget {
  const _RecentlyAddedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyAddedAsync = ref.watch(recentlyAddedFilesProvider);
    final recentFiles = recentlyAddedAsync.value ?? [];

    if (recentFiles.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Separate movies from TV/anime
    final movies = recentFiles
        .where((f) => f.mediaType != 'tv' && f.mediaType != 'anime')
        .toList();
    final tvFiles = recentFiles
        .where((f) => f.mediaType == 'tv' || f.mediaType == 'anime')
        .toList();

    // Group TV/anime into series
    final seriesList = SeriesItem.groupFiles(tvFiles);

    // Build display items: movies as individual + series as grouped
    final displayItems = <_RecentItem>[];
    for (final file in movies) {
      displayItems.add(_RecentItem(
        mediaItem: MediaItem.fromMediaFile(file),
        file: file,
      ));
    }
    for (final series in seriesList) {
      displayItems.add(_RecentItem(
        mediaItem: MediaItem.fromSeriesItem(series),
        series: series,
      ));
    }

    if (displayItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        ...MediaGrid(
          title: 'Recently Added',
          items: displayItems.map((e) => e.mediaItem).toList(),
          onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Recently Added'))),
          onItemTap: (index) {
            final item = displayItems[index];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaDetailScreen(
                  series: item.series,
                  mediaFile: item.file,
                ),
              ),
            );
          },
        ).buildSlivers(context),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }
}

/// Helper class for recently added items (either a file or a grouped series).
class _RecentItem {
  final MediaItem mediaItem;
  final MediaFile? file;
  final SeriesItem? series;
  const _RecentItem({required this.mediaItem, this.file, this.series});
}

// ─── Category Grids Sliver Section ──────────────────────────────────────────

/// A custom sliver that watches [allMediaFilesProvider] and produces
/// multiple child slivers — one [MediaGrid.buildSlivers] per category.
///
/// TV Shows and Anime are grouped by series (one card per series),
/// Movies and Uncategorized show individual files.
///
/// Caches the widget to avoid unnecessary rebuilds during metadata fetching.
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

    // Also watch grouped series for TV/anime
    final allSeries = ref.watch(groupedSeriesProvider);

    // Build a lightweight hash of all file IDs + series count.
    final newIdHash =
        '${files.map((f) => f.id).join(',')}_${allSeries.length}';
    if (newIdHash == _trackedIdHash) {
      return _cached;
    }
    _trackedIdHash = newIdHash;

    final allMediaItems = files.map(MediaItem.fromMediaFile).toList();

    // Movies: individual file cards
    final movieItems =
        allMediaItems.where((item) => item.type == MediaType.movie).toList();

    // TV Shows: grouped series cards
    final tvSeries =
        allSeries.where((s) => s.type == MediaType.tvShow).toList();
    final tvItems =
        tvSeries.map((s) => MediaItem.fromSeriesItem(s)).toList();

    // Anime: grouped series cards
    final animeSeries =
        allSeries.where((s) => s.type == MediaType.anime).toList();
    final animeItems =
        animeSeries.map((s) => MediaItem.fromSeriesItem(s)).toList();

    // Uncategorized: individual file cards
    final uncategorizedItems = allMediaItems
        .where((item) => item.type == MediaType.uncategorized)
        .toList();

    // Collect all category slivers into a single list.
    final slivers = <Widget>[];

    if (movieItems.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'Movies',
        items: movieItems,
        onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Movies'))),
        onItemTap: (index) =>
            _navigateToPlayer(context, movieItems[index]),
      ).buildSlivers(context));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 36)));
    }

    if (tvItems.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'TV Shows',
        items: tvItems,
        onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'TV Shows'))),
        onItemTap: (index) =>
            _navigateToMediaDetail(context, series: tvSeries[index]),
      ).buildSlivers(context));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 36)));
    }

    if (animeItems.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'Anime',
        items: animeItems,
        onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Anime'))),
        onItemTap: (index) =>
            _navigateToMediaDetail(context, series: animeSeries[index]),
      ).buildSlivers(context));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 36)));
    }

    if (uncategorizedItems.isNotEmpty) {
      slivers.addAll(MediaGrid(
        title: 'Uncategorized',
        items: uncategorizedItems,
        onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Uncategorized'))),
        onItemTap: (index) {
          final file = files.firstWhere((f) => f.id.toString() == uncategorizedItems[index].id);
          _navigateToMediaDetail(context, mediaFile: file);
        },
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

  void _navigateToMediaDetail(
    BuildContext context, {
    SeriesItem? series,
    MediaFile? mediaFile,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaDetailScreen(
          series: series,
          mediaFile: mediaFile,
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
            Icon(PhosphorIcons.folderOpen(), size: 64, color: kMutedText),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: AppTextStyles.emptyLibraryTitle,
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
              style: AppTextStyles.fetchStatus,
            ),
            const Spacer(),
            Text(
              '${fetchStatus.processedFiles}/${fetchStatus.totalFiles}',
              style: AppTextStyles.episodeMeta,
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
              Text(
                'Penguin',
                style: AppTextStyles.brandTitle,
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
              _NavItem(
                label: 'Movies',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Movies'))),
              ),
              _NavItem(
                label: 'TV Shows',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'TV Shows'))),
              ),
              _NavItem(
                label: 'Anime',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Anime'))),
              ),
              _NavItem(
                label: 'Library',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'Library'))),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(PhosphorIcons.magnifyingGlass()),
                onPressed: () {},
                tooltip: 'Search',
              ),
              IconButton(
                icon: Icon(PhosphorIcons.gear()),
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
  const _NavItem({required this.label, this.isActive = false, this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

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
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.navItem.copyWith(
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
              color: widget.isActive
                  ? Colors.white
                  : _hovering
                      ? Colors.white70
                      : AppTheme.mutedText,
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
