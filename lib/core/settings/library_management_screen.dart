import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/library/library_providers.dart';

class LibraryManagementScreen extends ConsumerStatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  ConsumerState<LibraryManagementScreen> createState() => _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends ConsumerState<LibraryManagementScreen> {
  final _pathController = TextEditingController();

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _addFolder() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    
    try {
      final db = ref.read(databaseProvider);
      await db.insertLibraryFolder(path);
      _pathController.clear();
      
      _triggerScan();
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
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(libraryFoldersProvider);
    final isScanning = ref.watch(scanningStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Management'),
        backgroundColor: kBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a folder to scan for video files:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      fillColor: Colors.black26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addFolder,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Folder'),
                  style: ElevatedButton.styleFrom(
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
                const Text(
                  'Library Folders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: isScanning ? null : _triggerScan,
                  icon: isScanning 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: const Text('Rescan All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: foldersAsync.when(
                data: (folders) {
                  if (folders.isEmpty) {
                    return const Center(
                      child: Text('No library folders configured.', style: TextStyle(color: kMutedText)),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      return Card(
                        color: Colors.white10,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.folder, color: kAccentColor),
                          title: Text(folder.label ?? folder.path),
                          subtitle: Text(folder.path),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
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
