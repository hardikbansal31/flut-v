/// Root MaterialApp configuration.
///
/// Sets up the dark theme, removes the debug banner, and routes to
/// the home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

class SaveStateNotifier extends Notifier<Future<void> Function()?> {
  @override
  Future<void> Function()? build() => null;

  void setCallback(Future<void> Function()? callback) => state = callback;
}
final saveStateProvider = NotifierProvider<SaveStateNotifier, Future<void> Function()?>(SaveStateNotifier.new);

class PenguinApp extends ConsumerWidget {
  const PenguinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyQ, control: true): () async {
          final saveCallback = ref.read(saveStateProvider);
          if (saveCallback != null) {
            await saveCallback();
          }
          await windowManager.destroy();
        },
        SingleActivator(LogicalKeyboardKey.keyQ, meta: true): () async {
          final saveCallback = ref.read(saveStateProvider);
          if (saveCallback != null) {
            await saveCallback();
          }
          await windowManager.destroy();
        },
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
