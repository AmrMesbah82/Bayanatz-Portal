// ******************* FILE INFO *******************
// File Name: strategy_preview.dart
// Screen 3 of 3 — Our Strategy CMS: Preview (Desktop/Tablet/Mobile + ENG/AR)
//
// REWRITTEN: the preview now draws the REAL public About Us page from
//            package:website_app, opened on its "Our Strategy" tab, instead of
//            the admin-styled accordions ("Strategic House - ENG / ARB") it used
//            to show. What the admin sees here is what a visitor sees.
//
//            Images picked in the edit screen are not in Firebase Storage yet,
//            so they reach the site through in-memory blob URLs — the preview
//            shows the picture just chosen, not the published one.
//
// Created by: Amr Mesbah

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:web_app_admin/core/custom/circle_progress.dart';
import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../../core/site_preview/site_preview_frame.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../../../core/two_tab.dart';
import '../../../../data/models/about_us_model.dart';
import '../../../controller/about_us_cubit.dart';
import '../../../controller/about_us_state.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';


// Upload keys written by strategy_edit.dart.
const String _kNavIconKey = 'strategy_cms/navLabel/icon';
const String _kEnDesktop  = 'strategy_cms/strategicHouse/en/desktop';
const String _kEnTablet   = 'strategy_cms/strategicHouse/en/tablet';
const String _kEnMobile   = 'strategy_cms/strategicHouse/en/mobile';
const String _kArDesktop  = 'strategy_cms/strategicHouse/ar/desktop';
const String _kArTablet   = 'strategy_cms/strategicHouse/ar/tablet';
const String _kArMobile   = 'strategy_cms/strategicHouse/ar/mobile';

// ═══════════════════════════════════════════════════════════════════════════════

class StrategyPreviewPage extends StatefulWidget {
  final OurStrategyModel model;
  final Map<String, Uint8List> imageUploads;

  /// Whether this preview can publish.
  ///
  /// The edit flow opens it with Save, because it is showing unsaved work. The
  /// "Preview Screen" button on the main page opens it read-only — you are
  /// looking at what is already live, so there is nothing to save.
  final bool showSave;

  const StrategyPreviewPage({
    super.key,
    required this.model,
    this.imageUploads = const {},
    this.showSave = true,
  });

  @override
  State<StrategyPreviewPage> createState() => _StrategyPreviewPageState();
}

class _StrategyPreviewPageState extends State<StrategyPreviewPage> {
  SitePreviewDevice _device       = SitePreviewDevice.desktop;
  bool              _isAr         = false;
  bool              _isPublishing = false;

  /// Freshly picked images, handed to the browser as blob: URLs so the site
  /// widgets load them exactly as they load a Storage URL. Revoked on dispose.
  final Map<String, String> _blobUrls = {};

  @override
  void initState() {
    super.initState();
    _makeBlobUrls();
  }

  @override
  void didUpdateWidget(covariant StrategyPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.imageUploads, oldWidget.imageUploads)) {
      _revokeBlobUrls();
      _makeBlobUrls();
    }
  }

  @override
  void dispose() {
    _revokeBlobUrls();
    super.dispose();
  }

  void _makeBlobUrls() {
    widget.imageUploads.forEach((key, bytes) {
      if (bytes.isEmpty) return;
      final blob = html.Blob(
        <dynamic>[bytes],
        _isSvgBytes(bytes) ? 'image/svg+xml' : 'application/octet-stream',
      );
      _blobUrls[key] = html.Url.createObjectUrlFromBlob(blob);
    });
  }

  void _revokeBlobUrls() {
    for (final url in _blobUrls.values) {
      html.Url.revokeObjectUrl(url);
    }
    _blobUrls.clear();
  }

  static bool _isSvgBytes(Uint8List b) {
    if (b.length < 5) return false;
    final head =
        String.fromCharCodes(b.sublist(0, b.length.clamp(0, 100))).trimLeft();
    return head.startsWith('<svg') || head.startsWith('<?xml');
  }

  /// The draft the site renders: the edited model with every image the user
  /// just picked swapped in, so nothing shows a stale published picture.
  OurStrategyModel get _draft {
    String pick(String key, String saved) => _blobUrls[key] ?? saved;

    final m = widget.model;
    return m.copyWith(
      navigationLabel: m.navigationLabel.copyWith(
        iconUrl: pick(_kNavIconKey, m.navigationLabel.iconUrl),
      ),
      strategicHouseEnDesktopUrl:
          pick(_kEnDesktop, m.strategicHouseEnDesktopUrl),
      strategicHouseEnTabletUrl: pick(_kEnTablet, m.strategicHouseEnTabletUrl),
      strategicHouseEnMobileUrl: pick(_kEnMobile, m.strategicHouseEnMobileUrl),
      strategicHouseArDesktopUrl:
          pick(_kArDesktop, m.strategicHouseArDesktopUrl),
      strategicHouseArTabletUrl: pick(_kArTablet, m.strategicHouseArTabletUrl),
      strategicHouseArMobileUrl: pick(_kArMobile, m.strategicHouseArMobileUrl),
    );
  }

  // ── Admin-only preview body ────────────────────────────────────────────────
  Widget _strategyPreview() {
    final d = _draft;
    final String url = switch (_device) {
      SitePreviewDevice.desktop =>
        _isAr ? d.strategicHouseArDesktopUrl : d.strategicHouseEnDesktopUrl,
      SitePreviewDevice.tablet =>
        _isAr ? d.strategicHouseArTabletUrl : d.strategicHouseEnTabletUrl,
      SitePreviewDevice.mobile =>
        _isAr ? d.strategicHouseArMobileUrl : d.strategicHouseEnMobileUrl,
    };
    final double maxW = switch (_device) {
      SitePreviewDevice.desktop => 1000.w,
      SitePreviewDevice.tablet  => 700.w,
      SitePreviewDevice.mobile  => 375.w,
    };
    return Center(
      child: Container(
        width: maxW,
        padding: EdgeInsets.all(20.sp),
        decoration: BoxDecoration(
          color: ColorPick.white,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Directionality(
          textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAr ? 'استراتيجيتنا' : 'Our Strategy',
                style: StyleText.fontSize18Weight500.copyWith(
                    color: ColorPick.primary, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16.h),
              url.isEmpty
                  ? SizedBox(
                      height: 200.h,
                      child: Center(
                        child: Text(
                          _isAr ? 'لا توجد صورة' : 'No image uploaded',
                          style: StyleText.fontSize12Weight400
                              .copyWith(color: AppColors.secondaryText),
                        ),
                      ),
                    )
                  : NetworkImageView(
                      url: url,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onBack() => Navigator.pop(context);

  void _onSave() {
    showPublishConfirmDialog(
      context: context,
      title: 'EDITING OUR STRATEGY DETAILS',
      subtitle: 'Do you want to save the changes made to this Our Strategy?',
      confirmLabel: 'Confirm',
      onConfirm: () async {
        setState(() => _isPublishing = true);
        try {
          await context.read<StrategyCubit>().save(
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<StrategyCubit, StrategyState>(
      listener: (context, state) {
        if (state is StrategySaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          });
        }
        if (state is StrategyError) {
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
              child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
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
                SizedBox(height: 25.h),
                Text(
                  'Preview Our Strategy Details',
                  style: StyleText.fontSize45Weight600.copyWith(
                    color: ColorPick.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Device tabs + Language toggle ──────────────────────────
                Row(
                  children: [
                    _tab('Desktop', SitePreviewDevice.desktop),
                    SizedBox(width: 24.w),
                    _tab('Tablet', SitePreviewDevice.tablet),
                    SizedBox(width: 24.w),
                    _tab('Mobile', SitePreviewDevice.mobile),
                    const Spacer(),
                    SizedBox(
                      width: 95.w,
                      height: 36.h,
                      child: CustomSegmentedTabs(
                        tabs: const ['ENG', 'AR'],
                        selectedIndex: _isAr ? 1 : 0,
                        onTabSelected: (i) => setState(() => _isAr = i == 1),
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

                // ── The real site, on its Our Strategy tab ─────────────────
                // Admin-only preview (no dependency on the website_app project):
                // the Strategic House image for the selected device + language.
                _strategyPreview(),

                SizedBox(height: 24.h),

                // ── Back (+ Save, only when there is unsaved work) ─────────
                _actions(),
                SizedBox(height: 40.h),
              ],
            ),
          ),

          if (_isPublishing)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircleProgress()),
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

  // ── Device tab widget ──────────────────────────────────────────────────────
  Widget _tab(String label, SitePreviewDevice device) {
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
}
