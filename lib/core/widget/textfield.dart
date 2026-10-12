// ******************* FILE INFO *******************
// File Name: textfield.dart
// Description: DEPRECATED SHIM — CustomValidatedTextFieldMaster is now a
//              thin wrapper around the single shared text field in
//              lib/core/custom/2-custom_textfield.dart.
//              App-wide rules (enforced by the shared widget):
//              • NO character counter is ever shown (showCharCount ignored).
//              • NO language restriction — Arabic AND English always allowed.
// Created by: Amr Mesbah
// Last Update: 12/7/2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom/2-custom_textfield.dart' as custom;
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

class CustomValidatedTextFieldMaster extends StatelessWidget {
  final String? label;

  /// Optional widget pinned to the END of the label row (same width as the
  /// field). Used e.g. to align a Status switch with the end of this field.
  final Widget? labelTrailing;
  final String hint;
  final TextEditingController controller;
  final double height;
  final double? width;
  final int maxLines;
  final bool enabled;

  /// IGNORED — no character counter anywhere in the app.
  final bool showCharCount;
  final ValueChanged<String>? onChanged;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final bool onlyDigits;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;

  /// Kept for call-site compatibility — ignored internally.
  final Color? primaryColor;

  /// Hard character cap (default 500) — enforced silently, no counter.
  final int maxLength;

  // Kept for call-site compatibility — ignored internally
  final bool submitted;
  final bool isRequired;
  final int minLength;
  final String? Function(String?)? validator;

  /// Overrides the label style so a screen can match its other field titles.
  /// Defaults to the legacy 14sp / w500 style.
  final TextStyle? labelStyle;

  /// Explicit error (red border + message under the field), e.g. a score
  /// outside 1–5 (BUG-264).
  final String? errorText;

  /// BUG-294: detail-page read-only value — solid white, not dimmed.
  final bool readOnlyView;

  const CustomValidatedTextFieldMaster({
    super.key,
    this.label,
    this.labelTrailing,
    required this.hint,
    required this.controller,
    this.height = 36,
    this.width,
    this.maxLines = 1,
    this.enabled = true,
    this.showCharCount = false,
    this.onChanged,
    this.textDirection = TextDirection.ltr,
    this.textAlign = TextAlign.start,
    this.onlyDigits = false,
    this.textStyle,
    this.hintStyle,
    this.fillColor,
    this.primaryColor,
    this.maxLength = 500,
    this.submitted = false,
    this.isRequired = false,
    this.minLength = 0,
    this.validator,
    this.labelStyle,
    this.errorText,
    this.readOnlyView = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool lightMode = Theme.of(context).brightness == Brightness.light;
    final bool isMultiline = maxLines > 1;

    final Color resolvedFill = fillColor ??
        AppColors.card;

    final EdgeInsetsGeometry contentPadding = isMultiline
        ? EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w)
        : EdgeInsets.symmetric(
            vertical: (height - 20).h / 2,
            horizontal: 12.w,
          );

    final Widget labelText = Text(
      label ?? '',
      textDirection: textDirection,
      style: labelStyle ??
          StyleText.fontSize14Weight500.copyWith(
            color: AppColors.text,
          ),
    );

    final field = custom.CustomTextField(
      controller: controller,
      hint: hint,
      // Label row is rendered here (legacy style + trailing support).
      label: null,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      width: width,
      height: isMultiline ? null : height,
      textDirection: textDirection,
      textAlign: textAlign,
      onlyDigits: onlyDigits,
      // BUG-290: `submitted` / `isRequired` used to be accepted and IGNORED,
      // so these fields never showed the shared red border + message.
      submitted: submitted && isRequired,
      required: isRequired,
      errorText: errorText,
      keyboardType: onlyDigits ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      fillColor: resolvedFill,
      readOnlyView: readOnlyView, // BUG-294
      // contentPadding: contentPadding,
      valueStyle: textStyle ??
          StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
      hintStyle: hintStyle ??
          StyleText.fontSize12Weight400.copyWith(
            color: lightMode ? const Color(0xFF9E9E9E) : ColorAppDark.titleKey,
          ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          labelTrailing != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label!,
                        textDirection: textDirection,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle ??
                            StyleText.fontSize14Weight600.copyWith(
                              color: const Color(0xFF1A1A1A),
                            ),
                      ),
                    ),
                    labelTrailing!,
                  ],
                )
              : labelText,
          SizedBox(height: 6.h),
        ],
        field,
      ],
    );
  }
}
