// ═══════════════════════════════════════════════════════════════════
// FILE: application_main.dart
// Path: lib/features/job/presentation/ui/pages/application_main.dart
// ═══════════════════════════════════════════════════════════════════

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/utils/display_format.dart';
import 'package:web_app_admin/core/widget/auto_close_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:web_app_admin/core/widget/button.dart';
import 'package:web_app_admin/core/widget/date_pic.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/core/widget/search.dart';
import 'package:web_app_admin/features/main/presentation/controller/main_cubit.dart';
import 'package:web_app_admin/features/main/presentation/controller/main_state.dart';

import '../../../../../core/constant/color.dart';
import 'package:web_app_admin/core/main_widgets/admin_layout.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/application_filter_dialog.dart';
import '../../../../../core/main_widgets/csv_export_dialog.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../home/presentation/controller/home_cubit.dart';
import '../../../../home/presentation/controller/home_state.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_listing_model.dart';
import '../../controller/application_cubit.dart';
import '../../controller/application_state.dart';
import '../../controller/job_listing_cubit.dart';
import 'application_detail.dart';
import 'job_listing_main.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/widget/empty_lottie.dart'; // QA-Oct11 #24

part '../widgets/application_main/app_card.dart';
part '../widgets/application_main/app_table.dart';

// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color border    = Color(0xFFE0E0E0);
// }

class ApplicationMainPage extends StatefulWidget {
  const ApplicationMainPage({super.key});

  @override
  State<ApplicationMainPage> createState() => _ApplicationMainPageState();
}

class _ApplicationMainPageState extends State<ApplicationMainPage> {
  final _searchController = TextEditingController();
  bool _isGridView = true;
  ApplicationFilterData? _activeFilter;

  /// BUG-35: the "Time Frame" button did nothing — it now filters by the
  /// application date range picked here.
  DateTimeRange? _timeFrame;

  Future<void> _pickTimeFrame() async {
    // BUG-153: shared dialog-size picker (was the full-screen one).
    final picked = await showAdminDateRangePicker(context, initial: _timeFrame);
    if (picked != null) setState(() => _timeFrame = picked);
  }

  // BUG-145: one date format ("4 Oct 2026") across the admin.
  String _fmtShort(DateTime d) => DateFormat('d MMM yyyy').format(d);

  // BUG-32: Export used to do nothing.
  void _exportApplications(List<ApplicationModel> apps) {
    String d(DateTime? dt) => dt == null ? '' : _fmtShort(dt);
    showCsvExportDialog(
      context,
      defaultFileName: 'applications',
      itemLabel: 'applications',
      header: const ['No', 'Name', 'Email', 'Phone', 'Job Title', 'Department',
        'Application Date', 'Status', 'Stage', 'Tag', 'Experience Level',
        'Employment Type'],
      rows: [
        for (int i = 0; i < apps.length; i++)
          [
            '${i + 1}',
            apps[i].fullName,
            apps[i].email,
            '${apps[i].countryCode} ${apps[i].phone}'.trim(),
            apps[i].jobTitle,
            apps[i].department,
            d(apps[i].applicationDate),
            apps[i].status.label,
            apps[i].status.stage,
            apps[i].tag,
            apps[i].experienceLevel,
            apps[i].employmentType,
          ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<ApplicationCubit>().loadApplications();
    // Jobs are needed so the filter tabs show ALL jobs — even those
    // without any applications yet.
    final jobCubit = context.read<JobListingCubit>();
    if (jobCubit.allJobs.isEmpty) jobCubit.loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PDF DOWNLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _downloadPdf(ApplicationModel app) async {
    try {
      final pdf = pw.Document();

      // BUG-304: the admin's one date format ("8 Oct 2026").
      final dateStr = DisplayFormat.date(app.applicationDate, empty: 'N/A');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) => [
            // ── Header ──
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#008037'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Application Summary', // BUG-241: what this file is
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${DisplayFormat.date(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Personal Information ──
            _pdfSection('Personal Information', [
              _pdfRow('Full Name', app.fullName),
              _pdfRow('Email', app.email),
              // BUG-241: "+20 0000000000" like the cards (was "+200000000000").
              _pdfRow('Phone', DisplayFormat.phone(app.countryCode, app.phone)),
              _pdfRow('Year of Graduation', app.yearOfGraduation),
            ]),
            pw.SizedBox(height: 16),

            // ── Job Information ──
            _pdfSection('Job Information', [
              _pdfRow('Job Title', app.jobTitle),
              _pdfRow('Department', app.department),
              _pdfRow('Work Type', DisplayFormat.workType(app.workType)), // BUG-157
              _pdfRow('Employment Type', app.employmentType),
              _pdfRow('Employment Duration',
                  DisplayFormat.durationText(app.employmentDuration)), // BUG-172
              _pdfRow('Location', app.jobLocation),
              _pdfRow('Experience Level', app.experienceLevel),
              _pdfRow('Salary Range', app.salaryRange.isNotEmpty ? '${app.salaryRange.replaceAll(' - ', ' – ')} ${app.currency}' : 'N/A'),
            ]),
            pw.SizedBox(height: 16),

            // ── Requirements ──
            _pdfSection('Requirements', [
              _pdfRow('Required Qualification', app.requiredQualification),
              _pdfRow('Required Skills', app.requiredSkills),
            ]),
            pw.SizedBox(height: 16),

            // ── Application Status ──
            _pdfSection('Application Status', [
              _pdfRow('Status', app.status.label),
              _pdfRow('Tag', app.tag.isNotEmpty ? app.tag : 'N/A'),
              _pdfRow('Application Date', dateStr),
            ]),
            pw.SizedBox(height: 16),

            // ── Scoring (Interview) ──
            _pdfSection('Interview Scoring', [
              // BUG-264: scores are 1–5; 0 means "not scored".
              _pdfRow('Technical Skills', _scoreText(app.technicalSkills)),
              _pdfRow('Communication Skills', _scoreText(app.communicationSkills)),
              _pdfRow('Experience & Background', _scoreText(app.experienceBackground)),
              _pdfRow('Culture Fit', _scoreText(app.cultureFit)),
              _pdfRow('Leadership Potential', _scoreText(app.leadershipPotential)),
              _pdfRow('Comments', app.comments.isNotEmpty ? app.comments : 'N/A'),
            ]),
            pw.SizedBox(height: 16),

            // ── Documents / Links ──
            // BUG-235 / BUG-241: EVERY document the applicant sent (it listed
            // only Resume + Cover Letter, and a link's "file name" printed as
            // "Link"). Files and links are listed with their URL.
            _pdfSection('Documents', [
              if (app.documents.isEmpty) ...[
                _pdfRow('Resume', app.resumeUrl.isNotEmpty ? app.resumeUrl : 'Not uploaded'),
                _pdfRow('Cover Letter', app.coverLetterUrl.isNotEmpty ? app.coverLetterUrl : 'Not uploaded'),
              ] else
                for (final d in app.documents)
                  _pdfRow(
                    '${d.name} (${d.docType == 'Link' ? 'link' : 'PDF'})',
                    d.url.isEmpty
                        ? 'Not provided'
                        : (d.docType == 'Link' || d.fileName.isEmpty || d.fileName == 'Link'
                            ? d.url
                            : '${d.fileName}\n${d.url}'),
                  ),
            ]),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${app.fullName.replaceAll(' ', '_')}_application.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      // Show success dialog
      if (mounted) {
        _showDownloadSuccessDialog(app.fullName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _scoreText(int v) => v >= 1 && v <= 5 ? '$v / 5' : 'Not scored';

  // ── PDF helper: Section ──
  pw.Widget _pdfSection(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E8F5E9'),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#008037'),
            ),
          ),
        ),
        ...rows,
      ],
    );
  }

  // ── PDF helper: Row ──
  pw.Widget _pdfRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? 'N/A' : value,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success Dialog ──
  void _showDownloadSuccessDialog(String name) {
    // Closes itself after 3 s (AutoCloseDialog) — no OK button.
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AutoCloseDialog(child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 320.w,
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.sp,
                height: 64.sp,
                decoration: BoxDecoration(
                  color: ColorPick.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: ColorPick.primary, size: 40.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                '$name\ndownload file success',
                textAlign: TextAlign.center,
                style: StyleText.fontSize15Weight600.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      )),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApplicationCubit, ApplicationState>(
      listener: (context, state) {
        if (state is ApplicationUpdated) {
          context.read<ApplicationCubit>().loadApplications();
        }
      },
      child: BlocBuilder<ApplicationCubit, ApplicationState>(
        builder: (context, state) {
          // BUG-281: keep the header, menu and page title while loading —
          // the whole window used to be empty with only a spinner.
          if (state is ApplicationInitial || state is ApplicationLoading) {
            return Scaffold(
              backgroundColor: ColorPick.background,
              body: AdminStickyBody(
                reflowOnPhone: true,
                children: [
                  AppAdminNavbar(
                    activeLabel: 'Applications',
                    homePage: CareersMainPageDashboard(),
                    webPage: MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AdminLayout.sidePadding(context),
                        vertical: 20.h),
                    child: SizedBox(
                      width: AdminLayout.contentWidth(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applications',
                            style: StyleText.fontSize28Weight600.copyWith(
                              color: ColorPick.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 60.h),
                          const Center(child: CircleProgress()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final cubit = context.read<ApplicationCubit>();
          List<ApplicationModel> apps = [];
          String activeJobTitle = 'All';
          Map<String, int> jobTitleCounts = {};
          int totalCount = 0;
          int appliedPending = 0, appliedQualified = 0, appliedUnqualified = 0;
          int interviewPassed = 0, interviewWithdrew = 0, interviewFailed = 0;
          int offerApproved = 0, offerPending = 0, offerRejected = 0;
          int hiredCompleted = 0;

          if (state is ApplicationLoaded) {
            apps = state.filteredApps;
            activeJobTitle = state.activeJobTitleFilter;
            jobTitleCounts = state.jobTitleCounts;
            totalCount = state.totalCount;
            appliedPending = state.appliedPending; // BUG-170
            appliedQualified = state.appliedQualified;
            appliedUnqualified = state.appliedUnqualified;
            interviewPassed = state.interviewPassed;
            interviewWithdrew = state.interviewWithdrew;
            interviewFailed = state.interviewFailed;
            offerApproved = state.offerApproved;
            offerPending = state.offerPending;
            offerRejected = state.offerRejected;
            hiredCompleted = state.hiredCompleted;
          }

          if (state is ApplicationError && state.lastApps != null) {
            apps = state.lastApps!;
          }

          // BUG-35: Time Frame filter (inclusive of both days).
          if (_timeFrame != null) {
            final from = DateTime(_timeFrame!.start.year,
                _timeFrame!.start.month, _timeFrame!.start.day);
            final to = DateTime(_timeFrame!.end.year, _timeFrame!.end.month,
                _timeFrame!.end.day, 23, 59, 59);
            apps = apps.where((a) {
              final d = a.applicationDate;
              return d != null && !d.isBefore(from) && !d.isAfter(to);
            }).toList();
            totalCount = apps.length;
          }

          return Scaffold(
            backgroundColor: ColorPick.background,
            body: AdminStickyBody(
                reflowOnPhone: true, // BUG-16
  children: [
                    AppAdminNavbar(
                      activeLabel: 'Applications',
                      homePage: CareersMainPageDashboard(),
                      webPage: MainMainPage(),
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
                            // ── Title ──
                            Text(
                              'Applications',
                              style: StyleText.fontSize28Weight600.copyWith(
                                color: ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // ── Job Title filter tabs — shows ALL jobs,
                            //    including ones with no applications yet ──
                            Builder(builder: (context) {
                              final allJobs =
                                  context.watch<JobListingCubit>().allJobs;
                              // BUG-35: removed (and draft) jobs are not
                              // job tabs any more.
                              final hiddenTitles = allJobs
                                  .where((j) =>
                                      j.status == JobStatus.removed ||
                                      j.status == JobStatus.drafted)
                                  .map((j) => j.title.en.trim().toLowerCase())
                                  .toSet();
                              final liveTitles = allJobs
                                  .where((j) =>
                                      j.status != JobStatus.removed &&
                                      j.status != JobStatus.drafted)
                                  .map((j) => j.title.en.trim().toLowerCase())
                                  .toSet();
                              final tabCounts = Map<String, int>.from(jobTitleCounts)
                                ..removeWhere((t, _) {
                                  final k = t.trim().toLowerCase();
                                  return hiddenTitles.contains(k) &&
                                      !liveTitles.contains(k);
                                });
                              for (final j in allJobs) {
                                if (j.status == JobStatus.removed ||
                                    j.status == JobStatus.drafted) continue;
                                final t = j.title.en.trim();
                                if (t.isNotEmpty) {
                                  tabCounts.putIfAbsent(t, () => 0);
                                }
                              }
                              // BUG-218: the job chips WRAP onto more lines, so
                              // the last jobs are reachable with a mouse (the
                              // scroll row was cut with no hint).
                              return Wrap(
                                spacing: 0,
                                runSpacing: 8,
                                children: [
                                  _filterTab('All', apps.length, activeJobTitle == 'All', () => cubit.setJobTitleFilter('All')),
                                  ...tabCounts.entries.map((e) =>
                                      _filterTab(e.key, e.value, activeJobTitle == e.key, () => cubit.setJobTitleFilter(e.key))),
                                ],
                              );
                            }),
                            SizedBox(height: 16.h),

                            // ── Search + buttons row ──
                            Row(
                              children: [
                                AppSearchTextField(
                                  controller: _searchController,
                                  onChanged: (v) => cubit.setSearch(v),
                                  hintText: 'Search',
                                ),
                                SizedBox(width: 12.w),
                                customButton(
                                  title: _timeFrame == null
                                      ? 'Time Frame'
                                      : '${_fmtShort(_timeFrame!.start)} – ${_fmtShort(_timeFrame!.end)}',
                                  function: _pickTimeFrame,
                                  width: _timeFrame == null ? 110.w : 170.w,
                                  height: 36.h,
                                  radius: 6,
                                  color: ColorPick.primary,
                                  textColor: Colors.white,
                                  textStyle: StyleText.fontSize13Weight600.copyWith(color: Colors.white),
                                ),
                                if (_timeFrame != null)
                                  IconButton(
                                    tooltip: 'Clear time frame',
                                    icon: Icon(Icons.close, size: 16.sp, color: ColorPick.primary),
                                    onPressed: () => setState(() => _timeFrame = null),
                                  ),
                                SizedBox(width: 8.w),
                                customButton(
                                  title: 'Filter',
                                  function: () async {
                                    final result = await showApplicationFilterDialog(
                                      context,
                                      initial: _activeFilter,
                                    );
                                    if (result != null) {
                                      setState(() => _activeFilter = result);
                                      cubit.setFilter(result);
                                    }
                                  },
                                  width: 100.w,
                                  height: 36.h,
                                  radius: 6,
                                  color: _activeFilter != null && !_activeFilter!.isEmpty
                                      ? ColorPick.primary.withValues(alpha: 0.85)
                                      : ColorPick.primary,
                                  textColor: Colors.white,
                                  textStyle: StyleText.fontSize13Weight600.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),

                            // ── Total + Export + Grid/List toggle ──
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: ColorPick.white,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Total Applications: $totalCount' /* BUG-41 */,
                                    style: StyleText.fontSize12Weight500.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.text),
                                  ),
                                ),
                                const Spacer(),

                                // ── Export button ──
                                customButtonWithImage(
                                  title: 'Export',
                                  // BUG-32: Export did nothing.
                                  function: () => _exportApplications(apps),
                                  textStyle: StyleText.fontSize12Weight600.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  height: 32.h,
                                  space: 4.w,
                                  radius: 6,
                                  color: ColorPick.primary,
                                  image: 'assets/images/export.svg',
                                  widthImage: 14.sp,
                                  heightImage: 14.sp,
                                  colorBorder: ColorPick.primary,
                                  svgColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                                ),
                                SizedBox(width: 8.w),

                                // ── Grid toggle ──
                                customButtonWithImage(
                                  title: '',
                                  function: () => setState(() => _isGridView = true),
                                  textStyle: StyleText.fontSize14Weight400.copyWith(),
                                  height: 32.sp,
                                  width: 32.sp,
                                  space: 0,
                                  radius: 6,
                                  color: _isGridView ? ColorPick.primary : ColorPick.white,
                                  image: 'assets/images/grid.svg',
                                  widthImage: 16.sp,
                                  heightImage: 16.sp,
                                  colorBorder: Colors.transparent,
                                  svgColor: _isGridView ? Colors.white : AppColors.secondaryText,
                                ),
                                SizedBox(width: 4.w),

                                // ── List toggle ──
                                customButtonWithImage(
                                  title: '',
                                  function: () => setState(() => _isGridView = false),
                                  textStyle: StyleText.fontSize14Weight400.copyWith(),
                                  height: 32.sp,
                                  width: 32.sp,
                                  space: 0,
                                  radius: 6,
                                  color: !_isGridView ? ColorPick.primary : ColorPick.white,
                                  image: 'assets/images/table.svg',
                                  widthImage: 16.sp,
                                  heightImage: 16.sp,
                                  colorBorder: Colors.transparent,
                                  svgColor: !_isGridView ? Colors.white : AppColors.secondaryText,
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            // ── Summary cards with SVG icons ──
                            // BUG-16: stage cards become a 1-column list on a
                            // phone (they wrapped one letter per line).
                            AdminCardsRow(
                              phoneColumns: 1,
                              children: [
                                _summaryCard(
                                  'Applied',
                                  // BUG-170: + not-yet-reviewed, so the cards add up.
                                  'Pending: $appliedPending  Qualified: $appliedQualified  Unqualified: $appliedUnqualified',
                                  'assets/images/job_list/applied.svg',
                                ),
                                _summaryCard(
                                  'Interview',
                                  'Passed: $interviewPassed  Withdrew: $interviewWithdrew  Failed: $interviewFailed',
                                  'assets/images/job_list/interview.svg',
                                ),
                                _summaryCard(
                                  'Offer',
                                  'Approved: $offerApproved  Pending: $offerPending  Rejected: $offerRejected',
                                  'assets/images/job_list/offer.svg',
                                ),
                                _summaryCard(
                                  'Hired',
                                  'Completed: $hiredCompleted',
                                  'assets/images/job_list/hired.svg',
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),

                            // ── Content ──
                            if (apps.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.sp),
                                  // QA-Oct11 #24: Lottie, no text.
                                  child: const EmptyLottie(
                                      size: 220,
                                      semanticLabel: 'No applications found'),
                                ),
                              )
                            else
                              _isGridView ? _buildGrid(apps) : _buildTable(apps),

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

  // ── Filter Tab ─────────────────────────────────────────────────────────────
  Widget _filterTab(String label, int count, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isActive ? ColorPick.primary : ColorPick.white,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != 'All') ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.3) : ColorPick.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('$count', style: StyleText.fontSize11Weight600.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Colors.white)),
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: StyleText.fontSize13Weight500.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isActive ? Colors.white : AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary Card with SVG icon ─────────────────────────────────────────────
  Widget _summaryCard(String title, String details, String svgPath) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: ColorPick.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: Color(0xFFF1F2ED),
              shape: BoxShape.circle
            ),
            child: Center(
              child: SvgPicture.asset(
                svgPath,
                width: 16.sp,
                height: 16.sp,
                color: ColorPick.primary,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: StyleText.fontSize13Weight600.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
                SizedBox(height: 4.h),
                Text(details, style: StyleText.fontSize10Weight400.copyWith(fontSize: 10.sp, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ═════════════════════════════════════════════════════════════════════════════
//  APPLICATION CARD
// ═════════════════════════════════════════════════════════════════════════════
