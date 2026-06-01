// Basic smoke test — verifies the app launches and renders key sections with database content.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video/app.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/library/library_providers.dart';

void main() {
  testWidgets('App smoke test — home screen renders', (tester) async {
    // Set up an in-memory database for testing
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

    // Seed mock folder and file to populate library and continue watching
    await db.into(db.libraryFolders).insert(
      LibraryFoldersCompanion.insert(
        path: '/mock',
        addedAt: const Value.absent(),
      ),
    );

    await db.into(db.mediaFiles).insert(
      MediaFilesCompanion.insert(
        filePath: '/mock/video.mp4',
        fileName: 'video.mp4',
        fileExtension: 'mp4',
        fileSizeBytes: BigInt.from(1024 * 1024),
        libraryFolderId: 1,
        lastModified: DateTime.now(),
        durationMillis: const Value(100000), // 100 seconds
        positionMillis: const Value(50000),  // 50 seconds (50% watched)
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const PenguinApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the app title / logo is present.
    expect(find.text('Penguin'), findsWidgets);

    // Verify Continue Watching is visible because we seeded a partially watched file.
    expect(find.text('Continue Watching'), findsOneWidget);

    // Verify video.mp4 (seeding) is displayed as the title of the video file.
    expect(find.text('video.mp4'), findsWidgets);

    // Close the database to release resources.
    await db.close();
  });
}
