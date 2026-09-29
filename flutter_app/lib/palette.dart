import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game.dart';

/// Claymorphism design tokens, mirroring the CSS variables of the web version.
class Palette {
  const Palette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.foreground,
    required this.muted,
    required this.border,
    required this.winBg,
    required this.winText,
    required this.shadow,
  });

  final Color primary; // X
  final Color secondary; // O
  final Color accent;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color foreground;
  final Color muted;
  final Color border;
  final Color winBg;
  final Color winText;
  final Color shadow;

  static const light = Palette(
    primary: Color(0xFFEC4899),
    secondary: Color(0xFF8B5CF6),
    accent: Color(0xFFF59E0B),
    onPrimary: Colors.white,
    background: Color(0xFFFDF2F8),
    surface: Colors.white,
    foreground: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    border: Color(0xFFFBCFE8),
    winBg: Color(0xFFFEF3C7),
    winText: Color(0xFFB45309),
    shadow: Color(0x24EC4899),
  );

  static const dark = Palette(
    primary: Color(0xFFF472B6),
    secondary: Color(0xFFA78BFA),
    accent: Color(0xFFFBBF24),
    onPrimary: Color(0xFF1E1B2E),
    background: Color(0xFF1A1625),
    surface: Color(0xFF272238),
    foreground: Color(0xFFF5F3FF),
    muted: Color(0xFFA8A3BD),
    border: Color(0xFF3B3354),
    winBg: Color(0xFF4A3A17),
    winText: Color(0xFFFBBF24),
    shadow: Color(0x59000000),
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color markColor(Player player) => player == Player.x ? primary : secondary;

  BoxDecoration clay({Color? color, Color? borderColor, double radius = 16}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? border, width: 3),
      boxShadow: [
        BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 8)),
      ],
    );
  }

  TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color ?? foreground, height: 1.15);
}
