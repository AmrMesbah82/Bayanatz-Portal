// ******************* FILE INFO *******************
// File Name: services_edit.dart
// Screen 2 — Services CMS: Edit "Headings" (title + description, AR + EN)
// Navigates to: ServicesMainPreviewPage (screen 3)
// UPDATED: Removed success dialog — on ServiceCmsSaved, navigates to ServicesMainPageMaster
// UPDATED: Uses BlocConsumer pattern matching home_edit_page_master.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import 'package:web_app_admin/core/widget/button.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/core/widget/custom_field.dart';
import 'package:web_app_admin/features/services/presentation/ui/pages/services_main/services_main.dart';
import 'package:web_app_admin/features/services/presentation/ui/pages/services_main/services_preview.dart';

import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../../main/presentation/ui/pages/main_main.dart';
import '../../../../data/models/services_model.dart';
import '../../../controller/services_cubit.dart';
import '../../../controller/services_state.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';



// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF1A1A1A);
//   static const Color grey      = Color(0xFF9E9E9E);
//   static const Color back      = Color(0xFFF1F2ED);
// }

class ServicesMainEditPage extends StatefulWidget {
  final ServicePageModel model;
  const ServicesMainEditPage({super.key, required this.model});

  @override
  State<ServicesMainEditPage> createState() => _ServicesMainEditPageState();
}

class _ServicesMainEditPageState extends State<ServicesMainEditPage> {
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _titleArCtrl;
  late final TextEditingController _descEnCtrl;
  late final TextEditingController _descArCtrl;

  bool _headingsOpen = true;
  bool _submitted    = false;
  bool _hasChanges   = false;
  bool _isSaving     = false;

  // Validation tracking
  bool _titleEnValid = true;
  bool _titleArValid = true;
  bool _descEnValid  = true;
  bool _descArValid  = true;

  // Store original values
  late String _originalTitleEn;
  late String _originalTitleAr;
  late String _originalDescEn;
  late String _originalDescAr;

  @override
  void initState() {
    super.initState();

    _originalTitleEn = widget.model.title.en;
    _originalTitleAr = widget.model.title.ar;
    _originalDescEn  = widget.model.shortDescription.en;
    _originalDescAr  = widget.model.shortDescription.ar;

    _titleEnCtrl = TextEditingController(text: widget.model.title.en);
    _titleArCtrl = TextEditingController(text: widget.model.title.ar);
    _descEnCtrl  = TextEditingController(text: widget.model.shortDescription.en);
    _descArCtrl  = TextEditingController(text: widget.model.shortDescription.ar);

    _titleEnCtrl.addListener(_checkForChangesAndValidate);
    _titleArCtrl.addListener(_checkForChangesAndValidate);
    _descEnCtrl.addListener(_checkForChangesAndValidate);
    _descArCtrl.addListener(_checkForChangesAndValidate);
  }

  void _checkForChangesAndValidate() {
    final bool hasChanges =
        _titleEnCtrl.text != _originalTitleEn ||
            _titleArCtrl.text != _originalTitleAr ||
            _descEnCtrl.text  != _originalDescEn  ||
            _descArCtrl.text  != _originalDescAr;

    final bool titleEnValid = _validateSingleField(_titleEnCtrl.text, 'en', isTitle: true);
    final bool titleArValid = _validateSingleField(_titleArCtrl.text, 'ar', isTitle: true);
    final bool descEnValid  = _validateSingleField(_descEnCtrl.text,  'en', isTitle: false);
    final bool descArValid  = _validateSingleField(_descArCtrl.text,  'ar', isTitle: false);

    if (hasChanges   != _hasChanges   ||
        titleEnValid != _titleEnValid ||
        titleArValid != _titleArValid ||
        descEnValid  != _descEnValid  ||
        descArValid  != _descArValid) {
      setState(() {
        _hasChanges   = hasChanges;
        _titleEnValid = titleEnValid;
        _titleArValid = titleArValid;
        _descEnValid  = descEnValid;
        _descArValid  = descArValid;
      });
    }
  }

  bool _validateSingleField(String text, String language, {required bool isTitle}) {
    final bool isEmpty   = text.trim().isEmpty;
    if (isTitle && isEmpty) return false;

    // NOTE: No language validation - every field accepts Arabic AND English.
    return true;
  }

  bool get _isFormValid =>
      _titleEnValid && _titleArValid && _descEnValid && _descArValid;

  bool get _isPublishEnabled =>
      _hasChanges && !_isSaving && _isFormValid;

  @override
  void dispose() {
    _titleEnCtrl.removeListener(_checkForChangesAndValidate);
    _titleArCtrl.removeListener(_checkForChangesAndValidate);
    _descEnCtrl.removeListener(_checkForChangesAndValidate);
    _descArCtrl.removeListener(_checkForChangesAndValidate);

    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _descEnCtrl.dispose();
    _descArCtrl.dispose();
    super.dispose();
  }

  ServicePageModel get _edited => widget.model.copyWith(
    title:            BilingualText(en: _titleEnCtrl.text, ar: _titleArCtrl.text),
    shortDescription: BilingualText(en: _descEnCtrl.text, ar: _descArCtrl.text),
  );

  // ── Validation ─────────────────────────────────────────────────────────────
  bool _validateFields() {
    if (_titleEnCtrl.text.trim().isEmpty) return false;
    if (_titleArCtrl.text.trim().isEmpty) return false;

    // NOTE: No language validation \u2014 every field accepts Arabic AND English.
    return true;
  }

  void _showValidationError() {
    final List<String> missingFields = [];

    // NOTE: No language validation \u2014 every field accepts Arabic AND English.
    if (_titleEnCtrl.text.trim().isEmpty) {
      missingFields.add('Title (English)');
    }

    if (_titleArCtrl.text.trim().isEmpty) {
      missingFields.add('Title (Arabic)');
    }

    final message = missingFields.isEmpty
        ? 'Please check all required fields.'
        : 'Please fix the following issues:\n\n• ${missingFields.join('\n• ')}';

    showConfirmDialog(
      context: context,
      title: 'Required Fields Missing',
      subtitle: message,
      confirmLabel: 'OK',
      cancelLabel: '',
      onConfirm: () {},
      iconWidget: Container(
        width: 60.r, height: 60.r,
        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
        child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
      ),
    );
  }

  // ── Preview ────────────────────────────────────────────────────────────────
  void _onPreview() async {
    setState(() => _submitted = true);
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_validateFields()) {
      _showValidationError();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ServiceCmsCubit>(),
          child: ServicesMainPreviewPage(model: _edited),
        ),
      ),
    );
  }

  // ── Save / Publish ─────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    setState(() => _submitted = true);
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_validateFields()) {
      _showValidationError();
      return;
    }

    setState(() => _isSaving = true);

    try {
      context.read<ServiceCmsCubit>().updateTitle(
          en: _titleEnCtrl.text, ar: _titleArCtrl.text);
      context.read<ServiceCmsCubit>().updateShortDescription(
          en: _descEnCtrl.text, ar: _descArCtrl.text);
      await context.read<ServiceCmsCubit>().save(publishStatus: 'published');

      // Update original values so _hasChanges resets correctly
      _originalTitleEn = _titleEnCtrl.text;
      _originalTitleAr = _titleArCtrl.text;
      _originalDescEn  = _descEnCtrl.text;
      _originalDescAr  = _descArCtrl.text;

      setState(() {
        _hasChanges = false;
        _isSaving   = false;
      });

      // Navigation is handled by BlocConsumer listener (ServiceCmsSaved)
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        showConfirmDialog(
          context: context,
          title: 'Error',
          subtitle: 'Failed to save: ${e.toString()}',
          confirmLabel: 'OK',
          cancelLabel: '',
          onConfirm: () {},
          iconWidget: Container(
            width: 60.r, height: 60.r,
            decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
          ),
        );
      }
    }
  }

  void _onDiscard() {
    if (_hasChanges) {
      confirmDiscard(context, onDiscard: () => Navigator.pop(context));
    } else {
      Navigator.pop(context);
    }
  }

  void _showPublishConfirmDialog() {
    showPublishConfirmDialog(
      context: context,
      title: 'EDITING SERVICES DETAILS',
      subtitle: 'Do you want to save the changes made to this Service Details?',
      confirmLabel: 'Publish',
      onConfirm: _onSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPick.background,
      // ── Use BlocConsumer so listener handles navigation on success ──────────
      body: BlocConsumer<ServiceCmsCubit, ServiceCmsState>(
        listener: (context, state) {
          // ── Published successfully → navigate to ServicesMainPageMaster ──
          if (state is ServiceCmsSaved) {
            // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const ServicesMainPageMaster(),
                  ),
                      (route) => false,
                );
              }
            });
          }

          if (state is ServiceCmsError) {
            showConfirmDialog(
              context: context,
              title: 'Error',
              subtitle: state.message,
              confirmLabel: 'OK',
              cancelLabel: '',
              onConfirm: () {},
              iconWidget: Container(
                width: 60.r, height: 60.r,
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
                child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  children: [
                      AppAdminNavbar(
                        activeLabel:     'Web Page',
                        homePage:        CareersMainPageDashboard(),
                        webPage:         MainMainPage(),
                        jobListingPage:  JobListingMainPage(),
                      ),
                      SizedBox(height: 20.h),
                      AdminSubNavBar(activeIndex: 2),
                      SizedBox(
                        width: 1000.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5.h),

                            // ── Large green title ──────────────────────────
                            Text(
                              'Editing Services Details',
                              style: StyleText.fontSize45Weight600.copyWith(
                                color: ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // ── Headings accordion ─────────────────────────
                            _headingsAccordion(),
                            SizedBox(height: 24.h),

                            // ── Action buttons ─────────────────────────────
                            _actionButtons(),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ],
),
              if (_isSaving) _buildSavingOverlay(),
            ],
          );
        },
      ),
    );
  }

  // ── Accordion ──────────────────────────────────────────────────────────────
  Widget _headingsAccordion() {
    return CustomAccordion(
      title:    'Headings',
      isOpen:   _headingsOpen,
      onToggle: () => setState(() => _headingsOpen = !_headingsOpen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title: EN + AR side by side ──────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Title',    style: _labelStyle()),
                      Text('العنوان', style: _labelStyle()),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(children: [
                    Expanded(
                      child: CustomTextField(
                        controller:    _titleEnCtrl,
                        hint:          'Text Here',
                        submitted:     _submitted,
                        primaryColor:  ColorPick.primary,
                        fillColor:     Colors.white,
                        textDirection: TextDirection.ltr,
                        height:        36,
                        isRequired:    true,
                        minLength:     1,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomTextField(
                        controller:    _titleArCtrl,
                        hint:          'أدخل النص هنا',
                        submitted:     _submitted,
                        primaryColor:  ColorPick.primary,
                        fillColor:     Colors.white,
                        textDirection: TextDirection.rtl,
                        textAlign:     TextAlign.right,
                        height:        36,
                        isRequired:    true,
                        minLength:     1,
                      ),
                    ),
                  ]),
                  SizedBox(height: 16.h),

                  // ── Description EN full width ────────────────────────
                  Text('Description', style: _labelStyle()),
                  SizedBox(height: 6.h),
                  CustomTextField(
                    controller:    _descEnCtrl,
                    hint:          'Text Here',
                    submitted:     false,
                    primaryColor:  ColorPick.primary,
                    fillColor:     Colors.white,
                    textDirection: TextDirection.ltr,
                    maxLines:      4,
                    height:        100,
                    maxLength:     10000,
                    isRequired:    false,
                  ),
                  SizedBox(height: 16.h),

                  // ── Description AR full width RTL ────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('وصف', style: _labelStyle()),
                  ),
                  SizedBox(height: 6.h),
                  CustomTextField(
                    controller:    _descArCtrl,
                    hint:          'أدخل النص هنا',
                    submitted:     false,
                    primaryColor:  ColorPick.primary,
                    fillColor:     Colors.white,
                    textDirection: TextDirection.rtl,
                    textAlign:     TextAlign.right,
                    maxLines:      4,
                    height:        100,
                    maxLength:     10000,
                    isRequired:    false,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return Column(
      children: [
        EditActionButtons(
          publishEnabled: _isPublishEnabled,
          onPreview: _onPreview,
          onPublish: _showPublishConfirmDialog,
          onDiscard: _onDiscard,
          publishDisabledTooltip: _hasChanges
              ? 'Please fix validation errors before publishing'
              : 'No changes to publish',
        ),

        // Validation summary message
        if (!_isFormValid && _hasChanges)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Text(
              'Please fix validation errors above before publishing',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ── Saving overlay ─────────────────────────────────────────────────────────
  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 180.w, height: 100.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleProgress(),
              SizedBox(height: 12.h),
              Text(
                'Saving...',
                style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() =>
      StyleText.fontSize12Weight600.copyWith(color: AppColors.text);
}