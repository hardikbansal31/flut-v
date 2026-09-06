import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video/features/metadata/metadata_service.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart';

void main() {
  group('Folder context extraction', () {
    test('extracts direct parent folder as show name', () {
      expect(
        extractShowFolderName('/media/shows/Bleach TYBW/Episode 46.mkv'),
        equals('Bleach TYBW'),
      );
    });

    test('skips Season folders to extract grandparent as show name', () {
      expect(
        extractShowFolderName(
            '/media/anime/Bleach Thousand-Year Blood War/Season 01/Episode 01.mkv'),
        equals('Bleach Thousand-Year Blood War'),
      );
      expect(
        extractShowFolderName(
            '/media/shows/Avatar The Last Airbender/Season 2/S02E05.mkv'),
        equals('Avatar The Last Airbender'),
      );
      expect(
        extractShowFolderName(
            '/media/shows/One Piece/s03/Episode 100.mkv'),
        equals('One Piece'),
      );
    });

    test('skips Specials and Extras folders', () {
      expect(
        extractShowFolderName(
            '/media/anime/Attack on Titan/Specials/OVA 01.mkv'),
        equals('Attack on Titan'),
      );
      expect(
        extractShowFolderName(
            '/media/anime/Fullmetal Alchemist/Extras/OVA.mkv'),
        equals('Fullmetal Alchemist'),
      );
    });

    test('returns null for standalone file with no parent folder', () {
      expect(extractShowFolderName('Episode 01.mkv'), isNull);
    });
  });

  group('Title normalization', () {
    test('removes punctuation, symbols and normalizes whitespace', () {
      expect(
        normalizeTitle('Bleach: Thousand-Year Blood War (2022)'),
        equals('bleach thousand year blood war 2022'),
      );
      expect(
        normalizeTitle('Avatar: The Last Airbender!'),
        equals('avatar the last airbender'),
      );
      expect(
        normalizeTitle('Fullmetal   Alchemist:   Brotherhood'),
        equals('fullmetal alchemist brotherhood'),
      );
    });
  });

  group('Known title overrides', () {
    test('contains verified TMDB IDs for common anime collisions', () {
      // Bleach TYBW vs original Bleach
      expect(knownTitleOverrides['bleach thousand-year blood war'], equals(213669));
      expect(knownTitleOverrides['bleach tybw'], equals(213669));
      expect(knownTitleOverrides['bleach'], equals(30984));

      // Avatar animated vs live-action
      expect(knownTitleOverrides['avatar the last airbender'], equals(246));
      expect(knownTitleOverrides['avatar'], equals(246));

      // One Piece animated
      expect(knownTitleOverrides['one piece'], equals(37854));

      // Fullmetal Alchemist Brotherhood
      expect(knownTitleOverrides['fullmetal alchemist brotherhood'], equals(31911));
      expect(knownTitleOverrides['fma brotherhood'], equals(31911));
      expect(knownTitleOverrides['fullmetal alchemist'], equals(406));
    });
  });

  group('Scoring signals', () {
    test('exact title match scores higher than partial match', () {
      const exactMatch = TmdbSearchResult(
        id: 213669,
        mediaType: 'tv',
        title: 'Bleach: Thousand-Year Blood War',
      );

      const partialMatch = TmdbSearchResult(
        id: 30984,
        mediaType: 'tv',
        title: 'Bleach',
      );

      final exactScore = scoreTvCandidate(
        candidate: exactMatch,
        query: 'Bleach: Thousand-Year Blood War',
        rawFileName: 'Bleach.TYBW.S01E01.mkv',
      );

      final partialScore = scoreTvCandidate(
        candidate: partialMatch,
        query: 'Bleach: Thousand-Year Blood War',
        rawFileName: 'Bleach.TYBW.S01E01.mkv',
      );

      expect(exactScore, greaterThan(partialScore));
    });

    test('anime signals ([SubGroup], anime tags) prefer JP origin and Animation genre', () {
      // Animated Avatar (TMDB ID 246: Animation genre 16)
      const animatedCandidate = TmdbSearchResult(
        id: 246,
        mediaType: 'tv',
        title: 'Avatar: The Last Airbender',
        genreIds: [16, 10759], // Animation
        releaseDate: '2005-02-21',
      );

      // Live-action Avatar (TMDB ID 82452: no animation genre)
      const liveActionCandidate = TmdbSearchResult(
        id: 82452,
        mediaType: 'tv',
        title: 'Avatar: The Last Airbender',
        genreIds: [10759, 10765], // Action & Adventure, Sci-Fi & Fantasy (no 16)
        releaseDate: '2024-02-22',
      );

      // When file has a fansub tag: [SubsPlease] Avatar - S01E01 [1080p].mkv
      final animeFileScoreAnimated = scoreTvCandidate(
        candidate: animatedCandidate,
        query: 'Avatar: The Last Airbender',
        rawFileName: '[SubsPlease] Avatar: The Last Airbender - S01E01.mkv',
        targetYear: 2005,
      );

      final animeFileScoreLiveAction = scoreTvCandidate(
        candidate: liveActionCandidate,
        query: 'Avatar: The Last Airbender',
        rawFileName: '[SubsPlease] Avatar: The Last Airbender - S01E01.mkv',
        targetYear: 2005,
      );

      expect(animeFileScoreAnimated, greaterThan(animeFileScoreLiveAction));
    });

    test('live-action signals (1080p BluRay REMUX, WEB-DL) deprioritize animation', () {
      const animatedCandidate = TmdbSearchResult(
        id: 246,
        mediaType: 'tv',
        title: 'Avatar: The Last Airbender',
        genreIds: [16, 10759], // Animation
        releaseDate: '2005-02-21',
      );

      const liveActionCandidate = TmdbSearchResult(
        id: 82452,
        mediaType: 'tv',
        title: 'Avatar: The Last Airbender',
        genreIds: [10759, 10765], // Live action
        releaseDate: '2024-02-22',
      );

      // Filename: Avatar.The.Last.Airbender.2024.S01E01.1080p.BluRay.REMUX.mkv
      final remuxFileScoreAnimated = scoreTvCandidate(
        candidate: animatedCandidate,
        query: 'Avatar: The Last Airbender',
        rawFileName: 'Avatar.The.Last.Airbender.2024.S01E01.1080p.BluRay.REMUX.mkv',
        targetYear: 2024,
      );

      final remuxFileScoreLiveAction = scoreTvCandidate(
        candidate: liveActionCandidate,
        query: 'Avatar: The Last Airbender',
        rawFileName: 'Avatar.The.Last.Airbender.2024.S01E01.1080p.BluRay.REMUX.mkv',
        targetYear: 2024,
      );

      expect(remuxFileScoreLiveAction, greaterThan(remuxFileScoreAnimated));
    });

    test('release year in filename heavily penalizes mismatched release dates', () {
      const show2005 = TmdbSearchResult(
        id: 1,
        mediaType: 'tv',
        title: 'Test Show',
        releaseDate: '2005-01-01',
      );

      const show2024 = TmdbSearchResult(
        id: 2,
        mediaType: 'tv',
        title: 'Test Show',
        releaseDate: '2024-01-01',
      );

      final scoreMatch = scoreTvCandidate(
        candidate: show2024,
        query: 'Test Show',
        rawFileName: 'Test.Show.2024.S01E01.mkv',
        targetYear: 2024,
      );

      final scoreMismatch = scoreTvCandidate(
        candidate: show2005,
        query: 'Test Show',
        rawFileName: 'Test.Show.2024.S01E01.mkv',
        targetYear: 2024,
      );

      expect(scoreMatch, greaterThan(scoreMismatch + 60.0));
    });

    test('Japanese origin country gives boost when anime keywords present', () {
      const jpAnime = TmdbSearchResult(
        id: 37854,
        mediaType: 'tv',
        title: 'One Piece',
        originCountry: ['JP'],
        originalLanguage: 'ja',
        genreIds: [16, 10759],
      );

      const usShow = TmdbSearchResult(
        id: 111110,
        mediaType: 'tv',
        title: 'One Piece',
        originCountry: ['US'],
        originalLanguage: 'en',
        genreIds: [10759],
      );

      final scoreJp = scoreTvCandidate(
        candidate: jpAnime,
        query: 'One Piece',
        rawFileName: '[Erai-raws] One Piece - 1000 [1080p][Multiple Subtitle].mkv',
      );

      final scoreUs = scoreTvCandidate(
        candidate: usShow,
        query: 'One Piece',
        rawFileName: '[Erai-raws] One Piece - 1000 [1080p][Multiple Subtitle].mkv',
      );

      expect(scoreJp, greaterThan(scoreUs));
    });
  });
}
