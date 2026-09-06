/// Dialog for manually searching TMDB and overriding metadata for a series or movie.
library;

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/metadata/metadata_providers.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart' as tmdb;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal dialog that allows searching TMDB for TV shows or movies and overriding
/// metadata for a series or an individual movie file.
class EditMetadataDialog extends ConsumerStatefulWidget {
  const EditMetadataDialog({
    super.key,
    this.series,
    this.mediaFile,
    required this.initialTitle,
  }) : assert(series != null || mediaFile != null);

  final SeriesItem? series;
  final MediaFile? mediaFile;
  final String initialTitle;

  @override
  ConsumerState<EditMetadataDialog> createState() => _EditMetadataDialogState();
}

class _EditMetadataDialogState extends ConsumerState<EditMetadataDialog> {
  late final TextEditingController _searchController;
  late bool _isTvSearch;
  Timer? _debounceTimer;

  List<tmdb.TmdbSearchResult> _results = [];
  bool _isSearching = false;
  bool _isApplying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isTvSearch = widget.series != null ||
        (widget.mediaFile != null && widget.mediaFile!.mediaType != 'movie');
    _searchController = TextEditingController(text: widget.initialTitle);

    // Initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchController.text.trim().isNotEmpty) {
        _performSearch(_searchController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _results.clear(); // Free memory immediately on dialog close
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    final client = ref.read(tmdbClientProvider);
    if (client == null) {
      setState(() {
        _errorMessage = 'TMDB API key not configured. Please set it in Settings.';
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final List<tmdb.TmdbSearchResult> results;
      if (_isTvSearch) {
        results = await client.searchTvList(query, limit: 5);
      } else {
        results = await client.searchMovieList(query, limit: 5);
      }

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } on tmdb.TmdbRateLimitException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Rate limited. Retry after ${e.retryAfterSeconds}s.';
        _isSearching = false;
      });
    } on tmdb.TmdbAuthException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid TMDB API key. Please check Settings.';
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Search error: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _selectResult(tmdb.TmdbSearchResult selected) async {
    final metadataService = ref.read(metadataServiceProvider);
    if (metadataService == null) {
      setState(() {
        _errorMessage = 'Metadata service unavailable.';
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
      _results.clear(); // Free memory immediately upon selection
    });

    try {
      if (widget.series != null) {
        await metadataService.overrideSeriesMetadata(
          episodes: widget.series!.episodes,
          selectedShow: selected,
        );
      } else if (widget.mediaFile != null) {
        await metadataService.overrideFileMetadata(
          file: widget.mediaFile!,
          selectedResult: selected,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated metadata for "${selected.title}"'),
          backgroundColor: kCardColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isApplying = false;
        _errorMessage = 'Failed to apply override: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kDivider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Metadata',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x, color: kMutedText),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search type toggle (TV Show vs Movie)
              Row(
                children: [
                  _TypeFilterButton(
                    label: 'TV Show',
                    icon: PhosphorIcons.television,
                    isSelected: _isTvSearch,
                    onTap: () {
                      if (!_isTvSearch) {
                        setState(() => _isTvSearch = true);
                        _performSearch(_searchController.text.trim());
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  _TypeFilterButton(
                    label: 'Movie',
                    icon: PhosphorIcons.filmStrip,
                    isSelected: !_isTvSearch,
                    onTap: () {
                      if (_isTvSearch) {
                        setState(() => _isTvSearch = false);
                        _performSearch(_searchController.text.trim());
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search input field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (val) => _performSearch(val.trim()),
                style: AppTextStyles.buttonText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.normal,
                ),
                cursorColor: kAccentColor,
                decoration: InputDecoration(
                  hintText: _isTvSearch
                      ? 'Search TV series title...'
                      : 'Search movie title...',
                  hintStyle: AppTextStyles.bodyMuted,
                  prefixIcon: Icon(
                    PhosphorIcons.magnifyingGlass,
                    color: kMutedText,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(PhosphorIcons.xCircle, color: kMutedText, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: kCardColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kDivider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kAccentColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIcons.warningCircleFill,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyMuted.copyWith(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Results List / Loading / Empty
              Expanded(
                child: _isApplying
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: kAccentColor),
                            const SizedBox(height: 16),
                            Text(
                              'Re-linking metadata and updating episodes...',
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _isSearching
                        ? const Center(
                            child: CircularProgressIndicator(color: kAccentColor),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Text(
                                  _searchController.text.isEmpty
                                      ? 'Type a title to search TMDB'
                                      : 'No TMDB matches found',
                                  style: AppTextStyles.bodyMuted,
                                ),
                              )
                            : ListView.separated(
                                itemCount: _results.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _results[index];
                                  return _SearchResultTile(
                                    item: item,
                                    onTap: () => _selectResult(item),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? kAccentColor : kSurfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? kAccentColor : kDivider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.textPrimary : kMutedText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.buttonText.copyWith(
                  fontSize: 13,
                  color: isSelected ? AppTheme.textPrimary : kMutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatefulWidget {
  const _SearchResultTile({
    required this.item,
    required this.onTap,
  });

  final tmdb.TmdbSearchResult item;
  final VoidCallback onTap;

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final poster = tmdb.posterUrl(item.posterPath);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered ? kCardColor.withValues(alpha: 0.9) : kSurfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? kAccentColor.withValues(alpha: 0.4) : AppTheme.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 48,
                  height: 72,
                  child: poster != null
                      ? CachedNetworkImage(
                          imageUrl: poster,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: kCardColor),
                          errorWidget: (_, _, _) => Container(color: kCardColor),
                        )
                      : Container(
                          color: kCardColor,
                          child: Center(
                            child: Icon(PhosphorIcons.filmSlate, color: kMutedText, size: 20),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.episodeTitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (item.releaseYear != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kCardColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: kDivider),
                            ),
                            child: Text(
                              '${item.releaseYear}',
                              style: AppTextStyles.episodeMeta.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating & Media type badge
                    Row(
                      children: [
                        if (item.voteAverage > 0) ...[
                          Icon(PhosphorIcons.starFill, size: 13, color: kSecondaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            item.voteAverage.toStringAsFixed(1),
                            style: AppTextStyles.seriesRating.copyWith(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          item.mediaType == 'tv' ? 'TV Series' : 'Movie',
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),

                    // Overview snippet
                    if (item.overview != null && item.overview!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.overview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              // Chevron / Select indicator
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Icon(
                  PhosphorIcons.arrowRight,
                  color: _hovered ? kAccentColor : kMutedText.withValues(alpha: 0.4),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
