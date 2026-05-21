/// A labelled grid section that displays media cards in a responsive grid.
///
/// Used for the "Movies" and "TV Shows" sections of the home screen.
/// Uses [SliverGrid] semantics but is wrapped as a normal widget for
/// easy composition inside a [CustomScrollView] or [ListView].
library;

import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';
import 'package:flutter_video/features/browse/widgets/media_card.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.onItemTap,
  });

  /// Section heading (e.g. "Movies").
  final String title;

  /// Items to render.
  final List<MediaItem> items;

  /// Called when "See All" is tapped.
  final VoidCallback? onSeeAll;

  /// Called when a specific media item is tapped.
  final void Function(int index)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: kAccentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: kAccentColor),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Responsive grid ──
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive column count based on available width.
              final width = constraints.maxWidth;
              int crossAxisCount;
              if (width >= 1200) {
                crossAxisCount = 6;
              } else if (width >= 900) {
                crossAxisCount = 5;
              } else if (width >= 600) {
                crossAxisCount = 4;
              } else {
                crossAxisCount = 3;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  return MediaCard(
                    item: items[index],
                    width: double.infinity,
                    height: double.infinity,
                    onTap: () {
                      if (onItemTap != null) {
                        onItemTap!(index);
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
