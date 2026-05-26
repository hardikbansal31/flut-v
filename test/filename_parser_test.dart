import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video/features/metadata/filename_parser.dart';

void main() {
  group('FilenameParser Tests', () {
    test('Standard movie with year and noise', () {
      final parsed = FilenameParser.parse('Blade.Runner.2049.2017.1080p.BluRay.x264.mkv');
      expect(parsed.cleanTitle, 'Blade Runner 2049');
      expect(parsed.year, 2017);
    });

    test('TV show with brackets and episode marker', () {
      final parsed = FilenameParser.parse('[SubGroup] Attack on Titan S04E01 [1080p].mkv');
      expect(parsed.cleanTitle, 'Attack on Titan S04E01');
      expect(parsed.year, null);
    });

    test('Movie with year in parentheses and underscores', () {
      final parsed = FilenameParser.parse('The_Batman_(2022)_WEB-DL.mp4');
      expect(parsed.cleanTitle, 'The Batman');
      expect(parsed.year, 2022);
    });

    test('Movie with no year, only source and resolution', () {
      final parsed = FilenameParser.parse('Interstellar.1080p.BluRay.x264.mkv');
      expect(parsed.cleanTitle, 'Interstellar');
      expect(parsed.year, null);
    });

    test('Anime file with bracketed tags', () {
      final parsed = FilenameParser.parse('[HorribleSubs] Shingeki no Kyojin - 75 [1080p].mkv');
      expect(parsed.cleanTitle, 'Shingeki no Kyojin 75');
    });

    test('Movie with anniversary tag and ordinals', () {
      final parsed = FilenameParser.parse('Goodfellas (1990) 25th Anniv (1080p BluRay x265 10bit Tigole).mkv');
      expect(parsed.cleanTitle, 'Goodfellas');
      expect(parsed.year, 1990);
    });
  });
}
