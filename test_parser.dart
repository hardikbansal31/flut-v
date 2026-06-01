import 'package:flutter/foundation.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';

void main() {
  final names = [
    "[SubsPlease] Tengoku Daimakyou - 13 (1080p) [2B9B9B8A].mkv",
    "One Piece 1071.mkv",
    "Attack on Titan S04E15.mkv",
    "Jujutsu Kaisen 2nd Season - 05.mkv"
  ];
  
  for (final name in names) {
    final parsed = FilenameParser.parse(name);
    debugPrint('$name -> S${parsed.season}E${parsed.episode}');
  }
}
