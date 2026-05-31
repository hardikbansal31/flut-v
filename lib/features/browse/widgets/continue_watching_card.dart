/// A wider card with a progress bar for the "Continue Watching" row.
///
/// Shows a TMDB backdrop/poster thumbnail when available, falling back to
/// a gradient. Includes title, time remaining label, and a slim progress
/// bar at the bottom edge.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';

class ContinueWatchingCard extends StatefulWidget {
  const ContinueWatchingCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MediaItem item;
  final VoidCallback? onTap;

  @override
  State<ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<ContinueWatchingCard> {
  bool _hovering = false;

  /// Formats minutes into "Xh Ym" or "Ym".
  String _formatRemaining(int minutes) {
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m left';
    }
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = item.posterGradientColors;
    final remaining = item.durationMinutes - item.watchedMinutes;
    // Prefer backdrop for the wider card, fall back to poster
    final thumbnailUrl = item.backdropUrl ?? item.posterUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 220,
          height: 140,
          transform: Matrix4.diagonal3Values(
            _hovering ? 1.04 : 1.0,
            _hovering ? 1.04 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color(colors[0]).withValues(alpha: _hovering ? 0.45 : 0.2),
                blurRadius: _hovering ? 18 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Thumbnail image or gradient ──
                if (thumbnailUrl != null)
                  Builder(
                    builder: (context) {
                      final dpr = MediaQuery.devicePixelRatioOf(context);
                      return CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: (500 * dpr).round(),
                        memCacheHeight: (280 * dpr).round(),
                        placeholder: (context, url) => _GradientThumbnail(colors: colors),
                        errorWidget: (context, url, error) => _GradientThumbnail(colors: colors),
                      );
                    }
                  )
                else
                  _GradientThumbnail(colors: colors),

                // ── Darkening overlay ──
                Container(color: Colors.black.withValues(alpha: 0.25)),

                // ── Play icon centre ──
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hovering ? 1.0 : 0.6,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // ── Bottom overlay: title + time remaining ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 8, top: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.continueWatchingTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRemaining(remaining),
                          style: AppTextStyles.cardMeta,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Progress bar at very bottom ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: kProgressTrack,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(kProgressFill),
                      minHeight: 3,
                    ),
                  ),
                ),

                // ── Hover border ──
                if (_hovering)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: kProgressFill.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
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

/// Gradient thumbnail fallback for continue watching cards.
class _GradientThumbnail extends StatelessWidget {
  const _GradientThumbnail({required this.colors});
  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(colors[0]), Color(colors[1])],
        ),
      ),
    );
  }
}
