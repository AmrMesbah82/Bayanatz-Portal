import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvg extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  const CustomSvg({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.scaleDown,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width ?? 12.sp,
      height: height ?? 12.sp,
      fit: fit,
      color: color,
    );
  }
}
