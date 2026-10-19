import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Independent, softly blended passes of the bundled panorama. Motion is
/// bounded and considerably slower than a piece's rise or a cylinder turn.
class GardenBackdrop {
  static const cycleSeconds = 720.0;

  static Offset layerOffset(int layer, double seconds, double yaw, Size size) {
    final phase = seconds * 2 * math.pi;
    return Offset(
      math.sin(yaw * (.10 + layer * .06)) * size.width * (.01 + layer * .007) +
          math.sin(phase / (210 - layer * 31) + layer) *
              size.width *
              (.006 + layer * .003),
      math.sin(phase / (260 - layer * 23) + layer * .7) * (1 + layer * .5),
    );
  }

  static Color tint(double seconds) {
    final phase = (seconds % cycleSeconds) / cycleSeconds * 4;
    const colors = [
      Color(0x16041428),
      Color(0x1fd49b82),
      Color(0x1b86b9ae),
      Color(0x20b77971),
      Color(0x16041428),
    ];
    final stage = phase.floor();
    final progress = phase - stage;
    // Smooth derivatives at each boundary, including the cycle seam.
    final eased = progress * progress * (3 - 2 * progress);
    return Color.lerp(colors[stage], colors[stage + 1], eased)!;
  }

  static void paint(
    Canvas canvas, {
    required Size size,
    required ui.Image? image,
    required double seconds,
    required double yaw,
  }) {
    final rect = Offset.zero & size;
    if (image != null) {
      final factor =
          math.max(size.width / image.width, size.height / image.height) * 1.10;
      final width = image.width * factor;
      final height = image.height * factor;
      final base = Rect.fromLTWH(
        (size.width - width) / 2,
        (size.height - height) / 2,
        width,
        height,
      );
      final source = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final paint = Paint()..filterQuality = FilterQuality.none;
      canvas.save();
      canvas.clipRect(rect);
      // Sky is a continuous base. Terrain passes fade in over broad bands,
      // avoiding exposed crop seams as each pass moves independently.
      canvas.drawImageRect(
        image,
        source,
        base.shift(layerOffset(0, seconds, yaw, size)),
        paint,
      );
      for (var layer = 1; layer <= 2; layer++) {
        final fadeStart = size.height * (layer == 1 ? .52 : .72);
        final fadeEnd = fadeStart + size.height * .12;
        canvas.saveLayer(rect, Paint());
        canvas.drawImageRect(
          image,
          source,
          base.shift(layerOffset(layer, seconds, yaw, size)),
          paint,
        );
        canvas.drawRect(
          rect,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.linear(
              Offset(0, fadeStart),
              Offset(0, fadeEnd),
              const [Colors.transparent, Colors.white],
            ),
        );
        canvas.restore();
      }
      canvas.drawRect(rect, Paint()..color = const Color(0x26071d26));
      canvas.drawRect(rect, Paint()..color = tint(seconds));
      canvas.restore();
    }
    for (var layer = 0; layer < 2; layer++) {
      final shift = layerOffset(layer + 1, seconds, yaw, size).dx * 1.3;
      final hill = Path()..moveTo(-50, size.height);
      for (var i = -2; i < 15; i++) {
        hill.lineTo(
          i * size.width / 10 + shift,
          size.height * (.82 + layer * .045) +
              math.sin(i * .85 + layer * 2) * (18 + layer * 8),
        );
      }
      hill
        ..lineTo(size.width + 50, size.height)
        ..close();
      canvas.drawPath(
        hill,
        Paint()
          ..color = layer == 0
              ? const Color(0xFF163c3e)
              : const Color(0xFF0a292c),
      );
    }
    // A faint, broad horizon haze breathes over a multi-minute period.
    final mist = .018 + .012 * math.sin(seconds * 2 * math.pi / 155);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * .57),
          Offset(0, size.height * .83),
          [
            Colors.transparent,
            const Color(0xffa6c8bd).withValues(alpha: mist),
            Colors.transparent,
          ],
          [0, .55, 1],
        ),
    );
  }
}
