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
    // BUG-268: up to 6 cards in one row; more (8 since On Site / Hybrid and
    // Scheduled got their own card) wrap into rows of 4 equal cards.
    final int perRow = cards.length > 6 ? 4 : cards.length;
    final rows = <Widget>[];
    for (var start = 0; start < cards.length; start += perRow) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: 10.h));
      rows.add(Row(
        children: [
          for (var i = 0; i < perRow; i++) ...[
            if (i > 0) SizedBox(width: 10.w),
            Expanded(
              child: start + i < cards.length
                  ? _StatCard(data: cards[start + i])
                  : const SizedBox(),
            ),
          ],
        ],
      ));
    }
    return Column(children: rows);
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