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
    this.time30,
  });
  final String name;
  final double seconds;
  final int rings;
  final double height;
  final double? time30;
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name'] as String,
        seconds: (json['seconds'] as num).toDouble(),
        rings: (json['rings'] as num).toInt(),
        height: (json['height'] as num).toDouble(),
        time30: (json['time30'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'name': name,
    'seconds': seconds,
    'rings': rings,
    'height': height,
    'time30': time30,
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

  /// Record both rankings from one final run. The Worker writes them atomically.
  Future<LeaderboardTable> submitRun(
    GameMode view,
    String name,
    double elapsed,
    int rings,
    double height,
    double? time30,
  ) {
    name = name.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(name) ||
        !elapsed.isFinite ||
        elapsed <= 0 ||
        elapsed > 31536000 ||
        rings < 0 ||
        rings > 10000000 ||
        !height.isFinite ||
        height < 0 ||
        height > 1000000000 ||
        (time30 != null &&
            (!time30.isFinite ||
                time30 <= 0 ||
                time30 > elapsed ||
                rings < 30)) ||
        (rings >= 30 && time30 == null)) {
      throw ArgumentError('Enter three letters and a valid completed result.');
    }
    return _request(
      view,
      LeaderboardEntry(
        name: name,
        seconds: elapsed,
        rings: rings,
        height: height,
        time30: time30,
      ),
      run: true,
    );
  }

  String _key(GameMode mode) => 'devxsd.leaderboard.v2.${mode.name}';

  List<LeaderboardEntry> _readLocal(GameMode mode) {
    try {
      final saved =
          platform.read(_key(mode)) ??
          platform.read('devxsd.leaderboard.v1.${mode.name}') ??
          '[]';
      return (jsonDecode(saved) as List).map((value) {
        final entry = LeaderboardEntry.fromJson(value as Map<String, dynamic>);
        return mode == GameMode.timed && entry.time30 == null
            ? LeaderboardEntry(
                name: entry.name,
                seconds: entry.seconds,
                rings: entry.rings,
                height: entry.height,
                time30: entry.seconds,
              )
            : entry;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<LeaderboardEntry> _saveLocal(GameMode mode, LeaderboardEntry? entry) {
    final entries = _readLocal(mode);
    if (entry != null) entries.add(entry);
    entries.sort(
      mode == GameMode.timed
          ? (a, b) {
              final time = (a.time30 ?? a.seconds).compareTo(
                b.time30 ?? b.seconds,
              );
              return time != 0 ? time : b.rings.compareTo(a.rings);
            }
          : (a, b) {
              final rings = b.rings.compareTo(a.rings);
              if (rings != 0) return rings;
              final height = b.height.compareTo(a.height);
              return height != 0 ? height : a.seconds.compareTo(b.seconds);
            },
    );
    final top = entries.take(10).toList();
    platform.write(_key(mode), jsonEncode(top.map((e) => e.toJson()).toList()));
    return top;
  }

  Future<LeaderboardTable> _request(
    GameMode mode,
    LeaderboardEntry? entry, {
    bool run = false,
  }) async {
    try {
      final response = await platform.request(
        mode.name,
        entry == null
            ? null
            : jsonEncode({
                'mode': run ? 'run' : mode.name,
                'view': mode.name,
                ...entry.toJson(),
              }),
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
      platform.write(
        _key(mode),
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
      return LeaderboardTable(entries: entries, shared: true);
    } catch (_) {
      if (run && entry != null) {
        _saveLocal(GameMode.unlimited, entry);
        if (entry.time30 != null) {
          _saveLocal(
            GameMode.timed,
            LeaderboardEntry(
              name: entry.name,
              seconds: entry.seconds,
              rings: entry.rings,
              height: entry.height,
              time30: entry.time30,
            ),
          );
        }
        return LeaderboardTable(entries: _saveLocal(mode, null), shared: false);
      }
      return LeaderboardTable(entries: _saveLocal(mode, entry), shared: false);
    }
  }
}
