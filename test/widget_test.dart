// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gameon/main.dart';

class _TestGameState extends ChangeNotifier {
  bool isLoading = true;
  bool hasSeenTutorial = false;
  List games = [];
  String? activeGameId;
}

void main() {
  testWidgets('App shows splash title', (WidgetTester tester) async {
    // Provide a lightweight GameState stub so `ZenLifeApp` can build.
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: _TestGameState(),
      child: const ZenLifeApp(),
    ));

    await tester.pump();

    // The splash screen shows the app title "Zen Focus".
    expect(find.text('Zen Focus'), findsOneWidget);
  });
}
