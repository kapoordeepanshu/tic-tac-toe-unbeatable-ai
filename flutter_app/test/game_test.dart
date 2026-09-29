import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/game.dart';

List<Player?> parse(String s) => [
      for (final c in s.split(''))
        c == 'X' ? Player.x : (c == 'O' ? Player.o : null),
    ];

void main() {
  group('evaluate', () {
    test('detects a row win', () {
      final r = evaluate(parse('XXXOO....'));
      expect(r?.winner, Player.x);
      expect(r?.line, [0, 1, 2]);
    });

    test('detects a diagonal win', () {
      expect(evaluate(parse('OX.XO.X.O'))?.winner, Player.o);
    });

    test('detects a draw', () {
      expect(evaluate(parse('XOXXOOOXX'))?.isDraw, isTrue);
    });

    test('returns null while the game is running', () {
      expect(evaluate(parse('X...O....')), isNull);
    });
  });

  group('hard AI', () {
    test('takes an immediate win', () {
      expect(bestMove(parse('OO.XX....'), Player.o), 2);
    });

    test('blocks an immediate loss', () {
      expect(bestMove(parse('XX..O....'), Player.o), 2);
    });

    test('never loses, whoever starts', () {
      var gamesPlayed = 0;

      // Explore every possible human (X) move sequence against the AI (O).
      void explore(List<Player?> board, Player turn) {
        final result = evaluate(board);
        if (result != null) {
          expect(result.winner, isNot(Player.x), reason: 'AI lost: $board');
          gamesPlayed++;
          return;
        }
        if (turn == Player.o) {
          final next = List<Player?>.of(board)..[bestMove(board, Player.o)] = Player.o;
          explore(next, Player.x);
        } else {
          for (final i in emptyCells(board)) {
            explore(List<Player?>.of(board)..[i] = Player.x, Player.o);
          }
        }
      }

      explore(List<Player?>.filled(9, null), Player.x);
      explore(List<Player?>.filled(9, null), Player.o);
      expect(gamesPlayed, greaterThan(0));
    });
  });
}
