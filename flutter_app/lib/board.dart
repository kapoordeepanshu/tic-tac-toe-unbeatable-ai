import 'dart:math';

import 'package:flutter/material.dart';

import 'game.dart';
import 'palette.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.cells,
    required this.winLine,
    required this.enabled,
    required this.onTap,
  });

  final List<Player?> cells;
  final List<int> winLine;
  final bool enabled;
  final ValueChanged<int> onTap;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    // Fixed rows/columns of Expanded children: a mark can never resize its cell.
    return Container(
      padding: const EdgeInsets.all(_gap),
      decoration: p.clay(radius: 24),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: _gap),
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    if (col > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: _Cell(
                        index: row * 3 + col,
                        value: cells[row * 3 + col],
                        isWin: winLine.contains(row * 3 + col),
                        enabled: enabled,
                        onTap: onTap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.value,
    required this.isWin,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final Player? value;
  final bool isWin;
  final bool enabled;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final playable = enabled && value == null;

    return Semantics(
      button: true,
      enabled: playable,
      label: 'Cell ${index + 1}, ${value?.label ?? 'empty'}',
      child: MouseRegion(
        cursor: playable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: playable ? () => onTap(index) : null,
          // One-shot bounce whenever the cell becomes part of the winning line.
          child: TweenAnimationBuilder<double>(
            key: ValueKey(isWin),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: isWin ? 450 : 0),
            builder: (context, t, child) =>
                Transform.scale(scale: isWin ? 1 + 0.08 * sin(pi * t) : 1, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: p.clay(
                color: isWin ? p.winBg : p.background,
                borderColor: isWin ? p.accent : p.border,
              ),
              child: value == null
                  ? null
                  : Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.64,
                        heightFactor: 0.64,
                        child: AnimatedMark(key: ValueKey(value), player: value!),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// X or O that draws itself with a stroke animation.
class AnimatedMark extends StatelessWidget {
  const AnimatedMark({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final color = Palette.of(context).markColor(player);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: reduceMotion ? 0 : 320),
      curve: Curves.easeOut,
      builder: (context, progress, _) => CustomPaint(
        painter: MarkPainter(player: player, progress: progress, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class MarkPainter extends CustomPainter {
  MarkPainter({required this.player, required this.progress, required this.color});

  final Player player;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Same 100-unit coordinate system as the web SVG marks.
    final u = size.shortestSide / 100;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * u
      ..strokeCap = StrokeCap.round;

    if (player == Player.x) {
      void line(Offset a, Offset b, double t) {
        if (t <= 0) return;
        canvas.drawLine(a, Offset.lerp(a, b, t.clamp(0, 1))!, paint);
      }

      line(Offset(18 * u, 18 * u), Offset(82 * u, 82 * u), progress * 2);
      line(Offset(82 * u, 18 * u), Offset(18 * u, 82 * u), progress * 2 - 1);
    } else {
      final rect = Rect.fromCircle(center: Offset(50 * u, 50 * u), radius: 34 * u);
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(MarkPainter old) =>
      old.progress != progress || old.color != color || old.player != player;
}
