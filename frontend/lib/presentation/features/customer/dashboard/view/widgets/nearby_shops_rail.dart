import 'package:flutter/material.dart';

import '../../../../../../data/models/shop_model/shop_model1.dart';
import '../../../../../../theme/app_spacing.dart';
import '../../../../../common/animations/entrance.dart';
import '../../../../../common/animations/nearzy_page_route.dart';
import '../../../../../common/widgets/nearzy_shop_card.dart';
import '../../../shops/shop_details_screen.dart';

/// Horizontal rail of the closest shops, nearest first.
///
/// Cards carry no hero tag: the Explore grid owns `shop-<id>` and both
/// screens are alive at once inside the shell's PageView, so claiming the
/// same tag here would be a duplicate-hero crash rather than a nicer
/// transition.
class NearbyShopsRail extends StatelessWidget {
  const NearbyShopsRail({super.key, required this.shops, this.maxItems = 8});

  final List<ShopModel1> shops;

  /// The rail is a taster, not the whole list — "See all" is the way to the
  /// rest of them.
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final visible = shops.take(maxItems).toList();

    return SizedBox(
      height: 244,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.gridGap),
        itemBuilder: (context, index) {
          final shop = visible[index];
          return SizedBox(
            width: 228,
            child: NearzyShopCard(
              name: shop.displayName,
              imageUrl: shop.shopPicUrl,
              address: shop.address.isNotEmpty
                  ? shop.address
                  : shop.locationInfo.shortAddress,
              categories: shop.categories,
              isVerified: shop.isVerified ?? false,
              distanceLabel: shop.distanceLabel,
              onTap: () =>
                  context.pushScreen(() => ShopDetailsScreen(shop: shop)),
            ),
          ).animateEntrance(index: index, horizontal: true, offset: 24);
        },
      ),
    );
  }
}
