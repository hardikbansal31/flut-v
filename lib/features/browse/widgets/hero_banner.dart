/// Full-width hero banner with auto-scrolling carousel.
///
/// Displays a featured media item with a dramatic backdrop image (from TMDB)
/// or gradient fallback, title, metadata chips, synopsis, and action buttons.
/// Includes page indicators and auto-advances every 6 seconds.
library;

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key, required this.items, this.onPlay});

  final List<MediaItem> items;
  final ValueChanged<MediaItem>? onPlay;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.items.length;
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
          // ── Page view of backdrop gradients ──
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _HeroBannerSlide(
                item: item,
                onPlay: widget.onPlay != null ? () => widget.onPlay!(item) : null,
              );
            },
          ),

          // ── Page indicators ──
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? kAccentColor
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual slide ───────────────────────────────────────────────────────

class _HeroBannerSlide extends StatelessWidget {
  const _HeroBannerSlide({required this.item, this.onPlay});

  final MediaItem item;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = item.backdropGradientColors ?? item.posterGradientColors;
    final hasBackdrop = item.backdropUrl != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Backdrop image or gradient ──
        if (hasBackdrop) ...[
          // Real TMDB backdrop image
          CachedNetworkImage(
            imageUrl: item.backdropUrl!,
            fit: BoxFit.cover,
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
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
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

        // ── Decorative radial glow ──
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(colors[0]).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Content overlay ──
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
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        g,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
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

              // Year • Rating row
              Row(
                children: [
                  if (item.year != null)
                    Text(
                      '${item.year}',
                      style: const TextStyle(
                        color: kMutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (item.year != null && item.rating != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: kMutedText)),
                    ),
                  if (item.rating != null) ...[
                    const Icon(Icons.star_rounded,
                        color: kSecondaryAccent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      item.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: kSecondaryAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (item.type == MediaType.tvShow) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: kMutedText)),
                    ),
                    const Text(
                      'TV Series',
                      style: TextStyle(
                        color: kMutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (item.type == MediaType.anime) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: kMutedText)),
                    ),
                    const Text(
                      'Anime',
                      style: TextStyle(
                        color: kMutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  // Play button
                  ElevatedButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // More info button
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    label: const Text('More Info'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
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
