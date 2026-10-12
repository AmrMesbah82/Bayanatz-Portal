// ******************* FILE INFO *******************
// File Name: cms_sub_tabs.dart
// Purpose: BUG-155 — ONE sub-tab row for every Web Page CMS tab (Services,
//          About Us, Careers …). Careers drew padded boxes with dark text and
//          no gaps while Services / About Us drew plain grey text with gaps;
//          every page now uses this widget, so they cannot drift apart again.
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/color.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

class CmsSubTabs extends StatelessWidget {
  const CmsSubTabs({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Wraps instead of overflowing on narrow screens (BUG-265: "Abo…").
    return Wrap(
      spacing: 24.w,
      runSpacing: 8.h,
      children: List.generate(labels.length, (i) {
        final bool isActive = activeIndex == i;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onTap(i),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      labels[i],
                      style: StyleText.fontSize15Weight500.copyWith(
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? ColorPick.primary
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    color: isActive ? ColorPick.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
