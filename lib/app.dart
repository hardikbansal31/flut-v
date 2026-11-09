/// Root MaterialApp configuration.
///
/// Sets up the dark theme, global keyboard shortcuts, and desktop
/// window close listener for saving playback state.
library;

import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/save_state_provider.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

class PenguinApp extends ConsumerStatefulWidget {
  const PenguinApp({super.key});

  @override
  ConsumerState<PenguinApp> createState() => _PenguinAppState();
}

class _PenguinAppState extends ConsumerState<PenguinApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
    }
  }

  @override
  void dispose() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  /// Saves playback progress before exiting the application.
  Future<void> _handleQuit() async {
    final saveCallback = ref.read(saveStateProvider);
    if (saveCallback != null) {
      try {
        await saveCallback();
      } catch (e) {
        developer.log('Error saving state on quit: $e', name: 'PenguinApp');
      }
    }
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.destroy();
    }
  }

  @override
  void onWindowClose() async {
    await _handleQuit();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyQ, control: true): _handleQuit,
        SingleActivator(LogicalKeyboardKey.keyQ, meta: true): _handleQuit,
      },
      child: Focus(
        autofocus: true,
        child: MaterialApp(
          title: 'Penguin',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
