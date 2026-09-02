import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/address.dart';
import '../../../../data/models/cart.dart';
import '../../../../data/repositories/customer/customer_data_repository.dart';
import '../../../../services/api_service.dart';
import '../../../../services/razorpay_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/money.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/widgets/nearzy_network_image.dart';
import '../address/address_picker_sheet.dart';
import '../cart/cart_screen.dart' show cartSubtotalPaise;

/// Confirm the bag, choose where it goes, pay.
///
/// Rebuilt off the old free-text form: the address is now a real saved row
/// whose id goes to the backend, and the fake "₹100 shipping" line is gone —
/// it was never charged, so the total on screen disagreed with the amount
/// Razorpay collected.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.cartItemDetails});

  final List<CartItemDetails> cartItemDetails;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  Address? _address;
  bool _loadingAddress = true;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _preselectAddress();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// Starts on the customer's default address so the common case needs no
  /// interaction at all.
  Future<void> _preselectAddress() async {
    try {
      final addresses = await ApiService.fetchAddresses();
      if (!mounted) return;
      setState(() {
        _address = addresses.isEmpty
            ? null
            : addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => addresses.first,
              );
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _chooseAddress() async {
    final picked = await AddressPickerSheet.show(
      context,
      selectedId: _address?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _address = picked);
  }

  int get _subtotalPaise => cartSubtotalPaise(widget.cartItemDetails);

  Future<void> _placeOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final address = _address;
    if (address?.id == null) {
      _complain('Choose where this order should be delivered.');
      return;
    }

    final repository = context.read<CustomerDataRepository>();
    final customer = repository.customer;
    if (customer == null) {
      _complain('Please sign in again to place this order.');
      return;
    }

    setState(() => _placing = true);

    final result = await RazorpayService.makePayment(
      PaymentData(
        buyerName: customer.user.username,
        email: customer.user.email,
        addressId: address!.id!,
        phoneNumber: _phone.text.trim(),
        orderItems: widget.cartItemDetails
            .map((e) => OrderItem.fromCartItemDetails(cartItemDetails: e))
            .toList(),
      ),
    );

    // The Razorpay sheet can outlive this screen.
    if (!mounted) return;
    setState(() => _placing = false);

    if (result.isSuccess) {
      repository.cartItemDetails = [];
      repository.customer?.cartItems = [];
      HapticFeedback.mediumImpact();
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _OutcomeDialog(
        success: result.isSuccess,
        orderNumber: result.orderNumber,
        message: result.message,
      ),
    );

    if (!mounted) return;
    // A placed order leaves nothing to check out, so return to the bag.
    if (result.isSuccess) Navigator.of(context).pop();
  }

  void _complain(String message) {
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
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxxl,
          ),
          children: [
            _Block(
              title: 'Deliver to',
              index: 0,
              trailing: _address == null
                  ? null
                  : TextButton(
                      onPressed: _chooseAddress,
                      child: Text('Change', style: AppTextStyles.link),
                    ),
              child: _AddressSlot(
                address: _address,
                loading: _loadingAddress,
                onChoose: _chooseAddress,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Block(
              title: 'Contact number',
              index: 1,
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: AppTextStyles.inputText,
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  counterText: '',
                  prefixText: '+91  ',
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(text)) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Block(
              title: widget.cartItemDetails.length == 1
                  ? '1 item'
                  : '${widget.cartItemDetails.length} items',
              index: 2,
              child: Column(
                children: [
                  for (var i = 0; i < widget.cartItemDetails.length; i++) ...[
                    if (i > 0) Divider(height: 22, color: AppColors.line),
                    _ItemRow(details: widget.cartItemDetails[i]),
                  ],
                  Divider(height: 24, color: AppColors.line),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Subtotal', style: AppTextStyles.bodySmall),
                      ),
                      Text(Money.exact(_subtotalPaise),
                          style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Delivery', style: AppTextStyles.bodySmall),
                      ),
                      Text('Free', style: AppTextStyles.labelMedium),
                    ],
                  ),
                  Divider(height: 24, color: AppColors.line),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Total', style: AppTextStyles.heading4),
                      ),
                      Text(Money.exact(_subtotalPaise),
                          style: AppTextStyles.priceMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The final amount is priced by Nearzy from current shop '
                    'prices when your order is created.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PayBar(
        amountPaise: _subtotalPaise,
        busy: _placing,
        enabled: _address?.id != null && !_placing,
        onPay: _placeOrder,
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.child,
    required this.index,
    this.trailing,
  });

  final String title;
  final Widget child;
  final int index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.heading4)),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: AppSpacing.shadowSoft,
          ),
          child: child,
        ),
      ],
    ).animateEntrance(index: index);
  }
}

class _AddressSlot extends StatelessWidget {
  const _AddressSlot({
    required this.address,
    required this.loading,
    required this.onChoose,
  });

  final Address? address;
  final bool loading;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.sage),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('Finding your addresses…', style: AppTextStyles.bodySmall),
        ],
      );
    }

    if (address == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No delivery address yet.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onChoose,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add an address'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.place_outlined, size: 18, color: AppColors.sage),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(address!.displayLabel, style: AppTextStyles.labelLarge),
              const SizedBox(height: 2),
              Text(address!.streetLine, style: AppTextStyles.bodySmall),
              Text(address!.regionLine, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.details});

  final CartItemDetails details;

  @override
  Widget build(BuildContext context) {
    final product = details.product;
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusSm,
          child: NearzyNetworkImage(
            url: product.images.isNotEmpty ? product.images.first : '',
            width: 44,
            height: 44,
            semanticLabel: product.name,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                '${details.quantity} × ${Money.exact(product.disCountedPrice)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Text(
          Money.exact(product.disCountedPrice * details.quantity),
          style: AppTextStyles.labelMedium,
        ),
      ],
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.amountPaise,
    required this.busy,
    required this.enabled,
    required this.onPay,
  });

  final int amountPaise;
  final bool busy;
  final bool enabled;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppSpacing.shadowElevated,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        14,
        AppSpacing.gutter,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: AppTextStyles.caption),
              Text(Money.exact(amountPaise), style: AppTextStyles.priceMedium),
            ],
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: SizedBox(
              height: 56,
              // The one lime CTA on the screen.
              child: ElevatedButton(
                onPressed: enabled ? onPay : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                  disabledBackgroundColor: AppColors.line,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: Motion.quick,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.ink),
                        )
                      : Text(
                          'Pay securely',
                          style: AppTextStyles.buttonText
                              .copyWith(color: AppColors.ink),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeDialog extends StatelessWidget {
  const _OutcomeDialog({
    required this.success,
    required this.orderNumber,
    required this.message,
  });

  final bool success;
  final String? orderNumber;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        success ? 'Order placed' : "Order didn't go through",
        style: AppTextStyles.heading3.copyWith(
          color: success ? AppColors.success : AppColors.error,
        ),
      ),
      content: Text(
        success
            ? 'Order $orderNumber is confirmed. The shop will start preparing it.'
            : message,
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        if (!success)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        if (success)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
      ],
    );
  }
}
