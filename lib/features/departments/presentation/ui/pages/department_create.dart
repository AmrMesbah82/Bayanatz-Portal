// ═══════════════════════════════════════════════════════════════════
// FILE 7: department_create.dart (Create Page)
// Path: lib/features/departments/presentation/ui/pages/department_create.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/main_widgets/admin_back_link.dart';
import 'package:web_app_admin/core/widget/success_toast.dart';
import 'package:web_app_admin/core/custom_dialog.dart' show confirmDiscard;
import 'package:web_app_admin/core/main_widgets/admin_layout.dart';
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
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../controller/department_cubit.dart';
import '../../controller/department_state.dart';
import '../widgets/department_image_field.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';



// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
// }

class DepartmentCreatePage extends StatefulWidget {
  const DepartmentCreatePage({super.key});

  @override
  State<DepartmentCreatePage> createState() => _DepartmentCreatePageState();
}

class _DepartmentCreatePageState extends State<DepartmentCreatePage> {
  final Map<String, bool> _open = {'dept_info': true};

  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameArController = TextEditingController();

  bool _submitted = false;
  bool _isSaving  = false;
  /// BUG-86: department image (uploaded by DepartmentImageField).
  String _iconUrl = '';

  // Inline validation messages under each name field.
  String? _nameEnError;
  String? _nameArError;

  @override
  void initState() {
    super.initState();
    // The duplicate check reads the cubit's loaded list — make sure it is
    // fresh, otherwise a department added elsewhere would slip through.
    context.read<DepartmentCubit>().loadDepartments();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  // BUG-292: ask before throwing the form away (every other editor does).
  void _onDiscard() {
    confirmDiscard(context, onDiscard: () => Navigator.pop(context));
  }

  // ── Validation ────────────────────────────────────────────────────────────
  // Required + "no two departments may share a name". The name is compared
  // ignoring case and surrounding spaces, and against BOTH the English and
  // the Arabic name of every existing department.
  bool _validate() {
    final cubit = context.read<DepartmentCubit>();
    final nameEn = _nameEnController.text.trim();
    final nameAr = _nameArController.text.trim();

    String? enError;
    String? arError;

    if (nameEn.isEmpty) {
      enError = 'This field is required.';
    } else if (cubit.nameExists(nameEn)) {
      enError = 'A department with this name already exists.';
    }

    if (nameAr.isEmpty) {
      arError = 'هذا الحقل مطلوب.';
    } else if (cubit.nameExists(nameAr)) {
      arError = 'يوجد قسم بهذا الاسم بالفعل.';
    }

    setState(() {
      _nameEnError = enError;
      _nameArError = arError;
    });

    return enError == null && arError == null;
  }

  void _onCreate() {
    setState(() => _submitted = true);

    if (!_validate()) return;

    _showConfirmDialog(
      title: 'NEW DEPARTMENT',
      message:
      'You are about to publish a new Department. Please ensure all details are accurate before confirming.',
      confirmLabel: 'Submit',
      imagePath: 'assets/images/dashboard_image.svg',
      onConfirm: () async {
        Navigator.of(context).pop(); // close dialog
        setState(() => _isSaving = true);

        await context.read<DepartmentCubit>().createDepartment(
          nameEn:  _nameEnController.text.trim(),
          nameAr:  _nameArController.text.trim(),
          iconUrl: _iconUrl, // BUG-86
        );

        // DepartmentMainPage's BlocListener handles pop + reload
      },
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required String imagePath,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/images/department_icon.svg",
                  height: 120.h, fit: BoxFit.contain),
              SizedBox(height: 20.h),
              Text(
                title,
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
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
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      height: 44.h,
                      // BUG-287: light-grey Back, dark text (admin pattern).
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCDCDC),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Center(
                        child: Text(
                          'Back',
                          style: StyleText.fontSize14Weight600.copyWith(
                            color: AppColors.text
                          )
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: ColorPick.primary,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Center(
                        child: Text(
                          confirmLabel,
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
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
          // BUG-293: one error style (the shared toast).
          showSuccessToast(context, state.message, isError: true);
        }
        if (state is DepartmentCreated) {
          setState(() => _isSaving = false);
          // BUG-293: the same success toast as every other save.
          showSuccessToast(context, 'Department created');
          // Pop handled by DepartmentMainPage BlocListener
        }
      },
      child: Scaffold(
        backgroundColor: ColorPick.background,
        body: Stack(
          children: [
            AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  children: [
                    AppAdminNavbar(
                      activeLabel:    'Job Listing', // BUG-46: was 'Home'
                      homePage:       CareersMainPageDashboard(),
                      webPage:        MainMainPage(),
                      jobListingPage: JobListingMainPage(),
                    ),

                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 20.h),
                      child: SizedBox(
                        width: 1000.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BUG-298: same back link as About Company.
                            const AdminBackLink(parentLabel: 'Our Departments', parentRoute: '/jobs/departments'),
                            // ── Title ──
                            Text(
                              'Create New Department',
                              style: StyleText.fontSize45Weight600.copyWith(
                                color: ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // ── Accordion ──
                            _accordion(
                              key: 'dept_info',
                              title: 'Department Information',
                              children: [_editableSection()],
                            ),

                            SizedBox(height: 20.h),

                            // ── Discard / Create ──
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _onDiscard,
                                    child: Container(
                                      height: 48.h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF797979),
                                        borderRadius:
                                        BorderRadius.circular(8.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Discard',
                                        style: StyleText.fontSize14Weight600
                                            .copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                AdminButtonGap(desktop: 400), // BUG-265
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isSaving ? null : _onCreate,
                                    child: Container(
                                      height: 48.h,
                                      decoration: BoxDecoration(
                                        color: ColorPick.primary,
                                        borderRadius:
                                        BorderRadius.circular(8.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: _isSaving
                                          ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child:
                                        const CircleProgress(),
                                      )
                                          : Text(
                                        'Create',
                                        style: StyleText
                                            .fontSize14Weight600
                                            .copyWith(
                                            color: Colors.white),
                                      ),
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

  /// Inline validation message under a field (nothing when [message] is null).
  Widget _errorText(String? message) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            message,
            style: StyleText.fontSize11Weight400.copyWith(color: ColorPick.red),
          ),
        );

  // ── Accordion ──────────────────────────────────────────────────────────────
  Widget _accordion({
    required String key,
    required String title,
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

  // ── Editable Section ──────────────────────────────────────────────────────
  Widget _editableSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.r),
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


          // ── Department Name EN ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomValidatedTextFieldMaster(
                      label: 'Department Name',
                      hint: 'Text Here',
                      controller: _nameEnController,
                      height: 36,
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      showCharCount: false,
                      maxLength: 60, // BUG-46: cap name length
                      minLength: 0,
                      submitted: _submitted,
                      primaryColor: ColorPick.primary,
                      fillColor: ColorPick.white,
                      // Clear the message as soon as the name changes.
                      onChanged: (_) {
                        if (_nameEnError != null) {
                          setState(() => _nameEnError = null);
                        }
                      },
                      textStyle: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.text),
                      hintStyle: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText),
                    ),
                    _errorText(_nameEnError),
                  ],
                ),
              ),

              SizedBox(width: 15.h),

              // ── Department Name AR ──
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomValidatedTextFieldMaster(
                        label: 'اسم القسم',
                        hint: 'أدخل النص هنا' /* BUG-173 */,
                        controller: _nameArController,
                        height: 36,
                        maxLines: 1,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.start,
                        showCharCount: false,
                        maxLength: 60, // BUG-46: cap name length
                        minLength: 0,
                        submitted: _submitted,
                        primaryColor: ColorPick.primary,
                        fillColor: ColorPick.white,
                        onChanged: (_) {
                          if (_nameArError != null) {
                            setState(() => _nameArError = null);
                          }
                        },
                        textStyle: StyleText.fontSize12Weight400
                            .copyWith(color: AppColors.text),
                        hintStyle: StyleText.fontSize12Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                      _errorText(_nameArError),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}