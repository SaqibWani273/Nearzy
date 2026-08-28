import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mca_project/presentation/features/customer/dashboard/view_model/customer_data_bloc.dart';
import '../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../common/widgets/shimmer_loading.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import 'category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    context.read<CustomerDataBloc>().add(CustomerDataFetchCategoriesEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDataBloc, CustomerDataState>(
      builder: (context, state) {
        final categories = context.read<CustomerDataRepository>().categories;
        if (state is CustomerDataLoadedState &&
            state.loadedCategories == true) {
          if (categories == null || categories.isEmpty) {
            return _EmptyCategoriesState();
          }
          return CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Browse Categories',
                          style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text(
                        '${categories.length} categories available',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              // ── Grid ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final e = categories[index];
                      return _CategoryCard(
                        name: e.name,
                        imageUrl: e.image,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(category: e),
                          ),
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                ),
              ),
            ],
          );
        }
        return ShimmerLoading.categoryGrid(count: 6);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.name,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppSpacing.shadowCard,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primarySurface,
                child: const Icon(
                  Icons.category_outlined,
                  size: 40,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Text(
                  name,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: Colors.white, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
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
              Icons.category_outlined,
              size: 40,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text('No Categories Yet', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text(
            'Categories will appear here once added',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
