// ═══════════════════════════════════════════════════════════════════
// FILE: application_filter_dialog.dart
// Path: lib/core/main_widgets/application_filter_dialog.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_app_admin/core/widget/custom_dropdwon.dart';

import '../../features/job/data/models/application_model.dart';

class _C {
  // BUG-35: admin red, not the site's green.
  static const Color primary = Color(0xFFD31426);
  static const Color cardBg  = Color(0xFFFFFFFF);
  static const Color label   = Color(0xFF333333);
  static const Color hint    = Color(0xFFAAAAAA);
  static const Color resetBg = Color(0xFFEEEEEE);
  static const Color fieldBg = Color(0xFFF5F5F5);
}

// ═════════════════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═════════════════════════════════════════════════════════════════════════════

class ApplicationFilterData {
  final String? sortBy;
  final String? score;
  final String? employmentType;
  final String? yearsOfExperience;
  final String? status;
  final String? stage;

  const ApplicationFilterData({
    this.sortBy,
    this.score,
    this.employmentType,
    this.yearsOfExperience,
    this.status,
    this.stage,
  });

  bool get isEmpty =>
      sortBy == null &&
          score == null &&
          employmentType == null &&
          yearsOfExperience == null &&
          status == null &&
          stage == null;
}

// ═════════════════════════════════════════════════════════════════════════════
//  PUBLIC API
// ═════════════════════════════════════════════════════════════════════════════

Future<ApplicationFilterData?> showApplicationFilterDialog(
    BuildContext context, {
      ApplicationFilterData? initial,
    }) {
  return showDialog<ApplicationFilterData>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _ApplicationFilterDialog(initial: initial),
  );
}

// ── Default lookup data ───────────────────────────────────────────────────────
const _kSortBy = [
  {'key': 'date_desc', 'value': 'Newest First'},
  {'key': 'date_asc',  'value': 'Oldest First'},
  {'key': 'name_asc',  'value': 'Name A–Z'},
  {'key': 'name_desc', 'value': 'Name Z–A'},
];
const _kScore = [
  {'key': 'strong',   'value': 'Strong'},
  {'key': 'adequate', 'value': 'Adequate'},
  {'key': 'weak',     'value': 'Weak'},
];
const _kEmpTypes = [
  {'key': 'full_time',  'value': 'Full Time'} /* BUG-157 */,
  {'key': 'part_time',  'value': 'Part Time'} /* BUG-157 */,
  {'key': 'contract',   'value': 'Contract'},
  {'key': 'internship', 'value': 'Internship'},
  {'key': 'freelance',  'value': 'Freelance'},
];
const _kYearsOfExp = [
  {'key': '0_1',  'value': '0 – 1 year'},
  {'key': '1_3',  'value': '1 – 3 years'},
  {'key': '3_5',  'value': '3 – 5 years'},
  {'key': '5_10', 'value': '5 – 10 years'},
  {'key': '10+',  'value': '10+ years'},
];

final _kStatuses = ApplicationStatus.values
    .map((s) => {'key': s.label, 'value': s.label})
    .toList();

const _kStages = [
  {'key': 'Applied',   'value': 'Applied'},
  {'key': 'Interview', 'value': 'Interview'},
  {'key': 'Offer',     'value': 'Offer'},
  {'key': 'Hired',     'value': 'Hired'},
];

// ═════════════════════════════════════════════════════════════════════════════
//  DIALOG (private)
// ═════════════════════════════════════════════════════════════════════════════

class _ApplicationFilterDialog extends StatefulWidget {
  final ApplicationFilterData? initial;
  const _ApplicationFilterDialog({this.initial});

  @override
  State<_ApplicationFilterDialog> createState() =>
      _ApplicationFilterDialogState();
}

class _ApplicationFilterDialogState extends State<_ApplicationFilterDialog> {
  String? _sortBy;
  String? _score;
  String? _emp;
  String? _yoe;
  String? _status;
  String? _stage;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _sortBy = i.sortBy;
      _score  = i.score;
      _emp    = i.employmentType;
      _yoe    = i.yearsOfExperience;
      _status = i.status;
      _stage  = i.stage;
    }
  }

  void _reset() => setState(() {
    _sortBy = null;
    _score  = null;
    _emp    = null;
    _yoe    = null;
    _status = null;
    _stage  = null;
  });

  void _apply() => Navigator.of(context).pop(
    ApplicationFilterData(
      sortBy:            _sortBy,
      score:             _score,
      employmentType:    _emp,
      yearsOfExperience: _yoe,
      status:            _status,
      stage:             _stage,
    ),
  );

  Widget _dd({
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return CustomDropdownFormFieldInvMaster(
      selectedValue: value,
      items:         items,
      onChanged:     onChanged,
      widthIcon:     18,
      heightIcon:    18,
      height:        36,          // ← fixed height
      dropdownColor: _C.fieldBg,
      borderRadius:  8,
      hint: Text(
        hint,
        style: TextStyle(
          fontSize:   12.sp,
          color:      _C.hint,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
      child: Container(
        width:  654.w,           // ← fixed width
        constraints: BoxConstraints(maxWidth: 654.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36.sp, height: 36.sp,
                  decoration: const BoxDecoration(
                    color: _C.primary, shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.tune_rounded, color: Colors.white, size: 18.sp),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Filter', // BUG-35: the Filter button opened a dialog titled "Sort"
                  style: TextStyle(
                    fontSize:   20.sp,
                    fontWeight: FontWeight.w700,
                    color:      _C.label,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close_rounded, color: _C.label, size: 20.sp),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Row 1: Sort By | Score ───────────────────────────────────────
            Row(
              children: [
                Expanded(child: _dd(
                  hint: 'Sort By', value: _sortBy,
                  items: _kSortBy,
                  onChanged: (v) => setState(() => _sortBy = v),
                )),
                SizedBox(width: 14.w),
                Expanded(child: _dd(
                  hint: 'Score', value: _score,
                  items: _kScore,
                  onChanged: (v) => setState(() => _score = v),
                )),
              ],
            ),
            SizedBox(height: 12.h),

            // ── Row 2: Employment Type | Years Of Experience ─────────────────
            Row(
              children: [
                Expanded(child: _dd(
                  hint: 'Employment Type', value: _emp,
                  items: _kEmpTypes,
                  onChanged: (v) => setState(() => _emp = v),
                )),
                SizedBox(width: 14.w),
                Expanded(child: _dd(
                  hint: 'Years Of Experience', value: _yoe,
                  items: _kYearsOfExp,
                  onChanged: (v) => setState(() => _yoe = v),
                )),
              ],
            ),
            SizedBox(height: 12.h),

            // ── Row 3: Status | Stage ────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _dd(
                  hint: 'Status', value: _status,
                  items: _kStatuses,
                  onChanged: (v) => setState(() => _status = v),
                )),
                SizedBox(width: 14.w),
                Expanded(child: _dd(
                  hint: 'Stage', value: _stage,
                  items: _kStages,
                  onChanged: (v) => setState(() => _stage = v),
                )),
              ],
            ),
            SizedBox(height: 24.h),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36.h,        // ← fixed height
                    child: TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        backgroundColor: _C.resetBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize:   13.sp,
                          fontWeight: FontWeight.w600,
                          color:      _C.label,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: SizedBox(
                    height: 36.h,        // ← fixed height
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontSize:   13.sp,
                          fontWeight: FontWeight.w600,
                          color:      Colors.white,
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
    );
  }
}