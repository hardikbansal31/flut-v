/// Root MaterialApp configuration.
///
/// Sets up the dark theme, removes the debug banner, and routes to
/// the home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/screens/home_screen.dart';

class PenguinApp extends StatelessWidget {
  const PenguinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penguin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
