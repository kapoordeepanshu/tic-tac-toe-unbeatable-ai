import 'dart:math';

enum Player { x, o }

extension PlayerInfo on Player {
  Player get other => this == Player.x ? Player.o : Player.x;
  String get label => this == Player.x ? 'X' : 'O';
}

enum GameMode { pvp, cpu }

enum Difficulty { easy, hard }

/// Finished game: [winner] is null for a draw.
class GameResult {
  const GameResult(this.winner, this.line);

  final Player? winner;
  final List<int> line;

  bool get isDraw => winner == null;
}

const List<List<int>> winLines = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
  [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
  [0, 4, 8], [2, 4, 6], //            diagonals
];

/// Returns the result if the game is over, otherwise null.
GameResult? evaluate(List<Player?> board) {
  for (final line in winLines) {
    final a = board[line[0]];
    if (a != null && a == board[line[1]] && a == board[line[2]]) {
      return GameResult(a, line);
    }
  }
  if (board.every((cell) => cell != null)) return const GameResult(null, []);
  return null;
}

List<int> emptyCells(List<Player?> board) =>
    [for (var i = 0; i < board.length; i++) if (board[i] == null) i];

/// Picks the computer's move. Hard = perfect minimax play; easy = mostly random.
int bestMove(
  List<Player?> board,
  Player ai, {
  Difficulty difficulty = Difficulty.hard,
  Random? random,
}) {
  final options = emptyCells(board);
  if (options.isEmpty) throw StateError('No moves left');

  final rng = random ?? Random();
  if (difficulty == Difficulty.easy && rng.nextDouble() < 0.7) {
    return options[rng.nextInt(options.length)];
  }

  final b = List<Player?>.of(board);
  var bestScore = -1000;
  var best = options.first;
  for (final i in options) {
    b[i] = ai;
    final score = _minimax(b, ai, ai.other, 1);
    b[i] = null;
    if (score > bestScore) {
      bestScore = score;
      best = i;
    }
  }
  return best;
}

// Depth-adjusted so the AI prefers faster wins and slower losses.
int _minimax(List<Player?> b, Player ai, Player turn, int depth) {
  final result = evaluate(b);
  if (result != null) {
    if (result.winner == ai) return 10 - depth;
    if (result.isDraw) return 0;
    return depth - 10;
  }

  var best = turn == ai ? -1000 : 1000;
  for (final i in emptyCells(b)) {
    b[i] = turn;
    final score = _minimax(b, ai, turn.other, depth + 1);
    b[i] = null;
    best = turn == ai ? max(best, score) : min(best, score);
  }
  return best;
}
