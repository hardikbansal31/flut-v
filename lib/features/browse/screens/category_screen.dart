import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/media_item.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/browse/screens/media_detail_screen.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:flutter_video/features/browse/widgets/media_grid.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class CategoryScreen extends ConsumerWidget {
  final String title;

  const CategoryScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMediaFilesAsync = ref.watch(libraryFilesProvider);
    final files = allMediaFilesAsync.value ?? [];
    
    final allSeries = ref.watch(groupedSeriesProvider);
    
    final allMediaItems = files.map(MediaItem.fromMediaFile).toList();
    
    List<MediaItem> items = [];
    
    if (title == 'Movies') {
      items = allMediaItems.where((item) => item.type == MediaType.movie).toList();
    } else if (title == 'TV Shows') {
      final tvSeries = allSeries.where((s) => s.type == MediaType.tvShow).toList();
      items = tvSeries.map((s) => MediaItem.fromSeriesItem(s)).toList();
    } else if (title == 'Anime') {
      final animeSeries = allSeries.where((s) => s.type == MediaType.anime).toList();
      items = animeSeries.map((s) => MediaItem.fromSeriesItem(s)).toList();
    } else if (title == 'Library' || title == 'All Media') {
      final movies = allMediaItems.where((item) => item.type == MediaType.movie).toList();
      final tvSeries = allSeries.where((s) => s.type == MediaType.tvShow).toList();
      final animeSeries = allSeries.where((s) => s.type == MediaType.anime).toList();
      final uncategorized = allMediaItems.where((item) => item.type == MediaType.uncategorized).toList();
      
      items = [
        ...movies,
        ...tvSeries.map((s) => MediaItem.fromSeriesItem(s)),
        ...animeSeries.map((s) => MediaItem.fromSeriesItem(s)),
        ...uncategorized,
      ];
      items.sort((a, b) => a.title.compareTo(b.title));
    } else if (title == 'Uncategorized') {
      items = allMediaItems.where((item) => item.type == MediaType.uncategorized).toList();
    } else if (title == 'Recently Added') {
      final recentFiles = ref.watch(recentlyAddedFilesProvider).value ?? [];
      final recentMovies = recentFiles.where((f) => f.mediaType != 'tv' && f.mediaType != 'anime').toList();
      final recentTv = recentFiles.where((f) => f.mediaType == 'tv' || f.mediaType == 'anime').toList();
      final recentSeriesList = SeriesItem.groupFiles(recentTv);
      
      items = [
        ...recentMovies.map(MediaItem.fromMediaFile),
        ...recentSeriesList.map((s) => MediaItem.fromSeriesItem(s)),
      ];
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.brandTitle.copyWith(fontSize: 24, color: AppTheme.textPrimary)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty 
          ? Center(child: Text('No media found', style: AppTextStyles.emptyLibraryTitle))
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ...MediaGrid(
                  title: '',
                  items: items,
                  onItemTap: (index) {
                    final item = items[index];
                    if (item.type == MediaType.movie || item.type == MediaType.uncategorized) {
                      // We need to find the matching file from the *full* list or recent list
                      final matchingFile = (title == 'Recently Added' ? (ref.read(recentlyAddedFilesProvider).value ?? []) : files)
                          .firstWhere((file) => file.id.toString() == item.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MediaDetailScreen(mediaFile: matchingFile)));
                    } else {
                      // Need to match series from the correct list
                      final matchingSeries = (title == 'Recently Added' 
                          ? SeriesItem.groupFiles((ref.read(recentlyAddedFilesProvider).value ?? []).where((f) => f.mediaType == 'tv' || f.mediaType == 'anime').toList())
                          : allSeries).firstWhere((s) => s.groupKey == item.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MediaDetailScreen(series: matchingSeries)));
                    }
                  }
                ).buildSlivers(context),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
    );
  }
}
