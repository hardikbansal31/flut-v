/// A labelled grid section that displays media cards in a responsive sliver grid.
///
/// Used for the "Movies", "TV Shows", "Anime", and "Uncategorized" sections
/// of the home screen.  Returns a list of slivers suitable for use inside a
/// [CustomScrollView], which enables true lazy-loading of grid children —
/// only cards currently visible in the viewport are built and laid out.
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

  /// Returns the list of slivers that compose this grid section.
  ///
  /// Call this from a [CustomScrollView.slivers] list. The returned slivers
  /// include the section header and the responsive grid itself.
  List<Widget> buildSlivers(BuildContext context) {
    return [
      // ── Section header ──
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: Row(
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
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 14)),

      // ── Responsive sliver grid ──
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            // Responsive column count based on available cross-axis width.
            final width = constraints.crossAxisExtent;
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

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.65,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                childCount: items.length,
              ),
            );
          },
        ),
      ),
    ];
  }

  /// Fallback [build] — kept so the widget can still be instantiated
  /// as a regular widget in tests or simple layouts.  Prefer [buildSlivers]
  /// for use inside a [CustomScrollView].
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: buildSlivers(context),
    );
  }
}
