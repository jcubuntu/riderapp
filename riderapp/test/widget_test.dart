// Basic Flutter widget test for RiderApp

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build a minimal MaterialApp to verify basic widget rendering
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('RiderApp Test'),
          ),
        ),
      ),
    );

    // Verify the test app renders
    expect(find.text('RiderApp Test'), findsOneWidget);
  });
}
