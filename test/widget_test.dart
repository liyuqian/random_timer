import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:random_timer/main.dart';

void main() {
  testWidgets('Play smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(RandomTimerApp());

    expect(find.text('Lower bound (in seconds):'), findsOneWidget);
    expect(find.text('Upper bound (in seconds):'), findsOneWidget);
    expect(
      find.text('Random timer between 1 and 1 seconds. Last run: 0 seconds.'),
      findsOneWidget,
    );

    // Tap the play icon.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Tap the stop icon.
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    find.byType(Text).last;

    expect(
      find.text('Random timer between 1 and 1 seconds. Last run: 1 seconds. Alarm lasts: 0 seconds.'),
      findsOneWidget,
    );
  });
}
