// The device back button used to close the app from any screen.
//
// The app shell puts a *nested* Navigator under `MaterialApp.home` so that a
// switch of account can throw the whole navigation stack away. The system back
// gesture, though, is delivered to the root navigator — which holds exactly
// one route — so every screen pushed into the nested Navigator was invisible
// to it and `handlePopRoute` fell through to "nothing to pop, leave the app".
//
// These tests drive the real gesture path: `handlePopRoute` is what the
// platform channel calls when Android's back button is pressed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/main.dart';
import 'package:nearzy/presentation/common/animations/nearzy_page_route.dart';
import 'package:nearzy/presentation/features/onboarding/view/onboarding_screen.dart';

/// A stand-in for any of the app's pushed screens.
class _PushedScreen extends StatelessWidget {
  const _PushedScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('pushed')));
}

void main() {
  // The onboarding entry point is the only one that renders without hitting
  // the network, and it sits inside the same nested Navigator as every other
  // shell — which is the part under test.
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(userModel: null, hasSeenOnboarding: false),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  }

  testWidgets('back pops a screen pushed into the app-shell Navigator',
      (tester) async {
    await pumpShell(tester);

    final BuildContext context = tester.element(find.byType(OnboardingScreen));
    context.pushScreen(() => const _PushedScreen());
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);

    // What Android's back button triggers.
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue,
        reason: 'the gesture must be consumed, not passed to the OS');
    expect(find.text('pushed'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('back unwinds a stack one screen at a time', (tester) async {
    await pumpShell(tester);

    final BuildContext context = tester.element(find.byType(OnboardingScreen));
    context.pushScreen(() => const _PushedScreen());
    await tester.pumpAndSettle();
    context.pushScreen(() => const _PushedScreen());
    await tester.pumpAndSettle();

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    // One of the two is gone; the other is still standing.
    expect(find.text('pushed'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('back closes a modal sheet rather than the app', (tester) async {
    await pumpShell(tester);

    final BuildContext context = tester.element(find.byType(OnboardingScreen));
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(height: 120, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
  });

  testWidgets('back on the shell itself is left to the platform',
      (tester) async {
    await pumpShell(tester);

    // Nothing to pop: the gesture has to fall through so Android can do what
    // it normally does at the root of an app. Swallowing it here would trap
    // the user in the app instead.
    expect(await tester.binding.handlePopRoute(), isFalse);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
