/// Application entry point.
///
/// Wraps the app in a [ProviderScope] for Riverpod state management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/app.dart';

import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/library/library_providers.dart';

import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_video/features/metadata/metadata_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit
  MediaKit.ensureInitialized();
  
  // Initialize window_manager on desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }

  final database = AppDatabase();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
    ],
  );

  // Load TMDB API key & custom base URL from SharedPreferences before running the app
  await container.read(tmdbApiKeyProvider.notifier).load();
  await container.read(tmdbApiBaseUrlProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PenguinApp(),
    ),
  );
}
