import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/shop_product.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/nearzy_page_route.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../../../common/widgets/shimmer_loading.dart';
import '../product_upload/view/upload_product_screen.dart';
import 'scan/bulk_scan_screen.dart';
import 'widgets/product_edit_sheet.dart';

/// The shop's own stock list.
///
/// Rewritten onto the design system — it previously rendered raw Material
/// cards with hardcoded blue, dollar-sign prices and unguarded
/// `Image.network`, which made the operator side look like a different app
/// from the one customers use.
///
/// Editing happens in a sheet over this list rather than on a pushed page, so
/// the owner keeps their place while correcting one row.
class ShopInventoryScreen extends StatefulWidget {
  const ShopInventoryScreen({super.key});

  @override
  State<ShopInventoryScreen> createState() => _ShopInventoryScreenState();
}

class _ShopInventoryScreenState extends State<ShopInventoryScreen> {
  final _search = TextEditingController();

  late Future<List<ShopProduct>> _products;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _products = ApiService.fetchMyShopProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// The server matches on name and SKU, but only from two characters up, so
  /// a one-letter query is treated as no filter rather than as a request that
  /// returns everything.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _products = ApiService.fetchMyShopProducts(query: value);
      });
    });
  }

  Future<void> _refresh() async {
    final next = ApiService.fetchMyShopProducts(query: _query);
    setState(() => _products = next);
    await next.catchError((_) => <ShopProduct>[]);
  }

  Future<void> _edit(ShopProduct product) async {
    final changed = await ProductEditSheet.show(context, productId: product.id);
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.ink,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.base,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inventory', style: AppTextStyles.heading1),
                      const SizedBox(height: AppSpacing.base),
                      _SearchField(
                        controller: _search,
                        onChanged: _onQueryChanged,
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<ShopProduct>>(
                future: _products,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        child: ShimmerLoading.listRows(count: 5, height: 104),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: _InventoryMessage(
                        icon: Icons.cloud_off_rounded,
                        title: "Couldn't load your inventory",
                        body: 'Check your connection and pull to retry.',
                      ),
                    );
                  }

                  final products = snapshot.data ?? const <ShopProduct>[];
                  if (products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _InventoryMessage(
                        icon: Icons.inventory_2_outlined,
                        title: _query.trim().length >= 2
                            ? 'No matches'
                            : 'Nothing listed yet',
                        body: _query.trim().length >= 2
                            ? 'No product matches "$_query".'
                            : 'Add your first product and it will appear here.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    sliver: SliverList.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => ShopProductCard(
                        product: products[index],
                        onTap: () => _edit(products[index]),
                      ).animateEntrance(index: index),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                // Clears the nav bar *and* the two stacked FABs above it.
                child: SizedBox(height: AppSpacing.bottomNavInset + 72),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Restocking is the frequent job and adding a product the rare one,
          // so the scanner sits closer to the thumb.
          FloatingActionButton.small(
            heroTag: 'inventory-add',
            onPressed: () async {
              await context.pushScreen(() => const UploadProductScreen());
              if (mounted) await _refresh();
            },
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.ink,
            // A white FAB floating over white product cards has no edge at
            // all, so it needs a border rather than relying on elevation.
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.line),
            ),
            tooltip: 'Add a product',
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(height: AppSpacing.md),
          FloatingActionButton.extended(
            heroTag: 'inventory-scan',
            onPressed: () async {
              final applied = await context.pushScreen<bool>(
                () => const BulkScanScreen(),
              );
              if (applied == true && mounted) await _refresh();
            },
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.lime,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            // labelMedium carries textPrimary, which is invisible on ink —
            // the FAB's foregroundColor does not override a style's own colour.
            label: Text(
              'Scan stock',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.lime),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: 'Search by name or SKU',
        hintStyle: AppTextStyles.inputHint,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
      ),
    );
  }
}

/// One row of stock.
///
/// The badge matters more than it looks: an owner whose item vanished from the
/// feed needs to know whether they hid it or it sold out, because only one of
/// those is fixed by restocking.
class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ShopProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final images = product.product.images;
    final discounted = product.discountPercent > 0;
    final finalPaise =
        (product.priceInPaise * (1 - product.discountPercent / 100)).round();

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppSpacing.shadowSubtle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: NearzyNetworkImage(
                url: images.isEmpty ? '' : images.first,
                width: 76,
                height: 76,
                semanticLabel: product.name,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sku.isEmpty ? 'No SKU' : product.sku,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        '₹${(finalPaise / 100).toStringAsFixed(0)}',
                        style: AppTextStyles.priceSmall,
                      ),
                      if (discounted) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '₹${(product.priceInPaise / 100).toStringAsFixed(0)}',
                          style: AppTextStyles.priceStrikethrough,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StockBadge(product: product),
                if (product.markdownEnabled) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final (label, tone, surface) = switch (product) {
      _ when product.isOutOfStock => ('Sold out', AppColors.error, AppColors.errorSurface),
      _ when product.isOwnerHidden => ('Hidden', AppColors.textSecondary, AppColors.paperDim),
      _ when product.stockQuantity <= 3 =>
        ('${product.stockQuantity} left', AppColors.warning, AppColors.warningSurface),
      _ => ('${product.stockQuantity} in stock', AppColors.success, AppColors.successSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: tone),
      ),
    );
  }
}

class _InventoryMessage extends StatelessWidget {
  const _InventoryMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xxl,
        AppSpacing.gutter,
        AppSpacing.gutter,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Icon(icon, size: 34, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    ).animateEntrance();
  }
}
