// ═══════════════════════════════════════════════════════════════════
// department_edit.dart  (Edit Page)
// Path: lib/features/departments/presentation/ui/pages/department_edit.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../../../core/widget/success_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/textfield.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/image_upload_circle.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../job/data/models/job_listing_model.dart';
import '../../../../job/presentation/controller/job_listing_cubit.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/department_model.dart';
import '../../controller/department_cubit.dart';
import '../../controller/department_state.dart';
import '../widgets/department_image_field.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/custom/16-custom_dialog_manager.dart';


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color grey      = Color(0xFF797979);
//   static const Color red       = Color(0xFFD32F2F);
// }

class DepartmentEditPage extends StatefulWidget {
  final DepartmentModel department;

  const DepartmentEditPage({super.key, required this.department});

  @override
  State<DepartmentEditPage> createState() => _DepartmentEditPageState();
}

class _DepartmentEditPageState extends State<DepartmentEditPage> {
  final Map<String, bool> _open = {'dept_info': true};

  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;

  bool _submitted = false;
  bool _isSaving  = false;
  /// BUG-86: department image (uploaded by DepartmentImageField).
  late String _iconUrl = widget.department.iconUrl;
  String? _nameEnError;
  String? _nameArError;

  /// BUG-46: a sane cap (168-character names were accepted).
  static const int _kMaxNameLength = 60;

  /// Jobs (not removed) that still point at this department.
  List<JobPostModel> _jobsInDepartment() {
    try {
      return context
          .read<JobListingCubit>()
          .allJobs
          .where((j) =>
              j.status != JobStatus.removed &&
              widget.department.matchesJob(j.department))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// BUG-46: same rules as the Create form, with visible error text.
  bool _validate() {
    final cubit  = context.read<DepartmentCubit>();
    final nameEn = _nameEnController.text.trim();
    final nameAr = _nameArController.text.trim();
    String? enError;
    String? arError;
    if (nameEn.isEmpty) {
      enError = 'This field is required.';
    } else if (cubit.nameExists(nameEn, excludeId: widget.department.id)) {
      enError = 'A department with this name already exists.';
    }
    if (nameAr.isEmpty) {
      arError = 'هذا الحقل مطلوب.';
    } else if (cubit.nameExists(nameAr, excludeId: widget.department.id)) {
      arError = 'يوجد قسم بهذا الاسم بالفعل.';
    }
    setState(() {
      _nameEnError = enError;
      _nameArError = arError;
    });
    return enError == null && arError == null;
  }

  Widget _errorText(String? message) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            message,
            style: StyleText.fontSize11Weight400.copyWith(color: ColorPick.red),
          ),
        );

  @override
  void initState() {
    super.initState();
    _nameEnController =
        TextEditingController(text: widget.department.nameEn);
    _nameArController =
        TextEditingController(text: widget.department.nameAr);
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  // ── Discard ───────────────────────────────────────────────────────────────
  void _onDiscard() => Navigator.pop(context);

  // ── Save ──────────────────────────────────────────────────────────────────
  void _onSave() {
    setState(() => _submitted = true);
    // BUG-46: Save with an empty name used to do nothing at all.
    if (!_validate()) return;
    final String oldEn = widget.department.nameEn;
    _showConfirmDialog(
      title:        'EDITING DEPARTMENT DETAILS',
      message:      'Do you want to save the changes made to this Department information?',
      confirmLabel: 'Confirm',
      confirmColor: ColorPick.primary,
      onConfirm: () async {
        Navigator.of(context).pop(); // close dialog
        setState(() => _isSaving = true);

        final affected = _jobsInDepartment();
        final jobCubit = context.read<JobListingCubit>();
        final newEn = _nameEnController.text.trim();
        await context.read<DepartmentCubit>().updateDepartment(
          id:      widget.department.id,
          nameEn:  newEn,
          nameAr:  _nameArController.text.trim(),
          iconUrl: _iconUrl, // BUG-86 (was dropped → '' on every save)
        );
        // BUG-30: jobs store the department NAME, so a rename used to orphan
        // them ("Select Department" in the job form). Move them along.
        if (newEn != oldEn) {
          for (final j in affected) {
            await jobCubit.updateJob(j.copyWith(department: newEn));
          }
        }
      },
    );
  }

  // ── Remove ────────────────────────────────────────────────────────────────
  void _onRemove() {
    // BUG-30: deleting a department that still has jobs broke those jobs
    // (JS errors, "Select Department", ghost department on the dashboard).
    final jobs = _jobsInDepartment();
    if (jobs.isNotEmpty) {
      // Message only — closes itself after 3 s (no Back / OK buttons).
      CustomDialogManager.showMessage(
        context:   context,
        title:     'CAN\'T DELETE DEPARTMENT',
        message:
        'This department has ${jobs.length} job${jobs.length == 1 ? '' : 's'}. '
            'Move ${jobs.length == 1 ? 'it' : 'them'} to another department '
            '(or remove ${jobs.length == 1 ? 'it' : 'them'}) first.',
        imagePath: 'assets/images/department_icon.svg',
      );
      return;
    }
    _showConfirmDialog(
      title:        'DELETE DEPARTMENT',
      message:
      'Are you sure you want to permanently delete this Department? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: ColorPick.red,
      onConfirm: () async {
        Navigator.of(context).pop(); // close dialog
        setState(() => _isSaving = true);

        await context
            .read<DepartmentCubit>()
            .deleteDepartment(id: widget.department.id);
      },
    );
  }

  // ── Dialog ────────────────────────────────────────────────────────────────
  void _showConfirmDialog({
    required String        title,
    required String        message,
    required String        confirmLabel,
    required Color         confirmColor,
    required VoidCallback  onConfirm,
  }) {
    showDialog(
      context:           context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width:   450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/department_icon.svg',
                height: 120.h,
                fit:    BoxFit.contain,
              ),
              SizedBox(height: 20.h),

              Text(
                title,
                style: TextStyle(
                    fontSize:   18.sp,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.text),
              ),
              SizedBox(height: 12.h),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.sp, color: AppColors.secondaryText, height: 1.5),
              ),
              SizedBox(height: 24.h),

              Row(children: [
                // Back
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      height: 44.h,
                      decoration: BoxDecoration(
                        color:        ColorPick.back,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      alignment: Alignment.center,
                      child: Text('Back',
                          style: StyleText.fontSize16Weight500
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Confirm / Delete
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      height: 44.h,
                      decoration: BoxDecoration(
                        color:        confirmColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(confirmLabel,
                          style: TextStyle(
                              fontSize:   14.sp,
                              fontWeight: FontWeight.w600,
                              color:      Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DepartmentCubit, DepartmentState>(
      listener: (context, state) {
        if (state is DepartmentError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is DepartmentUpdated || state is DepartmentDeleted) {
          setState(() => _isSaving = false);
          // BUG-46: confirm the save (root-overlay toast survives the pops).
          showSuccessToast(
              context,
              state is DepartmentDeleted
                  ? 'Department deleted'
                  : 'Department saved');
          final cubit = context.read<DepartmentCubit>();
          // pop twice: edit page → detail page → main page
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
          cubit.loadDepartments(silent: true);
        }
      },
      child: Scaffold(
        backgroundColor: ColorPick.background,
        body: Stack(
          children: [
            AdminStickyBody(
  children: [
                    AppAdminNavbar(
                      activeLabel:    'Job Listing',
                      homePage:       CareersMainPageDashboard(),
                      webPage:        MainMainPage(),
                      jobListingPage: JobListingMainPage(),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 0.h),
                      child: SizedBox(
                        width: 1000.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title ──
                            Text(
                              'Editing Department Details',
                              style: StyleText.fontSize45Weight600.copyWith(
                                color:      ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: _onRemove,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color:        ColorPick.red,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text('Remove',
                                        style: TextStyle(
                                            fontSize:   12.sp,
                                            fontWeight: FontWeight.w600,
                                            color:      Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15.h),

                            // ── Accordion ──
                            _accordion(
                              key:      'dept_info',
                              title:    'Department Information',
                              children: [_editableSection()],
                            ),

                            SizedBox(height: 20.h),

                            // ── Discard / Save ──
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _onDiscard,
                                    child: Container(
                                      height:    48.h,
                                      decoration: BoxDecoration(
                                        color:        ColorPick.discard,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('Discard',
                                          style: StyleText.fontSize14Weight600
                                              .copyWith(color: Colors.white)),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 300.w),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isSaving ? null : _onSave,
                                    child: Container(
                                      height:    48.h,
                                      decoration: BoxDecoration(
                                        color:        ColorPick.primary,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: _isSaving
                                          ? SizedBox(
                                        width:  20.w,
                                        height: 20.h,
                                        child: const CircleProgress(),
                                      )
                                          : Text('Save',
                                          style: StyleText.fontSize14Weight600
                                              .copyWith(color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ],
),

            // ── Loading overlay ──
            if (_isSaving)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircleProgress(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Accordion ──────────────────────────────────────────────────────────────
  Widget _accordion({
    required String       key,
    required String       title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Editable Section ───────────────────────────────────────────────────────
  Widget _editableSection() {
    return Container(
      width:   double.infinity,

      decoration: BoxDecoration(

        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(6.r),
          bottomRight: Radius.circular(6.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: 20.h),
          // ── BUG-86: Department Image ──
          DepartmentImageField(
            url: _iconUrl,
            enabled: !_isSaving,
            onChanged: (u) => setState(() => _iconUrl = u),
          ),
          SizedBox(height: 20.h),

          // ── Name EN / AR ──
          Row(
            children: [
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  label:          'Department Name',
                  hint:           'Text Here',
                  controller:     _nameEnController,
                  onChanged: (_) {
                    if (_nameEnError != null) setState(() => _nameEnError = null);
                  },
                  height:         36,
                  maxLines:       1,
                  textDirection:  TextDirection.ltr,
                  textAlign:      TextAlign.start,
                  showCharCount:  false,
                  maxLength: _kMaxNameLength, // BUG-46
                  minLength:      0,
                  submitted:      _submitted,
                  primaryColor:   ColorPick.primary,
                  fillColor:      ColorPick.white,
                  textStyle: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.text),
                  hintStyle: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: CustomValidatedTextFieldMaster(
                    label:         'اسم القسم',
                    hint:          'ادخل النص هنا',
                    controller:    _nameArController,
                    onChanged: (_) {
                      if (_nameArError != null) setState(() => _nameArError = null);
                    },
                    height:        36,
                    maxLines:      1,
                    textDirection: TextDirection.rtl,
                    textAlign:     TextAlign.start,
                    showCharCount: false,
                    maxLength: _kMaxNameLength, // BUG-46
                    minLength:     0,
                    submitted:     _submitted,
                    primaryColor:  ColorPick.primary,
                    fillColor:     ColorPick.white,
                    textStyle: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.text),
                    hintStyle: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
              ),
            ],
          ),
          // BUG-46: visible error text, like the Create form.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _errorText(_nameEnError)),
              SizedBox(width: 15.w),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: _errorText(_nameArError),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
