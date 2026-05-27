/// A standard poster-style media card.
///
/// Shows a TMDB poster image when available, falling back to a gradient
/// placeholder. Includes hover / focus elevation animation for desktop UIs.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    this.width = 140,
    this.height = 210,
    this.onTap,
  });

  final MediaItem item;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = item.posterGradientColors;
    final hasPoster = item.posterUrl != null;

    return _HoverScaleWrapper(
      width: width,
      height: height,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Poster image or gradient fallback ──
          if (hasPoster)
            CachedNetworkImage(
              imageUrl: item.posterUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              memCacheHeight: 450,
              placeholder: (context, url) => _GradientPlaceholder(
                colors: colors,
                type: item.type,
              ),
              errorWidget: (context, url, error) => _GradientPlaceholder(
                colors: colors,
                type: item.type,
              ),
            )
          else
            _GradientPlaceholder(
              colors: colors,
              type: item.type,
            ),

          // ── Bottom info gradient ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.year != null)
                        Text(
                          '${item.year}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: kMutedText,
                          ),
                        ),
                      if (item.rating != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            size: 12, color: kSecondaryAccent),
                        const SizedBox(width: 2),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: kSecondaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // ── Rating badge ──
          if (item.rating != null)
            Positioned(
              top: 8,
              right: 8,
              child: _RatingBadge(rating: item.rating!),
            ),
        ],
      ),
    );
  }
}

class _HoverScaleWrapper extends StatefulWidget {
  const _HoverScaleWrapper({
    required this.child,
    required this.width,
    required this.height,
    this.onTap,
  });

  final Widget child;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  State<_HoverScaleWrapper> createState() => _HoverScaleWrapperState();
}

class _HoverScaleWrapperState extends State<_HoverScaleWrapper> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.width,
          height: widget.height,
          transform: Matrix4.diagonal3Values(
            _hovering ? 1.05 : 1.0,
            _hovering ? 1.05 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (_hovering)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: kSecondaryAccent),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient placeholder shown when no poster image is available or while loading.
class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.colors, required this.type});

  final List<int> colors;
  final MediaType type;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(colors[0]), Color(colors[1])],
            ),
          ),
        ),
        // Film-grain style noise overlay
        Container(color: Colors.black.withValues(alpha: 0.15)),
        // Icon watermark
        Center(
          child: Icon(
            type == MediaType.tvShow
                ? Icons.live_tv_rounded
                : type == MediaType.anime
                    ? Icons.animation_rounded
                    : Icons.movie_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
