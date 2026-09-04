// The admin verification gesture.
//
// Worth testing rather than eyeballing: a swipe is the only way to reach an
// irreversible decision about a real business, and the direction-to-outcome
// mapping is exactly the kind of thing that silently inverts during a refactor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/data/models/shop_verification.dart';
import 'package:nearzy/presentation/features/admin/verification/widgets/verification_card_stack.dart';

ShopVerification _application(int shopId, {String owner = 'Test Owner'}) =>
    ShopVerification.fromJson({
      'id': shopId,
      'shopId': shopId,
      'ownerName': owner,
      'status': 'PENDING',
      'submittedAt': DateTime.now().toIso8601String(),
      'documents': [
        {'label': 'PAN card', 'url': 'https://example.test/pan.jpg'},
        {'label': 'Owner ID', 'url': 'https://example.test/id.jpg'},
      ],
    });

/// Advances past the throw animation.
///
/// `pumpAndSettle` cannot be used here: the card's images render through
/// `NearzyNetworkImage`, whose shimmer placeholder loops forever in a test
/// environment where no image ever resolves, so the tree never goes quiet.
/// The throw itself runs for `Motion.base` (340ms) and then completes a
/// Future, which needs one more pump to flush.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

/// Pumps the stack and records what it decides.
Future<List<(int, SwipeDecision)>> _mount(
  WidgetTester tester,
  List<ShopVerification> items, {
  GlobalKey<VerificationCardStackState>? key,
}) async {
  final decisions = <(int, SwipeDecision)>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: VerificationCardStack(
            key: key,
            items: items,
            onDecide: (item, decision) =>
                decisions.add((item.shopId, decision)),
          ),
        ),
      ),
    ),
  );
  return decisions;
}

void main() {
  group('VerificationCardStack', () {
    testWidgets('a swipe right approves the top application', (tester) async {
      final decisions = await _mount(tester, [
        _application(1),
        _application(2),
      ]);

      await tester.drag(
        find.byType(VerificationCardStack),
        const Offset(320, 0),
      );
      await _settle(tester);

      expect(decisions, [(1, SwipeDecision.approve)]);
    });

    testWidgets('a swipe left rejects the top application', (tester) async {
      final decisions = await _mount(tester, [
        _application(1),
        _application(2),
      ]);

      await tester.drag(
        find.byType(VerificationCardStack),
        const Offset(-320, 0),
      );
      await _settle(tester);

      expect(decisions, [(1, SwipeDecision.reject)]);
    });

    testWidgets('a short drag springs back and decides nothing', (
      tester,
    ) async {
      final decisions = await _mount(tester, [_application(1)]);

      // Well under the commit threshold: an accidental brush must not reject
      // a real business.
      await tester.drag(
        find.byType(VerificationCardStack),
        const Offset(30, 0),
      );
      await _settle(tester);

      expect(decisions, isEmpty);
    });

    testWidgets('a fast flick commits even when the drag is short', (
      tester,
    ) async {
      final decisions = await _mount(tester, [_application(1)]);

      await tester.fling(
        find.byType(VerificationCardStack),
        const Offset(60, 0),
        1200,
      );
      await _settle(tester);

      expect(decisions, [(1, SwipeDecision.approve)]);
    });

    testWidgets('the buttons produce the same outcome as a swipe', (
      tester,
    ) async {
      final key = GlobalKey<VerificationCardStackState>();
      final decisions = await _mount(tester, [_application(1)], key: key);

      // A swipe is unreachable by keyboard or switch control, so the explicit
      // controls must drive the identical path.
      key.currentState!.swipe(SwipeDecision.reject);
      await _settle(tester);

      expect(decisions, [(1, SwipeDecision.reject)]);
    });

    testWidgets('an empty queue renders nothing rather than throwing', (
      tester,
    ) async {
      final decisions = await _mount(tester, []);
      await _settle(tester);

      expect(decisions, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
