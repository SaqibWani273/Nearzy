// The side menu used to offer rows that went somewhere else, or nowhere.
//
// "Your Orders" opened the profile tab and stopped; "Shop" opened Explore;
// and signed out, the three account-only rows led to endpoints that answer
// 401. Every row in the list now has a destination, and a row only appears
// when that destination works.

import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/constants/drawer_data.dart';

void main() {
  group('drawerItemsFor', () {
    test('every row is reachable and named once', () {
      for (final signedIn in const [true, false]) {
        final items = drawerItemsFor(signedIn: signedIn);
        final values = items.map((i) => i.enumValue).toList();

        expect(values.toSet().length, values.length,
            reason: 'a duplicated row would highlight two at once');
        expect(items.every((i) => i.title.trim().isNotEmpty), isTrue);
      }
    });

    test('signed out, the account-only rows are left out', () {
      final values =
          drawerItemsFor(signedIn: false).map((i) => i.enumValue).toSet();

      // All three call authenticated endpoints.
      expect(values, isNot(contains(DrawerItemsEnum.yourOrders)));
      expect(values, isNot(contains(DrawerItemsEnum.addresses)));
      expect(values, isNot(contains(DrawerItemsEnum.profile)));

      // ...and a way in is offered in their place.
      expect(values, contains(DrawerItemsEnum.signIn));
    });

    test('signed in, they are present and sign-in is not', () {
      final values =
          drawerItemsFor(signedIn: true).map((i) => i.enumValue).toSet();

      expect(values, contains(DrawerItemsEnum.yourOrders));
      expect(values, contains(DrawerItemsEnum.addresses));
      expect(values, contains(DrawerItemsEnum.profile));
      expect(values, isNot(contains(DrawerItemsEnum.signIn)));
    });

    test('the rows anyone can use are always offered', () {
      for (final signedIn in const [true, false]) {
        final values =
            drawerItemsFor(signedIn: signedIn).map((i) => i.enumValue).toSet();
        for (final always in const [
          DrawerItemsEnum.home,
          DrawerItemsEnum.exploreShops,
          DrawerItemsEnum.categories,
          DrawerItemsEnum.specialOffers,
          DrawerItemsEnum.savedItems,
          DrawerItemsEnum.cart,
          DrawerItemsEnum.registerShop,
          DrawerItemsEnum.helpAndSupport,
        ]) {
          expect(values, contains(always), reason: 'signedIn: $signedIn');
        }
      }
    });

    test('no row is named after a destination it does not have', () {
      // Regression guard for the two mislabelled rows. "Shop" pointed at the
      // Explore tab, so the label is now "Explore shops"; the shop sign-up
      // row is "Sell on Nearzy".
      final titles = drawerItemsFor(signedIn: true)
          .map((i) => i.title.toLowerCase())
          .toList();
      expect(titles, isNot(contains('shop')));
      expect(titles, contains('explore shops'));
      expect(titles, contains('your orders'));
    });
  });
}
