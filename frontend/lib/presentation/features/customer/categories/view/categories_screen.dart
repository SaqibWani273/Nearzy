import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/animations/entrance.dart';
import '../../../../common/animations/nearzy_page_route.dart';
import '../../../../common/animations/pressable_scale.dart';
import '../../../../common/widgets/nearzy_network_image.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../../dashboard/view_model/customer_data_bloc.dart';
import 'category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<CustomerDataBloc>().add(CustomerDataFetchCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        final categories = context.read<CustomerDataRepository>().categories;
        final loaded =
            state is CustomerDataLoadedState && state.loadedCategories == true;

        if (!loaded) {
          return const Padding(
            padding: EdgeInsets.only(top: 90),
            child: _CategoriesSkeleton(),
          );
        }

        if (categories == null || categories.isEmpty) {
          return const _EmptyCategoriesState();
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  16,
                  AppSpacing.gutter,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Browse', style: AppTextStyles.heading1)
                        .animateEntrance(),
                    const SizedBox(height: 4),
                    Text(
                      '${categories.length} categories from local shops',
                      style: AppTextStyles.bodySmall,
                    ).animateEntrance(index: 1),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 150,
                  mainAxisSpacing: AppSpacing.gridGap,
                  crossAxisSpacing: AppSpacing.gridGap,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: categories.length,
                  (context, index) {
                    final category = categories[index];
                    return _CategoryCard(
                      name: category.name,
                      imageUrl: category.image,
                      onTap: () => context.pushScreen(
                        () => CategoryScreen(category: category),
                      ),
                    ).animateEntrance(index: index);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavInset),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.imageUrl,
    this.onTap,
  });

  final String name;
  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppSpacing.shadowSoft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NearzyNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              fallbackIcon: Icons.category_outlined,
              semanticLabel: name,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.imageScrim),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                name,
                style: AppTextStyles.heading4.copyWith(color: AppColors.paper),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) => ShimmerLoading.listRows(
        count: 4,
        height: 150,
      );
}

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: const Icon(Icons.category_outlined,
                  size: 34, color: AppColors.sage),
            ).animateEntrance(),
            const SizedBox(height: 20),
            Text('No categories yet', style: AppTextStyles.heading3)
                .animateEntrance(index: 1),
            const SizedBox(height: 6),
            Text(
              'Categories appear once local shops start listing.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ).animateEntrance(index: 2),
          ],
        ),
      ),
    );
  }
}
