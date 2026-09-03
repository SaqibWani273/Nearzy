import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../data/models/product.dart';
import '../../../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../../../services/api_service.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_motion.dart';
import '../../../../../../theme/app_spacing.dart';
import '../../../../../../theme/app_text_styles.dart';
import '../../../../../../utils/money.dart';
import '../../../../../common/animations/cross_fade.dart';
import '../../../../../common/animations/entrance.dart';
import '../../../../../common/animations/pressable_scale.dart';
import '../../../../../common/widgets/section_header.dart';
import '../../../../../common/widgets/shimmer_loading.dart';
import 'product_carousel.dart';

/// One price cap the customer can browse under.
class _Cap {
  const _Cap(this.label, this.paise);

  final String label;

  /// Null is "no cap" — the plain cheapest-first list.
  final int? paise;
}

/// Cheapest-first products nearby, filtered by a price ceiling the customer
/// picks.
///
/// The cap is a server-side filter, not a client-side trim, so "under ₹200"
/// really searches every shop in range rather than filtering the twelve
/// products that happened to arrive first.
class BudgetPicksSection extends StatefulWidget {
  const BudgetPicksSection({super.key, required this.areaKey});

  /// Identifies the area being browsed. When it changes the section
  /// refetches — "under ₹500 nearby" means nothing once "nearby" moves.
  final String areaKey;

  @override
  State<BudgetPicksSection> createState() => _BudgetPicksSectionState();
}

class _BudgetPicksSectionState extends State<BudgetPicksSection> {
  static const List<_Cap> _caps = [
    _Cap('Any price', null),
    _Cap('Under ₹200', 20000),
    _Cap('Under ₹500', 50000),
    _Cap('Under ₹1,000', 100000),
  ];

  static const int _pageSize = 12;

  _Cap _selected = _caps.first;
  late Future<List<Product>> _products;

  /// True once the uncapped fetch comes back empty: an area with no
  /// affordable products has nothing for this section to say, chips
  /// included, so it removes itself rather than showing four dead filters.
  bool _hidden = false;

  /// Bumped once per fetch, so that re-picking a cap counts as a new phase
  /// for [CrossFade] even when it lands on the same branch as the last one.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(BudgetPicksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaKey != widget.areaKey) {
      _selected = _caps.first;
      _hidden = false;
      _reload();
    }
  }

  void _reload() {
    _request++;
    final repository = context.read<CustomerDataRepository>();
    _products = ApiService.fetchAffordableProducts(
      repository.currentSelectedLocation,
      radiusKm: repository.radiusKm,
      maxPriceInPaise: _selected.paise,
      limit: _pageSize,
    );

    // Only the uncapped result decides whether the section exists at all.
    if (_selected.paise == null) {
      _products.then(
        (items) {
          if (mounted && items.isEmpty) setState(() => _hidden = true);
        },
        onError: (_, _) {},
      );
    }
  }

  void _select(_Cap cap) {
    if (cap.paise == _selected.paise) return;
    setState(() {
      _selected = cap;
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Under budget',
          subtitle: 'Cheapest first, from shops in range',
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            itemCount: _caps.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cap = _caps[index];
              return _CapChip(
                label: cap.label,
                isSelected: cap.paise == _selected.paise,
                onTap: () => _select(cap),
              ).animateEntrance(index: index, horizontal: true, offset: 20);
            },
          ),
        ),
        const SizedBox(height: 14),
        // Cross-faded and resized rather than cut, so switching caps reads
        // as the same rail re-filtering instead of a section reloading.
        AnimatedSize(
          duration: Motion.duration(context, Motion.quick),
          curve: Motion.easeOut,
          alignment: Alignment.topCenter,
          child: FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, snapshot) {
              final products = snapshot.data ?? const <Product>[];
              // Phased per request as well as per branch, so a re-filter
              // re-runs the rail's entrance instead of silently swapping
              // cards under the customer.
              return CrossFade(
                state: (_request, snapshot.connectionState, products.isEmpty),
                child: switch (snapshot.connectionState) {
                  ConnectionState.waiting =>
                    ShimmerLoading.productRow(count: 3),
                  _ when products.isEmpty =>
                    _NothingUnderCap(cap: _selected),
                  _ => ProductCarousel(
                      products: products,
                      heroPrefix: 'budget',
                    ),
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: PressableScale(
        onTap: onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: Motion.duration(context, Motion.quick),
          curve: Motion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : AppColors.card,
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(
              color: isSelected ? AppColors.ink : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.paper : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the area has affordable products but none under this cap —
/// which is a result, not an error, so it stays inline and small.
class _NothingUnderCap extends StatelessWidget {
  const _NothingUnderCap({required this.cap});

  final _Cap cap;

  @override
  Widget build(BuildContext context) {
    final ceiling = cap.paise;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 6,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.paperDim,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.savings_outlined, size: 20,
                color: AppColors.sage),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ceiling == null
                    ? 'Nothing to show here yet.'
                    : 'Nothing under ${Money.rupees(ceiling)} from shops in '
                        'range. Try a bigger budget.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
