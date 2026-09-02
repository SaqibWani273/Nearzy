import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/shop_model/shop_model1.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/nearzy_shop_card.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../dashboard/view_model/customer_data_bloc.dart';
import '../location/location_picker_screen.dart';
import '../location/nearby_shops_map_screen.dart';
import 'shop_details_screen.dart';

/// Explore: shops around the customer's chosen location.
///
/// The location is the screen's primary control, not a detail — it sits at
/// the top, is one tap from the map picker, and drives both the radius chips
/// and the map view.
class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen>
    with AutomaticKeepAliveClientMixin {
  static const List<double> _radiusOptions = [2, 5, 15, 30, 100];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<CustomerDataBloc>().add(CustomerDataFetchNearbyShopsEvent());
  }

  CustomerDataRepository get _repo => context.read<CustomerDataRepository>();

  Future<void> _changeLocation() async {
    final picked = await context.pushModal<LocationInfo>(
      () => LocationPickerScreen(initial: _repo.currentSelectedLocation),
    );
    if (picked == null || !mounted) return;
    context.read<CustomerDataBloc>().add(
          SetCustomerLocationEvent(location: picked),
        );
  }

  void _changeRadius(double km) {
    if (_repo.radiusKm == km) return;
    HapticFeedback.selectionClick();
    context.read<CustomerDataBloc>().add(ChangeSearchRadiusEvent(radiusKm: km));
  }

  void _openMap(List<ShopModel1> shops) {
    context.pushScreen(
      () => NearbyShopsMapScreen(
        shops: shops,
        origin: _repo.currentSelectedLocation,
        radiusKm: _repo.radiusKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        final loaded = state is CustomerDataLoadedState;
        final shops = loaded ? state.shops : null;
        final busy = !loaded || state.isChangingLocation == true;

        return RefreshIndicator.adaptive(
          color: AppColors.ink,
          backgroundColor: AppColors.card,
          onRefresh: () async => context
              .read<CustomerDataBloc>()
              .add(CustomerDataFetchNearbyShopsEvent()),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    12,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shops near', style: AppTextStyles.overline)
                          .animateEntrance(),
                      const SizedBox(height: 6),
                      _LocationHeader(
                        location: _repo.currentSelectedLocation,
                        onTap: _changeLocation,
                      ).animateEntrance(index: 1),
                      const SizedBox(height: 16),
                      _RadiusRow(
                        options: _radiusOptions,
                        selected: _repo.radiusKm,
                        onSelect: _changeRadius,
                        onOpenMap:
                            shops == null || shops.isEmpty ? null : () => _openMap(shops),
                      ).animateEntrance(index: 2),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Skeleton and content cross-fade rather than cutting.
              if (busy)
                SliverToBoxAdapter(child: ShimmerLoading.shopGrid(count: 4))
              else if (shops == null || shops.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyShopsState(
                    radiusKm: _repo.radiusKm,
                    onWiden: _repo.radiusKm >= _radiusOptions.last
                        ? null
                        : () => _changeRadius(
                              _radiusOptions.firstWhere(
                                (r) => r > _repo.radiusKm,
                                orElse: () => _radiusOptions.last,
                              ),
                            ),
                    onChangeLocation: _changeLocation,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${shops.length} shop${shops.length == 1 ? '' : 's'} found',
                          style: AppTextStyles.labelMedium,
                        ),
                        Text('Nearest first', style: AppTextStyles.micro),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 244,
                      crossAxisSpacing: AppSpacing.gridGap,
                      mainAxisSpacing: AppSpacing.gridGap,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: shops.length,
                      (context, index) {
                        final shop = shops[index];
                        return NearzyShopCard(
                          name: shop.displayName,
                          imageUrl: shop.shopPicUrl,
                          address: shop.address.isNotEmpty
                              ? shop.address
                              : shop.locationInfo.shortAddress,
                          categories: shop.categories,
                          isVerified: shop.isVerified ?? false,
                          distanceLabel: shop.distanceLabel,
                          heroTag: 'shop-${shop.id ?? index}',
                          onTap: () => context.pushScreen(
                            () => ShopDetailsScreen(shop: shop),
                          ),
                        ).animateEntrance(index: index);
                      },
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.bottomNavInset),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The tappable location row — the screen's main control.
class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.location, required this.onTap});

  final LocationInfo? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              location?.shortAddress ?? 'Everywhere',
              style: AppTextStyles.heading1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: const Icon(Icons.tune_rounded,
                size: 19, color: AppColors.lime),
          ),
        ],
      ),
    );
  }
}

/// Radius chips plus the map toggle.
class _RadiusRow extends StatelessWidget {
  const _RadiusRow({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onOpenMap,
  });

  final List<double> options;
  final double selected;
  final ValueChanged<double> onSelect;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _RadiusChip(
                km: options[i],
                selected: options[i] == selected,
                onTap: () => onSelect(options[i]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MapToggle(onTap: onOpenMap),
      ],
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.km,
    required this.selected,
    required this.onTap,
  });

  final double km;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: Motion.duration(context, Motion.quick),
        curve: Motion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: Motion.duration(context, Motion.quick),
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.lime : AppColors.textSecondary,
          ),
          child: Text('${km.round()} km'),
        ),
      ),
    );
  }
}

class _MapToggle extends StatelessWidget {
  const _MapToggle({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: 'View shops on map',
      child: PressableScale(
        onTap: onTap,
        scale: 0.94,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: Motion.duration(context, Motion.quick),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: AppColors.limeGradient,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_rounded, size: 15, color: AppColors.ink),
                const SizedBox(width: 5),
                Text(
                  'Map',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyShopsState extends StatelessWidget {
  const _EmptyShopsState({
    required this.radiusKm,
    required this.onWiden,
    required this.onChangeLocation,
  });

  final double radiusKm;
  final VoidCallback? onWiden;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: const Icon(Icons.storefront_outlined,
                size: 34, color: AppColors.sage),
          ).animateEntrance(),
          const SizedBox(height: 20),
          Text('No shops within ${radiusKm.round()} km',
                  style: AppTextStyles.heading3)
              .animateEntrance(index: 1),
          const SizedBox(height: 6),
          Text(
            'Try a wider radius, or browse a different area.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ).animateEntrance(index: 2),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onWiden != null) ...[
                OutlinedButton(
                  onPressed: onWiden,
                  child: const Text('Widen search'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                onPressed: onChangeLocation,
                child: const Text('Change area'),
              ),
            ],
          ).animateEntrance(index: 3),
        ],
      ),
    );
  }
}
