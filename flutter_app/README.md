# Tic Tac Toe: Flutter App

The mobile version of the [Tic Tac Toe game with unbeatable AI](../README.md). It has the same minimax AI, claymorphism design, animated background and persistent scoreboard as the web version.

## Download (Android)

Get the latest APK from **[Releases](https://github.com/kapoordeepanshu/tic-tac-toe-unbeatable-ai/releases/latest)**. Open it on your phone and allow "install from unknown sources" when asked.

## Run from source

Platform folders (`android/`, `ios/` …) aren't committed. Generate them once:

```bash
cd flutter_app
flutter create . --project-name tic_tac_toe --org com.kapoordeepanshu --platforms android,ios
rm test/widget_test.dart   # template test, not used
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

The test suite plays **every possible game** against the AI and checks that it never loses.

## Structure

```
lib/
├── main.dart        # App, theme, game screen & layout
├── game.dart        # Rules + minimax AI (pure Dart, no Flutter)
├── board.dart       # 3×3 board, animated X/O painter
├── background.dart  # Drifting blobs + floating X/O shapes
└── palette.dart     # Claymorphism design tokens (light & dark)
```
