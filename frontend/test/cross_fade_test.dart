// Tests for CrossFade, the app's skeleton-to-content transition.
//
// The bug it exists to prevent — "Duplicate keys found" out of an
// AnimatedSwitcher — only shows up when phases change faster than the
// cross-fade, which is exactly what tapping the budget chips does and exactly
// what nobody does while checking a screen by hand.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/presentation/common/animations/cross_fade.dart';
import 'package:nearzy/theme/app_motion.dart';

/// The sequence that crashed the budget rail: shimmer, empty, shimmer again,
/// then the loaded list — each step landing before the previous cross-fade
/// has finished, so three entries are alive in the switcher at once.
const List<String> _phases = ['shimmer', 'empty', 'shimmer', 'list'];

/// Short enough that every phase overlaps the one before it.
const Duration _betweenPhases = Duration(milliseconds: 60);

/// Stand-ins for the budget rail's three branches: two keyless widgets of
/// different types, then a keyed one. That mix is what a raw AnimatedSwitcher
/// cannot survive — keyless entries all share a single key, and a keyed entry
/// arriving while two of them are still fading out puts the duplicates in the
/// Stack together. Same-typed keyless children would never reproduce it:
/// Widget.canUpdate matches them, so the switcher swaps them in place without
/// ever creating a second entry.
Widget _phaseChild(String phase) => switch (phase) {
  'shimmer' => const SizedBox(width: 40, child: Text('shimmer')),
  'empty' => const Padding(padding: EdgeInsets.zero, child: Text('empty')),
  _ => const Card(key: ValueKey('list'), child: Text('list')),
};

void main() {
  testWidgets('survives phases changing faster than the cross-fade', (
    tester,
  ) async {
    for (var i = 0; i < _phases.length; i++) {
      await tester.pumpWidget(
        MaterialApp(
          home: CrossFade(
            // The request counter is what makes a repeated phase distinct.
            state: (i, _phases[i]),
            child: _phaseChild(_phases[i]),
          ),
        ),
      );
      await tester.pump(_betweenPhases);
    }

    expect(tester.takeException(), isNull);

    // Proves the sequence actually overlapped: earlier phases are still on
    // screen, fading out, rather than having been cut.
    expect(find.text('shimmer'), findsWidgets);
    expect(find.text('list'), findsOneWidget);

    // The invariant itself, stated where it can be seen. A raw
    // AnimatedSwitcher reaches this point with three identically-keyed
    // entries in the Stack and throws before the assertion runs.
    final entries = tester.widget<Stack>(find.byType(Stack)).children;
    expect(entries.length, greaterThan(1), reason: 'phases did not overlap');
    expect(entries.map((e) => e.key).toSet(), hasLength(entries.length));

    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget);
    expect(find.text('shimmer'), findsNothing);
    expect(find.text('empty'), findsNothing);
  });

  testWidgets('rebuilding with an unchanged state updates in place', (
    tester,
  ) async {
    Future<void> pumpLabel(String label) => tester.pumpWidget(
      MaterialApp(
        home: CrossFade(state: 'loaded', child: Text(label)),
      ),
    );

    await pumpLabel('12 shops');
    await pumpLabel('13 shops');
    await tester.pump(Motion.base ~/ 2);

    // No cross-fade, so no stale copy of the old text hanging around.
    expect(find.text('12 shops'), findsNothing);
    expect(find.text('13 shops'), findsOneWidget);
  });

  testWidgets('a changed state does cross-fade', (tester) async {
    Future<void> pumpPhase(Object state, String label) => tester.pumpWidget(
      MaterialApp(
        home: CrossFade(state: state, child: Text(label)),
      ),
    );

    await pumpPhase('waiting', 'Looking around you…');
    await pumpPhase('loaded', '12 shops');
    await tester.pump(Motion.base ~/ 2);

    // Mid-flight both are mounted; that overlap is the whole point.
    expect(find.text('Looking around you…'), findsOneWidget);
    expect(find.text('12 shops'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Looking around you…'), findsNothing);
  });
}
