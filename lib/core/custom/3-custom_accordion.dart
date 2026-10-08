// ******************* FILE INFO *******************
// File Name: 3-custom_accordion.dart
// Description: Reusable collapsible accordion with a colored header bar and an
//              animated SVG chevron. Extracted from the duplicated
//              _buildAccordion helpers so every screen shares one look.
//
// Usage:
//   CustomAccordion(
//     title:    'Digital Journey Section Title',
//     isOpen:   _headerOpen,
//     onToggle: () => setState(() => _headerOpen = !_headerOpen),
//     child:    <body widget>,
//   )
//
// The header colour, padding, radius and title style can be overridden when a
// screen needs a different emphasis — defaults match the standard admin style.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constant/color.dart';
import '../theme/new_theme.dart';

class CustomAccordion extends StatelessWidget {
  /// Header label.
  final String title;

  /// Whether the body is expanded.
  final bool isOpen;

  /// Called when the header bar is tapped.
  final VoidCallback onToggle;

  /// Body shown while [isOpen] is true.
  final Widget child;

  // ── Optional styling overrides ──────────────────────────────────────────
  final Color? headerColor;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry? headerPadding;
  final double? headerRadius;

  /// Trailing widget rendered before the chevron (e.g. a delete button).
  final Widget? trailing;

  const CustomAccordion({
    super.key,
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
    this.headerColor,
    this.titleStyle,
    this.headerPadding,
    this.headerRadius,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // ScreenUtil extensions can't be used as const defaults, so resolve here.
    final double radius = headerRadius ?? 4.r;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: headerPadding ??
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: headerColor ?? ColorPick.primary,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: titleStyle ??
                          StyleText.fontSize14Weight400
                              .copyWith(color: Colors.white),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  // assets/arrow.svg points UP, so a half turn (0.5) flips it
                  // to point DOWN when the accordion is collapsed.
                  AnimatedRotation(
                    turns: isOpen ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: SvgPicture.asset(
                      'assets/arrow.svg',
                      width: 7.sp,
                      height: 7.sp,
                      fit: BoxFit.scaleDown,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) child,
        ],
      ),
    );
  }
}
