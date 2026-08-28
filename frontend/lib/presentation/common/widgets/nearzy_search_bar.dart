import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// A polished search bar with animated focus and icon transitions.
class NearzySearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;

  const NearzySearchBar({
    super.key,
    this.hintText = 'Search products, shops & more',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.controller,
  });

  @override
  State<NearzySearchBar> createState() => _NearzySearchBarState();
}

class _NearzySearchBarState extends State<NearzySearchBar> {
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.readOnly ? widget.onTap : null,
      child: AnimatedContainer(
        duration: AppSpacing.durationFast,
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isFocused ? AppColors.card : AppColors.inputFill,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: _isFocused ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: _isFocused ? AppSpacing.shadowMedium : [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          onTap: widget.readOnly ? widget.onTap : null,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.inputHint,
            prefixIcon: AnimatedSwitcher(
              duration: AppSpacing.durationFast,
              child: Icon(
                Icons.search_rounded,
                key: ValueKey(_isFocused),
                color: _isFocused ? AppColors.primary : AppColors.textTertiary,
                size: 22,
              ),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            filled: false,
          ),
        ),
      ),
    );
  }
}
