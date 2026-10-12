// ******************* FILE INFO *******************
// File Name: empty_lottie.dart
// QA-Oct11 #24: ONE empty state for the admin — the "no data" Lottie
// animation (taken from knowticed_plus) instead of a grey "No … found"
// sentence. Used by the Applications list, the Job listing, the Inquiries
// table and every dashboard / inquiry chart card.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'app_assets.dart';

class EmptyLottie extends StatelessWidget {
  /// Square size of the animation (design px, scaled with `.sp`).
  final double size;

  /// Read by screen readers only — nothing is printed on screen.
  final String semanticLabel;

  const EmptyLottie({
    super.key,
    this.size = 160,
    this.semanticLabel = 'No data',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Center(
        child: Lottie.asset(
          AppAssets.noData,
          width: size.sp,
          height: size.sp,
          fit: BoxFit.contain,
          repeat: true,
          // A missing / broken asset must never crash a page.
          errorBuilder: (_, __, ___) => SizedBox(width: size.sp, height: size.sp),
        ),
      ),
    );
  }
}
