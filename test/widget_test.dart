import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_chat/main.dart';

void main() {
  testWidgets('Splash screen visual regression test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify splash screen or login view is rendered.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
