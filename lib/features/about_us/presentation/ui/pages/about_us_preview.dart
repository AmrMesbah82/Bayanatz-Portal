// ******************* FILE INFO *******************
// File Name: about_us_preview.dart
// Screen 3 — About Us CMS: Preview with Desktop/Tablet/Mobile + ENG/AR toggle
// UPDATED: Mirrors about_page.dart UI exactly inside scaled device frames
//          Same top-tab bar, sub-tab items, accordion, values grid, colors.

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_app_admin/core/constant/color.dart';

import '../../../../../core/custom_dialog.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/two_tab.dart';
import '../../../data/models/about_us_model.dart';
import '../../controller/about_us_cubit.dart';
import '../../controller/about_us_state.dart';
import 'about_us_main.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';

part '../widgets/about_us_preview/desktop_frame.dart';
part '../widgets/about_us_preview/tablet_frame.dart';
part '../widgets/about_us_preview/mobile_frame.dart';
part '../widgets/about_us_preview/preview_content.dart';
part '../widgets/about_us_preview/desktop_sub_tab.dart';
part '../widgets/about_us_preview/tablet_sub_tab.dart';
part '../widgets/about_us_preview/mobile_accordion.dart';
part '../widgets/about_us_preview/values_grid.dart';
part '../widgets/about_us_preview/value_card.dart';
part '../widgets/about_us_preview/value_detail.dart';
part '../widgets/about_us_preview/browser_chrome.dart';

//── Admin-shell colors ────────────────────────────────────────────────────────
//class _AC {
//  static const Color primary   = Color(0xFF008037);
//  static const Color back      = Color(0xFFF1F2ED);
//  static const Color labelText = Color(0xFF333333);
//  static const Color hintText  = Color(0xFFAAAAAA);
//  static const Color border    = Color(0xFFE0E0E0);
//  static const Color grey      = Color(0xFF9E9E9E);
//}

// ── User-app palette (mirrors about_page.dart constants) ─────────────────────
const Color _kDefaultGreen = Color(0xFF2D8C4E);
const Color _kGreenLight   = Color(0xFFE8F5EE);
const Color _kSurface      = Color(0xFFFFFFFF);
const Color _kDivider      = Color(0xFFDDE8DD);

// ── Device viewport constants ─────────────────────────────────────────────────
const double _kDesktopW = 1366.0;
const double _kDesktopH =  768.0;
const double _kTabletW  =  768.0;
const double _kTabletH  = 1024.0;
const double _kMobileW  =  375.0;
const double _kMobileH  =  812.0;

double _safeScale(double v) =>
    (v.isFinite && !v.isNaN && v > 0) ? v : 1.0;

enum _PreviewDevice { desktop, tablet, mobile }

Color _hoverTint(Color c) => c.withValues(alpha: 0.12);

String _ab(AboutBilingualText b, bool isRtl) {
  final v = isRtl ? b.ar : b.en;
  return v.isNotEmpty ? v : b.en;
}

// ── HtmlElementView image helper (matches overview_preview_page.dart) ─────────
Widget _netImg({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
  ColorFilter? colorFilter,
}) {
  if (url.isEmpty) return const SizedBox.shrink();
  final id =
      'ab-pv-${url.hashCode}-${width?.toInt()}-${height?.toInt()}-${fit.index}';
  ui_web.platformViewRegistry.registerViewFactory(id, (_) {
    final img = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = fit == BoxFit.contain
          ? 'contain'
          : fit == BoxFit.scaleDown
          ? 'scale-down'
          : 'cover';
    return img;
  });
  Widget inner = HtmlElementView(viewType: id);
  if (width != null || height != null)
    inner = SizedBox(width: width, height: height, child: inner);
  if (borderRadius != null)
    inner = ClipRRect(borderRadius: borderRadius, child: inner);
  return inner;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREVIEW PAGE  (admin shell)
// ═══════════════════════════════════════════════════════════════════════════════

class AboutPreviewPageLast extends StatefulWidget {
  final AboutPageModel model;
  final Map<String, Uint8List> imageUploads;

  /// Whether this preview can publish.
  ///
  /// The edit flow opens it with Save, because it is showing unsaved work. The
  /// "Preview Screen" button on the main page opens it read-only — you are
  /// looking at what is already live, so there is nothing to save.
  final bool showSave;

  const AboutPreviewPageLast({
    super.key,
    required this.model,
    this.imageUploads = const {},
    this.showSave = true,
  });

  @override
  State<AboutPreviewPageLast> createState() => _AboutPreviewPageLastState();
}

class _AboutPreviewPageLastState extends State<AboutPreviewPageLast> {
  _PreviewDevice _device       = _PreviewDevice.desktop;
  bool           _isAr         = false;
  bool           _isPublishing = false;

  void _onBack() => Navigator.pop(context);

  void _onSave() {
    showPublishConfirmDialog(
      context: context,
      title: 'EDITING ABOUT US DETAILS',
      subtitle: 'Do you want to save the changes made to this About Us?',
      confirmLabel: 'Confirm',
      backLabel: 'Back',
      onConfirm: () async {
        setState(() => _isPublishing = true);
        try {
          await context.read<AboutCubit>().save(
            model: widget.model,
            imageUploads:
            widget.imageUploads.isEmpty ? null : widget.imageUploads,
          );
        } finally {
          if (mounted) setState(() => _isPublishing = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AboutCubit, AboutState>(
      listener: (context, state) {
        if (state is AboutSaved) {
          // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const AboutMainPageMasterDashboard()),
                    (route) => false,
              );
            }
          });
        }
        if (state is AboutError) {
          setState(() => _isPublishing = false);
          showConfirmDialog(
            context: context,
            title: 'Error',
            subtitle: state.message,
            confirmLabel: 'OK',
            cancelLabel: '',
            onConfirm: () {},
            iconWidget: Container(
              width: 60.r,
              height: 60.r,
              decoration: const BoxDecoration(
                  color: Color(0xFFE53935), shape: BoxShape.circle),
              child:
              Icon(Icons.error_outline, color: Colors.white, size: 36.r),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: ColorPick.background,
            body: AdminStickyBody(
  crossAxisAlignment: CrossAxisAlignment.start,
  contentWidth: 1000.w,
  children: [
                      AppAdminNavbar(
                        activeLabel:    'Web Page',
                        homePage:       CareersMainPageDashboard(),
                        webPage:        MainMainPage(),
                        jobListingPage: JobListingMainPage(),
                      ),
                      SizedBox(height: 20.h),
                      AdminSubNavBar(activeIndex: 3),
                      Text(
                        'Preview About Us Details',
                        style: StyleText.fontSize45Weight600.copyWith(
                            color: ColorPick.primary, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 16.h),

                      // ── Device tabs + Language toggle ──────────────
                      Row(
                        children: [
                          _tab('Desktop', _PreviewDevice.desktop),
                          SizedBox(width: 24.w),
                          _tab('Tablet',  _PreviewDevice.tablet),
                          SizedBox(width: 24.w),
                          _tab('Mobile',  _PreviewDevice.mobile),
                          const Spacer(),
                          SizedBox(
                            width: 95.w,
                            height: 36.h,
                            child: CustomSegmentedTabs(
                              tabs: const ['ENG', 'AR'],
                              selectedIndex: _isAr ? 1 : 0,
                              onTabSelected: (i) =>
                                  setState(() => _isAr = i == 1),
                              selectedColor: ColorPick.primary,
                              unselectedColor: Colors.white,
                              selectedTextColor: Colors.white,
                              unselectedTextColor: AppColors.text,
                              equalWidth: false,
                              containerPadding: EdgeInsets.symmetric(
                                  horizontal: 8.sp, vertical: 4.sp),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // ── Scaled device frame ────────────────────────
                      LayoutBuilder(
                          builder: (ctx, box) =>
                              _buildFrame(box.maxWidth)),

                      SizedBox(height: 24.h),

                      // ── Back (+ Save, only when there is unsaved work) ──
                      _actions(),
                      SizedBox(height: 40.h),
                    ],
),
          ),

          if (_isPublishing)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                  child: CircleProgress()),
            ),
        ],
      ),
    );
  }

  // ── Bottom actions ─────────────────────────────────────────────────────────
  // Read-only preview (opened from the main page): Back alone, full width.
  Widget _actions() {
    final back = GestureDetector(
      onTap: _onBack,
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
            color: AppColors.darkGrey,
            borderRadius: BorderRadius.circular(6.r)),
        child: Center(
          child: Text('Back',
              style: StyleText.fontSize14Weight600
                  .copyWith(color: Colors.white)),
        ),
      ),
    );

    // Read-only: Back keeps the width and position it has next to Save — the
    // empty half is left empty rather than stretching the button across.
    if (!widget.showSave) {
      return Row(
        children: [
          Expanded(child: back),
          SizedBox(width: 300.w),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: back),
        SizedBox(width: 300.w),
        Expanded(
          child: GestureDetector(
            onTap: _isPublishing ? null : _onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44.h,
              decoration: BoxDecoration(
                  color: _isPublishing
                      ? ColorPick.primary.withValues(alpha: 0.5)
                      : ColorPick.primary,
                  borderRadius: BorderRadius.circular(6.r)),
              child: Center(
                child: _isPublishing
                    ? SizedBox(
                        width: 18.w,
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
    );
  }

  Widget _tab(String label, _PreviewDevice device) {
    final active = _device == device;
    return GestureDetector(
      onTap: () => setState(() => _device = device),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(label,
                style: StyleText.fontSize15Weight500.copyWith(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? ColorPick.primary : AppColors.secondaryText,
                )),
          ),
          Container(
              height: 2,
              width: label.length * 8.0,
              color: active ? ColorPick.primary : Colors.transparent),
        ],
      ),
    );
  }

  // Admin-only preview (no dependency on the website_app project).
  Widget _buildFrame(double containerW) {
    switch (_device) {
      case _PreviewDevice.desktop:
        return _DesktopFrame(
            containerWidth: containerW, model: widget.model, isAr: _isAr);
      case _PreviewDevice.tablet:
        return _TabletFrame(
            containerWidth: containerW, model: widget.model, isAr: _isAr);
      case _PreviewDevice.mobile:
        return _MobileFrame(
            containerWidth: containerW, model: widget.model, isAr: _isAr);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DEVICE FRAMES
// ═══════════════════════════════════════════════════════════════════════════════
