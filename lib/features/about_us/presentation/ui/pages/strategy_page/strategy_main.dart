// ******************* FILE INFO *******************
// File Name: strategy_main.dart
// Screen 1 of 3 — Our Strategy CMS: Main view (read-only accordions)
// UPDATED: Added Strategic House ENG + ARB accordions

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';

import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom_svg.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../../../core/widget/navigator.dart';
import '../../../../data/models/about_us_model.dart';
import '../../../controller/about_us_cubit.dart';
import '../../../controller/about_us_state.dart';
import 'strategy_edit.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

// ─────────────────────────────────────────────────────────────────────────────

class StrategyMainView extends StatefulWidget {
  const StrategyMainView({super.key});

  @override
  State<StrategyMainView> createState() => _StrategyMainViewState();
}

class _StrategyMainViewState extends State<StrategyMainView> {
  final Map<String, bool> _open = {
    'navigationLabel':  true,
    'strategicHouseEn': true,
    'strategicHouseAr': true,
  };

  // ── Selected device per section (0 = Desktop, 1 = Tablet, 2 = Mobile) ──
  int _enSelectedDevice = 0;
  int _arSelectedDevice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StrategyCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StrategyCubit, StrategyState>(
      builder: (context, state) {
        if (state is StrategyLoading || state is StrategyInitial) {
          return const Center(
              child: CircleProgress());
        }

        final OurStrategyModel? model = switch (state) {
          StrategyLoaded s => s.data,
          StrategySaved  s => s.data,
          _                => null,
        };

        if (model == null) {
          return Center(
              child: Text('No data found',
                  style: StyleText.fontSize13Weight400
                      .copyWith(color: AppColors.secondaryText)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _lastUpdatedRow(
              lastUpdated: model.lastUpdatedAt,    // ← ADD this
              onEdit: () => navigateTo(
                context,
                BlocProvider.value(
                  value: context.read<StrategyCubit>(),
                  child: const StrategyEditPage(),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ① Navigation Label
            _accordion(
              key: 'navigationLabel',
              title: 'Navigation Label',
              children: [
                SizedBox(height: 20.h),
                _iconPreviewCircle(
                    label: 'Icon',
                    url: model.navigationLabel.iconUrl),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(
                      child: _readField(
                          'Title',
                          model.navigationLabel.title.en.isEmpty
                              ? 'Text Here'
                              : model.navigationLabel.title.en)),
                  SizedBox(width: 16.w),
                  Expanded(
                      child: _readFieldRtl(
                          'العنوان',
                          model.navigationLabel.title.ar)),
                ]),
                SizedBox(height: 16.h),
              ],
            ),
            SizedBox(height: 12.h),

            // ② Strategic House — ENG (Multi-device)
            _accordion(
              key: 'strategicHouseEn',
              title: 'Strategic House - ENG',
              children: [
                SizedBox(height: 20.h),
                // Device selector tabs - aligned to the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _deviceSelector(
                      selectedIndex: _enSelectedDevice,
                      onChanged: (index) => setState(() => _enSelectedDevice = index),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _imagePreviewBox(
                  label: '',
                  url: _getEnUrlForDevice(model, _enSelectedDevice),
                ),
                SizedBox(height: 16.h),
              ],
            ),
            SizedBox(height: 12.h),

            // ③ Strategic House — ARB (Multi-device)
            _accordion(
              key: 'strategicHouseAr',
              title: 'Strategic House - ARB',
              children: [
                SizedBox(height: 20.h),
                // Device selector tabs - aligned to the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _deviceSelector(
                      selectedIndex: _arSelectedDevice,
                      onChanged: (index) => setState(() => _arSelectedDevice = index),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _imagePreviewBox(
                  label: '',
                  url: _getArUrlForDevice(model, _arSelectedDevice),
                ),
                SizedBox(height: 16.h),
              ],
            ),
            SizedBox(height: 40.h),
          ],
        );
      },
    );
  }

  // Helper to get EN URL based on selected device
  String _getEnUrlForDevice(OurStrategyModel model, int deviceIndex) {
    switch (deviceIndex) {
      case 0: return model.strategicHouseEnDesktopUrl;
      case 1: return model.strategicHouseEnTabletUrl;
      case 2: return model.strategicHouseEnMobileUrl;
      default: return model.strategicHouseEnDesktopUrl;
    }
  }

  // Helper to get AR URL based on selected device
  String _getArUrlForDevice(OurStrategyModel model, int deviceIndex) {
    switch (deviceIndex) {
      case 0: return model.strategicHouseArDesktopUrl;
      case 1: return model.strategicHouseArTabletUrl;
      case 2: return model.strategicHouseArMobileUrl;
      default: return model.strategicHouseArDesktopUrl;
    }
  }

  // ── Device Selector Widget ────────────────────────────────────────────────
  Widget _deviceSelector({
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    final List<String> devices = ['Large Screen', 'Tablet', 'Mobile'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(devices.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? ColorPick.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                devices[index],
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

// ── Last Updated + Edit Details ───────────────────────────────────────────
  Widget _lastUpdatedRow({
    required VoidCallback onEdit,
    DateTime? lastUpdated,           // ← ADD this parameter
  }) {
    // ── Date formatter ──
    String fmtDate(DateTime? d) {
      if (d == null) return '—';
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
              color: ColorPick.white,
              borderRadius: BorderRadius.circular(4.r)),
          child: Text(
            'Last Updated On ${fmtDate(lastUpdated)}',   // ← dynamic
            style: StyleText.fontSize13Weight500
                .copyWith(color: ColorPick.primary),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            width: 130.w, height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Edit Details',
                    style: StyleText.fontSize14Weight500
                        .copyWith(color: Colors.black)),
                SizedBox(width: 6.w),
                CustomSvg(
                    assetPath: "assets/control/edit_icon_pick.svg",
                    width: 20.w, height: 20.h,
                    fit: BoxFit.scaleDown, color: ColorPick.primary),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Accordion ─────────────────────────────────────────────────────────────
  Widget _accordion({
    required String key,
    required String title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Image preview box (for Strategic House sections) ──────────────────────
  Widget _imagePreviewBox({required String label, required String url}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: StyleText.fontSize12Weight500
                .copyWith(color: AppColors.text)),
        SizedBox(height: 8.h),
        // Rendered fully through the shared NetworkImageView
        // (core/widget/network_image_view.dart) — its own placeholder
        // handles the empty-URL state.
        SizedBox(
          width: double.infinity,
          height: 200.h,
          child: Center(
            child: NetworkImageView(
              url: url,
              width: 300.w,
              height: 200.h,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(8.r),
              placeholder: Center(
                child: SvgPicture.asset(
                  'assets/images/null.svg',
                  width: 120.w,
                  height: 120.h,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Icon preview circle ────────────────────────────────────────────────────
  // Standard read-only icon circle — same UI everywhere via
  // NetworkImageView.circle (core/widget/network_image_view.dart).
  Widget _iconPreviewCircle({
    required String label,
    required String url,
    bool isSvg = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: StyleText.fontSize12Weight500
                .copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        NetworkImageView.circle(url: url, diameter: 56.w),
      ],
    );
  }

  // ── Read-only LTR ─────────────────────────────────────────────────────────
  Widget _readField(String label, String value,
      {double height = 36}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: StyleText.fontSize12Weight500
                  .copyWith(color: AppColors.text)),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            height: height.h,
            padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: height > 36 ? 8.h : 0),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4.r)),
            alignment: height > 36
                ? Alignment.topLeft
                : Alignment.centerLeft,
            child: Text(value,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
                maxLines: height > 36 ? 8 : 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  // ── Read-only RTL ─────────────────────────────────────────────────────────
  Widget _readFieldRtl(String label, String value,
      {double height = 36}) =>
      Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: StyleText.fontSize12Weight500
                    .copyWith(color: AppColors.text)),
            SizedBox(height: 4.h),
            Container(
              width: double.infinity,
              height: height.h,
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: height > 36 ? 8.h : 0),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(4.r)),
              alignment: height > 36
                  ? Alignment.topRight
                  : Alignment.centerRight,
              child: Text(
                  value.isEmpty ? 'أكتب هنا' : value,
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                  textDirection: TextDirection.rtl,
                  maxLines: height > 36 ? 8 : 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}