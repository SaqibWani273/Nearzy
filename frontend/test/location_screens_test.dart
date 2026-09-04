// Build tests for the location and map surfaces.
//
// These screens are hard to reach by tapping through a simulator (they sit
// two navigations deep behind a network fetch), and they are the ones most
// likely to break on a layout constraint — nested viewports, a PageView over
// a map, markers positioned by alignment. Pumping them directly catches that
// without needing a backend or a tile server.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/data/models/basic_user_model/basic_user_model.dart';
import 'package:nearzy/data/models/shop_model/shop_api_parser.dart';
import 'package:nearzy/data/models/shop_model/shop_model1.dart';
import 'package:nearzy/presentation/common/widgets/map/nearzy_map.dart';
import 'package:nearzy/presentation/common/widgets/nearzy_logo.dart';
import 'package:nearzy/presentation/common/widgets/nearzy_shop_card.dart';
import 'package:nearzy/presentation/features/customer/location/location_picker_screen.dart';
import 'package:nearzy/presentation/features/customer/location/nearby_shops_map_screen.dart';
import 'package:nearzy/theme/theme.dart';

ShopModel1 _shop({
  int id = 1,
  String name = 'Kashmir Shawl House',
  double lat = 34.075,
  double lng = 74.787,
}) {
  return ShopModel1(
    id: id,
    user: BasicUserModel(username: 'kashmir_shawls', password: '', email: ''),
    description: 'Handwoven pashmina.',
    categories: const ['Shawls & Wraps'],
    ownerPicUrl: '',
    locationInfo: LocationInfo(
      completeAddress: 'Lal Chowk, Srinagar',
      shortAddress: 'Lal Chowk',
      latitude: lat,
      longtitude: lng,
    ),
    ownerName: 'Owner',
    shopPicUrl: '',
    pancardPicUrl: '',
    ownerIdPicUrl: '',
    businessLicense: '',
    address: 'Shop 12, Lal Chowk',
    phoneNumber: '9191000001',
    name: name,
    distanceKm: 1.2,
    isVerified: true,
  );
}

Widget _host(Widget child) => MaterialApp(theme: nearzyTheme, home: child);

/// Advances past the staggered entrances without waiting for the screen to go
/// quiet — the map's user-location marker pulses forever by design, so
/// `pumpAndSettle` would time out.
Future<void> _settleAmbient(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('LocationPickerScreen builds with its search and confirm card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(LocationPickerScreen(initial: LocationInfo.defaultValue())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search area, street or landmark'), findsOneWidget);
    expect(find.text('Confirm location'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    // The draggable centre pin.
    expect(find.byType(ShopMapMarker), findsWidgets);
  });

  testWidgets('NearbyShopsMapScreen plots shops and shows their cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        NearbyShopsMapScreen(
          shops: [
            _shop(),
            _shop(id: 2, name: 'Saffron Garden', lat: 34.09, lng: 74.80),
          ],
          origin: LocationInfo.defaultValue(),
        ),
      ),
    );
    await _settleAmbient(tester);

    expect(find.text('2 shops nearby'), findsOneWidget);
    expect(find.text('Kashmir Shawl House'), findsOneWidget);
    expect(find.text('Directions'), findsWidgets);
  });

  testWidgets(
    'NearbyShopsMapScreen explains an empty map instead of blanking',
    (tester) async {
      await tester.pumpWidget(
        _host(
          NearbyShopsMapScreen(
            // A shop with no coordinates must not be plotted at (0, 0).
            shops: [_shop(lat: 0, lng: 0)],
            origin: LocationInfo.defaultValue(),
          ),
        ),
      );
      await _settleAmbient(tester);

      expect(find.text('Nothing to plot here'), findsOneWidget);
    },
  );

  testWidgets('NearzyShopCard renders name, distance and categories', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 244,
              child: NearzyShopCard(
                name: 'Kashmir Shawl House',
                imageUrl: '',
                address: 'Lal Chowk',
                categories: ['Shawls & Wraps'],
                isVerified: true,
                distanceLabel: '1.2 km',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kashmir Shawl House'), findsOneWidget);
    expect(find.text('1.2 km'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('NearzyLogo paints without a compositing error', (tester) async {
    await tester.pumpWidget(
      _host(const Scaffold(body: Center(child: NearzyLogo(size: 40)))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nearzy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('ShopApiParser', () {
    test('parses the raw ORM shape the deployed server still returns', () {
      final shop = ShopApiParser.parse(
        {
          'id': 1,
          'name': 'Kashmir Shawl House',
          'slug': 'kashmir-shawl-house',
          'shopPicUrl': 'https://example.test/a.jpg',
          'phoneNumber': '9191000001',
          'address': 'Shop 12, Lal Chowk, Srinagar',
          'description': 'Premium pashmina.',
          // Server spelling, not the client's misspelling.
          'locationInfo': {
            'latitude': 34.075,
            'longitude': 74.787,
            'city': 'Srinagar',
            'pincode': '190001',
          },
          // Category objects, not names.
          'categories': [
            {'id': 1, 'name': 'Shawls & Wraps'},
            {'id': 9, 'name': 'Pashmina Shawls'},
          ],
          'verification': {'status': 'APPROVED'},
          // No nested `user` object at all.
        },
        originLat: 34.083656,
        originLng: 74.797371,
      );

      expect(shop, isNotNull);
      expect(shop!.displayName, 'Kashmir Shawl House');
      expect(shop.locationInfo.longtitude, 74.787);
      expect(shop.categories, ['Shawls & Wraps', 'Pashmina Shawls']);
      expect(shop.isVerified, isTrue);
      // Falls back to the client-side Haversine when the server omits it.
      expect(shop.distanceKm, closeTo(1.35, 0.3));
      expect(shop.distanceLabel, '1.4 km');
    });

    test('parses the DTO shape and prefers the server distance', () {
      final shop = ShopApiParser.parse({
        'id': 2,
        'name': 'Saffron Garden',
        'user': {'id': 3, 'username': 'saffron_garden', 'email': 'a@b.test'},
        'locationInfo': {
          'latitude': 34.09,
          'longtitude': 74.80,
          'shortAddress': 'Pampore',
        },
        'categories': ['Spices'],
        'isVerified': false,
        'distanceKm': 4.2,
      });

      expect(shop!.distanceKm, 4.2);
      expect(shop.distanceLabel, '4.2 km');
      expect(shop.user.username, 'saffron_garden');
      // The hash must never be populated from a response.
      expect(shop.user.password, isEmpty);
    });

    test('formats sub-kilometre distances in metres', () {
      final shop = ShopApiParser.parse({
        'name': 'Corner Store',
        'locationInfo': {'latitude': 34.0837, 'longitude': 74.7975},
        'distanceKm': 0.45,
      });
      expect(shop!.distanceLabel, '450 m');
    });

    test('drops an unparseable row instead of failing the whole page', () {
      final shops = ShopApiParser.parseList([
        {
          'name': 'Good Shop',
          'locationInfo': {'latitude': 34.0, 'longitude': 74.0},
        },
        'not a map',
        42,
      ]);
      expect(shops, hasLength(1));
      expect(shops.single.displayName, 'Good Shop');
    });
  });
}
