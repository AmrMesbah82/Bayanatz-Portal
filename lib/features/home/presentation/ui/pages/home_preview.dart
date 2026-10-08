/// ******************* FILE INFO *******************
/// File Name: home_preview.dart
/// Page 7 — "Preview Home Details" (Figma screen 7)
/// Desktop / Tablet / Mobile tabs + ENG/AR chips
/// "Home View" accordion showing the REAL site Home page — navbar, hero,
/// cards and footer — via SiteHomePreview. It used to render an admin-side
/// copy of the hero and cards with no navbar and no footer.
/// FIXED: Device tabs restyled to match job_listing_detail_page tab bar pattern

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/constant/color.dart';
import '../../../../../core/widget/branding_helper.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/two_tab.dart';
import '../../../data/models/home_model.dart';
import '../../controller/home_cubit.dart';
import '../../controller/home_state.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';
import 'package:web_app_admin/core/site_preview/site_preview_frame.dart';


part '../widgets/home_preview/home_preview_builders.dart';
part '../widgets/home_preview/home_preview_cards.dart';

// BUG-15: referenced here (not only in the part file) so an IDE
// "Optimize Imports" can't drop the site_preview_frame import.
typedef _PreviewViewport = PreviewViewport;


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
// }

enum _Device { desktop, tablet, mobile }

// ─────────────────────────────────────────────────────────────────────────────
class HomePreviewPageMaster extends StatefulWidget {
  const HomePreviewPageMaster({super.key});
  @override
  State<HomePreviewPageMaster> createState() => _HomePreviewPageMasterState();
}

class _HomePreviewPageMasterState extends State<HomePreviewPageMaster> {
  _Device _device   = _Device.desktop;
  bool    _isSaving = false;
  bool    _homeViewOpen = true;

  /// The ENG / AR toggle above the preview belongs to THIS SCREEN ONLY.
  ///
  /// It used to drive the app-wide LanguageCubit, so flipping the preview to
  /// Arabic flipped the whole CMS to Arabic and left it that way after you
  /// navigated back. It is local state now — the preview shows the site in
  /// Arabic, the admin around it does not change.
  bool _isAr = false;

  Future<void> _publish(HomeCmsCubit cubit) async {
    setState(() => _isSaving = true);
    try {
      await cubit.save(publishStatus: 'published');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCmsCubit, HomeCmsState>(
      listener: (context, state) {
        if (state is HomeCmsSaved) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Published!',
                style: StyleText.fontSize14Weight400.copyWith(color: Colors.white)),
            backgroundColor: ColorPick.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ));
        }
        if (state is HomeCmsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${state.message}',
                style: StyleText.fontSize14Weight400.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        final cubit = context.read<HomeCmsCubit>();

        if (state is HomeCmsInitial || state is HomeCmsLoading) {
          return const Scaffold(
         
            body: Center(child: CircleProgress()),
          );
        }

        HomePageModel? data;
        if (state is HomeCmsLoaded) data = state.data;
        if (state is HomeCmsSaved)  data = state.data;

        // Language is preview-local — see the _isAr field above.
        return Builder(
          builder: (context) {
            final bool isAr = _isAr;

            return Scaffold(
              backgroundColor: ColorPick.white,
              body: AdminStickyBody(
  contentWidth: 1000.w,
  children: [
                            AppAdminNavbar(
                              activeLabel:    'Web Page',
                              homePage:       CareersMainPageDashboard(),
                              webPage:        MainMainPage(),
                              jobListingPage: JobListingMainPage(),
                            ),
                            SizedBox(height: 20.h),
                            AdminSubNavBar(
                              activeIndex: 1,
                              homeCubit: context.read<HomeCmsCubit>(),
                            ),

                            Container(
                              width: 1000.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20.h),

                                  Text('Preview Home Details',
                                    style: StyleText.fontSize45Weight600.copyWith(
                                      color: ColorPick.primary, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),

                                  // ── Device tabs + Language toggle ──────────
                                  Row(
                                    children: [
                                      _buildDeviceTabBar(),
                                      const Spacer(),
                                      CustomSegmentedTabs(
                                        tabs: ['ENG', 'AR'],
                                        selectedIndex: isAr ? 1 : 0,
                                        onTabSelected: (i) =>
                                            setState(() => _isAr = i == 1),
                                        selectedColor: ColorPick.primary,
                                        unselectedColor: Colors.transparent,
                                        selectedTextColor: Colors.white,
                                        unselectedTextColor: AppColors.text,
                                        containerColor: ColorPick.white.withValues(alpha: 0.45),
                                        equalWidth: false,
                                        containerPadding: EdgeInsets.symmetric(
                                            horizontal: 8.sp, vertical: 4.sp),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),

                                  // ── Home View accordion ───────────────────
                                  _homeViewAccordion(data, isAr),

                                  SizedBox(height: 24.h),

                                  // ── Bottom buttons ────────────────────────
                                  Row(children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => context.pop(),
                                        child: Container(
                                          height: 44.h,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(6.r),
                                          ),
                                          child: Center(
                                            child: Text('Back',
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
                                        onTap: _isSaving ? null : () => _publish(cubit),
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
                                                width: 18.w, height: 18.h,
                                                child: const CircleProgress())
                                                : Text('Publish',
                                                style: StyleText.fontSize14Weight600
                                                    .copyWith(color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                  SizedBox(height: 40.h),
                                ],
                              ),
                            ),
                          ],
),
            );
          },
        );
      },
    );
  }
}
