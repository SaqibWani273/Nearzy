import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Pill search field that lifts on focus.
///
/// The lift is the whole affordance: a flat field on a flat background reads
/// as decoration, one that rises when you touch it reads as a control.
class NearzySearchBar extends StatefulWidget {
  const NearzySearchBar({
    super.key,
    this.hintText = 'Search products, shops & more',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.readOnly = false,
    this.controller,
    this.autofocus = false,
    this.onFocusChange,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  /// Shows a clear affordance once there's text. Without it the field has no
  /// way back to the unfiltered feed on a touch keyboard.
  final VoidCallback? onClear;

  final bool readOnly;
  final TextEditingController? controller;
  final bool autofocus;

  /// Lets a parent reveal suggestions only while the field has focus.
  final ValueChanged<bool>? onFocusChange;

  @override
  State<NearzySearchBar> createState() => _NearzySearchBarState();
}

class _NearzySearchBarState extends State<NearzySearchBar> {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
      widget.onFocusChange?.call(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    // Only dispose a controller this widget created.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        10,
        AppSpacing.gutter,
        8,
      ),
      child: AnimatedContainer(
        duration: Motion.duration(context, Motion.quick),
        curve: Motion.easeOut,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: _focused ? AppColors.ink : AppColors.line,
            width: _focused ? 1.6 : 1,
          ),
          boxShadow: _focused ? AppSpacing.shadowSoft : AppSpacing.shadowSubtle,
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            AnimatedScale(
              scale: _focused ? 1.08 : 1,
              duration: Motion.duration(context, Motion.quick),
              curve: Motion.spring,
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: _focused ? AppColors.ink : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.readOnly,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onTap: widget.readOnly ? widget.onTap : null,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.inputHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.onClear != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => AnimatedSwitcher(
                  duration: Motion.duration(context, Motion.quick),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: value.text.isEmpty
                      ? const SizedBox(key: ValueKey('empty'), width: 18)
                      : IconButton(
                          key: const ValueKey('clear'),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _focusNode.unfocus();
                            widget.onClear!();
                          },
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textTertiary),
                        ),
                ),
              )
            else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}
