// ═══════════════════════════════════════════════════════════════════
// FILE 6: department_main.dart (View Page)
// Path: lib/features/departments/presentation/ui/pages/department_main.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../../../core/widget/success_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/features/main/presentation/controller/main_cubit.dart';
import 'package:web_app_admin/features/main/presentation/controller/main_state.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_layout.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../home/presentation/controller/home_cubit.dart';
import '../../../../home/presentation/controller/home_state.dart';
import '../../../../job/data/models/job_listing_model.dart';
import '../../../../job/presentation/controller/job_listing_cubit.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/department_model.dart';
import '../../controller/department_cubit.dart';
import '../../controller/department_state.dart';
import 'department_create.dart';
import 'department_detail.dart';   // ← NEW
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/department_main/department_card.dart';

// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
// }

class DepartmentMainPage extends StatefulWidget {
  const DepartmentMainPage({super.key});

  @override
  State<DepartmentMainPage> createState() => _DepartmentMainPageState();
}

class _DepartmentMainPageState extends State<DepartmentMainPage> {
  @override
  void initState() {
    super.initState();
    context.read<DepartmentCubit>().loadDepartments();
    final jobCubit = context.read<JobListingCubit>();
    if (jobCubit.allJobs.isEmpty) jobCubit.loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DepartmentCubit, DepartmentState>(
      listener: (context, state) {
        if (state is DepartmentCreated) {
          // Close the Create page — only if something is above this page.
          final route = ModalRoute.of(context);
          if (route != null && !route.isCurrent &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          // BUG-46: confirm the save — root-overlay toast, so it is still
          // visible after the Create page closes (the SnackBar was not).
          showSuccessToast(context, 'Department created');
          context.read<DepartmentCubit>().loadDepartments(silent: true);
        }
        // Updated / Deleted: the Edit page closes itself (it used to be
        // popped here AND there, which also closed this page).
        if (state is DepartmentUpdated || state is DepartmentDeleted) {
          context.read<DepartmentCubit>().loadDepartments(silent: true);
        }
      },
      child: BlocBuilder<DepartmentCubit, DepartmentState>(
        builder: (context, state) {
          if (state is DepartmentInitial || state is DepartmentLoading) {
            return const Scaffold(
              backgroundColor: ColorPick.background,
              body: Center(child: CircleProgress()),
            );
          }

          List<DepartmentModel> departments = [];
          if (state is DepartmentLoaded) departments = state.departments;
          if (state is DepartmentError && state.lastDepartments != null) {
            departments = state.lastDepartments!;
          }

          // `watch`, not `read`: jobs are fetched asynchronously, so this page
          // must rebuild when JobListingCubit finishes loading — otherwise the
          // card counts stay at 0 forever.
          final allJobs = context.watch<JobListingCubit>().allJobs;

          return Scaffold(
            backgroundColor: ColorPick.background,
            body: AdminStickyBody(
                reflowOnPhone: true, // BUG-16
  children: [
                    AppAdminNavbar(
                      activeLabel:    'Job Listing',
                      homePage:       CareersMainPageDashboard(),
                      webPage:        MainMainPage(),
                      jobListingPage: JobListingMainPage(),
                    ),
                    SizedBox(height: 20.h),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AdminLayout.sidePadding(context), vertical: 20.h),
                      child: SizedBox(
                        width: AdminLayout.contentWidth(context), // BUG-16
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Our Departments',
                              style: StyleText.fontSize45Weight600.copyWith(
                                color:      ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // ── Create Department button ──
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => navigateTo(
                                    context, const DepartmentCreatePage()),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color:        ColorPick.primary,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomSvg(assetPath: "assets/department.svg",color: Colors.white,),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Create Department', // BUG-41: was 'Departments'
                                        style: StyleText.fontSize12Weight500
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // ── Department Grid ──
                            // BUG-57: CustomSvg(assetPath: '') threw JS
                            // errors and showed nothing. Real empty state now.
                            if (departments.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.sp),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomSvg(
                                        assetPath: 'assets/images/null.svg',
                                        width:  150.w,
                                        height: 150.h,
                                        fit:    BoxFit.contain,
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'No departments yet — click "Create Department" to add one.',
                                        textAlign: TextAlign.center,
                                        style: StyleText.fontSize14Weight500
                                            .copyWith(color: AppColors.text),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              _buildGrid(departments, allJobs),

                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ],
),
          );
        },
      ),
    );
  }

  // ── Grid (3 columns) ──────────────────────────────────────────────────────
  Widget _buildGrid(
      List<DepartmentModel> depts, List<JobPostModel> allJobs) {
    // BUG-16: one department per row on a phone.
    final int cols = AdminLayout.isPhone(context) ? 1 : 3;
    final rows = (depts.length / cols).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final start = rowIndex * cols;
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(cols, (colIndex) {
                final i = start + colIndex;
                if (i >= depts.length) {
                  return const Expanded(child: SizedBox());
                }
                return Expanded(
                  child: Padding(
                    padding:
                    EdgeInsets.only(right: colIndex < cols - 1 ? 12.w : 0),
                    child: _DepartmentCard(
                      department: depts[i],
                      allJobs:    allJobs,
                      // ── tap → detail page ──
                      onTap: () => navigateTo(
                        context,
                        DepartmentDetailPage(department: depts[i]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  DEPARTMENT CARD
// ═════════════════════════════════════════════════════════════════════════════
