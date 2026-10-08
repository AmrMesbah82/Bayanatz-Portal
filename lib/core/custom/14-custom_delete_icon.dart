// ******************* FILE INFO *******************
// File Name: 14-custom_delete_icon.dart
// Delete action button (adapted for web_app_admin).
//
// Fixed (static) values:
// - Height: 38.sp, border radius 8.r
// - Svg: assets/delete.svg, 20.sp x 20.sp, 8.sp space before text

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom_svg.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

class CustomDeleteIcon extends StatelessWidget {
  static const String _svgPath = 'assets/delete.svg';

  final String? title;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final Color? svgColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const CustomDeleteIcon({
    super.key,
    this.title,
    this.onTap,
    this.color,
    this.borderColor,
    this.svgColor,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final String text = title ?? 'Delete';
    final Color iconColor = svgColor ?? AppColors.textButton;

    final TextStyle effectiveStyle =
        textStyle ?? StyleText.fontSize14Weight400.copyWith(color: iconColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.sp,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 12.sp),
        decoration: BoxDecoration(
          color: color ?? Colors.red,
          border: Border.all(color: borderColor ?? Colors.transparent),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomSvg(
              assetPath: _svgPath,
              width: 20.sp,
              height: 20.sp,
              color: iconColor,
              fit: BoxFit.scaleDown,
            ),
            SizedBox(width: 8.sp),
            Text(text, style: effectiveStyle, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
