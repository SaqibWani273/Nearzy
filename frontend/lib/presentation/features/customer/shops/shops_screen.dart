import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/common/widgets/shimmer_loading.dart';
import 'package:mca_project/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import 'package:mca_project/presentation/features/customer/shops/shop_details_screen.dart';
import 'package:mca_project/presentation/common/widgets/nearzy_shop_card.dart';
import 'package:mca_project/theme/app_colors.dart';
import 'package:mca_project/theme/app_text_styles.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  @override
  void initState() {
    context.read<CustomerDataBloc>().add(CustomerDataFetchNearbyShopsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;

    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        if (state is CustomerDataLoadedState && state.shops != null) {
          if (state.shops!.isEmpty) {
            return _EmptyShopsState();
          }
          return CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore Shops', style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text(
                        '${state.shops!.length} shops near you',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              // ── Shop Grid ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shop = state.shops![index];
                      return NearzyShopCard(
                        name: shop.user.username,
                        imageUrl: shop.shopPicUrl,
                        address: shop.address,
                        categories: shop.categories,
                        isVerified: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ShopDetailsScreen(shop: shop),
                          ),
                        ),
                      );
                    },
                    childCount: state.shops!.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: deviceHeight * 0.28,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        }
        return ShimmerLoading.shopGrid(count: 4);
      },
    );
  }
}

class _EmptyShopsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 40,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text('No Shops Nearby', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text(
            'Try changing your location to explore more',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
