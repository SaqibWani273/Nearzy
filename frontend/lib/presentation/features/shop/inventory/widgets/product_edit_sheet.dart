import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/models/shop_product.dart';
import '../../../../../services/api_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../common/widgets/shimmer_loading.dart';

/// Edit stock, price and markdown without leaving the list.
///
/// Replaces pushing a full-page form. The inventory stays visible and dimmed
/// behind the sheet, so the owner keeps their place in a long list while
/// correcting one row — the context is the point.
///
/// Returns `true` when something was saved, so callers can refresh.
class ProductEditSheet extends StatefulWidget {
  const ProductEditSheet({super.key, required this.productId});

  final int productId;

  static Future<bool?> show(BuildContext context, {required int productId}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.ink.withValues(alpha: 0.45),
        builder: (_) => ProductEditSheet(productId: productId),
      );

  @override
  State<ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<ProductEditSheet> {
  late Future<ShopProduct> _load;

  final _stock = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController();
  final _floor = TextEditingController();

  bool _available = true;
  bool _markdownEnabled = false;
  bool _saving = false;
  bool _seeded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load = ApiService.fetchMyProduct(widget.productId);
  }

  @override
  void dispose() {
    _stock.dispose();
    _price.dispose();
    _discount.dispose();
    _floor.dispose();
    super.dispose();
  }

  /// Fills the controllers once. Guarded because FutureBuilder rebuilds on
  /// every setState, and re-seeding would wipe what the owner is typing.
  void _seed(ShopProduct p) {
    if (_seeded) return;
    _seeded = true;
    _stock.text = '${p.stockQuantity}';
    _price.text = (p.priceInPaise / 100).toStringAsFixed(2);
    _discount.text = p.discountPercent.toStringAsFixed(0);
    _floor.text = p.markdownFloorPercent.toStringAsFixed(0);
    _available = p.available;
    _markdownEnabled = p.markdownEnabled;
  }

  Future<void> _save() async {
    final stock = int.tryParse(_stock.text.trim());
    final rupees = double.tryParse(_price.text.trim());
    final discount = double.tryParse(_discount.text.trim());
    final floor = double.tryParse(_floor.text.trim());

    if (stock == null || stock < 0) {
      setState(() => _error = 'Stock must be a whole number, 0 or more.');
      return;
    }
    if (rupees == null || rupees <= 0) {
      setState(() => _error = 'Price must be greater than zero.');
      return;
    }
    if (discount == null || discount < 0 || discount > 100) {
      setState(() => _error = 'Discount must be between 0 and 100.');
      return;
    }
    if (_markdownEnabled && (floor == null || floor <= discount)) {
      setState(() => _error =
          'Markdown floor must be deeper than the standing discount.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.updateProduct(
        widget.productId,
        stockQuantity: stock,
        // Paise is the wire unit; the field is in rupees because that is what
        // the owner thinks in.
        priceInPaise: (rupees * 100).round(),
        discountPercent: discount,
        available: _available,
        markdownEnabled: _markdownEnabled,
        markdownFloorPercent: floor ?? 0,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('CustomException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            const _DragHandle(),
            Expanded(
              child: FutureBuilder<ShopProduct>(
                future: _load,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _SheetSkeleton(controller: controller);
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _SheetError(controller: controller);
                  }
                  final product = snapshot.data!;
                  _seed(product);
                  return _form(context, product, controller);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    ShopProduct product,
    ScrollController controller,
  ) {
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        // Clears the keyboard when a field is focused.
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      children: [
        Text(product.name, style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text(
          product.sku.isEmpty ? 'No SKU' : product.sku,
          style: AppTextStyles.caption,
        ),
        if (product.isAutoUnpublished) ...[
          const SizedBox(height: AppSpacing.md),
          const _Notice(
            icon: Icons.visibility_off_rounded,
            text: 'Hidden automatically because it sold out. '
                'Adding stock brings it back.',
            tone: AppColors.warning,
            surface: AppColors.warningSurface,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),

        _Field(
          label: 'Stock',
          controller: _stock,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          helper: 'Set to 0 to hide it from customers.',
        ),
        const SizedBox(height: AppSpacing.base),
        _Field(
          label: 'Price (₹)',
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.base),
        _Field(
          label: 'Discount (%)',
          controller: _discount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),

        const SizedBox(height: AppSpacing.xl),
        _Toggle(
          label: 'Visible to customers',
          // The owner's switch is authoritative: turning it off keeps the item
          // hidden even after a restock.
          subtitle: 'Turn off to hide this item regardless of stock.',
          value: _available,
          onChanged: (v) => setState(() => _available = v),
        ),
        _Toggle(
          label: 'Automatic end-of-day markdown',
          subtitle: 'Discount deepens through the evening, then resets '
              'overnight to your standing discount.',
          value: _markdownEnabled,
          onChanged: (v) => setState(() => _markdownEnabled = v),
        ),
        if (_markdownEnabled) ...[
          const SizedBox(height: AppSpacing.sm),
          _Field(
            label: 'Deepest discount (%)',
            controller: _floor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            helper: 'The markdown never goes past this.',
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.base),
          _Notice(
            icon: Icons.error_outline_rounded,
            text: _error!,
            tone: AppColors.error,
            surface: AppColors.errorSurface,
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        _PrimaryButton(
          label: _saving ? 'Saving…' : 'Save changes',
          onTap: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: AppSpacing.borderRadiusFull,
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.formatters,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.paperDim,
            contentPadding: AppSpacing.inputPadding,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helper!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.ink,
      activeTrackColor: AppColors.lime,
      title: Text(label, style: AppTextStyles.labelMedium),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    required this.tone,
    required this.surface,
  });

  final IconData icon;
  final String text;
  final Color tone;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? AppColors.ink : AppColors.line,
          foregroundColor: enabled ? AppColors.lime : AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusFull,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: enabled ? AppColors.lime : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      children: [
        ShimmerLoading.line(width: 220, height: 20),
        const SizedBox(height: AppSpacing.sm),
        ShimmerLoading.line(width: 90, height: 12),
        const SizedBox(height: AppSpacing.xl),
        ShimmerLoading.listRows(count: 3, height: 72),
      ],
    );
  }
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(
          Icons.cloud_off_rounded,
          size: 40,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text("Couldn't load that product",
              style: AppTextStyles.heading4),
        ),
      ],
    );
  }
}
