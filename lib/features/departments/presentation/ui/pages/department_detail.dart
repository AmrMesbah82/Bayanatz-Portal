// ═══════════════════════════════════════════════════════════════════
// department_detail.dart  (Detail / View Page)
// Path: lib/features/departments/presentation/ui/pages/department_detail.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/main_widgets/admin_back_link.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';


import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../../job/data/models/job_listing_model.dart';
import '../../../../job/presentation/controller/job_listing_cubit.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/department_model.dart';
import 'department_edit.dart';
//
// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
// }

class DepartmentDetailPage extends StatefulWidget {
  final DepartmentModel department;

  const DepartmentDetailPage({super.key, required this.department});

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  DepartmentModel get department => widget.department;

  bool _infoOpen = true;

  @override
  void initState() {
    super.initState();
    // Opened directly (deep link / refresh) → make sure jobs are available.
    final jobCubit = context.read<JobListingCubit>();
    if (jobCubit.allJobs.isEmpty) jobCubit.loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    // `watch`, not `read`: rebuild once the jobs finish loading.
    final allJobs = context.watch<JobListingCubit>().allJobs;

    final deptJobs = allJobs
        .where((j) => department.matchesJob(j.department))
        .toList();

    final totalCount    = deptJobs.length;
    final activeCount   = deptJobs.where((j) => j.status == JobStatus.active).length;
    final inactiveCount = deptJobs.where((j) => j.status == JobStatus.inactive).length;

    return Scaffold(
      backgroundColor: ColorPick.background,
      body: AdminStickyBody(
  children: [
              AppAdminNavbar(
                activeLabel:    'Job Listing',
                homePage:       CareersMainPageDashboard(),
                webPage:        MainMainPage(),
                jobListingPage: JobListingMainPage(),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h) /* BUG-286: same title position as every page */,
                child: SizedBox(
                  width: 1000.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BUG-298: same back link as About Company.
                      const AdminBackLink(parentLabel: 'Our Departments', parentRoute: '/jobs/departments'),
                      // ── Title + Edit (BUG-299: Edit sits on the title row,
                      // same position as About Company / Main page) ──
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Department Details',
                              style: StyleText.fontSize45Weight600.copyWith(
                                color: ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToEdit,
                            child: Container(
                              width: 130.w, height: 36.h,
                              decoration: BoxDecoration(
                                color: ColorPick.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Edit Details',
                                      style: StyleText.fontSize14Weight500
                                          .copyWith(color: Colors.black),
                                    ),
                                    SizedBox(width: 6.w),
                                    CustomSvg(
                                      assetPath: 'assets/control/edit_icon_pick.svg',
                                      width: 20.w, height: 20.h,
                                      fit: BoxFit.scaleDown,
                                      color: ColorPick.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // ── Accordion card ──
                      CustomAccordion(
                        title:    'Department Information',
                        isOpen:   _infoOpen,
                        onToggle: () => setState(() => _infoOpen = !_infoOpen),
                        child: _detailContent(context, department,
                            totalCount, activeCount, inactiveCount),
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
),
    );
  }

  void _goToEdit() => navigateTo(
        context,
        DepartmentEditPage(department: department),
      );

  Widget _detailContent(
      BuildContext context,
      DepartmentModel dept,
      int total,
      int active,
      int inactive,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),

        // ── BUG-86: Department Image ──
        Text('Department Image',
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.text)),
        SizedBox(height: 8.h),
        Container(
          width: 64.w,
          height: 64.h,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white),
          child: ClipOval(
            child: dept.iconUrl.isNotEmpty
                ? NetworkImageView(
                    url: dept.iconUrl,
                    width: 64.w,
                    height: 64.h,
                    fit: BoxFit.cover)
                : Icon(Icons.image_outlined,
                    color: Colors.grey[500], size: 28.sp),
          ),
        ),
        SizedBox(height: 20.h),

        // ── Names row ──
        Row(
          children: [
            Expanded(child: _readField('Department Name', dept.nameEn)),
            SizedBox(width: 15.w),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _readField('اسم القسم', dept.nameAr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _readField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.text)),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color:  Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count, String svgPath) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            CustomSvg(
                assetPath: svgPath,
                width: 16.sp,
                height: 16.sp,
                fit: BoxFit.contain),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}