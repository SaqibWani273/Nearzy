import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/address.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/shimmer_loading.dart';
import 'address_form_sheet.dart';

/// Pick a delivery address, or manage the saved set.
///
/// One surface, two modes: checkout opens it to choose ([mode] pick, which
/// pops the chosen address), the profile opens it to tidy up ([mode] manage,
/// which pops nothing).
enum AddressSheetMode { pick, manage }

class AddressPickerSheet extends StatefulWidget {
  const AddressPickerSheet({
    super.key,
    this.mode = AddressSheetMode.pick,
    this.selectedId,
  });

  final AddressSheetMode mode;
  final int? selectedId;

  static Future<Address?> show(
    BuildContext context, {
    AddressSheetMode mode = AddressSheetMode.pick,
    int? selectedId,
  }) =>
      showModalBottomSheet<Address>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddressPickerSheet(mode: mode, selectedId: selectedId),
      );

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  late Future<List<Address>> _addresses;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _addresses = ApiService.fetchAddresses();
  }

  void _reload() => setState(() => _addresses = ApiService.fetchAddresses());

  Future<void> _add() async {
    final created = await AddressFormSheet.show(context);
    if (created == null || !mounted) return;
    // A freshly added address is almost always the one being delivered to.
    if (widget.mode == AddressSheetMode.pick) {
      Navigator.of(context).pop(created);
      return;
    }
    _reload();
  }

  Future<void> _edit(Address address) async {
    final saved = await AddressFormSheet.show(context, existing: address);
    if (saved == null || !mounted) return;
    _reload();
  }

  Future<void> _setDefault(Address address) async {
    final id = address.id;
    if (id == null) return;
    try {
      await ApiService.setDefaultAddress(id);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _reload();
    } catch (e) {
      _complain(_messageOf(e));
    }
  }

  Future<void> _delete(Address address) async {
    final id = address.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove address?'),
        content: Text(address.singleLine, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteAddress(id);
      if (!mounted) return;
      if (_selectedId == id) _selectedId = null;
      _reload();
    } catch (e) {
      // The backend answers 409 for an address a past order points at, and
      // that reason is worth showing rather than a generic failure.
      _complain(_messageOf(e));
    }
  }

  void _complain(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textOnInk)),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picking = widget.mode == AddressSheetMode.pick;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      picking ? 'Deliver to' : 'Your addresses',
                      style: AppTextStyles.heading2,
                    ),
                  ),
                  IconButton(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add an address',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.paper,
                      foregroundColor: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Flexible(
              child: FutureBuilder<List<Address>>(
                future: _addresses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      child: ShimmerLoading.listRows(count: 3, height: 84),
                    );
                  }
                  if (snapshot.hasError) {
                    return _Message(
                      icon: Icons.cloud_off_rounded,
                      title: "Couldn't load your addresses",
                      body: _messageOf(snapshot.error!),
                      action: 'Try again',
                      onAction: _reload,
                    );
                  }

                  final addresses = snapshot.data ?? const <Address>[];
                  if (addresses.isEmpty) {
                    return _Message(
                      icon: Icons.place_outlined,
                      title: 'No addresses saved',
                      body: 'Add where you want orders delivered.',
                      action: 'Add an address',
                      onAction: _add,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      AppSpacing.gutter,
                    ),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      final selected = picking &&
                          (_selectedId == address.id ||
                              (_selectedId == null && address.isDefault));

                      return _AddressTile(
                        address: address,
                        selected: selected,
                        showRadio: picking,
                        onTap: () {
                          if (picking) {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop(address);
                          } else {
                            _edit(address);
                          }
                        },
                        onEdit: () => _edit(address),
                        onDelete: () => _delete(address),
                        onSetDefault:
                            address.isDefault ? null : () => _setDefault(address),
                      ).animateEntrance(index: index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.showRadio,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  final Address address;
  final bool selected;
  final bool showRadio;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: AnimatedContainer(
        duration: Motion.quick,
        curve: Motion.easeOut,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: selected ? AppColors.limeSurface : AppColors.paper,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: selected ? AppColors.limeDeep : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showRadio)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md, top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? AppColors.ink : AppColors.textTertiary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.displayLabel,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sageSurface,
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Text('Default',
                              style: AppTextStyles.labelSmall),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(address.streetLine, style: AppTextStyles.bodySmall),
                  Text(address.regionLine, style: AppTextStyles.caption),
                ],
              ),
            ),
            _Overflow(
              onEdit: onEdit,
              onDelete: onDelete,
              onSetDefault: onSetDefault,
            ),
          ],
        ),
      ),
    );
  }
}

class _Overflow extends StatelessWidget {
  const _Overflow({
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded,
          size: 20, color: AppColors.textTertiary),
      tooltip: 'Address options',
      onSelected: (value) => switch (value) {
        'edit' => onEdit(),
        'default' => onSetDefault?.call(),
        'delete' => onDelete(),
        _ => null,
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit', style: AppTextStyles.bodyMedium),
        ),
        if (onSetDefault != null)
          PopupMenuItem(
            value: 'default',
            child: Text('Make default', style: AppTextStyles.bodyMedium),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Remove',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
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
            child: Icon(icon, size: 34, color: AppColors.sage),
          ).animateEntrance(),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.heading3).animateEntrance(index: 1),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.bodySmall, textAlign: TextAlign.center)
              .animateEntrance(index: 2),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: onAction,
            child: Text(action, style: AppTextStyles.link),
          ).animateEntrance(index: 3),
        ],
      ),
    );
  }
}

String _messageOf(Object error) {
  final match = RegExp(r'message:\s*(.+?)[,)]').firstMatch(error.toString());
  return match?.group(1) ?? 'Something went wrong.';
}
