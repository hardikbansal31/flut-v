import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/core/database/database.dart';

void main() {
  final file = MediaFile(
    id: 1,
    libraryFolderId: 1,
    fileName: '[YURI] Love, Chunibyo & Other Delusions!  S02E08 [BD 1080p x264 10bit FLAC].mkv',
    filePath: '/test.mkv',
    fileExtension: '.mkv',
    fileSizeBytes: BigInt.from(100),
    lastModified: DateTime.now(),
    addedAt: DateTime.now(),
    durationMillis: 1000,
    mediaType: 'anime', // Or whatever it is
    tmdbTitle: null, // Let's assume tmdbTitle is null
  );

  print(SeriesItem.episodeLabelFor(file));
}
