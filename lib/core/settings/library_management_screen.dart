import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:flutter_video/features/metadata/metadata_providers.dart';
import 'package:flutter_video/features/metadata/metadata_service.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class LibraryManagementScreen extends ConsumerStatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  ConsumerState<LibraryManagementScreen> createState() => _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends ConsumerState<LibraryManagementScreen> {
  final _pathController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  bool _apiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    // Load saved API key and base URL into the text fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedKey = ref.read(tmdbApiKeyProvider);
      if (savedKey.isNotEmpty) {
        _apiKeyController.text = savedKey;
      }
      
      final savedBaseUrl = ref.read(tmdbApiBaseUrlProvider);
      _baseUrlController.text = savedBaseUrl;
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _addFolder() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    
    try {
      final db = ref.read(databaseProvider);
      await db.insertLibraryFolder(path);
      _pathController.clear();
      
      await _triggerScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add folder: $e')),
        );
      }
    }
  }

  Future<void> _removeFolder(int folderId) async {
    try {
      final db = ref.read(databaseProvider);
      await db.removeLibraryFolder(folderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove folder: $e')),
        );
      }
    }
  }

  Future<void> _triggerScan() async {
    ref.read(scanningStateProvider.notifier).setScanning(true);
    try {
      final scanner = ref.read(libraryScannerProvider);
      await scanner.scanAllFolders();
    } finally {
      if (mounted) {
        ref.read(scanningStateProvider.notifier).setScanning(false);
      }
    }

    // Auto-fetch metadata after scan if API key is configured
    final apiKey = ref.read(tmdbApiKeyProvider);
    if (apiKey.isNotEmpty) {
      ref.read(metadataFetchProvider.notifier).fetchAll();
    }
  }

  Future<void> _saveTmdbSettings() async {
    final key = _apiKeyController.text.trim();
    final url = _baseUrlController.text.trim();
    await ref.read(tmdbApiKeyProvider.notifier).save(key);
    await ref.read(tmdbApiBaseUrlProvider.notifier).save(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('TMDB settings saved successfully.'),
          backgroundColor: Colors.green[800],
        ),
      );
    }
  }

  Future<void> _fetchMetadata() async {
    final apiKey = ref.read(tmdbApiKeyProvider);
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a TMDB API key first.'),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }
    ref.read(metadataFetchProvider.notifier).fetchAll();
  }

  Future<void> _refreshMetadata() async {
    final apiKey = ref.read(tmdbApiKeyProvider);
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a TMDB API key first.'),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }
    ref.read(metadataFetchProvider.notifier).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(libraryFoldersProvider);
    final isScanning = ref.watch(scanningStateProvider);
    final fetchStatus = ref.watch(metadataFetchProvider);

    // Show error snackbar when fetch errors occur
    ref.listen<MetadataFetchStatus>(metadataFetchProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorSnackbar,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TMDB Settings Section
            Text(
              'TMDB Settings',
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your TMDB API key and base URL to fetch movie/TV metadata, posters, and ratings.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: _apiKeyObscured,
              decoration: InputDecoration(
                labelText: 'TMDB API Key (v3 auth)',
                hintText: 'Paste your TMDB API key here',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.backgroundBlack26,
                suffixIcon: IconButton(
                  icon: Icon(
                    _apiKeyObscured
                        ? PhosphorIcons.eyeClosed
                        : PhosphorIcons.eye,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _apiKeyObscured = !_apiKeyObscured),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'TMDB API Base URL (Optional)',
                hintText: 'Default: https://api.themoviedb.org/3',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.backgroundBlack26,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveTmdbSettings,
                  icon: Icon(PhosphorIcons.floppyDisk, size: 18),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: fetchStatus.isFetching ? null : _fetchMetadata,
                  icon: fetchStatus.isFetching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(PhosphorIcons.download, size: 18),
                  label: Text(fetchStatus.isFetching
                      ? 'Fetching... ${fetchStatus.remainingFiles} remaining'
                      : 'Fetch Metadata'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: AppTheme.textPrimary12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: fetchStatus.isFetching ? null : _refreshMetadata,
                  icon: Icon(PhosphorIcons.arrowsClockwise, size: 18),
                  label: const Text('Refresh All'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: AppTheme.textPrimary12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),
            const Divider(color: kDivider),
            const SizedBox(height: 24),

            // Library Folders Section
            Text(
              'Add a folder to scan for video files:',
              style: AppTextStyles.settingsSectionHeader,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      hintText: '/home/user/Videos',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.backgroundBlack26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addFolder,
                  icon: Icon(PhosphorIcons.plus),
                  label: const Text('Add Folder'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Library Folders',
                  style: AppTextStyles.sectionHeader,
                ),
                ElevatedButton.icon(
                  onPressed: isScanning ? null : _triggerScan,
                  icon: isScanning 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(PhosphorIcons.arrowsClockwise),
                  label: const Text('Rescan All'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: AppTheme.textPrimary12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: foldersAsync.when(
                data: (folders) {
                  if (folders.isEmpty) {
                    return Center(
                      child: Text('No library folders configured.', style: AppTextStyles.textMutedOnly),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      return Card(
                        color: AppTheme.textPrimary10,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(PhosphorIcons.folder, color: kAccentColor),
                          title: Text(folder.label ?? folder.path),
                          subtitle: Text(folder.path),
                          trailing: IconButton(
                            icon: Icon(PhosphorIcons.trash, color: AppTheme.errorSnackbar),
                            onPressed: () => _removeFolder(folder.id),
                            tooltip: 'Remove folder',
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
