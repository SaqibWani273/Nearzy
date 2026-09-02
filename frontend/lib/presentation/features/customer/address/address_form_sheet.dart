import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/address.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';

/// Add or edit one delivery address.
///
/// Required fields mirror the backend's non-null columns, so the form catches
/// what the API would otherwise reject with a 400.
///
/// Returns the saved [Address], or null if dismissed.
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({super.key, this.existing, this.makeDefault});

  /// Null for a new address; otherwise the row being edited.
  final Address? existing;

  /// Force the saved address to become the default. Left null to preserve
  /// whatever the row already had.
  final bool? makeDefault;

  static Future<Address?> show(
    BuildContext context, {
    Address? existing,
    bool? makeDefault,
  }) =>
      showModalBottomSheet<Address>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddressFormSheet(
          existing: existing,
          makeDefault: makeDefault,
        ),
      );

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postalCode;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _line1 = TextEditingController(text: e?.line1 ?? '');
    _line2 = TextEditingController(text: e?.line2 ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _state = TextEditingController(text: e?.state ?? '');
    _postalCode = TextEditingController(text: e?.postalCode ?? '');
  }

  @override
  void dispose() {
    for (final c in [_label, _line1, _line2, _city, _state, _postalCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    // Country is not asked for: every shop on Nearzy is domestic, so a
    // country picker would be a required field with one answer.
    final draft = Address(
      id: widget.existing?.id,
      label: _label.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postalCode.text.trim(),
      country: widget.existing?.country.isNotEmpty == true
          ? widget.existing!.country
          : 'India',
      latitude: widget.existing?.latitude,
      longitude: widget.existing?.longitude,
      isDefault: widget.existing?.isDefault ?? false,
    );

    try {
      final saved = widget.existing == null
          ? await ApiService.createAddress(draft, asDefault: widget.makeDefault)
          : await ApiService.updateAddress(draft, asDefault: widget.makeDefault);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _messageOf(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Padding(
      // Lifts the sheet clear of the keyboard, which otherwise covers the
      // save button on every field below the fold.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.gutter,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(editing ? 'Edit address' : 'New address',
                      style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.lg),
                  _Field(
                    controller: _label,
                    label: 'Name it (optional)',
                    hint: 'Home, Office, Mum’s place',
                    textCapitalization: TextCapitalization.words,
                  ),
                  _Field(
                    controller: _line1,
                    label: 'Flat, house or building',
                    required: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  _Field(
                    controller: _line2,
                    label: 'Area or landmark (optional)',
                    textCapitalization: TextCapitalization.words,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _city,
                          label: 'City',
                          required: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _Field(
                          controller: _postalCode,
                          label: 'PIN code',
                          required: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return 'Required';
                            if (!RegExp(r'^\d{6}$').hasMatch(text)) {
                              return '6 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    controller: _state,
                    label: 'State',
                    required: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.lime,
                        disabledBackgroundColor: AppColors.inkMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.lime,
                              ),
                            )
                          : Text(
                              editing ? 'Save changes' : 'Save address',
                              style: AppTextStyles.buttonText
                                  .copyWith(color: AppColors.lime),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.keyboardType,
    this.maxLength,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
        ),
        validator: validator ??
            (required
                ? (value) =>
                    (value ?? '').trim().isEmpty ? 'Required' : null
                : null),
      ),
    );
  }
}

String _messageOf(Object error) {
  final match = RegExp(r'message:\s*(.+?)[,)]').firstMatch(error.toString());
  return match?.group(1) ?? 'Could not save that address.';
}
