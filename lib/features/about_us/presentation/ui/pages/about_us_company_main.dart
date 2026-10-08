// ═══════════════════════════════════════════════════════════════════
// FILE 6: about_us_company_main.dart  (View Page) — UPDATED
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/admin_back_link.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/about_us_company_model.dart';
import '../../controller/about_us_company_cubit.dart';
import '../../controller/about_us_company_state.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';



// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color back      = Color(0xFFF1F2ED);
// }

class AboutCompanyMainPage extends StatefulWidget {
  const AboutCompanyMainPage({super.key});

  @override
  State<AboutCompanyMainPage> createState() => _AboutCompanyMainPageState();
}

class _AboutCompanyMainPageState extends State<AboutCompanyMainPage> {
  final Map<String, bool> _open = {
    'company_info': true,
  };

  @override
  void initState() {
    super.initState();
    context.read<AboutCompanyCubit>().loadAboutCompany();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AboutCompanyCubit, AboutCompanyState>(
      builder: (context, state) {
        if (state is AboutCompanyInitial || state is AboutCompanyLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.background,
            body: Center(
                child: CircleProgress()),
          );
        }

        AboutCompanyModel? data;
        if (state is AboutCompanyLoaded) data = state.data;
        if (state is AboutCompanySaved) data = state.data;
        if (state is AboutCompanyError) data = state.lastData;

        // Fallback
        data ??= AboutCompanyModel.empty();

        return Scaffold(
          backgroundColor: ColorPick.background,
          body: AdminStickyBody(
  children: [
                  AppAdminNavbar(
                    // BUG-26: About Company belongs to the Job Listing section.
                    activeLabel:    'Job Listing',
                    homePage:       CareersMainPageDashboard(),
                    // Web Page tab must open the Web Page section — pointing
                    // it at this page made the tab look dead.
                    webPage:        const MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),

                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 20.h),
                    child: SizedBox(
                      width: 1000.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BUG-26: breadcrumb back to Job Listing.
                          const AdminBackLink(
                            parentLabel: 'Job Listing',
                            parentRoute: '/jobs',
                          ),
                          // ── Title Row ──────────────────────────────
                          Row(
                            children: [
                              Text(
                                'About Company',
                                style:
                                StyleText.fontSize45Weight600.copyWith(
                                  color: ColorPick.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),

                              // ── Edit button ────────────────────────
                              GestureDetector(
                                onTap: () =>
                                    context.pushNamed('about-company-edit'),
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
                                      CustomSvg(assetPath: "assets/control/edit_icon_pick.svg",
                                          width: 20.w, height: 20.h,
                                          fit: BoxFit.scaleDown, color: ColorPick.primary),
                                    ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // ── Company Information Accordion ──────────
                          _accordion(
                            key: 'company_info',
                            title: 'Company Information',
                            children: [
                              _readOnlyCompanyInfoSection(data)
                            ],
                          ),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ],
),
        );
      },
    );
  }

  // ── Accordion ──────────────────────────────────────────────────────────────
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

  // ── Read-only Company Info ─────────────────────────────────────────────────
  Widget _readOnlyCompanyInfoSection(AboutCompanyModel data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.r),
          bottomRight: Radius.circular(6.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          _readField(
            'About Company',
            data.aboutEn.isEmpty ? 'Text Here' : data.aboutEn,
          ),
          SizedBox(height: 16.h),
          _readFieldRtl(
            'عن الشركة',
            data.aboutAr.isEmpty ? 'ادخل النص هنا' : data.aboutAr,
          ),
        ],
      ),
    );
  }

  // ── Read-only helpers ──────────────────────────────────────────────────────
  Widget _readField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: StyleText.fontSize12Weight500
              .copyWith(color: AppColors.text)),
      SizedBox(height: 4.h),
      Container(
        width: double.infinity,
        height: 80.h,
        padding:
        EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4.r),
        ),
        alignment: Alignment.topLeft,
        child: Text(
          value,
          style: StyleText.fontSize12Weight400
              .copyWith(color: AppColors.secondaryText),
          overflow: TextOverflow.ellipsis,
          maxLines: 4,
        ),
      ),
    ],
  );

  Widget _readFieldRtl(String label, String value) => Directionality(
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
          height: 80.h,
          padding: EdgeInsets.symmetric(
              horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4.r),
          ),
          alignment: Alignment.topRight,
          child: Text(
            value,
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText),
            overflow: TextOverflow.ellipsis,
            maxLines: 4,
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    ),
  );
}