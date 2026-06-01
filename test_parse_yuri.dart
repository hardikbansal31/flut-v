import 'package:flutter/foundation.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';

void main() {
  final name = "[YURI] Love, Chunibyo & Other Delusions!  S02E08 [BD 1080p x264 10bit FLAC].mkv";
  final parsed = FilenameParser.parse(name);
  debugPrint(parsed.toString());
}
