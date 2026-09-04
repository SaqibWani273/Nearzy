// "Categories don't load sometimes", diagnosed.
//
// CustomerDataLoadedState carries fields that describe what the repository is
// holding — the nearby shop list, whether categories have been fetched — but
// every emit that did not name them reset them to null. So one tap on
// add-to-cart emitted a state claiming there were no shops and no categories,
// and the Browse grid fell back to its skeleton while Explore fell back to
// "no shops nearby". Neither ever recovered, because nothing refetches.
//
// The bloc is exercised through its own public surface: `_loaded` is private,
// so these drive it with the one event that touches no network
// (LoadCustomerDataEvent) and assert what comes out the other side.

import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/data/models/shop_model/shop_model1.dart';
import 'package:nearzy/data/repositories/customer/customer_data_repository.dart';
import 'package:nearzy/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';

CustomerDataBloc buildBloc() => CustomerDataBloc(
      customerDataRepository: CustomerDataRepository(),
    );

/// The most recent loaded state, or null if the bloc is somewhere else.
CustomerDataLoadedState? loaded(CustomerDataBloc bloc) =>
    bloc.state is CustomerDataLoadedState
        ? bloc.state as CustomerDataLoadedState
        : null;

void main() {
  group('CustomerDataLoadedState stickiness', () {
    test('an unrelated event keeps the categories flag', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      // Stand in for a completed category load.
      bloc.emit(CustomerDataLoadedState(loadedCategories: true));

      bloc.add(LoadCustomerDataEvent());
      await bloc.stream.first;

      expect(loaded(bloc)?.loadedCategories, isTrue,
          reason: 'a state that forgets this drops Browse to its skeleton');
    });

    test('an unrelated event keeps the shop list', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final shops = <ShopModel1>[];
      bloc.emit(CustomerDataLoadedState(shops: shops));

      bloc.add(LoadCustomerDataEvent());
      await bloc.stream.first;

      expect(loaded(bloc)?.shops, same(shops),
          reason: 'a state that forgets this shows "no shops nearby"');
    });

    test('a transient flag is not carried forward', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      // isChangingLocation describes an event in flight, not held data: it
      // has to clear, or the location chip spins forever.
      bloc.emit(CustomerDataLoadedState(isChangingLocation: true));

      bloc.add(LoadCustomerDataEvent());
      await bloc.stream.first;

      expect(loaded(bloc)?.isChangingLocation, isNull);
    });
  });

  group('CategoriesStatus', () {
    test('starts idle, so a grid can tell "not asked" from "empty"', () {
      final repository = CustomerDataRepository();
      expect(repository.categoriesStatus, CategoriesStatus.idle);
      expect(repository.categories, isNull);
    });
  });
}
