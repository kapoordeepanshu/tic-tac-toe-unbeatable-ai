import 'dart:math';

import 'package:flutter/material.dart';

import 'palette.dart';

/// Drifting colour blobs + slowly rising X/O shapes (same idea as the web CSS).
class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({super.key});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BackdropPainter(_controller, Palette.of(context), showShapes: !reduceMotion),
        size: Size.infinite,
      ),
    );
  }
}

class _Blob {
  const _Blob(this.x, this.y, this.radius, this.phase, this.opacity);
  final double x, y, radius, phase, opacity;
}

class _Shape {
  const _Shape(this.x, this.size, this.speed, this.phase, this.isX);
  final double x, size, phase;
  final int speed; // whole loops per controller cycle, so the animation wraps seamlessly
  final bool isX;
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.animation, this.palette, {required this.showShapes}) : super(repaint: animation);

  final Animation<double> animation;
  final Palette palette;
  final bool showShapes;

  static const _blobs = [
    _Blob(0.1, 0.1, 0.55, 0.0, 0.40),
    _Blob(0.9, 0.9, 0.55, 0.33, 0.40),
    _Blob(0.55, 0.5, 0.35, 0.66, 0.22),
  ];

  static const _shapes = [
    _Shape(0.06, 56, 1, 0.10, true),
    _Shape(0.22, 36, 2, 0.55, false),
    _Shape(0.44, 30, 1, 0.80, true),
    _Shape(0.64, 60, 1, 0.35, false),
    _Shape(0.80, 40, 2, 0.70, true),
    _Shape(0.92, 28, 1, 0.05, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final colors = [palette.primary, palette.secondary, palette.accent];

    for (var i = 0; i < _blobs.length; i++) {
      final b = _blobs[i];
      final angle = 2 * pi * (t + b.phase);
      final center = Offset(
        size.width * b.x + sin(angle) * size.shortestSide * 0.12,
        size.height * b.y + cos(angle) * size.shortestSide * 0.10,
      );
      final radius = size.longestSide * b.radius;
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          colors[i].withValues(alpha: b.opacity),
          colors[i].withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    if (!showShapes) return;

    for (final s in _shapes) {
      final progress = (t * s.speed + s.phase) % 1.0;
      final y = size.height + 100 - progress * (size.height + 200);
      final paint = Paint()
        ..color = (s.isX ? palette.primary : palette.secondary).withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.size / 6
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(size.width * s.x, y);
      canvas.rotate(progress * 2 * pi);
      final h = s.size / 2;
      if (s.isX) {
        final d = h * 0.7;
        canvas.drawLine(Offset(-d, -d), Offset(d, d), paint);
        canvas.drawLine(Offset(d, -d), Offset(-d, d), paint);
      } else {
        canvas.drawCircle(Offset.zero, h - s.size / 12, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.palette != palette || old.showShapes != showShapes;
}
