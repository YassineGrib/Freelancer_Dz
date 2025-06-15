import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = AppConstants.buttonHeight,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.isOutlined
            ? Colors.transparent
            : (widget.backgroundColor ?? AppColors.primary),
        border: widget.isOutlined
            ? Border.all(
                color: widget.backgroundColor ?? AppColors.primary,
                width: 1,
              )
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.text.length > 15 ? AppConstants.paddingSmall : AppConstants.paddingMedium,
            ),
            child: IntrinsicWidth(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isOutlined
                            ? (widget.backgroundColor ?? AppColors.primary)
                            : (widget.textColor ?? AppColors.textWhite),
                      ),
                    ),
                  )
                else if (widget.icon != null)
                  FaIcon(
                    widget.icon,
                    size: 18,
                    color: widget.isOutlined
                        ? (widget.backgroundColor ?? AppColors.primary)
                        : (widget.textColor ?? AppColors.textWhite),
                  ),

                if ((widget.isLoading || widget.icon != null) && widget.text.isNotEmpty)
                  const SizedBox(width: 12),

                if (widget.text.isNotEmpty)
                  Flexible(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: widget.text.length > 15 ? AppConstants.textMedium : AppConstants.textLarge,
                        fontWeight: FontWeight.w500,
                        color: widget.isOutlined
                            ? (widget.backgroundColor ?? AppColors.primary)
                            : (widget.textColor ?? AppColors.textWhite),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

