// ═══════════════════════════════════════════════════════════════════
// FILE: application_detail.dart (Detail / Edit Page)
// Path: lib/features/job/presentation/ui/pages/application_detail.dart
// UPDATED: Single dynamic dropdown for status pipeline
// UPDATED: All fields use CustomValidatedTextFieldMaster
// UPDATED: All dropdowns use CustomDropdownFormFieldInvMaster
// FIXED: Removed stuck spinner on status change
// UPDATED: Pipeline aligned to end, dynamic primaryColor from CMS,
//          grey text for read-only fields, clickable resume/cover letter
// ═══════════════════════════════════════════════════════════════════

import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/main_widgets/admin_back_link.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/custom_dropdwon.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/core/widget/success_toast.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/application_model.dart';
import '../../controller/application_cubit.dart';
import '../../controller/application_state.dart';
import 'job_listing_main.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/application_detail/detail_cards.dart';

// class _C {
//   static const Color primary = Color(0xFF008037);
//   static const Color back = Color(0xFFF1F2ED);
//   static const Color cardBg = Color(0xFFFFFFFF);
//   static const Color border = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText = Color(0xFFAAAAAA);
//   static const Color red = Color(0xFFE53935);
//   static const Color fieldValueGrey = Color(0xFF888888);
// }

// ── Tag dropdown items ────────────────────────────────────────────────────────
const List<Map<String, String>> _kTagItems = [
  {'key': 'Weak', 'value': 'Weak'},
  {'key': 'Adequate', 'value': 'Adequate'},
  {'key': 'Strong', 'value': 'Strong'},
];

const Map<String, Color> _kTagColors = {
  'Weak': Color(0xFFD32F2F),
  'Adequate': Color(0xFFF57F17),
  'Strong': Color(0xFF2E7D32),
};

// ── Helper: extract CMS primary color ─────────────────────────────────────────
Color _primaryFromCmsState(MainCmsState state) {
  final String hex = switch (state) {
    MainCmsLoaded(:final data) => data.branding.primaryColor,
    MainCmsSaved(:final data) => data.branding.primaryColor,
    _ => '',
  };
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {}
  return ColorPick.primary; // fallback to static green
}

class ApplicationDetailPage extends StatefulWidget {
  final String jobId;
  final String appId;
  const ApplicationDetailPage({
    super.key,
    required this.jobId,
    required this.appId,
  });

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  final _technicalCtrl = TextEditingController();
  final _communicationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _cultureFitCtrl = TextEditingController();
  final _leadershipCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  String? _selectedTag;
  bool _isSaving = false;
  bool _didLoad = false;

  ApplicationModel? _currentApp;

  List<TextEditingController> get _scoreCtrls => [
        _technicalCtrl,
        _communicationCtrl,
        _experienceCtrl,
        _cultureFitCtrl,
        _leadershipCtrl,
      ];

  @override
  void initState() {
    super.initState();
    context.read<ApplicationCubit>().loadDetail(widget.jobId, widget.appId);
    // Clamp every scoring field to max 5 + refresh the live Score header.
    for (final c in _scoreCtrls) {
      c.addListener(() => _onScoreChanged(c));
    }
  }

  // BUG-264: a typed 6 used to be silently turned into 5, "-1" into 1, and
  // empty / 0 fields were saved as 0 and COUNTED (score 44 % / 20 %). Now
  // only whole numbers 1–5 are accepted (anything else shows an error and
  // blocks Save), an empty field means "not scored", and the score is the
  // average of the criteria that were actually scored.
  void _onScoreChanged(TextEditingController c) {
    if (mounted) setState(() {});
  }

  String? _scoreError(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    final v = int.tryParse(t);
    if (v == null || v < 1 || v > 5) return 'Enter a whole number from 1 to 5.';
    return null;
  }

  bool get _scoresValid => _scoreCtrls.every((c) => _scoreError(c) == null);

  List<int> get _scoredValues => [
        for (final c in _scoreCtrls)
          if (_scoreError(c) == null && c.text.trim().isNotEmpty)
            int.parse(c.text.trim()),
      ];

  /// Average of the scored criteria as a percentage — e.g. one criterion
  /// scored 5 → 100 %, not 20 %.
  String get _scorePercent {
    final v = _scoredValues;
    if (v.isEmpty) return '—';
    final sum = v.fold<int>(0, (a, b) => a + b);
    return '${(sum / (v.length * 5) * 100).round()}%';
  }

  int _scoreOf(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v != null && v >= 1 && v <= 5) ? v : 0; // 0 = not scored
  }

  void _seedControllers(ApplicationModel app) {
    if (_didLoad) return;
    _didLoad = true;
    _currentApp = app;
    _technicalCtrl.text =
    app.technicalSkills > 0 ? app.technicalSkills.toString() : '';
    _communicationCtrl.text =
    app.communicationSkills > 0 ? app.communicationSkills.toString() : '';
    _experienceCtrl.text =
    app.experienceBackground > 0 ? app.experienceBackground.toString() : '';
    _cultureFitCtrl.text =
    app.cultureFit > 0 ? app.cultureFit.toString() : '';
    _leadershipCtrl.text =
    app.leadershipPotential > 0 ? app.leadershipPotential.toString() : '';
    _commentsCtrl.text = app.comments;
    _selectedTag = app.tag.isNotEmpty ? app.tag : null;
  }

  @override
  void dispose() {
    _technicalCtrl.dispose();
    _communicationCtrl.dispose();
    _experienceCtrl.dispose();
    _cultureFitCtrl.dispose();
    _leadershipCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  // ── Status change with confirm dialog ──────────────────────────────────────
  void _onStatusChange(ApplicationModel app, ApplicationStatus newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/dashboard_image.svg',
                height: 120.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20.h),
              Text(
                'CHANGE STATUS',
                style: StyleText.fontSize18Weight500.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "Are you sure you want to change this application's status from ${app.status.label} to ${newStatus.label}?" /* BUG-280 */,
                textAlign: TextAlign.center,
                style: StyleText.fontSize13Weight400.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Center(
                          child: Text(
                            'Back',
                            style: StyleText.fontSize14Weight600.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await context.read<ApplicationCubit>().updateStatus(
                          app.jobId,
                          app.id,
                          newStatus,
                        );
                        // BUG-293: every save confirms itself.
                        if (mounted) {
                          showSuccessToast(
                              context, 'Status changed to ${newStatus.label}');
                        }
                      },
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: ColorPick.primary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Center(
                          child: Text(
                            'Confirm',
                            style: StyleText.fontSize14Weight600.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save scoring ───────────────────────────────────────────────────────────
  Future<void> _saveScoring() async {
    if (_currentApp == null) return;
    // BUG-264: never save an invalid score.
    if (!_scoresValid) {
      showSuccessToast(context, 'Scores must be whole numbers from 1 to 5.',
          isError: true);
      setState(() {});
      return;
    }
    setState(() => _isSaving = true);

    final updated = _currentApp!.copyWith(
      tag: _selectedTag ?? '',
      // 0 = "not scored" (empty field) — excluded from every average.
      technicalSkills: _scoreOf(_technicalCtrl),
      communicationSkills: _scoreOf(_communicationCtrl),
      experienceBackground: _scoreOf(_experienceCtrl),
      cultureFit: _scoreOf(_cultureFitCtrl),
      leadershipPotential: _scoreOf(_leadershipCtrl),
      comments: _commentsCtrl.text,
    );

    await context.read<ApplicationCubit>().updateScoring(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      // BUG-293: the shared success toast (was a grey full-width bar).
      showSuccessToast(context, 'Scoring saved');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DYNAMIC STATUS DROPDOWN HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  int _getStageIndex(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
      case ApplicationStatus.qualified:
      case ApplicationStatus.unqualified:
        return 0;
      case ApplicationStatus.interviewPassed:
      case ApplicationStatus.interviewFailed:
      case ApplicationStatus.interviewWithdrew:
        return 1;
      case ApplicationStatus.offerApproved:
      case ApplicationStatus.offerPending:
      case ApplicationStatus.offerRejected:
        return 2;
      case ApplicationStatus.hired:
        return 3;
    }
  }

  bool _isStoppedStatus(ApplicationStatus status) {
    return status == ApplicationStatus.unqualified ||
        status == ApplicationStatus.interviewFailed ||
        status == ApplicationStatus.interviewWithdrew ||
        status == ApplicationStatus.offerRejected;
  }

  List<Map<String, String>> _getDropdownItems(ApplicationStatus status) {
    if (_isStoppedStatus(status) || status == ApplicationStatus.hired) {
      return [];
    }

    switch (status) {
      case ApplicationStatus.applied:
        return [
          {'key': 'qualified', 'value': 'Qualified'},
          {'key': 'unqualified', 'value': 'Unqualified'},
        ];
      // BUG-209: the next steps name their stage ("Interview: Passed").
      case ApplicationStatus.qualified:
        return [
          {'key': 'passed', 'value': 'Interview: Passed'},
          {'key': 'failed', 'value': 'Interview: Failed'},
          {'key': 'withdrew', 'value': 'Interview: Withdrew'},
        ];
      case ApplicationStatus.interviewPassed:
        return [
          {'key': 'approved', 'value': 'Offer: Approved'},
          {'key': 'rejected', 'value': 'Offer: Rejected'},
        ];
      case ApplicationStatus.offerApproved:
      case ApplicationStatus.offerPending:
        return [
          {'key': 'completed', 'value': 'Hired: Completed'},
        ];
      default:
        return [];
    }
  }

  ApplicationStatus? _mapKeyToStatus(String key) {
    switch (key) {
      case 'qualified':
        return ApplicationStatus.qualified;
      case 'unqualified':
        return ApplicationStatus.unqualified;
      case 'passed':
        return ApplicationStatus.interviewPassed;
      case 'failed':
        return ApplicationStatus.interviewFailed;
      case 'withdrew':
        return ApplicationStatus.interviewWithdrew;
      case 'approved':
        return ApplicationStatus.offerApproved;
      case 'rejected':
        return ApplicationStatus.offerRejected;
      case 'completed':
        return ApplicationStatus.hired;
      default:
        return null;
    }
  }

  // BUG-209: the box shows the CURRENT status (it said "Interview" right
  // after choosing "Qualified"); the next steps are in the list.
  String _getDropdownHint(ApplicationStatus status) => status.label;

  List<Widget> _buildCompletedStageChips(ApplicationStatus status) {
    final List<Widget> chips = [];
    final int currentStage = _getStageIndex(status);
    final bool isStopped = _isStoppedStatus(status);

    if (currentStage > 0) {
      chips.add(_completedChip('Applied: Qualified'));
      chips.add(SizedBox(width: 8.w));
    }
    if (currentStage > 1) {
      chips.add(_completedChip('Interview: Passed'));
      chips.add(SizedBox(width: 8.w));
    }
    if (currentStage > 2) {
      chips.add(_completedChip('Offer: Approved'));
      chips.add(SizedBox(width: 8.w));
    }

    if (isStopped) {
      String stoppedLabel = '';
      switch (status) {
        case ApplicationStatus.unqualified:
          stoppedLabel = 'Applied: Unqualified';
          break;
        case ApplicationStatus.interviewFailed:
          stoppedLabel = 'Interview: Failed';
          break;
        case ApplicationStatus.interviewWithdrew:
          stoppedLabel = 'Interview: Withdrew';
          break;
        case ApplicationStatus.offerRejected:
          stoppedLabel = 'Offer: Rejected';
          break;
        default:
          break;
      }
      if (stoppedLabel.isNotEmpty) {
        chips.add(_stoppedChip(stoppedLabel));
        chips.add(SizedBox(width: 8.w));
      }
    }

    if (status == ApplicationStatus.hired) {
      chips.add(_completedChip('Hired: Completed'));
      chips.add(SizedBox(width: 8.w));
    }

    return chips;
  }

  Widget _completedChip(String label) {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: ColorPick.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: ColorPick.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14.sp, color: ColorPick.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: StyleText.fontSize12Weight600.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: ColorPick.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stoppedChip(String label) {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: ColorPick.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: ColorPick.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, size: 14.sp, color: ColorPick.red),
          SizedBox(width: 6.w),
          Text(
            label,
            style: StyleText.fontSize12Weight600.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: ColorPick.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApplicationCubit, ApplicationState>(
      listener: (context, state) {
        if (state is ApplicationUpdated) {
          _didLoad = false;
          _currentApp = state.application;
        }
      },
      child: BlocBuilder<MainCmsCubit, MainCmsState>(
        builder: (context, cmsState) {
          // ── Extract dynamic primary color from CMS/Firebase ──
          final Color cmsPrimary = _primaryFromCmsState(cmsState);

          return BlocBuilder<ApplicationCubit, ApplicationState>(
            builder: (context, state) {
              ApplicationModel? app;
              if (state is ApplicationDetailLoaded) app = state.application;
              if (state is ApplicationUpdated) app = state.application;

              if (app == null && _currentApp != null) {
                app = _currentApp;
              }

              if (app == null) {
                return Scaffold(
                  backgroundColor: ColorPick.background,
                  body: Center(
                    child: CircleProgress(),
                  ),
                );
              }

              _seedControllers(app);
              _currentApp = app;

              final dropdownItems = _getDropdownItems(app.status);
              final completedChips = _buildCompletedStageChips(app.status);
              final bool hasNextOptions = dropdownItems.isNotEmpty;

              return Scaffold(
                backgroundColor: ColorPick.background,
                body: AdminStickyBody(
  children: [
                        AppAdminNavbar(
                          activeLabel: 'Applications',
                          homePage: CareersMainPageDashboard(),
                          webPage: MainMainPage(),
                          jobListingPage: JobListingMainPage(),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 20.h,
                          ),
                          child: SizedBox(
                            width: 1000.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // BUG-298: same back link as About Company.
                                const AdminBackLink(parentLabel: 'Applications', parentRoute: '/applications'),
                                // ── Title ──
                                Text(
                                  'Applications',
                                  style: StyleText.fontSize45Weight600.copyWith(
                                    color: ColorPick.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                // ══════════════════════════════════════════
                                // ── SCORE (left) + STATUS PIPELINE (right) ──
                                // ══════════════════════════════════════════
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Live score — sum of the 5 degrees as a
                                    // percentage out of 100.
                                    Text(
                                      'Score : ',
                                      style: StyleText.fontSize16Weight700
                                          .copyWith(
                                        fontSize: 16.sp,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    Text(
                                      _scorePercent,
                                      style: StyleText.fontSize16Weight700
                                          .copyWith(
                                        fontSize: 16.sp,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Align(
                                  alignment: Alignment.centerRight,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ...completedChips,

                                        if (completedChips.isNotEmpty &&
                                            hasNextOptions) ...[
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 4.w,
                                            ),
                                            child: Icon(
                                              Icons.chevron_right,
                                              size: 18.sp,
                                              color:AppColors.secondaryText,
                                            ),
                                          ),
                                        ],

                                        if (hasNextOptions)
                                          SizedBox(
                                            width: 200.w,
                                            child:
                                            CustomDropdownFormFieldInvMaster(
                                              selectedValue: null,
                                              items: dropdownItems,
                                              widthIcon: 18,
                                              heightIcon: 18,
                                              height: 36,
                                              primaryColor: cmsPrimary,
                                              dropdownColor: Colors.white,
                                              hint: Text(
                                                _getDropdownHint(app!.status),
                                                style: StyleText.fontSize12Weight400.copyWith(
                                                  fontSize: 12.sp,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              onChanged: (selectedKey) {
                                                if (selectedKey == null) return;
                                                final newStatus =
                                                _mapKeyToStatus(
                                                    selectedKey);
                                                if (newStatus != null) {
                                                  _onStatusChange(
                                                      app!, newStatus);
                                                }
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24.h),

                                // ── Personal Information Card ──
                                _buildPersonalInfoCard(app),
                                SizedBox(height: 24.h),

                                // ── Tags + Scoring Card ──
                                _buildTagsScoringCard(app, cmsPrimary),
                                SizedBox(height: 24.h),

                                // ── Save button ──
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _isSaving ? null : _saveScoring,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 30.w,
                                        vertical: 12.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorPick.primary,
                                        borderRadius:
                                        BorderRadius.circular(6.r),
                                      ),
                                      child: _isSaving
                                          ? SizedBox(
                                        width: 16.sp,
                                        height: 16.sp,
                                        child:
                                        const CircleProgress(),
                                      )
                                          : Text(
                                        'Save Scoring',
                                        style: StyleText.fontSize14Weight600.copyWith(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
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
        },
      ),
    );
  }

}