// Smoke test for the Nearzy app shell.
//
// The onboarding path is used because it is the only entry point that renders
// without hitting the network: a null user that has not seen onboarding yet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mca_project/main.dart';
import 'package:mca_project/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:mca_project/theme/theme.dart';

void main() {
  testWidgets('MyApp builds the onboarding flow for a first-time visitor',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(userModel: null, hasSeenOnboarding: false),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'Nearzy');
    expect(app.theme, nearzyTheme);
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
