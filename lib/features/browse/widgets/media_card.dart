/// A standard poster-style media card.
///
/// Shows a TMDB poster image when available, falling back to a gradient
/// placeholder. Includes hover / focus elevation animation for desktop UIs.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';

class MediaCard extends StatefulWidget {
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
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.item.posterGradientColors;
    final hasPoster = widget.item.posterUrl != null;

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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(colors[0]).withValues(alpha: _hovering ? 0.5 : 0.25),
                blurRadius: _hovering ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Poster image or gradient fallback ──
                if (hasPoster)
                  CachedNetworkImage(
                    imageUrl: widget.item.posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _GradientPlaceholder(
                      colors: colors,
                      type: widget.item.type,
                    ),
                    errorWidget: (context, url, error) => _GradientPlaceholder(
                      colors: colors,
                      type: widget.item.type,
                    ),
                  )
                else
                  _GradientPlaceholder(
                    colors: colors,
                    type: widget.item.type,
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
                          widget.item.title,
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
                            if (widget.item.year != null)
                              Text(
                                '${widget.item.year}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: kMutedText,
                                ),
                              ),
                            if (widget.item.rating != null) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded,
                                  size: 12, color: kSecondaryAccent),
                              const SizedBox(width: 2),
                              Text(
                                widget.item.rating!.toStringAsFixed(1),
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

                // ── Hover border glow ──
                if (_hovering)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kAccentColor.withValues(alpha: 0.6),
                        width: 2,
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
