// ******************* FILE INFO *******************
// File Name: job_listing_filter_dialog.dart
// Created by: Amr Mesbah
// Purpose: Filter dialog for Job Listing page — matches Figma design
// Fields: Departments, Locations, Employment Type, Years of Experience, Date
// Uses: CustomDropdownFormFieldInvMaster, _DatePickerField
// FIXED: Date picker now uses DatePicker().showDatePicker() from core/widget/date_picker.dart
// UPDATED: Dropdown hover color uses CMS primary color from Firebase

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:web_app_admin/core/constant/color.dart';
import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/custom_dropdwon.dart';
import 'package:web_app_admin/core/widget/date_pic.dart';
import 'package:web_app_admin/core/widget/date_picker.dart';

import '../../features/main/presentation/controller/main_cubit.dart';
import '../../features/main/presentation/controller/main_state.dart';



// ── Shared color palette ──────────────────────────────────────────────────────
class _C {
  static const Color primary = ColorPick.primary;
  static const Color cardBg  = Color(0xFFFFFFFF);
  static const Color label   = Color(0xFF333333);
  static const Color hint    = Color(0xFFAAAAAA);
  static const Color resetBg = Color(0xFFEEEEEE);
}

// ── CMS primary color helper ──────────────────────────────────────────────────
Color _cmsHexColor(String hex) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {}
  return ColorPick.primary;
}


// ═════════════════════════════════════════════════════════════════════════════
//  DATA MODEL  ─ carries selected filter values back to the caller
// ═════════════════════════════════════════════════════════════════════════════

class JobListingFilterData {
  final String?   department;
  final String?   location;
  final String?   employmentType;
  final String?   yearsOfExperience;
  final DateTime? date;

  const JobListingFilterData({
    this.department,
    this.location,
    this.employmentType,
    this.yearsOfExperience,
    this.date,
  });

  bool get isEmpty =>
      department == null &&
          location == null &&
          employmentType == null &&
          yearsOfExperience == null &&
          date == null;
}

// ═════════════════════════════════════════════════════════════════════════════
//  PUBLIC API  ─ call from the Filter button inside JobListingMainPage
// ═════════════════════════════════════════════════════════════════════════════

Future<JobListingFilterData?> showJobListingFilterDialog(
    BuildContext context, {
      JobListingFilterData?        initial,
      List<Map<String, String>>?   departments,
      List<Map<String, String>>?   locations,
      List<Map<String, String>>?   employmentTypes,
      List<Map<String, String>>?   yearsOfExperienceList,
    }) {
  return showDialog<JobListingFilterData>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _JobListingFilterDialog(
      initial:               initial,
      departments:           departments           ?? _kDepts,
      locations:             locations             ?? _kLocations,
      employmentTypes:       employmentTypes       ?? _kEmpTypes,
      yearsOfExperienceList: yearsOfExperienceList ?? _kYearsOfExp,
    ),
  );
}

// ── Default lookup data  (replace with real data from Cubit / Firebase) ───────
const _kDepts = [
  {'key': 'engineering', 'value': 'Engineering'},
  {'key': 'design',      'value': 'Design'},
  {'key': 'marketing',   'value': 'Marketing'},
  {'key': 'hr',          'value': 'Human Resources'},
  {'key': 'finance',     'value': 'Finance'},
  {'key': 'operations',  'value': 'Operations'},
];
const _kLocations = [
  {'key': 'cairo',  'value': 'Cairo, Egypt'},
  {'key': 'alex',   'value': 'Alexandria, Egypt'},
  {'key': 'giza',   'value': 'Giza, Egypt'},
  {'key': 'remote', 'value': 'Remote (Worldwide)'},
];
const _kEmpTypes = [
  {'key': 'full_time',  'value': 'Full-Time'},
  {'key': 'part_time',  'value': 'Part-Time'},
];
// BUG-43: the same Experience Levels as the job form (the filter offered
// year ranges that don't exist on jobs).
const _kYearsOfExp = [
  {'key': 'intern',     'value': 'Intern'},
  {'key': 'junior',     'value': 'Junior'},
  {'key': 'senior',     'value': 'Senior'},
  {'key': 'leadership', 'value': 'Leadership'},
];

/// BUG-43: readable label for a filter key (chips showed "part_time").
String jobFilterLabel(String key) {
  for (final list in [_kDepts, _kLocations, _kEmpTypes, _kYearsOfExp]) {
    for (final m in list) {
      if (m['key'] == key) return m['value'] ?? key;
    }
  }
  return key;
}

// ═════════════════════════════════════════════════════════════════════════════
//  DIALOG  (private)
// ═════════════════════════════════════════════════════════════════════════════

class _JobListingFilterDialog extends StatefulWidget {
  final JobListingFilterData?      initial;
  final List<Map<String, String>>  departments;
  final List<Map<String, String>>  locations;
  final List<Map<String, String>>  employmentTypes;
  final List<Map<String, String>>  yearsOfExperienceList;

  const _JobListingFilterDialog({
    this.initial,
    required this.departments,
    required this.locations,
    required this.employmentTypes,
    required this.yearsOfExperienceList,
  });

  @override
  State<_JobListingFilterDialog> createState() =>
      _JobListingFilterDialogState();
}

class _JobListingFilterDialogState
    extends State<_JobListingFilterDialog> {

  String?   _dept;
  String?   _loc;
  String?   _emp;
  String?   _yoe;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _dept = i.department;
      _loc  = i.location;
      _emp  = i.employmentType;
      _yoe  = i.yearsOfExperience;
      _date = i.date;
    }
  }

  void _reset() => setState(() {
    _dept = null;
    _loc  = null;
    _emp  = null;
    _yoe  = null;
    _date = null;
  });

  void _apply() => Navigator.of(context).pop(
    JobListingFilterData(
      department:        _dept,
      location:          _loc,
      employmentType:    _emp,
      yearsOfExperience: _yoe,
      date:              _date,
    ),
  );

  Future<void> _pickDate() async {
    final result = await DatePicker().showDatePicker(
      context,
      [_date],
      _date ?? DateTime.now(),
      CalendarDatePicker2Type.single,
    );

    if (result != null && result.isNotEmpty && result.first != null) {
      setState(() => _date = result.first);
    }
  }

  // ── Dropdown helper — reads primary from CMS ──────────────────────────────
  Widget _dd({
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    required Color primary,
  }) {
    return CustomDropdownFormFieldInvMaster(
      selectedValue: value,
      items:         items,
      onChanged:     onChanged,
      widthIcon:     22,
      heightIcon:    22,
      height:        50,
      dropdownColor: const Color(0xFFF5F5F5),
      borderRadius:  8,
      primaryColor:  primary,   // ← CMS branding color
      hint: Text(
        hint,
        style: TextStyle(
          fontSize:   13.sp,
          color:      _C.hint,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  String get _dateStr {
    if (_date == null) return '';
    return DateTimeHelper.formatDate(_date!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, cmsState) {
        // BUG-42: the admin's own red — not the public site's (green) CMS
        // colour, which made this dialog look like part of another app.
        final Color primary = ColorPick.primary;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Container(
            constraints: BoxConstraints(maxWidth: 920.w),
            padding: EdgeInsets.all(28.w),
            decoration: BoxDecoration(
              color:        _C.cardBg,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40.sp, height: 40.sp,
                      decoration: BoxDecoration(
                        color: primary,        // ← CMS color
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: Colors.white, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize:   22.sp,
                        fontWeight: FontWeight.w700,
                        color:      _C.label,
                      ),
                    ),
                    const Spacer(),
                    // BUG-42: a visible way to close without applying.
                    IconButton(
                      tooltip: 'Close',
                      icon: Icon(Icons.close_rounded, color: _C.label, size: 22.sp),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // ── Row 1: Departments | Locations ───────────────────────
                Row(
                  children: [
                    Expanded(child: _dd(
                        hint: 'Departments', value: _dept,
                        items: widget.departments,
                        primary: primary,
                        onChanged: (v) => setState(() => _dept = v))),
                    SizedBox(width: 16.w),
                    Expanded(child: _dd(
                        hint: 'Locations', value: _loc,
                        items: widget.locations,
                        primary: primary,
                        onChanged: (v) => setState(() => _loc = v))),
                  ],
                ),
                SizedBox(height: 14.h),

                // ── Row 2: Employment Type | Years Of Experience ─────────
                Row(
                  children: [
                    Expanded(child: _dd(
                        hint: 'Employment Type', value: _emp,
                        items: widget.employmentTypes,
                        primary: primary,
                        onChanged: (v) => setState(() => _emp = v))),
                    SizedBox(width: 16.w),
                    Expanded(child: _dd(
                        hint: 'Experience Level', value: _yoe,
                        items: widget.yearsOfExperienceList,
                        primary: primary,
                        onChanged: (v) => setState(() => _yoe = v))),
                  ],
                ),
                SizedBox(height: 14.h),

                // ── Row 3: Date (half-width) ─────────────────────────────
                FractionallySizedBox(
                  widthFactor: 0.49,
                  child: _DatePickerField(
                    dateLabel: _dateStr,
                    onTap:     _pickDate,
                  ),
                ),
                SizedBox(height: 28.h),

                // ── Action buttons ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52.h,
                        child: TextButton(
                          onPressed: _reset,
                          style: TextButton.styleFrom(
                            backgroundColor: Color(0xFFD9D9D9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text('Reset',
                              style: TextStyle(
                                  fontSize:   15.sp,
                                  fontWeight: FontWeight.w600,
                                  color:      Colors.black)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: SizedBox(
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,  // ← CMS color
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text('Apply',
                              style: TextStyle(
                                  fontSize:   15.sp,
                                  fontWeight: FontWeight.w600,
                                  color:      Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  DATE PICKER FIELD  —  styled to match the dropdowns above
// ═════════════════════════════════════════════════════════════════════════════

class _DatePickerField extends StatelessWidget {
  final String       dateLabel;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = dateLabel.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color:        const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? dateLabel : 'Date',
                style: TextStyle(
                  fontSize:   13.sp,
                  color:      hasValue ? _C.label : _C.hint,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CustomSvg(
              assetPath: 'assets/images/calender.svg',
              width:  20.w,
              height: 20.h,
              fit:    BoxFit.fill,
            ),
          ],
        ),
      ),
    );
  }
}