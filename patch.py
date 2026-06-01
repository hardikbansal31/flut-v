import sys

with open("lib/features/browse/screens/media_detail_screen.dart", "r") as f:
    content = f.read()

# 1. Imports
content = content.replace(
    "import 'package:flutter_video/features/player/screens/player_screen.dart';",
    "import 'package:flutter_video/features/player/screens/player_screen.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:flutter_video/features/library/library_providers.dart';"
)

# 2. ConsumerWidget
content = content.replace(
    "class MediaDetailScreen extends StatelessWidget {",
    "class MediaDetailScreen extends ConsumerWidget {"
)

# 3. Build method start
old_build = """  @override
  Widget build(BuildContext context) {
    final isSeries = series != null;
    final item = isSeries
        ? MediaItem.fromSeriesItem(series!)
        : MediaItem.fromMediaFile(mediaFile!);"""

new_build = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFiles = ref.watch(allMediaFilesProvider).value ?? [];
    final allSeries = ref.watch(groupedSeriesProvider);

    SeriesItem? currentSeries;
    MediaFile? currentMediaFile;

    if (series != null) {
      currentSeries = allSeries.cast<SeriesItem?>().firstWhere(
        (s) => s?.groupKey == series!.groupKey, 
        orElse: () => series
      );
    } else if (mediaFile != null) {
      currentMediaFile = allFiles.cast<MediaFile?>().firstWhere(
        (f) => f?.id == mediaFile!.id, 
        orElse: () => mediaFile
      );
    }

    final isSeries = currentSeries != null;
    final item = isSeries
        ? MediaItem.fromSeriesItem(currentSeries!)
        : MediaItem.fromMediaFile(currentMediaFile!);"""

content = content.replace(old_build, new_build)

# 4. _MediaInfoSection and mapping seasons
content = content.replace(
    "child: _MediaInfoSection(item: item, series: series),",
    "child: _MediaInfoSection(item: item, series: currentSeries),"
)
content = content.replace(
    "...series!.seasons.map((season) {",
    "...currentSeries!.seasons.map((season) {"
)
content = content.replace(
    "final episodes = series!.episodesForSeason(season);",
    "final episodes = currentSeries!.episodesForSeason(season);"
)
content = content.replace(
    "childCount: series!.episodesForSeason(season).length,",
    "childCount: currentSeries!.episodesForSeason(season).length,"
)

# 5. Episode mapping
old_episode = """                          return _EpisodeTile(
                            file: episode,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerScreen(mediaFile: episode),
                                ),
                              );
                            },
                          );"""

new_episode = """                          return _EpisodeTile(
                            file: episode,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerScreen(mediaFile: episode),
                                ),
                              );
                            },
                            onMarkWatched: () async {
                              final db = ref.read(databaseProvider);
                              final allEpisodes = currentSeries!.episodes;
                              final index = allEpisodes.indexWhere((e) => e.id == episode.id);
                              if (index != -1) {
                                final ids = allEpisodes.sublist(0, index + 1).map((e) => e.id).toList();
                                await db.markAsWatched(ids);
                              }
                            },
                            onMarkUnwatched: () async {
                              final db = ref.read(databaseProvider);
                              final allEpisodes = currentSeries!.episodes;
                              final index = allEpisodes.indexWhere((e) => e.id == episode.id);
                              if (index != -1) {
                                final ids = allEpisodes.sublist(index).map((e) => e.id).toList();
                                await db.markAsUnwatched(ids);
                              }
                            },
                          );"""
content = content.replace(old_episode, new_episode)


# 6. Movies button
old_button = """                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(mediaFile: mediaFile!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTextStyles.buttonText.copyWith(fontSize: 18),
                  ),
                ),"""

new_button = """                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(mediaFile: currentMediaFile!),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: AppTextStyles.buttonText.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Builder(
                      builder: (context) {
                        final duration = currentMediaFile!.durationMillis ?? 0;
                        final position = currentMediaFile!.positionMillis ?? 0;
                        final progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;
                        final isFullyWatched = progress >= 0.95;
                        
                        return ElevatedButton.icon(
                          onPressed: () async {
                            final db = ref.read(databaseProvider);
                            if (isFullyWatched) {
                              await db.markAsUnwatched([currentMediaFile!.id]);
                            } else {
                              await db.markAsWatched([currentMediaFile!.id]);
                            }
                          },
                          icon: Icon(isFullyWatched ? Icons.remove_done_rounded : Icons.done_all_rounded, size: 28),
                          label: Text(isFullyWatched ? 'Unwatched' : 'Watched'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFullyWatched ? kSurfaceColor : kCardColor,
                            foregroundColor: isFullyWatched ? kMutedText : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isFullyWatched ? kDivider : Colors.transparent),
                            ),
                            textStyle: AppTextStyles.buttonText.copyWith(fontSize: 16),
                          ),
                        );
                      }
                    ),
                  ],
                ),"""
content = content.replace(old_button, new_button)

# 7. _EpisodeTile properties
old_tile = """class _EpisodeTile extends StatefulWidget {
  const _EpisodeTile({required this.file, this.onTap});
  final MediaFile file;
  final VoidCallback? onTap;"""

new_tile = """class _EpisodeTile extends StatefulWidget {
  const _EpisodeTile({required this.file, this.onTap, this.onMarkWatched, this.onMarkUnwatched});
  final MediaFile file;
  final VoidCallback? onTap;
  final VoidCallback? onMarkWatched;
  final VoidCallback? onMarkUnwatched;"""
content = content.replace(old_tile, new_tile)

# 8. _EpisodeTile trailing icons
old_trailing = """              // ── Chevron ──
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: _hovering
                      ? Colors.white
                      : kMutedText.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),"""

new_trailing = """              // ── Watched Toggle ──
              if (_hovering || isFullyWatched)
                IconButton(
                  icon: Icon(
                    isFullyWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                  ),
                  color: isFullyWatched ? kSecondaryAccent : kMutedText.withValues(alpha: 0.5),
                  onPressed: isFullyWatched ? widget.onMarkUnwatched : widget.onMarkWatched,
                  tooltip: isFullyWatched ? 'Mark as unwatched' : 'Mark as watched',
                )
              else
                const SizedBox(width: 48),

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
              ),"""
content = content.replace(old_trailing, new_trailing)


with open("lib/features/browse/screens/media_detail_screen.dart", "w") as f:
    f.write(content)
