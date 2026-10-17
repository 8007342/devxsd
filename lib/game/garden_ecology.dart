import 'dart:math' as math;
import 'dart:ui';

import 'puzzle_model.dart';

typedef GardenProject =
    Offset Function(
      double column,
      double row, {
      double radius,
      double? centerRow,
    });

/// Deterministic decoration derived from surviving cells, never gameplay state.
/// Roots disappear with cleared occupancy and weathering follows settled ages.
class GardenEcology {
  static double weathering(double age) => ((age - 3) / 45).clamp(0.0, 1.0);

  static int butterflyCount(int rings, double clock) {
    if (rings <= 0) return 0;
    final phase = clock % 48;
    if (rings >= 20 && phase >= 44 && phase < 46) return 3;
    return rings >= 6 && phase >= 15 && phase < 35 ? 2 : 1;
  }

  static void paintHalf(
    Canvas canvas, {
    required PuzzleModel model,
    required double clock,
    required bool front,
    required GardenProject project,
    required double yaw,
    required double unit,
  }) {
    final pixel = (unit * .12).clamp(.65, 1.6);
    bool visible(double column) =>
        (math.cos(column * math.pi * 2 / 18 - yaw) >= 0) == front;
    final opacity = front ? 1.0 : .58;
    for (var row = 0; row < PuzzleModel.rows; row++) {
      for (var column = 0; column < PuzzleModel.columns; column++) {
        if (model.board[row][column] == 0 || !visible(column.toDouble())) {
          continue;
        }
        final age = model.settledAge(row, column);
        final amount = weathering(age);
        if (amount <= 0) continue;
        final seed = row * 19 + column * 7;
        final faceRadius = front ? 1.085 : .915;
        for (var speck = 0; speck < 3; speck++) {
          final x = -.3 + ((seed + speck * 13) % 11) * .055;
          final y = -.3 + ((seed * 3 + speck * 7) % 11) * .055;
          final point = project(
            column + x,
            row + y,
            radius: faceRadius,
            centerRow: row.toDouble(),
          );
          canvas.drawRect(
            Rect.fromLTWH(point.dx, point.dy, pixel, pixel),
            Paint()
              ..color = const Color(
                0xFF38422b,
              ).withValues(alpha: amount * .42 * opacity),
          );
        }
        // Small independent rootlets cling to occupied faces only.
        if (age > 7 && seed % 4 == 0) {
          final root = Path();
          for (var segment = 0; segment < 5; segment++) {
            final point = project(
              column + .18 + math.sin(segment * 2.4 + seed) * .12,
              row - .4 + segment * .19,
              radius: faceRadius,
              centerRow: row.toDouble(),
            );
            if (segment == 0) {
              root.moveTo(point.dx, point.dy);
            } else {
              root.lineTo(point.dx, point.dy);
            }
          }
          canvas.drawPath(
            root,
            Paint()
              ..color = const Color(0xFFa29660).withValues(alpha: opacity * .6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = pixel * .65,
          );
          final moss = project(
            column - .2,
            row - .3,
            radius: faceRadius,
            centerRow: row.toDouble(),
          );
          canvas.drawRect(
            Rect.fromLTWH(moss.dx, moss.dy, pixel * 2.4, pixel),
            Paint()
              ..color = const Color(
                0xFF65934f,
              ).withValues(alpha: amount * opacity * .7),
          );
        }
      }
    }
    if (model.stackDepth == 0) return;
    // Six slender tendrils maximum, growing quickly but leaving the middle open.
    final rootedColumns = [
      for (var column = 0; column < PuzzleModel.columns; column++)
        if (model.board.any((row) => row[column] != 0)) column,
    ];
    final count = math.min(6, rootedColumns.length);
    for (var vine = 0; vine < count; vine++) {
      final column = rootedColumns[vine].toDouble();
      if (!visible(column)) continue;
      final occupiedRow = model.board.lastIndexWhere(
        (row) => row[column.toInt()] != 0,
      );
      final reach = math.min(18.0, math.max(4.0, occupiedRow + 1.0));
      var oldestAge = 0.0;
      for (var row = 0; row < PuzzleModel.rows; row++) {
        oldestAge = math.max(oldestAge, model.settledAge(row, column.toInt()));
      }
      final length = math.min(reach, 1.0 + oldestAge * 1.4 + vine * .65);
      final path = Path();
      for (var step = 0; step <= 20; step++) {
        final row = -.5 + length * step / 20;
        final drift = .32 + math.sin(step * .28 + vine) * .13;
        final point = project(column + drift, row, radius: 1.10);
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF799254).withValues(alpha: opacity * .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = pixel,
      );
      for (var leaf = 1; leaf <= length.floor(); leaf++) {
        final side = leaf.isEven ? 1.0 : -1.0;
        final anchor = project(
          column + .32 + math.sin(leaf * .4 + vine) * .13,
          leaf.toDouble() - .4,
          radius: 1.12,
        );
        final size = math.max(2.8, pixel * 2.8);
        final shape = Path()
          ..moveTo(anchor.dx, anchor.dy)
          ..lineTo(anchor.dx + side * size, anchor.dy - size * .3)
          ..lineTo(anchor.dx + side * size * 1.3, anchor.dy + size * .45)
          ..lineTo(anchor.dx + side * size * .4, anchor.dy + size * 1.2)
          ..close();
        canvas.drawPath(
          shape,
          Paint()
            ..color =
                (leaf.isEven
                        ? const Color(0xFFa6c97a)
                        : const Color(0xFF70a55e))
                    .withValues(alpha: opacity),
        );
      }
    }
    // At most one fly, bee and ladybug; intermittent, never a swarm.
    for (var insect = 0; insect < 3; insect++) {
      if ((clock + insect * 7) % 27 > 9) continue;
      final column = (insect * 6 + 1).toDouble();
      if (!visible(column)) continue;
      final anchor = project(
        column + math.sin(clock * .7 + insect) * .35,
        2.5 + insect * 3 + math.sin(clock * .8) * .4,
        radius: 1.18,
      );
      final color = [
        const Color(0xFF9aa39b),
        const Color(0xFFe5bd58),
        const Color(0xFFc95e4f),
      ][insect];
      canvas.drawRect(
        Rect.fromCenter(center: anchor, width: pixel * 2, height: pixel * 1.4),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.drawRect(
        Rect.fromLTWH(anchor.dx, anchor.dy, pixel * .65, pixel),
        Paint()..color = const Color(0xFF23372e).withValues(alpha: opacity),
      );
      if (insect != 2) {
        canvas.drawRect(
          Rect.fromLTWH(
            anchor.dx - pixel,
            anchor.dy - pixel * 1.1,
            pixel,
            pixel * .65,
          ),
          Paint()
            ..color = const Color(0xFFd4ded3).withValues(alpha: opacity * .6),
        );
      }
    }
  }

  static void paintButterflies(
    Canvas canvas, {
    required Rect plantBounds,
    required int rings,
    required double clock,
  }) {
    final count = butterflyCount(rings, clock);
    final pixel = (plantBounds.width * .025).clamp(.8, 1.8);
    for (var index = 0; index < count; index++) {
      final phase = clock * .38 + index * 2.6;
      final anchor = Offset(
        plantBounds.center.dx + math.sin(phase) * plantBounds.width * .7,
        plantBounds.center.dy +
            math.sin(phase * .71 + index) * plantBounds.height * .33,
      );
      final wing = pixel * (1.3 + math.sin(clock * 8 + index).abs() * 1.5);
      final paint = Paint()
        ..color = [
          const Color(0xFFe8b875),
          const Color(0xFFb7c8db),
          const Color(0xFFd6a2bd),
        ][index];
      for (final side in [-1, 1]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(anchor.dx + side * wing * .6, anchor.dy),
            width: wing,
            height: pixel * 2,
          ),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(
              anchor.dx + side * wing * .45,
              anchor.dy + pixel * 1.3,
            ),
            width: wing * .7,
            height: pixel,
          ),
          paint,
        );
      }
      canvas.drawRect(
        Rect.fromCenter(center: anchor, width: pixel * .7, height: pixel * 3),
        Paint()..color = const Color(0xFF4a4932),
      );
    }
  }
}
