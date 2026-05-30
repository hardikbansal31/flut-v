/// Series detail page showing all episodes grouped by season.
///
/// Displays a backdrop banner, series info (title, year, rating, genres,
/// description), and episodes organised under "Season N" headers.
/// Each episode tile shows number, title, still image, duration, and
/// a progress bar if partially watched. Tapping an episode launches
/// the player directly.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart' as tmdb;
import 'package:flutter_video/features/player/screens/player_screen.dart';

class SeriesDetailScreen extends StatelessWidget {
  const SeriesDetailScreen({super.key, required this.series});

  final SeriesItem series;

  @override
  Widget build(BuildContext context) {
    final seasons = series.seasons;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Backdrop banner with back button ──────────────────────────
          SliverToBoxAdapter(
            child: _BackdropBanner(series: series),
          ),

          // ── Series info section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _SeriesInfoSection(series: series),
          ),

          // ── Season sections with episode tiles ───────────────────────
          for (final season in seasons) ...[
            // Season header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Season $season',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Episode list for this season
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final episodes = series.episodesForSeason(season);
                    final episode = episodes[index];
                    return _EpisodeTile(
                      file: episode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(mediaFile: episode),
                          ),
                        );
                      },
                    );
                  },
                  childCount: series.episodesForSeason(season).length,
                ),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ─── Backdrop Banner ────────────────────────────────────────────────────────

class _BackdropBanner extends StatelessWidget {
  const _BackdropBanner({required this.series});
  final SeriesItem series;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──
          if (series.backdropUrl != null)
            CachedNetworkImage(
              imageUrl: series.backdropUrl!,
              fit: BoxFit.cover,
              memCacheWidth: (1280 * dpr).round(),
              memCacheHeight: (720 * dpr).round(),
              placeholder: (_, __) => Container(color: kSurfaceColor),
              errorWidget: (_, __, ___) => Container(color: kSurfaceColor),
            )
          else if (series.posterUrl != null)
            CachedNetworkImage(
              imageUrl: series.posterUrl!,
              fit: BoxFit.cover,
              memCacheWidth: (500 * dpr).round(),
              placeholder: (_, __) => Container(color: kSurfaceColor),
              errorWidget: (_, __, ___) => Container(color: kSurfaceColor),
            )
          else
            Container(color: kSurfaceColor),

          // ── Gradient overlays ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  kBackgroundColor.withValues(alpha: 0.8),
                  kBackgroundColor,
                ],
                stops: const [0.0, 0.3, 0.75, 1.0],
              ),
            ),
          ),

          // ── Back button ──
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Series Info ────────────────────────────────────────────────────────────

class _SeriesInfoSection extends StatelessWidget {
  const _SeriesInfoSection({required this.series});
  final SeriesItem series;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            series.seriesTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          // ── Metadata row: year · rating · episode count ──
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (series.year != null)
                Text(
                  '${series.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: kMutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (series.rating != null && series.rating! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: kSecondaryAccent),
                    const SizedBox(width: 4),
                    Text(
                      series.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        color: kSecondaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              Text(
                '${series.episodeCount} episode${series.episodeCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: kMutedText,
                ),
              ),
              Text(
                '${series.seasons.length} season${series.seasons.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: kMutedText,
                ),
              ),
            ],
          ),

          // ── Genres ──
          if (series.genres.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: series.genres.map((genre) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAccentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kAccentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      fontSize: 12,
                      color: kAccentColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── Overview ──
          if (series.overview != null &&
              series.overview!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              series.overview!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Episode Tile ───────────────────────────────────────────────────────────

class _EpisodeTile extends StatefulWidget {
  const _EpisodeTile({required this.file, this.onTap});
  final MediaFile file;
  final VoidCallback? onTap;

  @override
  State<_EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<_EpisodeTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final epNum = SeriesItem.episodeNumberFor(file);
    final epName = SeriesItem.episodeNameFor(file) ?? file.fileName;
    final stillUrl = tmdb.backdropUrl(file.backdropPath);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // Watch progress
    final duration = file.durationMillis ?? 0;
    final position = file.positionMillis ?? 0;
    final progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;
    final hasProgress = position > 0 && progress > 0.01 && progress < 0.95;

    // Duration display
    final durationMin = duration > 0 ? (duration / 60000).round() : 0;
    final durationLabel = durationMin > 0
        ? (durationMin >= 60
            ? '${durationMin ~/ 60}h ${durationMin % 60}m'
            : '${durationMin}m')
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _hovering
                ? kCardColor.withValues(alpha: 0.8)
                : kSurfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovering
                  ? kAccentColor.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // ── Episode still image ──
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(8)),
                child: SizedBox(
                  width: 160,
                  height: 90,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (stillUrl != null)
                        CachedNetworkImage(
                          imageUrl: stillUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: (320 * dpr).round(),
                          memCacheHeight: (180 * dpr).round(),
                          placeholder: (_, __) =>
                              Container(color: kCardColor),
                          errorWidget: (_, __, ___) =>
                              Container(color: kCardColor),
                        )
                      else
                        Container(
                          color: kCardColor,
                          child: const Center(
                            child: Icon(Icons.movie_rounded,
                                color: kMutedText, size: 28),
                          ),
                        ),

                      // Play overlay on hover
                      if (_hovering)
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: const Center(
                            child: Icon(Icons.play_circle_fill_rounded,
                                size: 36, color: Colors.white),
                          ),
                        ),

                      // Progress bar at bottom
                      if (hasProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: kProgressTrack,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  kProgressFill),
                              minHeight: 3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Episode info ──
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Episode number badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: kAccentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'E$epNum',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kAccentColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Episode title
                          Expanded(
                            child: Text(
                              epName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (durationLabel != null)
                            Text(
                              durationLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMutedText,
                              ),
                            ),
                          if (hasProgress) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).round()}% watched',
                              style: TextStyle(
                                fontSize: 12,
                                color: kProgressFill.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Chevron ──
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: _hovering
                      ? Colors.white
                      : kMutedText.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
