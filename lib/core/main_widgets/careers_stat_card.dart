// ******************* FILE INFO *******************
// File Name: careers_stat_card.dart
// Created by: Amr Mesbah
// Purpose: Row of small stat cards (All Jobs, Office Jobs, Remote, etc.)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_app_admin/core/constant/color.dart';
import 'package:web_app_admin/core/widget/navigator.dart';

import 'admin_layout.dart';


class CareersStatCardData {
  final String label;
  final int value;
  final String? iconAsset;

  const CareersStatCardData({
    required this.label,
    required this.value,
    this.iconAsset,
  });
}

class CareersStatCardsRow extends StatelessWidget {
  final List<CareersStatCardData> cards;

  const CareersStatCardsRow({Key? key, required this.cards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // BUG-06: on a phone the KPI cards form a 2-column grid (they were six
    // squeezed cards showing only their icons).
    if (AdminLayout.isPhone(context)) {
      return AdminCardsRow(
        phoneColumns: 2,
        gap: 10,
        children: cards.map((c) => _StatCard(data: c)).toList(),
      );
    }
    return Row(
      children: cards.asMap().entries.map((entry) {
        final isLast = entry.key == cards.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10.w),
            child: _StatCard(data: entry.value),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final CareersStatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      // removed width: 200.w
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.sp,
            height: 36.sp,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:  ColorPick.primary.withOpacity(.2),
            ),
            child: Center(
              child: data.iconAsset != null && data.iconAsset!.isNotEmpty
                  ? SvgPicture.asset(
                data.iconAsset!,
                width: 18.sp,
                height: 18.sp,
                colorFilter: const ColorFilter.mode(
                    ColorPick.primary, BlendMode.srcIn),
              )
                  : Icon(
                Icons.work_outline_rounded,
                size: 18.sp,
                color: const Color(0xFF008037),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF888888),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  data.value.toString(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}