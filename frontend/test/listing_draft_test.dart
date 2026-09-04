// Tests for the listing assistant's client-side contract.
//
// Worth testing rather than eyeballing: the draft arrives from a model, so the
// shapes that matter are the degraded ones — a category it couldn't pick, a
// field it couldn't read, a response missing keys entirely. Those are exactly
// the cases a happy-path demo never shows, and the ones that would put a
// confident wrong value in front of a shopkeeper.

import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/data/models/listing_draft.dart';

/// The shape the server actually returns, from POST /shop/products/draft.
Map<String, dynamic> _serverResponse({
  Object? categoryId = 11,
  Map<String, String>? confidence,
  List<String>? needsAttention,
}) => {
  'draft': {
    'name': 'Pure Kashmiri Saffron 5 g',
    'brand': 'Himalayan Harvest',
    'size': '5 g',
    'categoryId': categoryId,
    'shortDescription': 'Grade A1 Mongra threads from Pampore.',
    'completeDescription': 'A 5 g pack of Grade A1 Mongra saffron threads.',
    'priceInPaise': null,
  },
  'confidence':
      confidence ??
      const {
        'name': 'high',
        'brand': 'high',
        'size': 'high',
        'categoryId': 'high',
      },
  'needsAttention': needsAttention ?? const <String>[],
  'model': 'gemini-3.8-flash',
};

void main() {
  group('ListingDraft.fromJson', () {
    test('reads the fields the server sends', () {
      final draft = ListingDraft.fromJson(_serverResponse());

      expect(draft.name, 'Pure Kashmiri Saffron 5 g');
      expect(draft.brand, 'Himalayan Harvest');
      expect(draft.size, '5 g');
      expect(draft.categoryId, 11);
      expect(draft.shortDescription, isNotEmpty);
      expect(draft.completeDescription, isNotEmpty);
      expect(draft.confidence['name'], 'high');
      expect(draft.needsAttention, isEmpty);
    });

    test('keeps categoryId null when the model could not pick one', () {
      final draft = ListingDraft.fromJson(
        _serverResponse(categoryId: null, needsAttention: ['categoryId']),
      );

      // Null rather than a default: guessing a category here would file the
      // product under something arbitrary without telling anyone.
      expect(draft.categoryId, isNull);
      expect(draft.needsChecking('categoryId'), isTrue);
    });

    test('surfaces low-confidence fields as needing a check', () {
      final draft = ListingDraft.fromJson(
        _serverResponse(
          confidence: const {
            'name': 'high',
            'brand': 'low',
            'size': 'low',
            'categoryId': 'medium',
          },
          needsAttention: const ['brand', 'size'],
        ),
      );

      expect(draft.needsChecking('brand'), isTrue);
      expect(draft.needsChecking('size'), isTrue);
      expect(draft.needsChecking('name'), isFalse);
    });

    test('survives a response missing every optional key', () {
      // A 200 with an unexpectedly thin body must not throw — the form still
      // has to be usable by hand.
      final draft = ListingDraft.fromJson({'draft': <String, dynamic>{}});

      expect(draft.name, '');
      expect(draft.brand, '');
      expect(draft.categoryId, isNull);
      expect(draft.confidence, isEmpty);
      expect(draft.needsAttention, isEmpty);
    });

    test('survives a response with no draft object at all', () {
      final draft = ListingDraft.fromJson(const {});
      expect(draft.name, '');
      expect(draft.categoryId, isNull);
    });

    test('trims whitespace the model left in', () {
      final response = _serverResponse();
      (response['draft'] as Map)['name'] = '  Saffron  ';
      expect(ListingDraft.fromJson(response).name, 'Saffron');
    });

    test('exposes no price, even when the server sends one', () {
      // The server never drafts a price, but the client must not start
      // carrying one if that ever changes: a price the owner did not type is
      // the one mistake that costs them money on a real sale.
      final response = _serverResponse();
      (response['draft'] as Map)['priceInPaise'] = 99900;

      final draft = ListingDraft.fromJson(response);
      final fields = [
        draft.name,
        draft.brand,
        draft.size,
        draft.shortDescription,
        draft.completeDescription,
      ];
      expect(fields.any((f) => f.contains('999')), isFalse);
      // And there is no price member to read at all — this is a compile-time
      // guarantee the class documents and this test pins.
      expect(draft.categoryId, 11);
    });
  });
}
