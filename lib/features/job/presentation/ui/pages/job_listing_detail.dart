// ******************* FILE INFO *******************
// File Name: job_listing_detail.dart
// Created by: Amr Mesbah
// Purpose: Job Post Details — 3 tabs: Job Details | Dashboard | Applicant Details
// UPDATED: Dashboard + Applicant Details use REAL Firebase data
//          Applications fetched from jobListings/{jobId}/applications subcollection
//          Applicant Details table refactored to use Table widget (ServiceTableWidget pattern)
//          Table Setting dialog controls column visibility for table + export

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_app_admin/core/main_widgets/admin_back_link.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:web_app_admin/core/constant/color.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/calender_widget.dart';
import 'package:web_app_admin/core/widget/custom_dropdwon.dart';
import 'package:web_app_admin/core/widget/date_pic.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/textfield.dart';

import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/job_listing_export_dialog.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/widget/button.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_listing_model.dart';
import '../../controller/job_listing_cubit.dart';
import '../../controller/job_listing_state.dart';
import 'job_listing_edit.dart';
import 'job_listing_main.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/job_listing_detail/ch.dart';
part '../widgets/job_listing_detail/table_setting_dialog_content.dart';
part '../widgets/job_listing_detail/job_details_tab.dart';
part '../widgets/job_listing_detail/dashboard_tab.dart';
part '../widgets/job_listing_detail/funnel_item.dart';
part '../widgets/job_listing_detail/pie_item.dart';
part '../widgets/job_listing_detail/score_segment.dart';
part '../widgets/job_listing_detail/applicant_details_tab.dart';
part '../widgets/job_listing_detail/section_card.dart';
part '../widgets/job_listing_detail/trapezoid_clipper.dart';

// ── Colors ───────────────────────────────────────────────────────────────────

/// BUG-264: average of the criteria that were actually scored (1–5); an
/// empty / 0 criterion is "not scored" and no longer drags the score down.
String scorePercentOf(ApplicationModel a) {
  final v = [
    a.technicalSkills,
    a.communicationSkills,
    a.experienceBackground,
    a.cultureFit,
    a.leadershipPotential,
  ].where((x) => x >= 1 && x <= 5).toList();
  if (v.isEmpty) return '';
  final sum = v.fold<int>(0, (p, x) => p + x);
  return '${(sum / (v.length * 5) * 100).round()}%';
}

/// BUG-235: documents other than Resume / Cover Letter.
List<ApplicationDocument> otherDocumentsOf(ApplicationModel a) => a.documents
    .where((d) {
      final n = d.name.trim().toLowerCase();
      return n != 'resume' && n != 'cv' && n != 'cover letter' &&
          n != 'cover_letter';
    })
    .toList();

class ColumnKey {
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String email = 'email';
  static const String code = 'code';
  static const String phone = 'phone';
  static const String source = 'source';
  static const String location = 'location';
  static const String resume = 'resume';
  static const String coverLetter = 'coverLetter';
  /// BUG-235: every other document the job asked for (Portfolio,
  /// Certificate …) — the table showed only Resume and Cover Letter.
  static const String documents = 'documents';
  static const String status = 'status';
  static const String stage = 'stage';
  static const String score = 'score';
  static const String tags = 'tags';
  static const String appliedDate = 'appliedDate';
  static const String interviewDate = 'interviewDate';
  static const String lastUpdate = 'lastUpdate';
  static const String yearOfGraduation = 'yearOfGraduation';
  static const String comment = 'comment';

  static const List<String> all = [
    firstName,
    lastName,
    email,
    code,
    phone,
    source,
    yearOfGraduation,
    resume,
    coverLetter,
    documents,
    stage,
    status,
    score,
    tags,
    appliedDate,
    interviewDate,
    lastUpdate,
    location,
    comment, // always the last column
  ];

  static const Map<String, String> labels = {
    firstName: 'First Name',
    lastName: 'Last Name',
    email: 'Email',
    code: 'Code',
    phone: 'Phone',
    source: 'Source',
    location: 'Location',
    resume: 'Resume',
    coverLetter: 'Cover Letter',
    documents: 'Other Documents',
    status: 'Status',
    stage: 'Stage',
    score: 'Score',
    tags: 'Tags',
    appliedDate: 'Applied Date',
    interviewDate: 'Interview Date',
    lastUpdate: 'Last Update',
    yearOfGraduation: 'Year Of Graduation',
    comment: 'Comment',
  };

  static Map<String, bool> defaultVisibility() {
    return {
      firstName: true,
      lastName: true,
      email: true,
      code: true,
      phone: true,
      source: false,
      location: true,
      resume: true,
      coverLetter: true,
      documents: true,
      status: true,
      stage: true,
      score: true,
      tags: true,
      appliedDate: true,
      interviewDate: false,
      lastUpdate: false,
      yearOfGraduation: true,
      comment: true,
    };
  }

  static String valueFromApp(String key, ApplicationModel a) {
    final scoreText = scorePercentOf(a); // BUG-264

    String fmtDate(DateTime? dt) {
      if (dt == null) return '';
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    }

    switch (key) {
      case ColumnKey.firstName:
        return a.firstName;
      case ColumnKey.lastName:
        return a.lastName;
      case ColumnKey.email:
        return a.email;
      case ColumnKey.code:
        return a.countryCode;
      case ColumnKey.phone:
        return a.phone;
      case ColumnKey.source:
        return a.source;
      case ColumnKey.location:
        return a.jobLocation;
      case ColumnKey.resume:
        return a.resumeUrl;
      case ColumnKey.coverLetter:
        return a.coverLetterUrl;
      case ColumnKey.status:
        return a.status.label;
      case ColumnKey.stage:
        return a.status.stage;
      case ColumnKey.score:
        return scoreText;
      case ColumnKey.tags:
        return a.tag;
      case ColumnKey.appliedDate:
        return fmtDate(a.applicationDate);
      case ColumnKey.interviewDate:
        return fmtDate(a.interviewDate);
      case ColumnKey.lastUpdate:
        return fmtDate(a.lastUpdate);
      case ColumnKey.yearOfGraduation:
        return a.yearOfGraduation;
      case ColumnKey.comment:
        return a.comments;
      default:
        return '';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TABLE SETTING DIALOG — show function (top-level so it's easy to call)
// ═════════════════════════════════════════════════════════════════════════════

Future<Map<String, bool>?> showTableSettingDialog(
    BuildContext context,
    Map<String, bool> currentVisibility,
    ) {
  return showGeneralDialog<Map<String, bool>?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'TableSettingDialog',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim, secondaryAnim) {
      return _TableSettingDialogContent(
        columnVisibility: Map.from(currentVisibility),
      );
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}

class JobListingDetailPage extends StatefulWidget {
  final String jobId;
  const JobListingDetailPage({super.key, required this.jobId});

  @override
  State<JobListingDetailPage> createState() => _JobListingDetailPageState();
}

class _JobListingDetailPageState extends State<JobListingDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  JobPostModel? _job;

  List<ApplicationModel> _applications = [];
  bool _loadingApps = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJob();
    _loadApplications();
  }

  void _loadJob() {
    final cubit = context.read<JobListingCubit>();
    final matches = cubit.allJobs.where((j) => j.id == widget.jobId).toList();
    if (matches.isNotEmpty) {
      setState(() => _job = matches.first);
      return;
    }
    // BUG-259: opened straight from its URL (refresh / bookmark / Back) —
    // the job list is not loaded yet, so load it and look again.
    cubit.loadJobs().then((_) {
      if (!mounted) return;
      final again =
          cubit.allJobs.where((j) => j.id == widget.jobId).toList();
      if (again.isNotEmpty) {
        setState(() => _job = again.first);
      } else {
        GoRouter.of(context).go('/jobs'); // unknown / deleted job
      }
    });
  }

  Future<void> _loadApplications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('jobListings')
          .doc(widget.jobId)
          .collection('applications')
          .orderBy('applicationDate', descending: true)
          .get(const GetOptions(source: Source.server));

      final apps = snapshot.docs.map((doc) {
        return ApplicationModel.fromMap(doc.id, {
          ...doc.data(),
          'jobId': widget.jobId,
        });
      }).toList();

      if (mounted)
        setState(() {
          _applications = apps;
          _loadingApps = false;
        });
    } catch (e) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('jobListings')
            .doc(widget.jobId)
            .collection('applications')
            .orderBy('applicationDate', descending: true)
            .get(const GetOptions(source: Source.cache));
        final apps = snapshot.docs.map((doc) {
          return ApplicationModel.fromMap(doc.id, {
            ...doc.data(),
            'jobId': widget.jobId,
          });
        }).toList();
        if (mounted)
          setState(() {
            _applications = apps;
            _loadingApps = false;
          });
      } catch (_) {
        if (mounted) setState(() => _loadingApps = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobListingCubit, JobListingState>(
      listener: (context, state) {
        if (state is JobListingLoaded) {
          final matches = state.jobs
              .where((j) => j.id == widget.jobId)
              .toList();
          if (matches.isNotEmpty) setState(() => _job = matches.first);
        }
        if (state is JobListingSaved && state.job.id == widget.jobId) {
          setState(() => _job = state.job);
        }
      },
      child: Scaffold(
        backgroundColor: ColorPick.background,
        body: AdminStickyBody(
  children: [
                AppAdminNavbar(
                  activeLabel: 'Job Listing',
                  homePage: CareersMainPageDashboard(),
                  webPage: MainMainPage(),
                  jobListingPage: JobListingMainPage(),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 0.h,
                  ),
                  child: SizedBox(
                    width: 1000.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BUG-298: same back link as About Company.
                        const AdminBackLink(parentLabel: 'Job Listing', parentRoute: '/jobs'),
                        Text(
                          'Job Post Details',
                          style: StyleText.fontSize28Weight600.copyWith(
                            color: ColorPick.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        Container(
                          child: Row(
                            children: [
                              _buildTabBar(),
                              const Spacer(),
                              if (_tabController.index == 0)
                                GestureDetector(
                                  onTap: () => navigateTo(
                                    context,
                                    JobListingEditPage(jobId: widget.jobId),
                                  ),
                                  // Same edit button as the Main page
                                  // (features/main/.../main_main.dart).
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
                                            'Edit Job Info',
                                            style: StyleText.fontSize14Weight500
                                                .copyWith(color: Colors.black),
                                          ),
                                          SizedBox(width: 6.w),
                                          CustomSvg(
                                            assetPath:
                                                'assets/control/edit_icon_pick.svg',
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
                        ),
                        SizedBox(height: 20.h),

                        if (_job == null)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.sp),
                              child: const CircleProgress(),
                            ),
                          )
                        else
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (_, __) {
                              switch (_tabController.index) {
                                case 0:
                                  return _JobDetailsTab(job: _job!);
                                case 1:
                                  return _DashboardTab(
                                    job: _job!,
                                    applications: _applications,
                                    loading: _loadingApps,
                                  );
                                case 2:
                                  return _ApplicantDetailsTab(
                                    job: _job!,
                                    applications: _applications,
                                    loading: _loadingApps,
                                    onRefresh: _loadApplications,
                                  );
                                default:
                                  return const SizedBox();
                              }
                            },
                          ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Job Details', 'Dashboard', 'Applicant Details'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final isActive = _tabController.index == i;
        return Padding(
          padding: EdgeInsets.only(right: 24.w),
          child: GestureDetector(
            onTap: () => setState(() => _tabController.animateTo(i)),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      tabs[i],
                      style: StyleText.fontSize15Weight500.copyWith(
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive ? ColorPick.primary : AppColors.secondaryText,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    color: isActive ? ColorPick.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 1 — JOB DETAILS (read-only) — unchanged
// ═════════════════════════════════════════════════════════════════════════════
