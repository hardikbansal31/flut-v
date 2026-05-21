/// Application entry point.
///
/// Wraps the app in a [ProviderScope] for Riverpod state management
/// (no providers yet in Phase 1, but the scaffold is ready).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/app.dart';

import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/library/library_providers.dart';

import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit
  MediaKit.ensureInitialized();
  
  // Initialize window_manager on desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }

  final database = AppDatabase();

  runApp(
    // Riverpod root — all providers are available below this point.
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const FluxPlayerApp(),
    ),
  );
}
