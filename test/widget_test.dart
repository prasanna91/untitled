// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled/main.dart';
import 'package:untitled/module/myapp.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
       const MyApp(
        webUrl: 'https://example.com',
        isBottomMenu: false,
        isSplash: false,
        splashLogo: '',
        splashBg: '',
        splashDuration: 1,
        splashAnimation: 'fade',
        bottomMenuItems: '[]',
        isDomainUrl: false,
        backgroundColor: '#FFFFFF',
        activeTabColor: '#000000',
        textColor: '#000000',
        iconColor: '#000000',
        iconPosition: 'above',
        taglineColor: '#000000',
        spbgColor: '#FFFFFF',
        isLoadIndicator: false,
        splashTagline: '',
        taglineFont: 'Roboto',
        taglineSize: 16.0,
        taglineBold: false,
        taglineItalic: false,
        initializeFirebaseAfterSplash: false, // FIXED: Add missing parameter
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
