import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'puzzle_model.dart';
import 'garden_ecology.dart';
import 'garden_backdrop.dart';

/// A perspective view of the rules grid. Drawing never participates in collision.
class ChandelierGame extends FlameGame {
  ChandelierGame({required this.model});

  final PuzzleModel model;
  static const sceneZoom = 1.10;
  double _clock = 0;
  double _cameraRow = 20.5;
  double _visibleRows = 46;
  double _burst = 1;
  int _seenClear = 0;
  List<int> _burstRows = [];
  ui.Image? _leafImage;
  ui.Image? _nightImage;
  double _burstColumn = 0;
  double _verticalFit = 1;
  double _verticalOffset = 0;
  static const _cream = Color(0xFFefe0c4);
  static const _mint = Color(0xFFa9f1d5);
  static const _colors = <Color>[
    Color(0xFF62d6d1),
    Color(0xFFefe0c4),
    Color(0xFFec6f7b),
    Color(0xFFba7256),
    Color(0xFFb59bcb),
    Color(0xFF729ebf),
    Color(0xFFd4b475),
  ];

  @override
  Future<void> onLoad() async {
    try {
      _nightImage = await images.load('night-landscape.png');
    } catch (_) {
      _nightImage = null;
    }
    // Procedural foliage remains available if the optional art is absent.
    try {
      _leafImage = await images.load('monstera-leaf.png');
    } catch (_) {
      _leafImage = null;
    }
  }

  void resetView() {
    _cameraRow = 20.5;
    _visibleRows = 46;
    _burst = 1;
    _seenClear = model.clearSerial;
    _burstRows = [];
  }

  @override
  Color backgroundColor() => const Color(0xFF091c21);

  @override
  void update(double dt) {
    super.update(dt);
    final frame = dt.clamp(0.0, 0.05);
    model.update(dt);
    _clock += frame;
    _burst += frame;
    if (_seenClear != model.clearSerial) {
      _seenClear = model.clearSerial;
      _burstRows = List.of(model.lastClearedRows);
      _burstColumn = model.angle;
      _burst = 0;
    }
    final targetRows = 46.0 + 2 * (model.stackDepth / 42).clamp(0.0, 1.0);
    _visibleRows += (targetRows - _visibleRows) * math.min(1, frame * 2.3);
  }

  double get _width => math.min(size.x * .84, size.y * .62);
  double get _unit => size.y * .70 / _visibleRows;
  double get _centerY => size.y * .48;
  double get _yaw => (model.angle + model.collisionBounce) * math.pi * 2 / 18;
  double get _cameraInclination =>
      -.055 + math.sin(_clock * math.pi * 2 / 52) * .012;
  double get _depthPitch => .045 + math.sin(_clock * math.pi * 2 / 67) * .006;
  double get _parallax =>
      math.sin(_yaw * .4) * size.x * .025 +
      math.sin(_clock * math.pi * 2 / 73) * size.x * .008;

  Offset _rawProject(
    double column,
    double row, {
    double radius = 1,
    double? centerRow,
  }) {
    final theta = column * math.pi * 2 / 18 - _yaw;
    final depth = math.cos(theta) * radius;
    final perspective = 1 / (1.38 - depth * .38);
    final x = math.sin(theta) * _width * .41 * radius * perspective;
    final rowCenter = centerRow ?? row;
    final y =
        (rowCenter - _cameraRow) * _unit +
        (row - rowCenter) * _unit * perspective +
        depth * _width * _depthPitch;
    final inclination = _cameraInclination;
    return Offset(
      size.x / 2 +
          _parallax +
          x * math.cos(inclination) -
          y * math.sin(inclination),
      _centerY + x * math.sin(inclination) + y * math.cos(inclination),
    );
  }

  Offset _project(
    double column,
    double row, {
    double radius = 1,
    double? centerRow,
  }) {
    final point = _rawProject(
      column,
      row,
      radius: radius,
      centerRow: centerRow,
    );
    return Offset(point.dx, point.dy * _verticalFit + _verticalOffset);
  }

  void _fitProjection() {
    if (size.y <= 0) return;
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (var sample = 0; sample < 90; sample++) {
      for (final row in [-1.0, 42.0]) {
        final y = _rawProject(sample / 5, row, radius: 1.09).dy;
        low = math.min(low, y);
        high = math.max(high, y);
      }
    }
    final top = math.max(size.y * .14, 128.0);
    final bottom = size.y * .815;
    _verticalFit = math.min(1, (bottom - top) / (high - low));
    _verticalOffset = (top + bottom) * .5 - (high + low) * .5 * _verticalFit;
  }

  /// Actual projected envelope, including the radially extruded outer faces.
  Rect get projectedBoardBounds {
    _fitProjection();
    var bounds = Rect.fromCenter(center: _project(0, 0), width: 0, height: 0);
    for (var sample = 0; sample < 360; sample++) {
      for (final row in [-.8, 41.8]) {
        final point = _project(sample / 20, row, radius: 1.08);
        bounds = bounds.expandToInclude(
          Rect.fromLTWH(point.dx, point.dy, 0, 0),
        );
      }
    }
    return _zoomBounds(bounds.inflate(2));
  }

  /// Matching projected end-plane profiles, used for geometry verification.
  Rect projectedRimBounds(double row) {
    _fitProjection();
    var bounds = Rect.fromLTWH(_project(0, row).dx, _project(0, row).dy, 0, 0);
    for (var i = 0; i < 360; i++) {
      final point = _project(i / 20, row, radius: 1.025);
      bounds = bounds.expandToInclude(Rect.fromLTWH(point.dx, point.dy, 0, 0));
    }
    return _zoomBounds(bounds);
  }

  Rect _zoomBounds(Rect bounds) {
    final center = Offset(size.x / 2, size.y * .48);
    return Rect.fromPoints(
      center + (bounds.topLeft - center) * sceneZoom,
      center + (bounds.bottomRight - center) * sceneZoom,
    );
  }

  Path _cell(double column, double row, [double inset = .07]) {
    final points = [
      _project(column - .5 + inset, row - .5 + inset, centerRow: row),
      _project(column + .5 - inset, row - .5 + inset, centerRow: row),
      _project(column + .5 - inset, row + .5 - inset, centerRow: row),
      _project(column - .5 + inset, row + .5 - inset, centerRow: row),
    ];
    return Path()..addPolygon(points, true);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    _fitProjection();
    _background(canvas);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, size.y * .115, size.x, size.y * .755));
    canvas.translate(size.x / 2, size.y * .48);
    canvas.scale(sceneZoom);
    canvas.translate(-size.x / 2, -size.y * .48);
    _rim(canvas, 41.8, false);
    _drawHalf(canvas, false);
    _ecology(canvas, false);
    _plant(canvas);
    _drawHalf(canvas, true);
    _ecology(canvas, true);
    final soil = _project(model.angle, 39.3, radius: 0);
    GardenEcology.paintButterflies(
      canvas,
      plantBounds: Rect.fromLTRB(
        soil.dx - _width * .22,
        soil.dy - model.stemRows * _unit * .76 * _verticalFit,
        soil.dx + _width * .22,
        soil.dy,
      ),
      rings: model.rings,
      clock: _clock,
    );

    _halo(canvas, model.landingCells, _mint, false);
    _halo(canvas, model.activeCells, _cream, true);
    _crown(canvas);
    _rim(canvas, 41.8, true);
    _ringBurst(canvas);
    canvas.restore();
    _queue(canvas);
    _bottomGlow(canvas);
  }

  void _background(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.x * .5, size.y * .39),
          size.y * .65,
          const [Color(0xFF183e3c), Color(0xFF091c21), Color(0xFF061316)],
          [0, .7, 1],
        ),
    );
    GardenBackdrop.paint(
      canvas,
      size: Size(size.x, size.y),
      image: _nightImage,
      seconds: _clock,
      yaw: _yaw,
    );
    // Restrained distant conservatory architecture and warm dust.
    final frame = Paint()
      ..color = const Color(0xFF34554d).withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * .055, size.y * .055, size.x * .89, size.y * .82),
        Radius.circular(size.x * .45),
      ),
      frame,
    );
    for (var i = 0; i < 24; i++) {
      final x = ((i * 73.7) % 101) / 101 * size.x;
      final y = ((i * 47.3 + _clock * (i % 3 + 1)) % 101) / 101 * size.y * .8;
      canvas.drawRect(
        Rect.fromLTWH(x, y, i % 4 == 0 ? 2 : 1, 1),
        Paint()..color = _cream.withValues(alpha: .08 + (i % 3) * .035),
      );
    }
  }

  void _drawHalf(Canvas canvas, bool front) {
    final columns = List.generate(18, (i) => i)
      ..sort(
        (a, b) => math
            .cos(a * math.pi * 2 / 18 - _yaw)
            .compareTo(math.cos(b * math.pi * 2 / 18 - _yaw)),
      );
    for (final column in columns) {
      final depth = math.cos(column * math.pi * 2 / 18 - _yaw);
      if ((depth >= 0) != front) continue;
      final brightness = front ? .70 + .30 * depth : .36;
      for (var row = 0; row < 42; row++) {
        final path = _cell(column.toDouble(), row.toDouble());
        final value = model.board[row][column];
        if (value > 0) {
          final color = _colors[(value - 1) % 7];
          _brick(canvas, column.toDouble(), row.toDouble(), color, brightness);
        } else {
          canvas.drawPath(
            path,
            Paint()
              ..color = _mint.withValues(alpha: front ? .075 : .035)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .65,
          );
        }
      }
    }
  }

  List<({double column, double row})> get activeDrawCells {
    final offset =
        model.angle + model.collisionBounce - model.activeCenterColumn;
    final cells = model.activeCells
        .map(
          (cell) => (
            column: cell.column + offset,
            row: cell.row - model.riseProgress,
          ),
        )
        .toList();
    cells.sort((a, b) {
      final depth = math
          .cos(a.column * math.pi * 2 / 18 - _yaw)
          .compareTo(math.cos(b.column * math.pi * 2 / 18 - _yaw));
      return depth != 0 ? depth : a.row.compareTo(b.row);
    });
    return cells;
  }

  void _halo(Canvas canvas, List<GridCell> cells, Color color, bool active) {
    final visualCells = active
        ? activeDrawCells
        : [
            for (final cell in cells)
              (column: cell.column.toDouble(), row: cell.row.toDouble()),
          ];
    // Every glow goes behind the WHOLE opaque piece. Interleaving strokes and
    // cuboids lets later neighboring glows wash out the earlier brick faces.
    for (final cell in visualCells) {
      final path = active
          ? (Path()..addPolygon(
              _brickCorners(
                cell.column,
                cell.row,
                math.cos(cell.column * math.pi * 2 / 18 - _yaw) >= 0
                    ? 1.08
                    : .92,
                half: .49,
              ),
              true,
            ))
          : _cell(cell.column, cell.row, .035);
      if (!active) {
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: .11));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: active ? .16 : .13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 4 : 7,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: active ? .8 : .88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 1 : 1.6,
      );
    }
    if (active) {
      for (final cell in visualCells) {
        final depth = math.cos(cell.column * math.pi * 2 / 18 - _yaw);
        _brick(
          canvas,
          cell.column,
          cell.row,
          _colors[(model.activeType - 1) % 7],
          depth >= 0 ? .70 + .30 * depth : .36,
        );
      }
    }
  }

  List<Offset> _brickCorners(
    double column,
    double row,
    double radius, {
    double half = .43,
  }) => [
    _project(column - half, row - half, radius: radius, centerRow: row),
    _project(column + half, row - half, radius: radius, centerRow: row),
    _project(column + half, row + half, radius: radius, centerRow: row),
    _project(column - half, row + half, radius: radius, centerRow: row),
  ];

  /// Shared solid pass for active/settled render verification and composition.
  void paintBrick(Canvas canvas, double column, double row, int type) {
    _fitProjection();
    final depth = math.cos(column * math.pi * 2 / 18 - _yaw);
    _brick(
      canvas,
      column,
      row,
      _colors[type - 1],
      depth >= 0 ? .70 + .30 * depth : .36,
    );
  }

  void paintActivePiece(Canvas canvas) {
    _fitProjection();
    _halo(canvas, model.activeCells, _cream, true);
  }

  void _plant(Canvas canvas) {
    final anchor = _project(model.angle, 40.8, radius: 0);
    final center = anchor.dx;
    final potBottom = anchor.dy;
    final potWidth = _width * .22;
    final potTop = potBottom - potWidth * .65;
    final shadow = Rect.fromCenter(
      center: Offset(center + 5, potBottom + 4),
      width: potWidth * 1.12,
      height: potWidth * .21,
    );
    canvas.drawOval(
      shadow,
      Paint()..color = const Color(0xFF041719).withValues(alpha: .5),
    );
    final pot = Path()
      ..moveTo(center - potWidth * .5, potTop)
      ..lineTo(center + potWidth * .5, potTop)
      ..lineTo(center + potWidth * .36, potBottom)
      ..quadraticBezierTo(
        center,
        potBottom + potWidth * .15,
        center - potWidth * .36,
        potBottom,
      )
      ..close();
    final highlight = .36 + math.sin(_yaw * .25) * .08;
    canvas.drawPath(
      pot,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center - potWidth * .5, potTop),
          Offset(center + potWidth * .5, potTop),
          const [
            Color(0xFF784635),
            Color(0xFFd19469),
            Color(0xFFb66d4e),
            Color(0xFF704335),
          ],
          [0, highlight, .68, 1],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center, potBottom),
        width: potWidth * .72,
        height: potWidth * .16,
      ),
      Paint()..color = const Color(0xFF8c503d),
    );
    final rim = Rect.fromCenter(
      center: Offset(center, potTop),
      width: potWidth * 1.12,
      height: potWidth * .30,
    );
    canvas.drawOval(
      rim.shift(const Offset(0, 3)),
      Paint()..color = const Color(0xFF9d5d43),
    );
    canvas.drawOval(rim, Paint()..color = const Color(0xFFdfa477));
    canvas.drawOval(
      rim.deflate(potWidth * .07),
      Paint()..color = const Color(0xFF342b24),
    );
    canvas.drawArc(
      rim.deflate(1),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFf0bc8c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          center - potWidth * .25 + i * potWidth * .12,
          potTop + (i.isEven ? -1 : 1),
          2,
          1,
        ),
        Paint()..color = const Color(0xFF70513b),
      );
    }
    final growth = model.rings;
    if (growth == 0) {
      final tip = Offset(center + 1, potTop - potWidth * .42);
      canvas.drawLine(
        Offset(center, potTop),
        tip,
        Paint()
          ..color = const Color(0xFFa3c778)
          ..strokeWidth = 2,
      );
      for (final side in [-1.0, 1.0]) {
        final leaf = Path()
          ..moveTo(tip.dx, tip.dy + 5)
          ..quadraticBezierTo(
            tip.dx + side * potWidth * .40,
            tip.dy - potWidth * .24,
            tip.dx + side * potWidth * .37,
            tip.dy - 2,
          )
          ..quadraticBezierTo(
            tip.dx + side * potWidth * .22,
            tip.dy + potWidth * .15,
            tip.dx,
            tip.dy + 5,
          );
        canvas.drawPath(
          leaf,
          Paint()
            ..color = side < 0
                ? const Color(0xFF6b9f58)
                : const Color(0xFF9ac66c),
        );
      }
    }
    if (growth > 0) {
      final length = model.stemRows * _unit * .76 * _verticalFit;
      final stemTop = potTop - length;
      canvas.drawLine(
        Offset(center, potTop),
        Offset(center + 3, stemTop),
        Paint()
          ..color = const Color(0xFF6a8a4c)
          ..strokeWidth = 3,
      );
      // Actual growth nodes remember their birth time and multi-clear vigor.
      // The fallback also makes deterministic direct-ring art fixtures useful.
      final leaves = model.leaves.isNotEmpty
          ? model.leaves
          : List.generate(
              math.min(24, growth),
              (i) => PlantLeaf(
                node: i + 1,
                bornAt: -10,
                vigor: 1,
                variation: .5,
                azimuth: 0,
              ),
            );
      final oldest = math.max(0, growth - 32);
      for (var i = 0; i < leaves.length; i++) {
        final leaf = leaves[i];
        final opening = leaf.opening(model.elapsed);
        final relative = leaf.node <= 8
            ? leaf.node / math.max(12, growth)
            : .25 +
                  .75 *
                      (leaf.node - oldest).clamp(0, 32) /
                      math.min(32, growth);
        final azimuth = leaf.node * 2.4 + leaf.azimuth + _yaw * .25;
        final side = math.sin(azimuth);
        final y = potTop - length * (.10 + .85 * relative.clamp(0, 1));
        final leafSize =
            _width * .12 * leaf.matureScale * (.22 + .78 * opening);
        final anchor = Offset(center + side * leafSize * .65, y);
        canvas.drawLine(
          Offset(center, y + leafSize * .2),
          anchor,
          Paint()
            ..color = const Color(0xFF789450)
            ..strokeWidth = 1.5,
        );
        canvas.save();
        canvas.translate(anchor.dx, anchor.dy);
        canvas.rotate((leaf.variation - .5) * .45);
        if (opening < .18) {
          // A tightly rolled new leaf with a light seam.
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(0, -leafSize * .35),
              width: leafSize * .18,
              height: leafSize * .8,
            ),
            Paint()..color = const Color(0xFFb3d987),
          );
        } else {
          _leaf(
            canvas,
            Offset.zero,
            leafSize,
            side >= 0 ? 1 : -1,
            (.35 + .65 * side.abs()) * (.18 + .82 * opening),
            math.cos(azimuth) < 0,
            vigor: leaf.vigor,
            opening: opening,
          );
        }
        canvas.restore();
      }
    }
  }

  void _leaf(
    Canvas canvas,
    Offset anchor,
    double length,
    double side,
    double squash,
    bool rear, {
    double vigor = 1,
    double opening = 1,
  }) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(side * -.38);
    canvas.scale(side * squash, 1);
    final image = _leafImage;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(-length * .5, -length * .95, length, length),
        Paint()
          ..filterQuality = FilterQuality.none
          ..color = Colors.white.withValues(alpha: rear ? .65 : 1)
          ..colorFilter = ColorFilter.matrix([
            1 + (vigor - 1) * .35,
            0,
            0,
            0,
            (1 - opening) * 10,
            0,
            1 + (vigor - 1) * .45,
            0,
            0,
            (1 - opening) * 20,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
      );
    } else {
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-length * .22, -length * .08)
        ..lineTo(-length * .43, length * .1)
        ..lineTo(-length * .48, length * .29)
        ..lineTo(-length * .27, length * .24)
        ..lineTo(-length * .45, length * .42)
        ..lineTo(-length * .33, length * .57)
        ..lineTo(-length * .15, length * .4)
        ..lineTo(-length * .2, length * .68)
        ..lineTo(0, length * .85)
        ..lineTo(length * .2, length * .67)
        ..lineTo(length * .15, length * .43)
        ..lineTo(length * .32, length * .6)
        ..lineTo(length * .44, length * .44)
        ..lineTo(length * .25, length * .26)
        ..lineTo(length * .47, length * .31)
        ..lineTo(length * .4, length * .11)
        ..lineTo(length * .2, -length * .09)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            rear ? const Color(0xFF28553c) : const Color(0xFF4e915a),
            const Color(0xFFb5df7a),
            ((vigor - 1) * .5 + (1 - opening) * .3).clamp(0, 1),
          )!,
      );
      canvas.drawLine(
        Offset.zero,
        Offset(0, length * .69),
        Paint()
          ..color = const Color(0xFFa3c778)
          ..strokeWidth = 1.7,
      );
      for (final sign in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(sign * length * .12, length * .23),
            width: length * .075,
            height: length * .15,
          ),
          Paint()..color = const Color(0xFF173e32),
        );
      }
    }
    canvas.restore();
  }

  void _ecology(Canvas canvas, bool front) {
    GardenEcology.paintHalf(
      canvas,
      model: model,
      clock: _clock,
      front: front,
      project: (column, row, {radius = 1, double? centerRow}) =>
          _project(column, row, radius: radius, centerRow: centerRow),
      yaw: _yaw,
      unit: _unit,
    );
  }

  void _rim(Canvas canvas, double row, bool front) {
    final path = Path();
    var started = false;
    for (var i = 0; i <= 120; i++) {
      final column = model.angle + i * 18 / 120;
      final isFront = math.cos(i * math.pi * 2 / 120) >= 0;
      if (isFront != front) {
        started = false;
        continue;
      }
      final point = _project(column, row, radius: 1.025);
      if (!started) {
        path.moveTo(point.dx, point.dy);
        started = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = front ? const Color(0xFFd4b475) : const Color(0xFF6b7461)
        ..style = PaintingStyle.stroke
        ..strokeWidth = front ? 2.5 : 1.5,
    );
  }

  void _crown(Canvas canvas) {
    const brass = Color(0xFFc49a61);
    const shadow = Color(0xFF5d5540);
    final light = _project(model.angle, -1.2, radius: 0);
    final crownWidth = _width * .88;
    // Keep the ornamental canopy inside the original HUD clearance without
    // changing the cylinder projection or scaling its matching end planes.
    final crownRise = math.min(
      crownWidth * .34,
      math.max(0.0, light.dy - math.max(128.0, size.y * .14) - 4),
    );
    final apex = light + Offset(0, -crownRise * .68);
    // A tiered central canopy and six curved metal arms, depth ordered.
    for (final rear in [true, false]) {
      for (var i = 0; i < 6; i++) {
        final column = i * 3.0;
        final depth = math.cos(column * math.pi * 2 / 18 - _yaw);
        if ((depth < 0) != rear) continue;
        final azimuth = column * math.pi * 2 / 18 - _yaw;
        final side = math.sin(azimuth);
        final root = light + Offset(side * crownWidth * .08, -crownRise * .38);
        final elbow = light + Offset(side * crownWidth * .40, -crownRise);
        final tip =
            light + Offset(side * crownWidth * .51, depth * crownWidth * .055);
        final curl =
            light +
            Offset(side * crownWidth * .46, depth * crownWidth * .055 + 7);
        final arm = Path()
          ..moveTo(root.dx, root.dy)
          ..quadraticBezierTo(elbow.dx, elbow.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(curl.dx, curl.dy, curl.dx + 1, curl.dy + 2);
        canvas.drawPath(
          arm,
          Paint()
            ..color = shadow
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawPath(
          arm.shift(const Offset(-.5, -.5)),
          Paint()
            ..color = rear ? const Color(0xFF827751) : brass
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          tip,
          Offset(tip.dx, tip.dy + 7),
          Paint()
            ..color = brass
            ..strokeWidth = 1,
        );
        final gem = Path()
          ..moveTo(tip.dx, tip.dy + 5)
          ..lineTo(tip.dx + 2.5, tip.dy + 9)
          ..lineTo(tip.dx, tip.dy + 14)
          ..lineTo(tip.dx - 2.5, tip.dy + 9)
          ..close();
        canvas.drawPath(
          gem,
          Paint()..color = _cream.withValues(alpha: rear ? .40 : .85),
        );
      }
    }
    _rim(canvas, -.8, false);
    _rim(canvas, -.8, true);
    canvas.drawLine(
      apex,
      light,
      Paint()
        ..color = shadow
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      apex + const Offset(-1, 0),
      light + const Offset(-1, 0),
      Paint()
        ..color = brass
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: apex, width: 19, height: 5),
      Paint()..color = brass,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(apex.dx, apex.dy + 6),
        width: 25,
        height: 5,
      ),
      Paint()..color = shadow,
    );
    canvas.drawCircle(
      light,
      49,
      Paint()
        ..shader = ui.Gradient.radial(light, 49, [
          _cream.withValues(alpha: .30),
          _cream.withValues(alpha: 0),
        ]),
    );
    final shade = Path()
      ..moveTo(light.dx - 5, light.dy - 6)
      ..lineTo(light.dx + 5, light.dy - 6)
      ..lineTo(light.dx + 12, light.dy + 3)
      ..lineTo(light.dx - 12, light.dy + 3)
      ..close();
    canvas.drawPath(shade, Paint()..color = brass);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(light.dx, light.dy + 4),
        width: 22,
        height: 4,
      ),
      Paint()..color = _cream,
    );
  }

  void _brick(
    Canvas canvas,
    double column,
    double row,
    Color color,
    double light,
  ) {
    final theta = column * math.pi * 2 / 18 - _yaw;
    final front = math.cos(theta) >= 0;
    final radialSign = front ? 1.0 : -1.0;
    final faceRadius = front ? 1.08 : .92;
    final back = _brickCorners(column, row, 1);
    final face = _brickCorners(column, row, faceRadius);
    // World coordinates: x=R sin(theta), y grows down, z=R cos(theta).
    // All surfaces use outward normals and the same upper-left/front light.
    Color surface(double nx, double ny, double nz) {
      const lightLength = 1.3285330255586423;
      final lambert = math.max(0.0, (-.45 * nx - ny + .75 * nz) / lightLength);
      final intensity = (.48 + .52 * lambert) * light;
      return Color.lerp(
        const Color(0xFF0b282b),
        color,
        intensity.clamp(0.0, 1.0),
      )!;
    }

    void polygon(List<Offset> points, Color fill) {
      canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = fill);
    }

    // Top plane has outward normal (0,-1,0), visible from above.
    polygon([back[0], back[1], face[1], face[0]], surface(0, -1, 0));
    // The left tangent face points toward the viewer on the cylinder's right
    // half, and vice versa. Selection uses the positive z dot view directly.
    final sine = math.sin(theta);
    final cosine = math.cos(theta);
    final leftNormalZ = sine;
    if (leftNormalZ > 0) {
      polygon([back[0], face[0], face[3], back[3]], surface(-cosine, 0, sine));
    } else if (leftNormalZ < 0) {
      polygon([face[1], back[1], back[2], face[2]], surface(cosine, 0, -sine));
    }
    // Near-side outer radius faces outward; far-side inner radius faces inward.
    // Paint the continuously filled radial face last to occlude hidden planes.
    polygon(face, surface(radialSign * sine, 0, radialSign * cosine));
  }

  void _ringBurst(Canvas canvas) {
    if (_burst > .22) return;
    final progress = _burst / .22;
    for (final row in _burstRows) {
      for (var i = 0; i < 36; i++) {
        if (i / 36 > progress) continue;
        final direction = i.isEven ? 1 : -1;
        final point = _project(
          _burstColumn + direction * (i ~/ 2) / 2,
          row.toDouble(),
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: point,
            width: 3 + 5 * (1 - progress),
            height: 3,
          ),
          Paint()..color = _cream.withValues(alpha: 1 - progress * .8),
        );
      }
    }
  }

  static double previewBlockSize(int index) => const [15.0, 10.0, 9.0][index];

  void _queue(Canvas canvas) {
    final queue = model.nextPieces;
    for (var i = 0; i < math.min(3, queue.length); i++) {
      final scale = previewBlockSize(i);
      final x = math.min(size.x * .82, size.x - 4 * previewBlockSize(0) - 10);
      final y = size.y * (.62 + i * .065);
      final cells = PuzzleModel.cellsForType(queue[i]);
      for (final cell in cells) {
        canvas.drawRect(
          Rect.fromLTWH(
            x + cell.column * scale,
            y + cell.row * scale,
            scale - 1,
            scale - 1,
          ),
          Paint()
            ..color = _colors[(queue[i] - 1) % 7].withValues(
              alpha: .86 - i * .1,
            ),
        );
      }
    }
  }

  void _bottomGlow(Canvas canvas) {
    final y = size.y * .80;
    canvas.drawLine(
      Offset(size.x * .14, y),
      Offset(size.x * .86, y),
      Paint()
        ..color = const Color(0xFFd4b475).withValues(alpha: .28)
        ..strokeWidth = 1,
    );
  }
}
