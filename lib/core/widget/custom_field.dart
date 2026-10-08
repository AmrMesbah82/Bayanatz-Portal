// ******************* FILE INFO *******************
// File Name: custom_field.dart
// Description: DEPRECATED SHIM — thin wrapper around the single shared
//              text field in lib/core/custom/2-custom_textfield.dart.
//              Keeps the legacy call-site API (labelTrailing, isRequired,
//              textStyle, primaryColor, minLength) while delegating ALL
//              rendering/behaviour to the shared widget.
//              App-wide rules (enforced by the shared widget):
//              • NO character counter is ever shown.
//              • NO language restriction — Arabic AND English always allowed.
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom/2-custom_textfield.dart' as custom;
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

/// Legacy-named wrapper. Delegates to the shared core/custom text field.
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final String? hint;
  final String? label;

  /// Optional widget pinned to the END of the label row (same width as the
  /// field). Used e.g. to align a Status switch with the end of this field.
  final Widget? labelTrailing;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final bool required;

  /// Alias for [required].
  final bool isRequired;

  /// Kept for call-site compatibility — ignored internally.
  final Color? primaryColor;

  /// Kept for call-site compatibility — ignored internally.
  final int minLength;

  /// Alias for [valueStyle] (legacy name).
  final TextStyle? textStyle;

  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<bool>? onFocusChanged;
  final VoidCallback? onTap;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? valueStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final TextStyle? counterStyle;
  final double? width;
  final double? height;
  final bool submitted;
  final bool onlyDigits;

  /// IGNORED — no language restriction anywhere in the app.
  final bool restrictByDirection;
  final bool autoCapitalize;

  /// IGNORED — no character counter anywhere in the app.
  final bool showCharCount;

  const CustomTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hint,
    this.label,
    this.labelTrailing,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.isRequired = false,
    this.primaryColor,
    this.minLength = 0,
    this.textStyle,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.onTap,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.valueStyle,
    this.hintStyle,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.counterStyle,
    this.width,
    this.height = 36,
    this.submitted = false,
    this.onlyDigits = false,
    this.restrictByDirection = false,
    this.autoCapitalize = false,
    this.showCharCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRequiredResolved = required || isRequired;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    final TextStyle resolvedLabelStyle = labelStyle ??
        StyleText.fontSize14Weight500.copyWith(
          color: hasError
              ? AppColors.red
              : !enabled
                  ? AppColors.text.withValues(alpha: 0.4)
                  : AppColors.text,
        );

    final field = custom.CustomTextField(
      controller: controller,
      focusNode: focusNode,
      initialValue: initialValue,
      hint: hint,
      // When a labelTrailing exists we render the label row ourselves.
      label: labelTrailing != null ? null : label,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
      readOnly: readOnly,
      required: isRequiredResolved,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textDirection: textDirection,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onFocusChanged: onFocusChanged,
      onTap: onTap,
      fillColor: fillColor,
      borderRadius: borderRadius,
      contentPadding: contentPadding,
      valueStyle: valueStyle ??
          textStyle ??
          StyleText.fontSize12Weight400.copyWith(
            color: !enabled
                ? AppColors.text.withValues(alpha: 0.4)
                : AppColors.text,
          ),
      hintStyle: hintStyle ??
          StyleText.fontSize12Weight400.copyWith(
            color: AppColors.text.withValues(alpha: 0.4),
          ),
      labelStyle: resolvedLabelStyle,
      errorStyle: errorStyle,
      helperStyle: helperStyle,
      counterStyle: counterStyle,
      width: width,
      height: height,
      submitted: submitted,
      onlyDigits: onlyDigits,
      autoCapitalize: autoCapitalize,
    );

    if (labelTrailing == null || label == null) return field;

    // Label row with trailing widget, then the field below.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  text: label,
                  style: resolvedLabelStyle,
                  children: isRequiredResolved
                      ? [

                        ]
                      : [],
                ),
              ),
            ),
            labelTrailing!,
          ],
        ),
        SizedBox(height: 6.h),
        field,
      ],
    );
  }
}
