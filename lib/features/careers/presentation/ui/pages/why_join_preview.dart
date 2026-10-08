// ******************* FILE INFO *******************
// File Name: why_join_preview.dart
// Preview page for Why Join Our Team / Our Interns / Our Teams
//
// CHANGES (Figma sync — mirrors careers_preview.dart shell):
//   • Admin shell background matches ColorPick.white (0xFFF1F2ED)
//   • Page title style matches "Preview {Section} Details" green heading
//   • Device tabs use underline-pill style (same as careers_preview_page)
//   • Language toggle uses CustomSegmentedTabs (ENG / AR) to match shell
//   • Green "View" collapsible bar (_ViewBar widget) above browser chrome
//   • Preview content wrapped in browser chrome + scaled device frame
//   • Bottom row: "Discard" (grey) + wide spacer + "Save" (green)
//   • _SiteNavBar injected at top of every preview viewport
//   • alternating left/right SVG + description layout preserved

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/two_tab.dart';
import '../../../data/models/careers_section_model.dart';
import '../../controller/careers_section_cubit.dart';
import '../../controller/careers_section_state.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/why_join_preview/desktop_frame.dart';
part '../widgets/why_join_preview/tablet_frame.dart';
part '../widgets/why_join_preview/mobile_frame.dart';
part '../widgets/why_join_preview/view_bar.dart';
part '../widgets/why_join_preview/browser_chrome.dart';
part '../widgets/why_join_preview/preview_content.dart';
part '../widgets/why_join_preview/icon_title_row.dart';

// ── Admin-shell colors (identical to careers_preview.dart) ───────────────
// class _AC {
//   static const Color primary   = Color(0xFF008037);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color grey      = Color(0xFF9E9E9E);
//   static const Color red       = Color(0xFFD32F2F);
// }

// ── Preview-viewport palette ──────────────────────────────────────────────────
const Color _kGreen  = Color(0xFF008037);
const Color _kBodyBg = Color(0xFFF8F9FA);

// ── Device viewport constants ─────────────────────────────────────────────────
const double _kDesktopW = 1366.0;
const double _kDesktopH =  900.0;
const double _kTabletW  =  768.0;
const double _kTabletH  = 1200.0;
const double _kMobileW  =  375.0;
const double _kMobileH  =  900.0;

double _safeScale(double v) =>
    (v.isFinite && !v.isNaN && v > 0) ? v : 1.0;

enum _Device { desktop, tablet, mobile }

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class CareersSectionPreviewPage extends StatefulWidget {
  final String sectionKey;
  final String sectionTitle;

  const CareersSectionPreviewPage({
    super.key,
    required this.sectionKey,
    required this.sectionTitle,
  });

  @override
  State<CareersSectionPreviewPage> createState() =>
      _CareersSectionPreviewPageState();
}

class _CareersSectionPreviewPageState
    extends State<CareersSectionPreviewPage> {
  _Device _device   = _Device.desktop;
  bool    _isAr     = false;
  bool    _isSaving = false;

  Future<void> _save(CareersSectionCubit cubit) async {
    setState(() => _isSaving = true);
    try {
      await cubit.save();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CareersSectionCubit, CareersSectionState>(
      listener: (context, state) {
        if (state is CareersSectionSaved) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '${widget.sectionTitle} saved!',
              style: StyleText.fontSize14Weight400
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: ColorPick.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ));
        }
        if (state is CareersSectionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Error: ${state.message}',
              style: StyleText.fontSize14Weight400
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: ColorPick.red
            ,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        final cubit = context.read<CareersSectionCubit>();

        if (state is CareersSectionInitial ||
            state is CareersSectionLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(
                child: CircleProgress()),
          );
        }

        CareersSectionModel? data;
        if (state is CareersSectionLoaded) data = state.data;
        if (state is CareersSectionSaved)  data = state.data;

        return Scaffold(
          backgroundColor: ColorPick.white,
          body: AdminStickyBody(
  crossAxisAlignment: CrossAxisAlignment.start,
  contentWidth: 1000.w,
  children: [
                    SizedBox(height: 20.h),
                    AdminSubNavBar(activeIndex: 5),
                    // ── Page title ─────────────────────────────────────────
                    Text(
                      'Preview ${widget.sectionTitle} Details',
                      style: StyleText.fontSize45Weight600.copyWith(
                        color:      ColorPick.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Device tabs + ENG/AR toggle ────────────────────────
                    Row(
                      children: [
                        _deviceTab('Desktop', _Device.desktop),
                        SizedBox(width: 24.w),
                        _deviceTab('Tablet',  _Device.tablet),
                        SizedBox(width: 24.w),
                        _deviceTab('Mobile',  _Device.mobile),
                        const Spacer(),
                        SizedBox(
                          width:  95.w,
                          height: 36.h,
                          child: CustomSegmentedTabs(
                            tabs: const ['ENG', 'AR'],
                            selectedIndex: _isAr ? 1 : 0,
                            onTabSelected: (i) =>
                                setState(() => _isAr = i == 1),
                            selectedColor:       ColorPick.primary,
                            unselectedColor:     Colors.white,
                            selectedTextColor:   Colors.white,
                            unselectedTextColor: AppColors.text,
                            equalWidth: false,
                            containerPadding: EdgeInsets.symmetric(
                              horizontal: 8.sp,
                              vertical:   4.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // ── Scaled device frame (View bar + browser) ───────────
                    LayoutBuilder(
                      builder: (ctx, box) =>
                          _buildFrame(box.maxWidth, data),
                    ),
                    SizedBox(height: 24.h),

                    // ── Discard + Save ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: ColorPick.discard,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Center(
                                child: Text(
                                  'Discard',
                                  style: StyleText.fontSize14Weight600
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 300.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isSaving ? null : () => _save(cubit),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: _isSaving
                                    ? ColorPick.primary.withValues(alpha: 0.5)
                                    : ColorPick.primary,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Center(
                                child: _isSaving
                                    ? SizedBox(
                                  width:  18.w,
                                  height: 18.h,
                                  child: const CircleProgress(),
                                )
                                    : Text(
                                  'Save',
                                  style: StyleText.fontSize14Weight600
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                  ],
),
        );
      },
    );
  }

  // ── Device tab pill ────────────────────────────────────────────────────────
  Widget _deviceTab(String label, _Device device) {
    final bool active = _device == device;
    return GestureDetector(
      onTap: () => setState(() => _device = device),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              label,
              style: StyleText.fontSize15Weight500.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color:      active ? ColorPick.primary : AppColors.secondaryText,
              ),
            ),
          ),
          Container(
            height: 2,
            width:  label.length * 8.0,
            color:  active ? ColorPick.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // ── Frame builder ──────────────────────────────────────────────────────────
  Widget _buildFrame(double containerW, CareersSectionModel? data) {
    switch (_device) {
      case _Device.desktop:
        return _DesktopFrame(
            containerWidth: containerW, data: data, isAr: _isAr);
      case _Device.tablet:
        return _TabletFrame(
            containerWidth: containerW, data: data, isAr: _isAr);
      case _Device.mobile:
        return _MobileFrame(
            containerWidth: containerW, data: data, isAr: _isAr);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DEVICE FRAMES
// ═══════════════════════════════════════════════════════════════════════════════

// ── Desktop ───────────────────────────────────────────────────────────────────
