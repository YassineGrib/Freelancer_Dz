import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool enabled;
  final Function(String)? onChanged;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onChanged,
    this.maxLines,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  bool _isPasswordVisible = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: AppConstants.textMedium,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText || (widget.isPassword && !_isPasswordVisible),
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines ?? 1,
          style: const TextStyle(
            fontSize: AppConstants.textLarge,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: AppConstants.textLarge,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? AppColors.borderFocus : AppColors.textLight,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.suffixIcon ??
                (widget.isPassword
                    ? IconButton(
                        icon: FaIcon(
                          _isPasswordVisible
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          size: 18,
                          color: _isFocused ? AppColors.borderFocus : AppColors.textLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      )
                    : null),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.borderFocus,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }
}

