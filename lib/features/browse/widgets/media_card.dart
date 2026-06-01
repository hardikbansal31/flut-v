/// A standard poster-style media card.
///
/// Shows a TMDB poster image when available, falling back to a gradient
/// placeholder. Includes hover / focus elevation animation for desktop UIs.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MediaItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = item.posterGradientColors;
    final hasPoster = item.posterUrl != null;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HoverScaleWrapper(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poster image or gradient fallback ──
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasPoster
                    ? CachedNetworkImage(
                        imageUrl: item.posterUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheWidth: (300 * dpr).round(),
                          memCacheHeight: (450 * dpr).round(),
                          placeholder: (context, url) => _GradientPlaceholder(
                            colors: colors,
                            type: item.type,
                          ),
                          errorWidget: (context, url, error) => _GradientPlaceholder(
                            colors: colors,
                            type: item.type,
                          ),
                        )
                      : _GradientPlaceholder(
                          colors: colors,
                          type: item.type,
                        ),
                ),
              ),

              // ── Bottom info ──
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item.year != null)
                    Text(
                      '${item.year}',
                      style: AppTextStyles.cardMeta,
                    ),
                  if (item.year != null && item.rating != null)
                    const SizedBox(width: 6),
                  if (item.rating != null) ...[
                    Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: 12, color: kSecondaryAccent),
                    const SizedBox(width: 2),
                    Text(
                      item.rating!.toStringAsFixed(1),
                      style: AppTextStyles.cardRating,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoverScaleWrapper extends StatefulWidget {
  const _HoverScaleWrapper({
    required this.child,
    this.onTap,
  });

  final Widget child;
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
          transform: Matrix4.identity()
            ..translate(0.0, _hovering ? -4.0 : 0.0)
            ..scale(_hovering ? 1.04 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
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
            children: [
              widget.child,
              if (_hovering)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Icon(
                        PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                        size: 48,
                        color: Colors.white,
                      ),
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
                ? PhosphorIcons.television()
                : type == MediaType.anime
                    ? PhosphorIcons.filmStrip()
                    : PhosphorIcons.filmSlate(),
            size: 40,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
