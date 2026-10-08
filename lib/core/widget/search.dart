import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../custom/2-custom_textfield.dart';
import '../theme/app_theme.dart';
import '../theme/appcolors.dart';
import '../theme/text.dart';

class AppSearchTextField extends StatelessWidget {
  const AppSearchTextField({
    required this.controller,
    required this.onChanged,
    super.key,
    this.fillColor,
    this.hintText,
    this.height = 36,
  });

  final TextEditingController controller;
  final Color? fillColor;
  final dynamic Function(String)? onChanged;
  final String? hintText;

  /// Field height (interpreted in .h — same scale as customButton height).
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color fill = fillColor ?? AppColors.card;
    // BUG-149: the filled box was shorter than the Filter / Time Frame
    // buttons next to it — a one-line TextField only paints its own text
    // height, whatever box it sits in. The background is now drawn by this
    // box at the full [height] (same .h as customButton) and the field is
    // centred inside it, so search and buttons line up top and bottom.
    return Expanded(
      child: Container(
        height: height.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: CustomTextField(
          controller: controller,
          onChanged: (v) => onChanged?.call(v),
          hint: hintText ?? "search",
          maxLines: 1,
          borderRadius: BorderRadius.circular(8.r),
          fillColor: fill,
          hintStyle: AppTextStyles.font14SecondaryBlackCairo.copyWith(
            height: 1,
            color: AppTheme.isDark
                ? AppColors.lightGrey
                : AppColors.secondaryBlack,
          ),
          prefixIcon: SvgPicture.asset(
            "assets/images/search_icon.svg",
            width: 24.w,
            height: 24.h,
            fit: BoxFit.contain,
            color: AppTheme.isDark
                ? AppColors.lightGrey
                : AppColors.secondaryBlack,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        ),
      ),
    );
  }
}
