import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'puzzle_model.dart';
import 'garden_ecology.dart';
import 'camera_rig.dart';

/// A perspective view of the rules grid. Drawing never participates in collision.
class ChandelierGame extends FlameGame {
  ChandelierGame({required this.model});

  final PuzzleModel model;
  double _clock = 0;
  final CameraRig _camera = CameraRig();
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
    _camera.reset(activeRow: _activeRow, pieceSerial: model.pieceSerial);
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
    _camera.update(
      activeRow: _activeRow,
      pieceSerial: model.pieceSerial,
      dt: dt,
    );
  }

  double get _activeRow =>
      model.activeCells.fold<double>(0, (sum, cell) => sum + cell.row) /
          model.activeCells.length -
      model.riseProgress;
  double get cameraFocusRow => _camera.focusRow;
  double get _radius => 18 / (2 * math.pi);
  double get _eyeRow => _camera.focusRow + 2;
  double get _eyeZ => _radius + 3;
  double get _pitch => 50 * math.pi / 180;
  double get _focalY => size.y * .61;
  double get _focalX => size.y * .66 / 1.62;
  double get _unit => _focalX / 11;
  double get _yaw => (model.angle + model.collisionBounce) * math.pi * 2 / 18;
  double get _cameraInclination =>
      -.12 + math.sin(_clock * math.pi * 2 / 52) * .012;
  double get _parallax =>
      math.sin(_yaw * .4) * size.x * .012 +
      math.sin(_clock * math.pi * 2 / 73) * size.x * .005;

  double _viewDepth(double column, double row, {double radius = 1}) {
    final theta = column * math.pi * 2 / 18 - _yaw;
    final dz = _radius * radius * math.cos(theta) - _eyeZ;
    return -math.sin(_pitch) * (row - _eyeRow) - math.cos(_pitch) * dz;
  }

  Offset _rawProject(
    double column,
    double row, {
    double radius = 1,
    double? centerRow,
  }) {
    final theta = column * math.pi * 2 / 18 - _yaw;
    final x = _radius * radius * math.sin(theta);
    final dy = row - _eyeRow;
    final dz = _radius * radius * math.cos(theta) - _eyeZ;
    final depth = math.max(.75, -math.sin(_pitch) * dy - math.cos(_pitch) * dz);
    final screenX = _focalX * x / depth;
    final screenY =
        _focalY * (math.cos(_pitch) * dy - math.sin(_pitch) * dz) / depth;
    final roll = _cameraInclination * .3;
    return Offset(
      size.x / 2 +
          _parallax +
          screenX * math.cos(roll) -
          screenY * math.sin(roll),
      math.max(size.y * .61, 128 + size.y * .452) +
          screenX * math.sin(roll) +
          screenY * math.cos(roll),
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
    return Offset(
      size.x / 2 + (point.dx - size.x / 2) * _verticalFit,
      point.dy * _verticalFit + _verticalOffset,
    );
  }

  void _fitProjection() {
    if (size.x <= 0 || size.y <= 0) return;
    final offset =
        model.angle + model.collisionBounce - model.activeCenterColumn;
    var left = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final cell in model.activeCells) {
      for (final dx in [-.43, .43]) {
        for (final dy in [-.43, .43]) {
          final point = _rawProject(
            cell.column + offset + dx,
            cell.row - model.riseProgress + dy,
            radius: 1.08,
          );
          left = math.min(left, point.dx);
          right = math.max(right, point.dx);
          bottom = math.max(bottom, point.dy);
        }
      }
    }
    // At contact during a spin the snapped ghost can project slightly below
    // the smooth active piece. Protect both silhouettes from excessive cropping.
    for (final cell in model.landingCells) {
      for (final dx in [-.43, .43]) {
        bottom = math.max(
          bottom,
          _rawProject(cell.column + dx, cell.row + .43, radius: 1.08).dy,
        );
      }
    }
    var crownTop = double.infinity;
    for (var column = 0; column < 36; column++) {
      crownTop = math.min(
        crownTop,
        _rawProject(column / 2, -.8, radius: 1.1).dy - 12,
      );
    }
    final targetBottom = size.y * 1.015;
    final safeTop = math.max(128.0, size.y * .15);
    final halfWidth = size.x * .5;
    final sideExtent = math.max(halfWidth - left, right - halfWidth);
    _verticalFit = math.min(
      1.45,
      math.min(
        (targetBottom - safeTop) / math.max(1, bottom - crownTop),
        size.x * .47 / math.max(1, sideExtent),
      ),
    );
    _verticalOffset = targetBottom - bottom * _verticalFit;
  }

  Rect get projectedActiveBounds {
    final offset =
        model.angle + model.collisionBounce - model.activeCenterColumn;
    final points = model.activeCells.expand(
      (cell) => projectedBrickFace(
        cell.column + offset,
        cell.row - model.riseProgress,
      ),
    );
    var bounds = Rect.fromLTWH(points.first.dx, points.first.dy, 0, 0);
    for (final point in points) {
      bounds = bounds.expandToInclude(Rect.fromLTWH(point.dx, point.dy, 0, 0));
    }
    return bounds;
  }

  Rect get projectedLandingBounds {
    final points = model.landingCells.expand(
      (cell) => projectedBrickFace(cell.column.toDouble(), cell.row.toDouble()),
    );
    var bounds = Rect.fromLTWH(points.first.dx, points.first.dy, 0, 0);
    for (final point in points) {
      bounds = bounds.expandToInclude(Rect.fromLTWH(point.dx, point.dy, 0, 0));
    }
    return bounds;
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
    return bounds.inflate(2);
  }

  /// Viewer-facing occupied face, shared by active and settled cuboids.
  List<Offset> projectedBrickFace(double column, double row) {
    _fitProjection();
    final theta = column * math.pi * 2 / 18 - _yaw;
    final radius = math.cos(theta) > _radius / _eyeZ ? 1.08 : .92;
    return [
      _project(column - .43, row - .43, radius: radius, centerRow: row),
      _project(column + .43, row - .43, radius: radius, centerRow: row),
      _project(column + .43, row + .43, radius: radius, centerRow: row),
      _project(column - .43, row + .43, radius: radius, centerRow: row),
    ];
  }

  /// Matching projected end-plane profiles, used for geometry verification.
  Rect projectedRimBounds(double row) {
    _fitProjection();
    var bounds = Rect.fromLTWH(_project(0, row).dx, _project(0, row).dy, 0, 0);
    for (var i = 0; i < 360; i++) {
      final point = _project(i / 20, row, radius: 1.025);
      bounds = bounds.expandToInclude(Rect.fromLTWH(point.dx, point.dy, 0, 0));
    }
    return bounds;
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
    canvas.clipRect(Rect.fromLTWH(0, size.y * .14, size.x, size.y * .86));
    _rim(canvas, 41.8, false);
    _drawHalf(canvas, false);
    _ecology(canvas, false);
    final plantBounds = _plant(canvas);
    _drawHalf(canvas, true);
    _ecology(canvas, true);
    GardenEcology.paintButterflies(
      canvas,
      plantBounds: plantBounds,
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
    final night = _nightImage;
    if (night != null) {
      final factor =
          math.max(size.x / night.width, size.y / night.height) * 1.10;
      final width = night.width * factor;
      final height = night.height * factor;
      final drift = math.sin(_yaw * .12) * size.x * .025;
      canvas.drawImageRect(
        night,
        Rect.fromLTWH(0, 0, night.width.toDouble(), night.height.toDouble()),
        Rect.fromLTWH(
          (size.x - width) / 2 + drift,
          (size.y - height) / 2 + math.cos(_yaw * .08) * 4,
          width,
          height,
        ),
        Paint()..filterQuality = FilterQuality.none,
      );
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF071d26).withValues(alpha: .20),
      );
    }
    // Separate nearer hills move faster than the distant panorama.
    for (var layer = 0; layer < 2; layer++) {
      final shift = math.sin(_yaw * (.18 + layer * .09)) * (12 + layer * 10);
      final hill = Path()..moveTo(-50, size.y);
      for (var i = -2; i < 15; i++) {
        final x = i * size.x / 10 + shift;
        final y =
            size.y * (.82 + layer * .045) +
            math.sin(i * .85 + layer * 2) * (18 + layer * 8);
        hill.lineTo(x, y);
      }
      hill
        ..lineTo(size.x + 50, size.y)
        ..close();
      canvas.drawPath(
        hill,
        Paint()
          ..color = layer == 0
              ? const Color(0xFF163c3e)
              : const Color(0xFF0a292c),
      );
    }
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
      if ((depth > _radius / _eyeZ) != front) continue;
      final brightness = front ? .70 + .30 * depth : .36;
      for (var row = 0; row < 42; row++) {
        if (_viewDepth(column.toDouble(), row.toDouble()) < 1) continue;
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

  void _halo(Canvas canvas, List<GridCell> cells, Color color, bool active) {
    for (final cell in cells) {
      final visualRow = cell.row.toDouble() - (active ? model.riseProgress : 0);
      final visualColumn =
          cell.column.toDouble() +
          (active
              ? model.angle + model.collisionBounce - model.activeCenterColumn
              : 0);
      // Paint the glow first; the opaque raised brick covers its entire interior.
      final path = _cell(visualColumn, visualRow, active ? -.015 : .035);
      if (!active) {
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: .11));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: active ? .20 : .13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 5 : 7,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: active ? .85 : .88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 1.2 : 1.6,
      );
      if (active) {
        _brick(
          canvas,
          visualColumn,
          visualRow,
          _colors[(model.activeType - 1) % 7],
          .96,
        );
      }
    }
  }

  Rect _plant(Canvas canvas) {
    final anchor = _project(model.angle, 40.8, radius: 0);
    final center = anchor.dx;
    final potBottom = anchor.dy;
    final potWidth =
        (_focalX * 2.1 / math.max(1, _viewDepth(model.angle, 40.8, radius: 0)))
            .clamp(25.0, size.x * .32);
    final potTop = _project(model.angle, 39.3, radius: 0).dy;
    if (_viewDepth(model.angle, 40.8, radius: 0) > 1 &&
        potBottom < size.y * .86) {
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
    }
    final growth = model.rings;
    final stemRows = growth == 0 ? 6.8 : math.min(31.0, 3 + growth * .48);
    final topRow = 39.3 - stemRows;
    Rect? foliageBounds;
    for (var row = 39.3; row > topRow; row -= .4) {
      if (_viewDepth(model.angle, row, radius: 0) < 1 ||
          _viewDepth(model.angle, row - .4, radius: 0) < 1) {
        continue;
      }
      final a = _project(model.angle, row, radius: 0);
      final b = _project(model.angle, row - .4, radius: 0);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF789450)
          ..strokeWidth = 2,
      );
    }
    final count = growth == 0 ? 2 : math.min(23, 2 + growth ~/ 2);
    for (var i = 0; i < count; i++) {
      final row = growth == 0
          ? topRow + .5
          : 39.3 - stemRows * (.15 + .8 * (i + 1) / count);
      final depth = _viewDepth(model.angle, row, radius: 0);
      if (depth < 1) continue;
      final azimuth = i * 2.4 + _yaw * .25 + (growth ~/ 46) * .31;
      final side = growth == 0 ? (i.isEven ? -1.0 : 1.0) : math.sin(azimuth);
      final base = _project(model.angle, row, radius: 0);
      final leafSize = (_focalX * (growth == 0 ? .65 : 1.65) / depth).clamp(
        8.0,
        85.0,
      );
      final leafAnchor = base + Offset(side * leafSize * .6, 0);
      if (base.dy < size.y * .12 || base.dy > size.y * .83) continue;
      canvas.drawLine(
        base + Offset(0, leafSize * .2),
        leafAnchor,
        Paint()
          ..color = const Color(0xFF789450)
          ..strokeWidth = 1.5,
      );
      if (growth == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: leafAnchor + Offset(side * leafSize * .2, -leafSize * .25),
            width: leafSize,
            height: leafSize * .45,
          ),
          Paint()..color = const Color(0xFF9ac66c),
        );
      } else {
        _leaf(
          canvas,
          leafAnchor,
          leafSize,
          side >= 0 ? 1 : -1,
          .35 + .65 * side.abs(),
          math.cos(azimuth) < 0,
        );
      }
      final leafBounds = Rect.fromCenter(
        center: leafAnchor + Offset(0, -leafSize * .4),
        width: leafSize * 1.4,
        height: leafSize * 1.4,
      );
      foliageBounds = foliageBounds?.expandToInclude(leafBounds) ?? leafBounds;
    }
    return foliageBounds ??
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y * .5),
          width: 0,
          height: 0,
        );
  }

  void _leaf(
    Canvas canvas,
    Offset anchor,
    double length,
    double side,
    double squash,
    bool rear,
  ) {
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
          ..color = Colors.white.withValues(alpha: rear ? .65 : 1),
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
          ..color = rear ? const Color(0xFF28553c) : const Color(0xFF4e915a),
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
      if (_viewDepth(column, row, radius: 1.025) < 1) {
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
    final crownWidth =
        (_focalX * 8 / math.max(1, _viewDepth(model.angle, -2, radius: 0)))
            .clamp(94.0, size.x * .65);
    final apex = light + Offset(0, -crownWidth * .23);
    // A tiered central canopy and six curved metal arms, depth ordered.
    for (final rear in [true, false]) {
      for (var i = 0; i < 6; i++) {
        final column = i * 3.0;
        final depth = math.cos(column * math.pi * 2 / 18 - _yaw);
        if ((depth < 0) != rear) continue;
        final azimuth = column * math.pi * 2 / 18 - _yaw;
        final side = math.sin(azimuth);
        final root = light + Offset(side * crownWidth * .08, -crownWidth * .13);
        final elbow =
            light + Offset(side * crownWidth * .40, -crownWidth * .34);
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
    if (_viewDepth(column, row) < 1) return;
    final theta = column * math.pi * 2 / 18 - _yaw;
    final front = math.cos(theta) > _radius / _eyeZ;
    final radialSign = front ? 1.0 : -1.0;
    final faceRadius = front ? 1.08 : .92;
    List<Offset> corners(double radius) => [
      _project(column - .43, row - .43, radius: radius, centerRow: row),
      _project(column + .43, row - .43, radius: radius, centerRow: row),
      _project(column + .43, row + .43, radius: radius, centerRow: row),
      _project(column - .43, row + .43, radius: radius, centerRow: row),
    ];
    final back = corners(1);
    final face = corners(faceRadius);
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

    // The eye is below the piece: the bottom plane faces the viewer.
    polygon([back[3], face[3], face[2], back[2]], surface(0, 1, 0));
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

  void _queue(Canvas canvas) {
    final queue = model.nextPieces;
    for (var i = 0; i < math.min(3, queue.length); i++) {
      final scale = 5.0 - i * .7;
      final x = size.x * .70 + i * 21;
      final y = size.y * .765 - i * 8;
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
              alpha: .58 - i * .12,
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
