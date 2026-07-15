/// Full-width hero banner with auto-scrolling carousel.
///
/// Displays a featured media item with a dramatic backdrop image (from TMDB)
/// or gradient fallback, title, metadata chips, synopsis, and action buttons.
/// Includes page indicators and auto-advances every 6 seconds.
///
/// Uses an [AnimationController] scoped to this widget only. The page
/// indicators are driven via [AnimatedBuilder] so that neither the PageView
/// nor any ancestor widget is rebuilt on page transitions.
library;

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key, required this.items, this.onPlay, this.onMoreInfo});

  final List<MediaItem> items;
  final ValueChanged<MediaItem>? onPlay;
  final ValueChanged<MediaItem>? onMoreInfo;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  /// ValueNotifier for the current page index - drives only the indicator
  /// row via [AnimatedBuilder], avoiding a full widget rebuild.
  late final ValueNotifier<int> _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = ValueNotifier<int>(0);
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final next = (_currentPage.value + 1) % widget.items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Banner takes up ~70 % of screen height for cinematic impact.
    final bannerHeight = screenHeight * 0.70;

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // Page view of backdrop gradients
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (i) => _currentPage.value = i,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _HeroBannerSlide(
                item: item,
                onPlay: widget.onPlay != null ? () => widget.onPlay!(item) : null,
                onMoreInfo: widget.onMoreInfo != null ? () => widget.onMoreInfo!(item) : null,
              );
            },
          ),

          // Page indicators (rebuilt only when _currentPage changes)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                return ValueListenableBuilder<int>(
                  valueListenable: _currentPage,
                  builder: (context, currentPage, _) {
                    final isActive = i == currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isActive
                            ? kAccentColor
                            : AppTheme.textPrimary.withValues(alpha: 0.3),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Individual slide

class _HeroBannerSlide extends StatelessWidget {
  const _HeroBannerSlide({required this.item, this.onPlay, this.onMoreInfo});

  final MediaItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onMoreInfo;

  @override
  Widget build(BuildContext context) {
    final colors = item.backdropGradientColors ?? item.posterGradientColors;
    final hasBackdrop = item.backdropUrl != null;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop image or gradient
        if (hasBackdrop) ...[
          // Real TMDB backdrop image
          CachedNetworkImage(
            imageUrl: item.backdropUrl!,
            fit: BoxFit.cover,
            memCacheWidth: (960 * dpr).round(),
            memCacheHeight: (540 * dpr).round(),
            placeholder: (context, url) => _GradientBackdrop(colors: colors),
            errorWidget: (context, url, error) => _GradientBackdrop(colors: colors),
          ),
          // Darken overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundBlack.withValues(alpha: 0.3),
                  AppTheme.backgroundBlack.withValues(alpha: 0.5),
                  kBackgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ] else ...[
          // Gradient-only backdrop (no TMDB image)
          _GradientBackdrop(colors: colors),
        ],


        // Content overlay
        Positioned(
          left: 32,
          right: 32,
          bottom: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Genre chips
              if (item.genres.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: item.genres.map((g) {
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.textPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.textPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        g,
                        style: AppTextStyles.genreTagHero,
                      ),
                    );
                  }).toList(),
                ),

              if (item.genres.isNotEmpty) const SizedBox(height: 12),

              // Title
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Year - Rating row
              Row(
                children: [
                  if (item.year != null)
                    Text(
                      '${item.year}',
                      style: AppTextStyles.seriesMeta,
                    ),
                  if (item.year != null && item.rating != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        PhosphorIcons.circleFill,
                        size: 6,
                        color: kMutedText,
                      ),
                    ),
                  if (item.rating != null) ...[
                    Icon(PhosphorIcons.starFill,
                        color: kSecondaryAccent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      item.rating!.toStringAsFixed(1),
                      style: AppTextStyles.seriesRating,
                    ),
                  ],
                  if (item.type == MediaType.tvShow) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        PhosphorIcons.circleFill,
                        size: 6,
                        color: kMutedText,
                      ),
                    ),
                    Text(
                      'TV Series',
                      style: AppTextStyles.seriesMeta,
                    ),
                  ],
                  if (item.type == MediaType.anime) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        PhosphorIcons.circleFill,
                        size: 6,
                        color: kMutedText,
                      ),
                    ),
                    Text(
                      'Anime',
                      style: AppTextStyles.seriesMeta,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Synopsis
              if (item.overview != null)
                Text(
                  item.overview!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overviewHero,
                ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  // Play button
                  ElevatedButton.icon(
                    onPressed: onPlay,
                    icon: Icon(PhosphorIcons.playFill, size: 22),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: AppTextStyles.buttonText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // More info button
                  OutlinedButton.icon(
                    onPressed: onMoreInfo,
                    icon: Icon(PhosphorIcons.info, size: 20),
                    label: const Text('More Info'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side:
                          BorderSide(color: AppTheme.textPrimary.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: AppTextStyles.buttonTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gradient-only backdrop used when no TMDB image is available.
class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({required this.colors});
  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(colors[0]),
            Color(colors[1]).withValues(alpha: 0.6),
            kBackgroundColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
