// ******************* FILE INFO *******************
// File Name: careers_main_page.dart
// Created by: Amr Mesbah
// Purpose: Careers CMS main page — Hero + Dashboard (10 charts, 2 per row)
// Pattern: Same as home_main.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/format.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/constant/job_status_style.dart';
import '../../../../../core/custom/1-custom_dropdwon.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/careers_stat_card.dart';
import '../../../../../core/main_widgets/funnel_chart_widget.dart';
import '../../../../../core/main_widgets/segmented_score_bar_widget.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/careers_model.dart';
import '../../controller/careers_cubit.dart';
import '../../controller/careers_state.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/main_widgets/admin_layout.dart';
import 'package:web_app_admin/core/widget/empty_lottie.dart'; // QA-Oct11 #24

part '../widgets/careers_main/chart_colors.dart';
part '../widgets/careers_main/legend_item.dart';
part '../widgets/careers_main/pie_item.dart';
part '../widgets/careers_main/careers_charts.dart';

// Keeps the EmptyLottie import (used only by the careers_charts part) from
// being removed by "Optimize Imports".
// ignore: unused_element
typedef _KeepEmptyLottie = EmptyLottie;

// ── Chart color palette ──────────────────────────────────────────────────────

class CareersMainPageDashboard extends StatefulWidget {
  const CareersMainPageDashboard({super.key});

  @override
  State<CareersMainPageDashboard> createState() => _CareersMainPageDashboardState();
}

class _CareersMainPageDashboardState extends State<CareersMainPageDashboard> {
  bool _heroImageVisible = true;

  @override
  void initState() {
    super.initState();
    // BUG-31: the dashboard was computed ONCE at app start, so jobs added or
    // edited afterwards never showed up until a full page reload. Recompute
    // it every time Home is opened.
    final cubit = context.read<CareersCmsCubit>();
    if (cubit.state is! CareersCmsLoading) {
      cubit.loadRealData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareersCmsCubit, CareersCmsState>(
      builder: (context, state) {
        if (state is CareersCmsInitial || state is CareersCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(
              child: CircleProgress(),
            ),
          );
        }

        CareersCmsModel? data;
        if (state is CareersCmsLoaded) data = state.data;
        if (state is CareersCmsSaved) data = state.data;

        if (data == null) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(
              child: CircleProgress(),
            ),
          );
        }

        final dash = data.dashboard;

        return Scaffold(
          backgroundColor: ColorPick.background,
          body: AdminStickyBody(
                reflowOnPhone: true, // BUG-06: real phone layout
  children: [
                  AppAdminNavbar(
                    activeLabel:    'Home',
                    homePage:       CareersMainPageDashboard(),
                    webPage:        MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),

                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: AdminLayout.sidePadding(context), vertical: 20.h),
                    child: SizedBox(
                      width: AdminLayout.contentWidth(context), // BUG-06
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Title Row with Hide / Collapse toggle ──
                          Row(
                            children: [
                              Text(
                                "Bayanatz Jobs",
                                style: StyleText.fontSize14Weight500.copyWith(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ColorPick.primary,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _heroImageVisible = !_heroImageVisible;
                                  });
                                },
                                child: IntrinsicWidth(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _heroImageVisible ? "Hide" : "Show", // BUG-58: was "Collapse"
                                        style: StyleText.fontSize14Weight500.copyWith(
                                          color: ColorPick.primary,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Container(
                                        height: 1.5,
                                        color: ColorPick.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── BUG-02: tell the admin when data failed to load ──
                          if (context.read<CareersCmsCubit>().dashboardLoadWarning != null)
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(top: 12.h),
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: ColorPick.primary, size: 18.sp),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      context.read<CareersCmsCubit>().dashboardLoadWarning!,
                                      style: StyleText.fontSize12Weight400
                                          .copyWith(color: ColorPick.primary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.read<CareersCmsCubit>().loadRealData(),
                                    child: Text('Retry',
                                        style: StyleText.fontSize12Weight600
                                            .copyWith(color: ColorPick.primary)),
                                  ),
                                ],
                              ),
                            ),

                          // ── Hero SVG ──
                          if (_heroImageVisible) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomSvg(
                                  assetPath: "assets/images/dashboard_image.svg",
                                  width: 300.w,
                                  height: 300.h,
                                  fit: BoxFit.fill,
                                ),
                              ],
                            ),
                          ],

                          SizedBox(height: 20.h),

                          // ── Dashboard Title + Filters (Time / Departments) ──
                          // BUG-06 / BUG-07: on a phone the filters go under
                          // the title instead of covering it.
                          if (AdminLayout.isPhone(context))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Dashboard',
                                  textAlign: TextAlign.center,
                                  style: StyleText.fontSize18Weight500.copyWith(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _dashboardFilters(context, compact: true),
                              ],
                            )
                          else
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'Dashboard',
                                  style: StyleText.fontSize18Weight500.copyWith(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _dashboardFilters(context),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          // ── Stat Cards Row ──
                          CareersStatCardsRow(
                            cards: dash.statCards
                                .map((c) => CareersStatCardData(
                              label: c.label,
                              value: c.value,
                              iconAsset: c.iconAsset,
                            ))
                                .toList(),
                          ),
                          SizedBox(height: 20.h),

                          // ══════════════════════════════════════════
                          //  DASHBOARD CHARTS — 2 per row
                          // ══════════════════════════════════════════

                          // Row 1: Applications Received | Job Posting Status
                          _chartRow(
                            left:  _buildApplicationsReceivedChart(dash),
                            right: _buildJobPostingStatusChart(dash),
                          ),
                          SizedBox(height: 16.h),

                          // Row 2: Hiring Stage (Funnel) | Job Status (Pie)
                          _chartRow(
                            left:  _buildHiringStageChart(dash),
                            right: _buildJobStatusChart(dash),
                          ),
                          SizedBox(height: 16.h),

                          // Row 3: Candidate Quality | Jobs Performance
                          _chartRow(
                            left:  _buildCandidateQualityChart(dash),
                            right: _buildJobsPerformanceChart(dash),
                          ),
                          SizedBox(height: 16.h),

                          // Row 4: Job Offer | Candidate Score Distribution
                          _chartRow(
                            left:  _buildJobOfferChart(dash),
                            right: _buildScoreDistributionChart(dash),
                          ),
                          SizedBox(height: 16.h),

                          // Row 5: Employment Types | Candidate Gender
                          // (BUG-85: flowchart step 1:9164).
                          _chartRow(
                            left:  _buildEmploymentTypesChart(dash),
                            right: _buildCandidateGenderChart(dash),
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

  // ══════════════════════════════════════════════════════════════════════════
  //  DASHBOARD FILTERS — Time + Departments
  // ══════════════════════════════════════════════════════════════════════════

  Widget _dashboardFilters(BuildContext context, {bool compact = false}) {
    final cubit = context.read<CareersCmsCubit>();
    final depts = cubit.availableDepartments;

    // compact (phone): both dropdowns share the full width.
    Widget sized(double w, Widget child) =>
        compact ? Expanded(child: child) : SizedBox(width: w, child: child);

    return Row(
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      children: [
        // ── Time ──
        sized(
          160.w,
          CustomDropdown<DashboardTimeRange>(
            hint: 'Time',
            value: cubit.timeRange,
            items: DashboardTimeRange.values
                .map((r) => DropdownItem<DashboardTimeRange>(
                      value: r,
                      label: r.label,
                    ))
                .toList(),
            onChanged: cubit.setDashboardTimeRange,
            fillColor: ColorPick.white,
            borderRadius: BorderRadius.circular(4.r),
            itemHeight: 36.h,
            maxOverlayHeight: 225.h,
            valueStyle: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.text),
            hintStyle: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.text.withOpacity(.8)),
          ),
        ),
        SizedBox(width: 12.w),

        // ── Departments ──
        sized(
          180.w,
          CustomDropdown<String>(
            hint: 'Departments',
            value: cubit.department ?? _kAllDepartments,
            items: [
              const DropdownItem<String>(
                value: _kAllDepartments,
                label: 'All Departments',
              ),
              ...depts.map((d) => DropdownItem<String>(value: d, label: d)),
            ],
            onChanged: (d) => cubit.setDashboardDepartment(
              d == _kAllDepartments ? null : d,
            ),
            fillColor: ColorPick.white,
            borderRadius: BorderRadius.circular(4.r),
            itemHeight: 36.h,
            maxOverlayHeight: 225.h,
            valueStyle: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.text),
            hintStyle: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.text.withOpacity(.8)),
          ),
        ),
      ],
    );
  }
}

/// Sentinel value for the "All Departments" entry (the dropdown needs a
/// non-null value, while the cubit uses `null` to mean "no filter").
const String _kAllDepartments = '__all__';

// ── Internal helper classes ──────────────────────────────────────────────────
