import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_bird_game/main.dart';

void main() {
  testWidgets('shows the start screen and options button', (tester) async {
    await tester.pumpWidget(const FlutterBirdApp());

    expect(find.text('FLUTTER BIRD'), findsOneWidget);
    expect(find.text('TAP TO START'), findsOneWidget);
    expect(find.text('OPTIONS'), findsOneWidget);
  });

  testWidgets('opens the options sheet', (tester) async {
    await tester.pumpWidget(const FlutterBirdApp());

    await tester.tap(find.text('OPTIONS'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('START LEVEL'), findsOneWidget);
    expect(find.text('RESET BEST SCORE'), findsOneWidget);
  });
}
