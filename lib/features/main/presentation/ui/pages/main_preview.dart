/// ******************* FILE INFO *******************
/// File Name: main_preview.dart
/// UPDATED: The preview frame now renders the REAL public-site widgets from
///          `package:website_app` (AppNavbar / AppFooter) instead of the
///          admin's own copies, fed by the Main draft through
///          [SitePreviewScope]. What you see here is literally the site's own
///          code — it can no longer drift from production.
/// UPDATED: Tablet tab now uses a real 768×1024 viewport. It previously used
///          1024×768, which is exactly the width at which the site switches to
///          its DESKTOP navbar and footer — so the Tablet tab rendered a page
///          identical to the Desktop tab.
/// UPDATED: The ENG / AR toggle is PREVIEW-LOCAL. It no longer drives the
///          app-wide LanguageCubit (which used to leave the whole CMS in
///          Arabic after you left this screen); isRtl is passed straight to
///          SiteShellPreview, which feeds the site's own LanguageCubit inside
///          SitePreviewScope.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:web_app_admin/core/custom_dialog.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/site_preview/site_shell_preview.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/two_tab.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../home/presentation/controller/home_cubit.dart';
import '../../../../home/presentation/controller/home_state.dart';
import '../../controller/main_cubit.dart';
import '../../controller/main_state.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import 'main_main.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

// The real site shell (website_app's AppNavbar + AppFooter) lives in
// core/site_preview/site_shell_preview.dart, which owns its own website_app
// imports — see the note in that file for why they must not live here.

part '../widgets/main_preview/preview_content.dart';
part '../widgets/main_preview/mobile_phone_shell.dart';

enum _PreviewDevice { desktop, tablet, mobile }

// ── Phone shell constants ─────────────────────────────────────────────────────
const double _kPhoneShellW = 300.0;
const double _kFakeMobileW = 375.0;
const double _kFakeMobileH = 812.0;

// ── Fake viewports — must match the site's own breakpoints ────────────────────
// The site switches to its DESKTOP navbar and footer at width >= 1024
// (AppNavbar._BP.tablet and AppFooter._BP.tablet are both 1024), so a 1024-wide
// "Tablet" frame sat exactly ON the desktop side of the boundary and rendered
// an identical page to the Desktop tab. The site's tablet band is 768–1023, and
// website_app's own _getDesignSize returns 768×1024 for a portrait tablet — so
// that is the viewport the Tablet tab simulates.
const double _kFakeDesktopW = 1366.0;
const double _kFakeDesktopH =  768.0;
const double _kFakeTabletW  =  768.0;
const double _kFakeTabletH  = 1024.0;

class MainPreviewPage extends StatefulWidget {
  const MainPreviewPage({super.key, this.showPublish = true});

  /// Whether this preview may publish.
  ///
  /// The page is reached two ways, and only one of them is an editing flow:
  ///   • Edit Details → Preview  → you are reviewing your own unsaved changes,
  ///     so Publish belongs here (the default).
  ///   • Main → "Preview Screen" → you are just LOOKING at what is already
  ///     live. There is nothing to publish, and offering the button invites
  ///     re-publishing untouched content by accident, so it is hidden and Back
  ///     takes the full row.
  final bool showPublish;

  @override
  State<MainPreviewPage> createState() => _MainPreviewPageState();
}

class _MainPreviewPageState extends State<MainPreviewPage> {
  _PreviewDevice _device   = _PreviewDevice.desktop;
  bool           _isSaving = false;

  /// The ENG / AR toggle above the preview belongs to THIS SCREEN ONLY.
  ///
  /// It used to drive the app-wide LanguageCubit, so flipping the preview to
  /// Arabic flipped the whole CMS to Arabic and left it that way after you
  /// navigated back. It is local state now: it is handed to SiteShellPreview,
  /// which feeds the site's OWN LanguageCubit inside SitePreviewScope, so the
  /// preview renders RTL while the admin around it is untouched.
  bool           _isRtl    = false;

  Future<void> _publish(MainCmsCubit cubit) async {
    setState(() => _isSaving = true);
    try {
      // Main navbar items are saved with the rest of the Main doc — they no
      // longer touch the HOME doc (that's a separate feature).
      await cubit.save(publishStatus: 'published');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainCmsCubit, MainCmsState>(
      listener: (context, state) {},
      builder: (context, state) {
        final cubit = context.read<MainCmsCubit>();

        if (state is MainCmsInitial || state is MainCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.background,
            body: Center(child: CircleProgress()),
          );
        }

        // Language is preview-local — see the _isRtl field above.
        return Builder(
          builder: (context) {
            final bool isRtl = _isRtl;

            return Stack(
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
                                AdminSubNavBar(activeIndex: 0),
                                // ── Page title ──────────────────────────────
                                Text(
                                  'Preview Main Details',
                                  style: StyleText.fontSize45Weight600.copyWith(
                                    color: ColorPick.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 16.h),

                                // ── Device tabs + language toggle ────────────
                                Row(
                                  children: [
                                    _deviceTab('Desktop', _PreviewDevice.desktop),
                                    SizedBox(width: 20.w),
                                    _deviceTab('Tablet',  _PreviewDevice.tablet),
                                    SizedBox(width: 20.w),
                                    _deviceTab('Mobile',  _PreviewDevice.mobile),
                                    const Spacer(),

                                    CustomSegmentedTabs(
                                      tabs: ['ENG', 'AR'],
                                      selectedIndex: isRtl ? 1 : 0,
                                      onTabSelected: (i) =>
                                          setState(() => _isRtl = i == 1),
                                      selectedColor:       ColorPick.primary,
                                      unselectedColor:     Colors.transparent,
                                      selectedTextColor:   Colors.white,
                                      unselectedTextColor: AppColors.text,
                                      containerColor:
                                      ColorPick.white.withValues(alpha: 0.45),
                                      equalWidth: false,
                                      containerPadding: EdgeInsets.symmetric(
                                          horizontal: 8.sp, vertical: 4.sp),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),

                                // ── Preview frame ────────────────────────────
                                LayoutBuilder(
                                  builder: (ctx, constraints) => _previewFrame(
                                    constraints.maxWidth,
                                    isRtl: isRtl,
                                  ),
                                ),

                                SizedBox(height: 24.h),

                                // ── Back (+ Publish, only in the edit flow) ──
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => context.pop(),
                                        child: Container(
                                          height: 44.h,
                                          decoration: BoxDecoration(
                                            color: AppColors.darkGrey,
                                            borderRadius:
                                            BorderRadius.circular(6.r),
                                          ),
                                          child: Center(
                                            child: Text('Back',
                                                style: StyleText
                                                    .fontSize14Weight600
                                                    .copyWith(
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Nothing to publish when the page was
                                    // opened from "Preview Screen" — see
                                    // MainPreviewPage.showPublish.
                                    if (widget.showPublish) ...[
                                    SizedBox(width: 400.w),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _isSaving
                                            ? null
                                            : () => showPublishConfirmDialog(
                                          context: context,
                                          onConfirm: () =>
                                              _publish(cubit),
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          height: 44.h,
                                          decoration: BoxDecoration(
                                            color: _isSaving
                                                ? ColorPick.primary.withValues(alpha: 0.5)
                                                : ColorPick.primary,
                                            borderRadius:
                                            BorderRadius.circular(6.r),
                                          ),
                                          child: Center(
                                            child: _isSaving
                                                ? SizedBox(
                                              width:  18.w,
                                              height: 18.h,
                                              child:
                                              const CircleProgress(),
                                            )
                                                : Text('Publish',
                                                style: StyleText
                                                    .fontSize14Weight600
                                                    .copyWith(
                                                    color:
                                                    Colors.white)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 40.h),
                              ],
),
                ),

                if (_isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                        child: CircleProgress()),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Device tab ──────────────────────────────────────────────────────────────
  Widget _deviceTab(String label, _PreviewDevice device) {
    final active = _device == device;
    return GestureDetector(
      onTap: () => setState(() => _device = device),
      child: Text(
        label,
        style: active
            ? StyleText.fontSize14Weight600.copyWith(
          color:           ColorPick.primary,
          decoration:      TextDecoration.underline,
          decorationColor: ColorPick.primary,
        )
            : StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
      ),
    );
  }

  // ── Preview frame dispatcher ────────────────────────────────────────────────
  Widget _previewFrame(double containerWidth, {required bool isRtl}) {
    if (_device == _PreviewDevice.mobile) {
      return _MobilePhoneShell(
          containerWidth: containerWidth, isRtl: isRtl);
    }

    // Desktop and Tablet cross different breakpoints on the real site, so they
    // must be previewed at different viewport widths.
    final bool isTablet = _device == _PreviewDevice.tablet;
    final double fakeW = isTablet ? _kFakeTabletW : _kFakeDesktopW;
    final double fakeH = isTablet ? _kFakeTabletH : _kFakeDesktopH;

    final double scale  = _safeScale(containerWidth / fakeW);
    final double outerH = fakeH * scale;

    return SizedBox(
      width:  double.infinity,
      height: outerH,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth:  fakeW,
          maxHeight: fakeH,
          child: Transform.scale(
            scale:     scale,
            alignment: Alignment.topLeft,
            child: SiteShellPreview(
              fakeWidth:  fakeW,
              fakeHeight: fakeH,
              isRtl:      isRtl,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Safe scale helper ─────────────────────────────────────────────────────────
double _safeScale(double v) =>
    (v.isFinite && !v.isNaN && v > 0) ? v : 1.0;

// The draft accessor and hex helper moved into SiteShellPreview so that every
// preview page can reuse them without copying code.
