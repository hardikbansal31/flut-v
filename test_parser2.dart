import 'package:flutter_video/features/metadata/filename_parser.dart';

void main() {
  final working = "[SubsPlease] Tengoku Daimakyou - 13 (1080p) [2B9B9B8A].mkv";
  print(FilenameParser.parse(working));
}
