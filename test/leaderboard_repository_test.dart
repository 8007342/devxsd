import 'package:devxsd_gamejam/data/leaderboard_platform.dart' as platform;
import 'package:devxsd_gamejam/data/leaderboard_repository.dart';
import 'package:devxsd_gamejam/game/puzzle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    for (final mode in GameMode.values) {
      platform.write('devxsd.leaderboard.v1.${mode.name}', '[]');
      platform.write('devxsd.leaderboard.v2.${mode.name}', '[]');
    }
  });

  test(
    'local fallback persists normalized results across repositories',
    () async {
      final result = await LeaderboardRepository().submit(
        GameMode.unlimited,
        'abc',
        12.5,
        2,
        3.5,
      );
      expect(result.shared, isFalse);
      final restored = await LeaderboardRepository().fetch(GameMode.unlimited);
      expect(restored.shared, isFalse);
      expect(restored.entries.single.name, 'ABC');
      expect(restored.entries.single.seconds, 12.5);
      expect(restored.entries.single.rings, 2);
      expect(restored.entries.single.height, 3.5);
      expect(
        (await LeaderboardRepository().fetch(GameMode.timed)).entries,
        isEmpty,
      );
    },
  );

  test('timed fallback retains only the fastest ten completed runs', () async {
    final repository = LeaderboardRepository();
    for (var seconds = 12; seconds >= 1; seconds--) {
      await repository.submit(
        GameMode.timed,
        'RUN',
        seconds.toDouble(),
        30,
        30,
      );
    }
    final result = await repository.fetch(GameMode.timed);
    expect(
      result.entries.map((entry) => entry.seconds),
      List.generate(10, (index) => (index + 1).toDouble()),
    );
  });

  test('unlimited fallback ranks plant height independently of time', () async {
    final repository = LeaderboardRepository();
    for (var height = 1; height <= 12; height++) {
      await repository.submit(
        GameMode.unlimited,
        'RUN',
        height.toDouble(),
        height,
        height.toDouble(),
      );
    }
    final result = await repository.fetch(GameMode.unlimited);
    expect(
      result.entries.map((entry) => entry.height),
      List.generate(10, (index) => (12 - index).toDouble()),
    );
  });

  test(
    'rejects incomplete timed runs, invalid names and numeric scores',
    () async {
      final repository = LeaderboardRepository();
      expect(
        () => repository.submit(GameMode.timed, 'ABC', 60, 29, 29),
        throwsArgumentError,
      );
      for (final name in ['AB', 'ABCD', 'A1C', 'ÄBC']) {
        expect(
          () => repository.submit(GameMode.unlimited, name, 60, 0, 0),
          throwsArgumentError,
        );
      }
      for (final seconds in [0.0, -1.0, double.infinity, double.nan]) {
        expect(
          () => repository.submit(GameMode.unlimited, 'ABC', seconds, 0, 0),
          throwsArgumentError,
        );
      }
      expect(
        () => repository.submit(GameMode.unlimited, 'ABC', 60, -1, 0),
        throwsArgumentError,
      );
      expect(
        () => repository.submit(GameMode.unlimited, 'ABC', 60, 0, double.nan),
        throwsArgumentError,
      );
      expect((await repository.fetch(GameMode.unlimited)).entries, isEmpty);
      expect((await repository.fetch(GameMode.timed)).entries, isEmpty);
    },
  );

  test(
    'paired offline records preserve milestone and final values from same run',
    () async {
      final repository = LeaderboardRepository();
      await repository.submitRun(GameMode.timed, 'abc', 600, 80, 91, 123.4);
      final timed = (await repository.fetch(GameMode.timed)).entries.single;
      final survival = (await repository.fetch(
        GameMode.unlimited,
      )).entries.single;
      expect(timed.toJson(), survival.toJson());
      expect(timed.time30, 123.4);
      expect(timed.seconds, 600);
      expect(timed.rings, 80);
      expect(timed.height, 91);
      await repository.submitRun(GameMode.unlimited, 'def', 900, 100, 10, 200);
      expect(
        (await repository.fetch(GameMode.unlimited)).entries.first.name,
        'DEF',
      );
      expect(
        (await repository.fetch(GameMode.timed)).entries.first.name,
        'ABC',
      );
      await repository.submitRun(GameMode.unlimited, 'new', 20, 2, 2, null);
      expect((await repository.fetch(GameMode.timed)).entries.length, 2);
      expect((await repository.fetch(GameMode.unlimited)).entries.length, 3);
    },
  );
  test('legacy cached entries retain first-thirty times', () async {
    platform.write(
      'devxsd.leaderboard.v2.timed',
      '[{"name":"OLD","seconds":100,"rings":30,"height":30}]',
    );
    final entry = (await LeaderboardRepository().fetch(
      GameMode.timed,
    )).entries.single;
    expect(entry.seconds, 100);
    expect(entry.time30, 100);
  });
}
