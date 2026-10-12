// ******************* FILE INFO *******************
// File Name: terms_preview.dart
// Screen 3 of 3 — Terms of Service CMS: Preview
//
// REWRITTEN: the preview now draws the REAL public About Us page from
//            package:website_app, opened on its "Terms and Conditions" or
//            "Privacy Policy" tab, instead of the hand-copied admin frames it
//            used to show. What the admin sees here is what a visitor sees.
//
//            Section icons picked in the edit screen are not in Firebase
//            Storage yet, so they reach the site through in-memory blob URLs.
//            Newly attached PDFs are only linked after they are saved.
//
// Created by: Amr Mesbah

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
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

// ── Dead code, kept only so these files still belong to a library ────────────
// The hand-copied frames this screen used before it rendered the real site.
// They compile but nothing here uses them; delete the files and these four
// directives together when you're ready.
part '../../widgets/terms_preview/a_c.dart';
part '../../widgets/terms_preview/desktop_frame.dart';
part '../../widgets/terms_preview/tablet_frame.dart';
part '../../widgets/terms_preview/mobile_frame.dart';
part '../../widgets/terms_preview/terms_preview_content.dart';
part '../../widgets/terms_preview/browser_chrome.dart';


// Upload keys written by terms_edit.dart.
const String _kTermsIconKey   = 'terms_cms/terms/icon';
const String _kPrivacyIconKey = 'terms_cms/privacy/icon';

class TermsPreviewPage extends StatefulWidget {
  final TermsOfServiceModel    model;
  final Map<String, Uint8List> imageUploads;
  final Map<String, DocUpload> docUploads;

  /// Whether this preview can publish.
  ///
  /// The edit flow opens it with Save, because it is showing unsaved work. The
  /// "Preview Screen" button on the main page opens it read-only — you are
  /// looking at what is already live, so there is nothing to save.
  final bool showSave;

  const TermsPreviewPage({
    super.key,
    required this.model,
    this.imageUploads = const {},
    this.docUploads   = const {},
    this.showSave     = true,
  });

  @override
  State<TermsPreviewPage> createState() => _TermsPreviewPageState();
}

class _TermsPreviewPageState extends State<TermsPreviewPage> {
  SitePreviewDevice _device       = SitePreviewDevice.desktop;
  bool              _isAr         = false;
  bool              _isPublishing = false;

  /// Which of the two documents the preview is showing.
  int _sectionTab = 0; // 0 = Terms and Conditions · 1 = Privacy Policy

  /// Freshly picked icons, handed to the browser as blob: URLs so the site
  /// widgets load them exactly as they load a Storage URL. Revoked on dispose.
  final Map<String, String> _blobUrls = {};

  @override
  void initState() {
    super.initState();
    _makeBlobUrls();
  }

  @override
  void didUpdateWidget(covariant TermsPreviewPage oldWidget) {
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

  /// The draft the site renders: the edited model with the icons just picked
  /// swapped in, so nothing shows a stale published one.
  TermsOfServiceModel get _draft {
    final m = widget.model;
    final String? termsIcon   = _blobUrls[_kTermsIconKey];
    final String? privacyIcon = _blobUrls[_kPrivacyIconKey];

    return m.copyWith(
      termsAndConditions: termsIcon == null
          ? m.termsAndConditions
          : m.termsAndConditions.copyWith(iconUrl: termsIcon),
      privacyPolicy: privacyIcon == null
          ? m.privacyPolicy
          : m.privacyPolicy.copyWith(iconUrl: privacyIcon),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onBack() => Navigator.pop(context);

  void _onSave() {
    showPublishConfirmDialog(
      context: context,
      title: 'EDITING TERMS OF SERVICE DETAILS',
      subtitle: 'Do you want to save the changes made to Terms and Conditions?',
      confirmLabel: 'Confirm',
      onConfirm: () async {
        setState(() => _isPublishing = true);
        try {
          await context.read<TermsCubit>().save(
                model:        widget.model,
                imageUploads: widget.imageUploads.isEmpty ? null : widget.imageUploads,
                docUploads:   widget.docUploads.isEmpty   ? null : widget.docUploads,
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
    return BlocListener<TermsCubit, TermsState>(
      listener: (context, state) {
        if (state is TermsSaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          });
        }
        if (state is TermsError) {
          setState(() => _isPublishing = false);
          showConfirmDialog(
            context: context,
            title: 'Error',
            subtitle: state.message,
            confirmLabel: 'OK',
            cancelLabel: '',
            onConfirm: () {},
            iconWidget: Container(
              width: 60.r, height: 60.r,
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
                Text(
                  'Preview Terms and Conditions Details',
                  style: StyleText.fontSize45Weight600.copyWith(
                      color: ColorPick.primary, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),

                // ── Device tabs + Language toggle ──────────────────────────
                Row(
                  children: [
                    _tab('Desktop', SitePreviewDevice.desktop),
                    SizedBox(width: 24.w),
                    _tab('Tablet',  SitePreviewDevice.tablet),
                    SizedBox(width: 24.w),
                    _tab('Mobile',  SitePreviewDevice.mobile),
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
                SizedBox(height: 12.h),

                // ── Which of the two documents to show ─────────────────────
                // The preview does not take taps (the site's links would pull
                // the admin off this screen), so the tab is picked here.
                SizedBox(
                  width: 260.w,
                  height: 36.h,
                  child: CustomSegmentedTabs(
                    tabs: const ['Terms and Conditions', 'Privacy Policy'],
                    selectedIndex: _sectionTab,
                    onTabSelected: (i) => setState(() => _sectionTab = i),
                    selectedColor: ColorPick.primary,
                    unselectedColor: Colors.white,
                    selectedTextColor: Colors.white,
                    unselectedTextColor: AppColors.text,
                    equalWidth: false,
                    containerPadding:
                        EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  ),
                ),
                SizedBox(height: 16.h),

                // ── The real site, on the selected tab ─────────────────────
                // Admin-only preview (no dependency on the website_app project).
                LayoutBuilder(builder: (ctx, box) {
                  final double w = box.maxWidth;
                  switch (_device) {
                    case SitePreviewDevice.desktop:
                      return _DesktopFrame(
                          containerWidth: w,
                          model: _draft,
                          imageUploads: widget.imageUploads,
                          isAr: _isAr);
                    case SitePreviewDevice.tablet:
                      return _TabletFrame(
                          containerWidth: w,
                          model: _draft,
                          imageUploads: widget.imageUploads,
                          isAr: _isAr);
                    case SitePreviewDevice.mobile:
                      return _MobileFrame(
                          containerWidth: w,
                          model: _draft,
                          imageUploads: widget.imageUploads,
                          isAr: _isAr);
                  }
                }),

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

  // ── Bottom actions ────────────────────────────────────────────────────────
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
                        width: 18.w, height: 18.h,
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

  // ── Device tab widget ─────────────────────────────────────────────────────
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
            color: active ? ColorPick.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
