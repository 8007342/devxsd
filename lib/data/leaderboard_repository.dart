import 'dart:convert';
import '../game/puzzle_model.dart';
import 'leaderboard_platform.dart'
    if (dart.library.js_interop) 'leaderboard_platform_web.dart'
    as platform;

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.seconds,
    required this.rings,
    required this.height,
  });
  final String name;
  final double seconds;
  final int rings;
  final double height;
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name'] as String,
        seconds: (json['seconds'] as num).toDouble(),
        rings: (json['rings'] as num).toInt(),
        height: (json['height'] as num).toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'name': name,
    'seconds': seconds,
    'rings': rings,
    'height': height,
  };
}

class LeaderboardTable {
  const LeaderboardTable({required this.entries, required this.shared});
  final List<LeaderboardEntry> entries;
  final bool shared;
}

class LeaderboardRepository {
  Future<LeaderboardTable> fetch(GameMode mode) => _request(mode, null);
  Future<LeaderboardTable> submit(
    GameMode mode,
    String name,
    double seconds,
    int rings,
    double height,
  ) {
    name = name.toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(name) ||
        !seconds.isFinite ||
        seconds <= 0 ||
        seconds > 31536000 ||
        rings < 0 ||
        rings > 10000000 ||
        !height.isFinite ||
        height < 0 ||
        height > 1000000000 ||
        (mode == GameMode.timed && rings < 30)) {
      throw ArgumentError('Enter three letters and a valid completed result.');
    }
    return _request(
      mode,
      LeaderboardEntry(
        name: name,
        seconds: seconds,
        rings: rings,
        height: height,
      ),
    );
  }

  Future<LeaderboardTable> _request(
    GameMode mode,
    LeaderboardEntry? entry,
  ) async {
    final key = 'devxsd.leaderboard.v1.${mode.name}';
    try {
      final response = await platform.request(
        mode.name,
        entry == null
            ? null
            : jsonEncode({'mode': mode.name, ...entry.toJson()}),
      );
      final data = jsonDecode(response) as Map<String, dynamic>;
      if (data['source'] != 'shared') {
        throw const FormatException('Missing leaderboard API');
      }
      final entries = (data['entries'] as List)
          .map(
            (value) => LeaderboardEntry.fromJson(value as Map<String, dynamic>),
          )
          .toList();
      // Cache the shared board so an offline reload still has useful results.
      platform.write(
        key,
        jsonEncode(entries.map((value) => value.toJson()).toList()),
      );
      return LeaderboardTable(entries: entries, shared: true);
    } catch (_) {
      List<LeaderboardEntry> entries;
      try {
        entries = (jsonDecode(platform.read(key) ?? '[]') as List)
            .map(
              (value) =>
                  LeaderboardEntry.fromJson(value as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        entries = [];
      }
      if (entry != null) {
        entries.add(entry);
      }
      entries.sort(
        mode == GameMode.timed
            ? (a, b) => a.seconds.compareTo(b.seconds)
            : (a, b) => b.height.compareTo(a.height),
      );
      entries = entries.take(10).toList();
      platform.write(
        key,
        jsonEncode(entries.map((value) => value.toJson()).toList()),
      );
      return LeaderboardTable(entries: entries, shared: false);
    }
  }
}
