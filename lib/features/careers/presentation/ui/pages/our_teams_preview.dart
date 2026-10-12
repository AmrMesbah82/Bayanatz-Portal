// ******************* FILE INFO *******************
// File Name: our_teams_preview.dart
// Preview page for "Our Teams" section.
// Figma: "Preview Our Teams Details"
// Features:
//   • Desktop / Tablet / Mobile device frame (mirrors about_us_preview.dart)
//   • ENG / AR language toggle
//   • Scaled device-frame preview of "Meet Our Teams" content
//   • Row sections (First Row, Second Row…) with card count badge
//   • + Row / Select Team controls (Figma "Fifths Row" section)
//   • Back + Save bottom buttons
// UPDATED: Full mockup-style preview matching Figma

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/two_tab.dart';
import '../../../data/models/our_teams_model.dart';
import '../../controller/our_teams_cubit.dart';
import '../../controller/our_teams_state.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/our_teams_preview/desktop_frame.dart';
part '../widgets/our_teams_preview/tablet_frame.dart';
part '../widgets/our_teams_preview/mobile_frame.dart';
part '../widgets/our_teams_preview/preview_content.dart';
part '../widgets/our_teams_preview/row_section.dart';
part '../widgets/our_teams_preview/team_card.dart';
part '../widgets/our_teams_preview/browser_chrome.dart';

// ── Admin-shell colors ────────────────────────────────────────────────────────
// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF1F2ED);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color discard   = Color(0xFF797979);
//   static const Color preview   = Color(0xFF608570);
// }

// ── Device viewport constants ─────────────────────────────────────────────────
const double _kDesktopW = 1366.0;
const double _kDesktopH =  900.0;
const double _kTabletW  =  768.0;
const double _kTabletH  = 1024.0;
const double _kMobileW  =  375.0;
const double _kMobileH  =  812.0;
const int    _kPerRow   = 3;

double _safeScale(double v) =>
    (v.isFinite && !v.isNaN && v > 0) ? v : 1.0;

enum _PreviewDevice { desktop, tablet, mobile }

// ── HtmlElementView SVG/image helper (XHR/CORS workaround) ───────────────────
Widget _netImg({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  if (url.isEmpty) return const SizedBox.shrink();
  final id = 'ot-pv-${url.hashCode}-${width?.toInt()}-${height?.toInt()}';
  ui_web.platformViewRegistry.registerViewFactory(id, (_) {
    final img = html.ImageElement()
      ..src = url
      ..style.width  = '100%'
      ..style.height = '100%'
      ..style.objectFit =
      fit == BoxFit.contain ? 'contain' : 'cover';
    return img;
  });
  Widget w = HtmlElementView(viewType: id);
  if (width != null || height != null)
    w = SizedBox(width: width, height: height, child: w);
  return w;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREVIEW PAGE  (admin shell)
// ═══════════════════════════════════════════════════════════════════════════════

class OurTeamsPreviewPage extends StatefulWidget {
  const OurTeamsPreviewPage({super.key});

  @override
  State<OurTeamsPreviewPage> createState() => _OurTeamsPreviewPageState();
}

class _OurTeamsPreviewPageState extends State<OurTeamsPreviewPage> {
  _PreviewDevice _device = _PreviewDevice.desktop;
  bool           _isAr   = false;
  bool           _isSaving = false;

  Future<void> _handleSave(OurTeamsCubit cubit) async {
    setState(() => _isSaving = true);
    try {
      await cubit.save();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OurTeamsCubit, OurTeamsState>(
      builder: (context, state) {
        OurTeamsModel? data;
        if (state is OurTeamsLoaded) data = state.data;
        if (state is OurTeamsSaved)  data = state.data;

        final cubit = context.read<OurTeamsCubit>();

        return Stack(
          children: [
            Scaffold(
              backgroundColor: ColorPick.white,
              body: AdminStickyBody(
  crossAxisAlignment: CrossAxisAlignment.start,
  contentWidth: 1000.w,
  children: [
                        SizedBox(height: 20.h),
                        AdminSubNavBar(activeIndex: 5),
                        // ── Page title ──────────────────────────────────────
                        Text(
                          'Preview Our Team Details',
                          style: StyleText.fontSize45Weight600.copyWith(
                            color:      ColorPick.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // ── Device tabs + ENG/AR toggle ─────────────────────
                        Row(
                          children: [
                            _deviceTab('Desktop', _PreviewDevice.desktop),
                            SizedBox(width: 24.w),
                            _deviceTab('Tablet',  _PreviewDevice.tablet),
                            SizedBox(width: 24.w),
                            _deviceTab('Mobile',  _PreviewDevice.mobile),
                            const Spacer(),
                            SizedBox(
                              width:  95.w,
                              height: 36.h,
                              child: CustomSegmentedTabs(
                                tabs:               const ['ENG', 'AR'],
                                selectedIndex:      _isAr ? 1 : 0,
                                onTabSelected: (i) =>
                                    setState(() => _isAr = i == 1),
                                selectedColor:      ColorPick.primary,
                                unselectedColor:    Colors.white,
                                selectedTextColor:  Colors.white,
                                unselectedTextColor: AppColors.text,
                                equalWidth: false,
                                containerPadding: EdgeInsets.symmetric(
                                    horizontal: 8.sp, vertical: 4.sp),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // ── Device frame ────────────────────────────────────
                        LayoutBuilder(
                          builder: (ctx, box) =>
                              _buildFrame(box.maxWidth, data),
                        ),

                        SizedBox(height: 24.h),

                        // ── Back + Save ─────────────────────────────────────
                        _bottomButtons(cubit),
                        SizedBox(height: 40.h),
                      ],
),
            ),

            // ── Saving overlay ──────────────────────────────────────────────
            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 40.w, vertical: 32.h),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleProgress(),
                        SizedBox(height: 16.h),
                        Text('Saving…',
                            style: StyleText.fontSize14Weight600
                                .copyWith(color: ColorPick.primary)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Device tab widget ───────────────────────────────────────────────────────
  Widget _deviceTab(String label, _PreviewDevice device) {
    final active = _device == device;
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
            width: label.length * 8.0,
            color: active ? ColorPick.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // ── Frame switcher ──────────────────────────────────────────────────────────
  Widget _buildFrame(double containerW, OurTeamsModel? data) {
    switch (_device) {
      case _PreviewDevice.desktop:
        return _DesktopFrame(
            containerWidth: containerW, data: data, isAr: _isAr);
      case _PreviewDevice.tablet:
        return _TabletFrame(
            containerWidth: containerW, data: data, isAr: _isAr);
      case _PreviewDevice.mobile:
        return _MobileFrame(
            containerWidth: containerW, data: data, isAr: _isAr);
    }
  }

  // ── Bottom buttons ──────────────────────────────────────────────────────────
  Widget _bottomButtons(OurTeamsCubit cubit) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color:        ColorPick.discard,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Center(
                    child: Text('Back',
                        style: StyleText.fontSize14Weight600
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ),
            SizedBox(width: 300.w),
            Expanded(
              child: GestureDetector(
                onTap: _isSaving ? null : () => _handleSave(cubit),
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
                        : Text('Save',
                        style: StyleText.fontSize14Weight600
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DEVICE FRAMES
// ═══════════════════════════════════════════════════════════════════════════════
