// ******************* FILE INFO *******************
// File Name: job_listing_main.dart
// Created by: Amr Mesbah
// Purpose: Job Listing main page — hero + filter tabs + job cards grid
// UPDATED: Uses Firebase via JobListingCubit.loadJobs() — no static data
// UPDATED: Uses AppSearchTextField, customButtonWithImage, SVG assets
// FIXED: BlocListener handles JobListingSaved — pops edit page + reloads list
// FIXED: initState reloads on JobListingSaved state too
// FIXED: Card tap navigates to JobListingDetailPage with jobId
// FIXED: Filter button opens showJobListingFilterDialog + applies result

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/constant/job_status_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/button.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/core/widget/search.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_layout.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/job_listing_filter_dialog.dart';
import '../../../../departments/presentation/controller/department_cubit.dart';
import '../../../../departments/presentation/controller/department_state.dart';
import '../../../../departments/data/models/department_model.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../departments/presentation/ui/pages/department_main.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/job_listing_model.dart';
import '../../controller/job_listing_cubit.dart';
import '../../controller/job_listing_state.dart';
import 'job_listing_detail.dart';
import 'job_listing_edit.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/widget/empty_lottie.dart'; // QA-Oct11 #24

part '../widgets/job_listing_main/svg.dart';
part '../widgets/job_listing_main/job_card.dart';
part '../widgets/job_listing_main/company_logo.dart';

// ── SVG asset paths ──────────────────────────────────────────────────────────

class JobListingMainPage extends StatefulWidget {
  const JobListingMainPage({super.key});

  @override
  State<JobListingMainPage> createState() => _JobListingMainPageState();
}

class _JobListingMainPageState extends State<JobListingMainPage> {
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'All', 'Active', 'Inactive', 'Ended', 'Scheduled', 'Drafted', 'Removed',
  ];

  // ── Track advanced filter state ────────────────────────────────────────────
  JobListingFilterData? _advancedFilter;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<JobListingCubit>();
    if (cubit.state is JobListingInitial || cubit.state is JobListingSaved) {
      cubit.loadJobs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getLogoUrl(BuildContext context) {
    try {
      final homeState = context.read<MainCmsCubit>().state;
      if (homeState is MainCmsLoaded) return homeState.data.branding.logoUrl;
      if (homeState is MainCmsSaved) return homeState.data.branding.logoUrl;
    } catch (_) {}
    return '';
  }

  // ── Branding primary color from CMS model data ────────────────────────────
  Color _getPrimaryColor(BuildContext context) {
    try {
      final homeState = context.read<MainCmsCubit>().state;
      final String hex = switch (homeState) {
        MainCmsLoaded(:final data) => data.branding.primaryColor,
        MainCmsSaved(:final data)  => data.branding.primaryColor,
        _                          => '',
      };
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {}
    return ColorPick.primary; // fallback
  }

  // ── Open filter dialog ─────────────────────────────────────────────────────
  Future<void> _openFilterDialog() async {
    // BUG-43 / BUG-54: offer the REAL departments and locations. The dialog
    // used to fall back to a fixed fake list (Engineering, Design… /
    // Cairo, Alexandria, Giza), so real departments could never be picked.
    final jobs = context.read<JobListingCubit>().allJobs;
    final deptNames = <String>{};
    bool deptListKnown = false;
    try {
      final cubit = context.read<DepartmentCubit>();
      final ds = cubit.state;
      final list = ds is DepartmentLoaded
          ? ds.departments
          : (ds is DepartmentError ? (ds.lastDepartments ?? const <DepartmentModel>[]) : const <DepartmentModel>[]);
      if (ds is DepartmentLoaded || list.isNotEmpty) deptListKnown = true;
      deptNames.addAll(
          list.map((d) => d.nameEn.trim()).where((n) => n.isNotEmpty));
    } catch (_) {}
    // BUG-54 (re-test): DELETED departments were still offered because every
    // name any (removed) job ever used was added. Only when the department
    // list is not available yet do we fall back to names of live jobs.
    if (!deptListKnown) {
      deptNames.addAll(jobs
          .where((j) => j.status != JobStatus.removed)
          .map((j) => j.department.trim())
          .where((n) => n.isNotEmpty));
    }
    final depts = (deptNames.toList()..sort())
        .map((n) => {'key': n, 'value': n})
        .toList();

    final locationNames = jobs
        .where((j) => j.workType != WorkType.remote)
        .map((j) => j.location.trim())
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final locations = [
      ...locationNames.map((l) => {'key': l, 'value': l}),
      if (jobs.any((j) => j.workType == WorkType.remote))
        {'key': 'remote', 'value': 'Remote'},
    ];

    final result = await showJobListingFilterDialog(
      context,
      initial: _advancedFilter,
      departments: depts,
      locations: locations,
    );
    if (result != null) {
      setState(() => _advancedFilter = result);
      context.read<JobListingCubit>().applyAdvancedFilter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobListingCubit, JobListingState>(
      listener: (context, state) {
        if (state is JobListingSaved) {
          // BUG-10 (white screen): this listener used to pop WHATEVER route
          // was on top, from every mounted Job Listing page. The edit page now
          // closes itself after a successful save, so we only refresh here.
          context.read<JobListingCubit>().loadJobs();
        }
      },
      child: BlocBuilder<JobListingCubit, JobListingState>(
        builder: (context, state) {
          if (state is JobListingInitial || state is JobListingLoading) {
            return const Scaffold(
              backgroundColor: ColorPick.background,
              body: Center(child: CircleProgress()),
            );
          }

          final cubit = context.read<JobListingCubit>();
          List<JobPostModel> jobs = [];
          String activeFilter = 'All';

          if (state is JobListingLoaded) {
            jobs = state.filteredJobs;
            activeFilter = state.activeFilter;
          }

          if (state is JobListingError) {
            if (state.lastJobs != null && state.lastJobs!.isNotEmpty) {
              jobs = state.lastJobs!;
            }
          }

          final logoUrl = _getLogoUrl(context);

          return Scaffold(
            backgroundColor: ColorPick.background,
            body: AdminStickyBody(
                reflowOnPhone: true, // BUG-16: real phone layout
  children: [
                    AppAdminNavbar(
                      activeLabel:    'Job Listing',
                      homePage:       CareersMainPageDashboard(),
                      webPage:        MainMainPage(),
                      jobListingPage: JobListingMainPage(),

                    ),


                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AdminLayout.sidePadding(context), vertical: 20.h),
                      child: SizedBox(
                        width: AdminLayout.contentWidth(context), // BUG-16
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Hero ──────────────────────────────────
                            _buildHeroSection(),
                            SizedBox(height: 20.h),

                            // ── Action buttons row ────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    customButtonWithImage(
                                      title: 'About Company',
                                      function: () {
                                        // Named route (not Navigator.push) so
                                        // the URL changes and browser Back
                                        // returns to this page.
                                        context.pushNamed('about-company');
                                      },
                                      textStyle: StyleText.fontSize12Weight500.copyWith(color: Colors.white),
                                      height: 36.h,
                                      space: 6,
                                      radius: 6,
                                      width: 130.w,
                                      color: ColorPick.primary,
                                      image: 'assets/images/job_list/about.svg',
                                      widthImage: 16.w,
                                      heightImage: 16.h,
                                      colorBorder: ColorPick.primary,
                                      svgColor: Colors.white,
                                    ),
                                    SizedBox(height: 15.h),
                                    customButtonWithImage(
                                      title: 'Departments',
                                      // BUG-119: named route → URL + Back work.
                                      function: () {
                                        context.pushNamed('departments');
                                      },
                                      textStyle: StyleText.fontSize12Weight500.copyWith(color: Colors.white),
                                      height: 36.h,
                                      width: 120.w,
                                      space: 6,
                                      radius: 6,
                                      color: ColorPick.primary,
                                      image: 'assets/images/job_list/department.svg',
                                      widthImage: 16.w,
                                      heightImage: 16.h,
                                      colorBorder: ColorPick.primary,
                                      svgColor: Colors.white,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                customButtonWithImage(
                                  title: 'Post Job',
                                  function: () => context.pushNamed('job-new'), // BUG-119
                                  textStyle: StyleText.fontSize12Weight500.copyWith(color: Colors.white),
                                  height: 36.h,
                                  space: 6,
                                  radius: 6,
                                  color: ColorPick.primary,
                                  image: 'assets/images/job_list/post_job.svg',
                                  widthImage: 16.w,
                                  heightImage: 16.h,
                                  colorBorder: ColorPick.primary,
                                  svgColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),

                            // ── Filter tabs ───────────────────────────
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _filters.map((f) {
                                  final isActive = f == activeFilter;
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.w),
                                    child: GestureDetector(
                                      onTap: () => cubit.setFilter(f),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: isActive ? ColorPick.primary : ColorPick.white,
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          // BUG-279: one name per status.
                                          f == 'Drafted' ? 'Draft' : f,
                                          style: StyleText.fontSize13Weight500.copyWith(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                            color: isActive ? Colors.white : AppColors.text,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // ── Search + Filter button ────────────────
                            Row(
                              children: [
                                AppSearchTextField(
                                  controller: _searchController,
                                  onChanged: (v) => cubit.setSearch(v),
                                  hintText: 'Search',
                                  height: 36, // scaled to 36.h — same as Filter button
                                ),
                                SizedBox(width: 12.w),
                                // ── FIXED: Filter button now opens the dialog ──
                                customButton(
                                  title: 'Filter',
                                  function: _openFilterDialog,
                                  width: 100.w,
                                  height: 36.h,
                                  radius: 8.r, // same as the Search field (8.r)
                                  color: ColorPick.primary,
                                  textColor: Colors.white,
                                  textStyle: StyleText.fontSize13Weight600.copyWith(color: Colors.white),
                                ),
                              ],
                            ),

                            // ── Active advanced-filter chips ──────────
                            if (_advancedFilter != null && !_advancedFilter!.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 12.h),
                                child: _buildActiveFilterChips(),
                              ),

                            SizedBox(height: 20.h),

                            // ── Error banner ──────────────────────────
                            if (state is JobListingError)
                              Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(bottom: 16.h),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: const Color(0xFFE53935), size: 18.sp),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        (state as JobListingError).message,
                                        style: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: const Color(0xFFE53935)),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => cubit.loadJobs(),
                                      child: Text(
                                        'Retry',
                                        style: StyleText.fontSize12Weight600.copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: ColorPick.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: ColorPick.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // ── Job cards grid ────────────────────────
                            if (jobs.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.sp),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // QA-Oct11 #24: the shared no-data
                                      // Lottie (was a static SVG).
                                      EmptyLottie(
                                        size: 200,
                                        semanticLabel:
                                            _emptyJobsMessage(activeFilter),
                                      ),
                                      // BUG-03: say WHY the list is empty.
                                      SizedBox(height: 12.h),
                                      Text(
                                        _emptyJobsMessage(activeFilter),
                                        textAlign: TextAlign.center,
                                        style: StyleText.fontSize14Weight500
                                            .copyWith(color: AppColors.text),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              _buildJobGrid(jobs, logoUrl),
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

  // BUG-03: empty-state text under the illustration.
  String _emptyJobsMessage(String activeFilter) {
    final searching = _searchController.text.trim().isNotEmpty ||
        (_advancedFilter != null && !_advancedFilter!.isEmpty);
    if (searching) return 'No jobs match your search or filters.';
    if (activeFilter == 'All') return 'No jobs found. Click "Post Job" to add one.';
    return 'No ${activeFilter.toLowerCase()} jobs found.';
  }

  // ── Active filter chips (shows what's applied + clear all) ────────────────

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];
    final f = _advancedFilter!;

    if (f.department != null) {
      chips.add(_filterChip('Dept: ${jobFilterLabel(f.department!)}', () {
        setState(() => _advancedFilter = JobListingFilterData(
          location: f.location,
          employmentType: f.employmentType,
          yearsOfExperience: f.yearsOfExperience,
          date: f.date,
        ));
        context.read<JobListingCubit>().applyAdvancedFilter(_advancedFilter!);
      }));
    }
    if (f.location != null) {
      chips.add(_filterChip('Location: ${jobFilterLabel(f.location!)}', () {
        setState(() => _advancedFilter = JobListingFilterData(
          department: f.department,
          employmentType: f.employmentType,
          yearsOfExperience: f.yearsOfExperience,
          date: f.date,
        ));
        context.read<JobListingCubit>().applyAdvancedFilter(_advancedFilter!);
      }));
    }
    if (f.employmentType != null) {
      chips.add(_filterChip('Type: ${jobFilterLabel(f.employmentType!)}', () {
        setState(() => _advancedFilter = JobListingFilterData(
          department: f.department,
          location: f.location,
          yearsOfExperience: f.yearsOfExperience,
          date: f.date,
        ));
        context.read<JobListingCubit>().applyAdvancedFilter(_advancedFilter!);
      }));
    }
    if (f.yearsOfExperience != null) {
      chips.add(_filterChip('Experience: ${jobFilterLabel(f.yearsOfExperience!)}', () {
        setState(() => _advancedFilter = JobListingFilterData(
          department: f.department,
          location: f.location,
          employmentType: f.employmentType,
          date: f.date,
        ));
        context.read<JobListingCubit>().applyAdvancedFilter(_advancedFilter!);
      }));
    }
    if (f.date != null) {
      final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      chips.add(_filterChip('Date: ${f.date!.day} ${m[f.date!.month - 1]} ${f.date!.year}', () {
        setState(() => _advancedFilter = JobListingFilterData(
          department: f.department,
          location: f.location,
          employmentType: f.employmentType,
          yearsOfExperience: f.yearsOfExperience,
        ));
        context.read<JobListingCubit>().applyAdvancedFilter(_advancedFilter!);
      }));
    }

    // Clear All chip
    chips.add(
      GestureDetector(
        onTap: () {
          setState(() => _advancedFilter = null);
          context.read<JobListingCubit>().clearAdvancedFilter();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            'Clear All',
            style: StyleText.fontSize11Weight600.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD32F2F),
            ),
          ),
        ),
      ),
    );

    return Wrap(spacing: 8.w, runSpacing: 6.h, children: chips);
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorPick.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: StyleText.fontSize11Weight400.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: ColorPick.primary,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14.sp, color: ColorPick.primary),
          ),
        ],
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bayanatz Jobs',
          style: StyleText.fontSize45Weight600.copyWith(
            color: ColorPick.primary,
            // fontSize: 28.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Job Cards Grid (3 columns) ────────────────────────────────────────────

  Widget _buildJobGrid(List<JobPostModel> jobs, String logoUrl) {
    // BUG-16: one card per row on a phone (three squeezed cards before).
    final int cols = AdminLayout.isPhone(context) ? 1 : 3;
    final rows = (jobs.length / cols).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final start = rowIndex * cols;
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: IntrinsicHeight(
            // BUG-148: the gap used to be padding INSIDE the first two
            // Expanded cells, so the 3rd card was 13 px wider. Gaps are now
            // separate boxes → three equal columns.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int colIndex = 0; colIndex < cols; colIndex++) ...[
                  if (colIndex > 0) SizedBox(width: 12.w),
                  if (start + colIndex >= jobs.length)
                    const Expanded(child: SizedBox())
                  else
                Expanded(
                    child: _JobCard(
                      job: jobs[start + colIndex],
                      // BUG-86: the department's image when it has one.
                      logoUrl: _deptImageFor(jobs[start + colIndex], ''), // '' → header logo
                      // BUG-259: the job page has its own URL (/jobs/<id>)
                      // so refresh / Back / bookmarks keep the open job.
                      onTap: () => context.push(
                          '/jobs/${jobs[start + colIndex].id}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  /// BUG-86: image of the job's department (Departments → Image), falling
  /// back to the company logo.
  String _deptImageFor(JobPostModel job, String fallback) {
    try {
      final ds = context.read<DepartmentCubit>().state;
      final list = ds is DepartmentLoaded ? ds.departments : const <DepartmentModel>[];
      for (final d in list) {
        if (d.iconUrl.isNotEmpty && d.matchesJob(job.department)) return d.iconUrl;
      }
    } catch (_) {}
    return fallback;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  JOB CARD WIDGET — uses SVG assets
// ═════════════════════════════════════════════════════════════════════════════
