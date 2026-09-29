import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background.dart';
import 'board.dart';
import 'game.dart';
import 'palette.dart';

void main() => runApp(const TicTacToeApp());

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme.fromSeed(seedColor: p.primary, brightness: brightness),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme)
          .apply(bodyColor: p.foreground, displayColor: p.foreground),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _human = Player.x;
  static const _cpu = Player.o;

  List<Player?> _board = List<Player?>.filled(9, null);
  Player _current = Player.x;
  Player _starter = Player.x;
  GameResult? _result;

  GameMode _mode = GameMode.pvp;
  Difficulty _difficulty = Difficulty.hard;
  int _scoreX = 0, _scoreO = 0, _draws = 0;

  SharedPreferences? _prefs;
  Timer? _cpuTimer;
  final _random = Random();

  // ---------- Persistence ----------
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _mode = GameMode.values[(prefs.getInt('mode') ?? 0).clamp(0, GameMode.values.length - 1)];
      _difficulty =
          Difficulty.values[(prefs.getInt('difficulty') ?? 1).clamp(0, Difficulty.values.length - 1)];
      _scoreX = prefs.getInt('scoreX') ?? 0;
      _scoreO = prefs.getInt('scoreO') ?? 0;
      _draws = prefs.getInt('draws') ?? 0;
    });
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt('mode', _mode.index);
    prefs.setInt('difficulty', _difficulty.index);
    prefs.setInt('scoreX', _scoreX);
    prefs.setInt('scoreO', _scoreO);
    prefs.setInt('draws', _draws);
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    super.dispose();
  }

  // ---------- Game flow ----------
  bool get _cpuTurn => _mode == GameMode.cpu && _current == _cpu && _result == null;

  void _play(int index) {
    if (_result != null || _board[index] != null) return;
    setState(() {
      _board[index] = _current;
      _result = evaluate(_board);
      final result = _result;
      if (result == null) {
        _current = _current.other;
      } else if (result.isDraw) {
        _draws++;
      } else if (result.winner == Player.x) {
        _scoreX++;
      } else {
        _scoreO++;
      }
    });
    if (_result != null) _save();
    if (_cpuTurn) _scheduleCpu();
  }

  void _scheduleCpu() {
    _cpuTimer?.cancel();
    _cpuTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || !_cpuTurn) return;
      _play(bestMove(_board, _cpu, difficulty: _difficulty, random: _random));
    });
  }

  void _newRound() {
    _cpuTimer?.cancel();
    setState(() {
      _board = List<Player?>.filled(9, null);
      _result = null;
      // Alternate who starts each round for fairness.
      _starter = _starter.other;
      _current = _starter;
    });
    if (_cpuTurn) _scheduleCpu();
  }

  void _resetMatch() {
    setState(() {
      _scoreX = 0;
      _scoreO = 0;
      _draws = 0;
      _starter = Player.o; // _newRound flips this so X starts
    });
    _save();
    _newRound();
  }

  // ---------- Text ----------
  String _nameOf(Player player) {
    if (_mode == GameMode.cpu) return player == _human ? 'You' : 'Computer';
    return 'Player ${player.label}';
  }

  String get _status {
    final result = _result;
    if (result != null) {
      if (result.isDraw) return "It's a draw!";
      final who = _nameOf(result.winner!);
      return who == 'You' ? 'You win!' : '$who wins!';
    }
    if (_cpuTurn) return 'Computer is thinking…';
    return _mode == GameMode.cpu ? 'Your turn (X)' : "${_current.label}'s turn";
  }

  // ---------- Layout ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackdrop()),
          SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 700 && c.maxWidth > c.maxHeight;
              final board = GameBoard(
                cells: _board,
                winLine: _result?.line ?? const [],
                enabled: _result == null && !_cpuTurn,
                onTap: _play,
              );

              if (wide) {
                // Tablet / landscape: info panel left, board right.
                // Phones in landscape are short, so the panel switches to compact spacing.
                final compact = c.maxHeight < 520;
                final gapW = compact ? 24.0 : 48.0;
                final size = min(c.maxHeight - 24, c.maxWidth - 320 - gapW - 32).clamp(180.0, 560.0);
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 320,
                        height: c.maxHeight,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _panel(wide: true, compact: compact),
                          ),
                        ),
                      ),
                      SizedBox(width: gapW),
                      SizedBox.square(dimension: size, child: board),
                    ],
                  ),
                );
              }

              // Phone portrait: stacked, board shrinks to fit so nothing scrolls.
              final reserved = _mode == GameMode.cpu ? 430.0 : 360.0;
              final size = min(c.maxWidth - 32, c.maxHeight - reserved).clamp(200.0, 520.0);
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _panel(wide: false),
                      const SizedBox(height: 16),
                      SizedBox.square(dimension: size, child: board),
                      const SizedBox(height: 16),
                      _actions(),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _panel({required bool wide, bool compact = false}) {
    final p = Palette.of(context);
    final winner = _result?.winner;
    final gap = SizedBox(height: compact ? 10 : 16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Tic ', style: TextStyle(color: p.primary)),
            const TextSpan(text: 'Tac '),
            TextSpan(text: 'Toe', style: TextStyle(color: p.secondary)),
          ]),
          style: p.display(compact ? 30 : (wide ? 44 : 36)),
        ),
        if (wide) ...[gap, _statusText(p, winner, compact ? 20 : 26)],
        gap,
        Segmented<GameMode>(
          value: _mode,
          activeColor: p.primary,
          options: const [(GameMode.pvp, '2 Players'), (GameMode.cpu, 'vs Computer')],
          onChanged: (mode) {
            if (mode == _mode) return;
            setState(() => _mode = mode);
            _resetMatch(); // scores don't carry across modes
          },
        ),
        if (_mode == GameMode.cpu) ...[
          SizedBox(height: compact ? 8 : 12),
          Segmented<Difficulty>(
            value: _difficulty,
            activeColor: p.secondary,
            options: const [(Difficulty.easy, 'Easy'), (Difficulty.hard, 'Unbeatable')],
            onChanged: (level) {
              if (level == _difficulty) return;
              setState(() => _difficulty = level);
              _resetMatch();
            },
          ),
        ],
        if (!wide) ...[gap, _statusText(p, winner, 20)],
        gap,
        Row(
          children: [
            Expanded(
              child: ScoreCard(
                label: _nameOf(Player.x),
                value: _scoreX,
                color: p.primary,
                highlighted: _result == null && _current == Player.x,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: ScoreCard(label: 'Draws', value: _draws, color: p.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: ScoreCard(
                label: _nameOf(Player.o),
                value: _scoreO,
                color: p.secondary,
                highlighted: _result == null && _current == Player.o,
              ),
            ),
          ],
        ),
        if (wide) ...[gap, _actions(start: true)],
      ],
    );
  }

  Widget _statusText(Palette p, Player? winner, double size) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        child: Text(
          _status,
          style: p.display(size, weight: FontWeight.w600, color: winner != null ? p.winText : null),
        ),
      ),
    );
  }

  Widget _actions({bool start = false}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: start ? WrapAlignment.start : WrapAlignment.center,
      children: [
        ClayButton(label: 'New Round', primary: true, onPressed: _newRound),
        ClayButton(label: 'Reset Score', onPressed: _resetMatch),
      ],
    );
  }
}

// ---------- Small clay widgets ----------

class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: p.clay(radius: 999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (option, label) in options)
            Semantics(
              button: true,
              selected: option == value,
              inMutuallyExclusiveGroup: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == value ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: p.display(
                        15,
                        weight: FontWeight.w500,
                        color: option == value ? p.onPrimary : p.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: p.clay(borderColor: highlighted ? color : null),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: p.muted,
              ),
            ),
          ),
          Text('$value', style: p.display(28, color: color)),
        ],
      ),
    );
  }
}

class ClayButton extends StatelessWidget {
  const ClayButton({super.key, required this.label, required this.onPressed, this.primary = false});

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          // Padding (not alignment) sizes the button to its label, keeping 48px height.
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: p.clay(
              color: primary ? p.primary : null,
              borderColor: primary ? p.primary : null,
            ),
            child: Text(
              label,
              style: p.display(16, weight: FontWeight.w600, color: primary ? p.onPrimary : null),
            ),
          ),
        ),
      ),
    );
  }
}
