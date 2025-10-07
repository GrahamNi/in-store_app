// Basic Flutter widget test for Label Scanner app
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:label_scanner/main.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LabelScannerApp());

    // Verify that the app initializes (presence of material app)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
