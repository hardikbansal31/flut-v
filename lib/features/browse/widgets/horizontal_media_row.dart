/// A labelled horizontal scrolling row of media cards.
///
/// Used for "Continue Watching", "Recently Added", and similar sections.
/// Supports both [MediaCard] and [ContinueWatchingCard] via a builder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class HorizontalMediaRow extends StatelessWidget {
  const HorizontalMediaRow({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.onSeeAll,
    this.height = 230,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  /// Section heading text (e.g. "Continue Watching").
  final String title;

  /// Number of items.
  final int itemCount;

  /// Builder that returns each card widget.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Called when the "See All" button is tapped.
  final VoidCallback? onSeeAll;

  /// Total height of the scrollable row (including cards + spacing).
  final double height;

  /// Horizontal padding of the header / list.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // â”€â”€ Section header â”€â”€
        Padding(
          padding: padding,
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: AppTextStyles.seeAll,
                      ),
                      SizedBox(width: 4),
                      Icon(PhosphorIcons.caretRight,
                          size: 12, color: kAccentColor),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // â”€â”€ Scrollable card list â”€â”€
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: itemCount,
            separatorBuilder: (_, a) => const SizedBox(width: 14),
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}
