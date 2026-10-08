// ═══════════════════════════════════════════════════════════════════
// FILE: inquiry_details.dart (Detail / Edit Page)
// Path: lib/features/inquire/presentation/ui/pages/inquiry_details.dart
// UPDATED: Status dropdown primaryColor driven by MainCmsCubit (same
//          logic as AppNavbar) instead of a hardcoded constant.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/custom/2-custom_textfield.dart';
import '../../../../../core/widget/custom_dropdwon.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/inquiry_model.dart';
import '../../controller/inquiry_cubit.dart';
import '../../controller/inquiry_state.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';




// ── Same helper used in AppNavbar ─────────────────────────────────────────────
Color _primaryFromCmsState(MainCmsState state) {
  final String hex = switch (state) {
    MainCmsLoaded(:final data) => data.branding.primaryColor,
    MainCmsSaved(:final data)  => data.branding.primaryColor,
    _                          => '',
  };
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {}
  return ColorPick.primary; // fallback
}

// ─────────────────────────────────────────────────────────────────────────────

class InquiryDetailPage extends StatefulWidget {
  final String inquiryId;
  const InquiryDetailPage({super.key, required this.inquiryId});

  @override
  State<InquiryDetailPage> createState() => _InquiryDetailPageState();
}

class _InquiryDetailPageState extends State<InquiryDetailPage> {
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;
  bool _didLoad  = false;
  InquiryModel? _current;

  @override
  void initState() {
    super.initState();
    context.read<InquiryCubit>().loadDetail(widget.inquiryId);
  }

  void _seed(InquiryModel inq) {
    if (_didLoad) return;
    _didLoad = true;
    _current = inq;
    _noteCtrl.text = inq.note;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onStatusChange(InquiryModel inq, InquiryStatus newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.asset('assets/images/dashboard_image.svg', height: 120.h, fit: BoxFit.contain),
            SizedBox(height: 20.h),
            Text('CHANGE SUBMISSION STATUS',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
            SizedBox(height: 12.h),
            Text(
              'Are you sure you want to change this Submissions status from ${inq.status.label} to ${newStatus.label}?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText, height: 1.5),
            ),
            SizedBox(height: 24.h),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6.r)),
                  child: Center(child: Text('Back', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.text))),
                ),
              )),
              SizedBox(width: 16.w),
              Expanded(child: GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.read<InquiryCubit>().updateStatus(inq.id, newStatus);
                },
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
                  child: Center(child: Text('Confirm', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (_current == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.asset('assets/images/dashboard_image.svg', height: 120.h, fit: BoxFit.contain),
            SizedBox(height: 20.h),
            Text('SAVING SUBMISSION',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
            SizedBox(height: 12.h),
            Text('Are you sure you want to Edit This Submissions?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText, height: 1.5)),
            SizedBox(height: 24.h),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6.r)),
                  child: Center(child: Text('Back', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.text))),
                ),
              )),
              SizedBox(width: 16.w),
              Expanded(child: GestureDetector(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  setState(() => _isSaving = true);
                  await context.read<InquiryCubit>().updateNote(_current!.id, _noteCtrl.text);
                  if (mounted) {
                    setState(() => _isSaving = false);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
                  child: Center(child: Text('Confirm', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Read CMS primary color (same source as AppNavbar) ────────────────────
    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, cmsState) {
        final Color cmsPrimary = _primaryFromCmsState(cmsState);

        return BlocBuilder<InquiryCubit, InquiryState>(
          builder: (context, state) {
            InquiryModel? inq;
            if (state is InquiryDetailLoaded) inq = state.inquiry;
            if (state is InquiryUpdated)       inq = state.inquiry;

            if (inq == null) {
              return const Scaffold(
                backgroundColor: ColorPick.background,
                body: Center(child: CircleProgress()),
              );
            }

            _seed(inq);
            _current = inq;

            final dateStr = inq.submissionDate != null
                ? '${inq.submissionDate!.day} ${_month(inq.submissionDate!.month)} ${inq.submissionDate!.year}'
                : '';

            // Status options based on current status
            final List<InquiryStatus> statusOptions;
            switch (inq.status) {
              case InquiryStatus.newInquiry:
                statusOptions = [InquiryStatus.newInquiry, InquiryStatus.replied, InquiryStatus.closed];
              case InquiryStatus.replied:
                statusOptions = [InquiryStatus.replied, InquiryStatus.closed];
              case InquiryStatus.closed:
                statusOptions = [InquiryStatus.closed];
            }

            return Scaffold(
              backgroundColor: ColorPick.background,
              body: Stack(children: [
                AdminStickyBody(
  children: [
                      AppAdminNavbar(
                        activeLabel: 'Inquiries',
                        homePage: CareersMainPageDashboard(),
                        webPage: MainMainPage(),
                        jobListingPage: JobListingMainPage(),
                      ),

                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                        child: SizedBox(
                          width: 1000.w,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Submission Details',
                                  style: StyleText.fontSize45Weight600.copyWith(
                                      color: cmsPrimary, fontWeight: FontWeight.w700)),
                              SizedBox(height: 12.h),

                              // ── Date + Status dropdown ───────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text('Submission Date: ',
                                          style: TextStyle(fontSize: 13.sp, color: AppColors.text)),
                                      Text(dateStr,
                                          style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText)),
                                    ],
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 160.w,
                                    child: CustomDropdownFormFieldInvMaster(
                                      selectedValue: inq.status.name,
                                      widthIcon: 18,
                                      heightIcon: 18,
                                      height: 36,
                                      borderRadius: 4,
                                      dropdownColor: Colors.white,
                                      showColorDots: true,
                                      // ✅ CMS-driven primary color — same as navbar
                                      primaryColor: cmsPrimary,
                                      items: statusOptions
                                          .map((s) => {'key': s.name, 'value': s.label})
                                          .toList(),
                                      onChanged: (val) {
                                        if (val == null) return;
                                        final newStatus = InquiryStatus.values
                                            .firstWhere((s) => s.name == val);
                                        if (newStatus != inq?.status) {
                                          _onStatusChange(inq!, newStatus);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),

                              // ── Form card ───────────────────────────────
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16.sp),
                                decoration: BoxDecoration(
                                  color: ColorPick.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: _readRow('Preferred Language', inq.preferredLanguage)),
                                      SizedBox(width: 16.w),
                                      Expanded(child: Container()),
                                    ]),
                                    SizedBox(height: 12.h),
                                    Row(children: [
                                      Expanded(child: _readRow('First Name', inq.firstName)),
                                      SizedBox(width: 16.w),
                                      Expanded(child: _readRow('Last Name', inq.lastName)),
                                    ]),
                                    SizedBox(height: 12.h),
                                    Row(children: [
                                      Expanded(child: _readRow('Email', inq.email)),
                                      SizedBox(width: 16.w),
                                      Expanded(child: _readRow('Phone Number', '${inq.countryCode} ${inq.phone}')),
                                    ]),
                                    SizedBox(height: 12.h),
                                    Row(children: [
                                      Expanded(child: _readRow('Location', inq.location)),
                                      SizedBox(width: 16.w),
                                      Expanded(child: _readRow("Entity's Name", inq.entityName)),
                                    ]),
                                    SizedBox(height: 12.h),
                                    Row(children: [
                                      Expanded(child: _readRow("Entity's Type", inq.entityType)),
                                      SizedBox(width: 16.w),
                                      Expanded(child: _readRow("Entity's Size", inq.entitySize)),
                                    ]),
                                    SizedBox(height: 12.h),
                                    _readRow('Subject', inq.subject),
                                    SizedBox(height: 12.h),
                                    _readRow('Message', inq.message, multiLine: true),
                                    SizedBox(height: 12.h),

                                    // ── Our Notes (editable) ────────────
                                    Text('Our Notes',
                                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.text)),
                                    SizedBox(height: 6.h),
                                    CustomTextField(
                                      controller: _noteCtrl,
                                      maxLines: 4,
                                      height: 80,
                                      valueStyle: TextStyle(fontSize: 12.sp, color: AppColors.text),
                                      hint: 'Text Here',
                                      hintStyle: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
                                      fillColor: const Color(0xFFF1F2ED),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // ── Discard / Submit ─────────────────────────
                              Row(children: [
                                Expanded(child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 48.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF797979),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('Discard',
                                        style: StyleText.fontSize14Weight600.copyWith(color: Colors.white)),
                                  ),
                                )),
                                SizedBox(width: 16.w),
                                Expanded(child: GestureDetector(
                                  onTap: _isSaving ? null : _onSubmit,
                                  child: Container(
                                    height: 48.h,
                                    decoration: BoxDecoration(
                                      // ✅ Submit button also uses CMS primary
                                      color: cmsPrimary,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: _isSaving
                                        ? SizedBox(width: 20.w, height: 20.h,
                                        child: const CircleProgress())
                                        : Text('Submit',
                                        style: StyleText.fontSize14Weight600.copyWith(color: Colors.white)),
                                  ),
                                )),
                              ]),
                              SizedBox(height: 40.h),
                            ],
                          ),
                        ),
                      ),
                    ],
),

                if (_isSaving)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircleProgress()),
                  ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _readRow(String label, String value, {bool multiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.text)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          height: multiLine ? 80.h : 36.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: multiLine ? 8.h : 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2ED),
            borderRadius: BorderRadius.circular(4.r),
          ),
          alignment: multiLine ? Alignment.topLeft : Alignment.centerLeft,
          child: Text(
            value.isEmpty ? 'Text Here' : value,
            style: StyleText.fontSize12Weight400.copyWith(
                color: value.isEmpty ? AppColors.secondaryText : AppColors.text),
            maxLines: multiLine ? 4 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}