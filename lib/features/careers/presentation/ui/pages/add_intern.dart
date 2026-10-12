// ******************* FILE INFO *******************
// File Name: add_intern.dart
// Figma: Adding New Intern / Editing Intern Details
// UPDATED: Fixed photo picker to only accept image formats (PNG, JPG, JPEG)

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:web_app_admin/core/main_widgets/admin_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/textfield.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/image_upload_circle.dart';
import '../../../../../core/custom_dialog.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/delete_intern_dialog.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/intern_model.dart';
import '../../controller/intern_cubit.dart';
import '../../controller/intern_state.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';


part '../widgets/add_intern/add_intern_widgets.dart';


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color bg        = Color(0xFFF1F2ED);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color discard   = Color(0xFF797979);
//   static const Color removeRed = Color(0xFFD32F2F);
//   static const Color errorRed  = Color(0xFFD32F2F);
// }

// ═══════════════════════════════════════════════════════════════════════════════
class AddInternPage extends StatefulWidget {
  /// Pass an existing intern to edit, null to create new.
  final InternModel? existing;

  const AddInternPage({super.key, this.existing});

  @override
  State<AddInternPage> createState() => _AddInternPageState();
}

class _AddInternPageState extends State<AddInternPage> {
  bool _submitted  = false;
  bool _isSaving   = false;
  bool _isRemoving = false;

  Uint8List? _photoBytes;
  String     _photoUrl = '';

  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _positionCtrl    = TextEditingController();
  final _degreesCtrl     = TextEditingController();
  final _whatLearnedCtrl = TextEditingController();
  // BUG-74: Arabic fields
  final _firstNameArCtrl   = TextEditingController();
  final _lastNameArCtrl    = TextEditingController();
  final _positionArCtrl    = TextEditingController();
  final _degreesArCtrl     = TextEditingController();
  final _whatLearnedArCtrl = TextEditingController();
  DateTime? _joinedDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _photoUrl             = e.photoUrl;
      _firstNameCtrl.text   = e.firstName;
      _lastNameCtrl.text    = e.lastName;
      _positionCtrl.text    = e.position;
      _degreesCtrl.text     = e.degrees;
      _whatLearnedCtrl.text = e.whatHaveILearned;
      _firstNameArCtrl.text   = e.firstNameAr;
      _lastNameArCtrl.text    = e.lastNameAr;
      _positionArCtrl.text    = e.positionAr;
      _degreesArCtrl.text     = e.degreesAr;
      _whatLearnedArCtrl.text = e.whatHaveILearnedAr;
      _joinedDate           = e.joinedDate;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _positionCtrl.dispose();
    _degreesCtrl.dispose();
    _whatLearnedCtrl.dispose();
    _firstNameArCtrl.dispose();
    _lastNameArCtrl.dispose();
    _positionArCtrl.dispose();
    _degreesArCtrl.dispose();
    _whatLearnedArCtrl.dispose();
    super.dispose();
  }

  // ── Pick photo (PNG, JPG, JPEG only - NO SVG) ────────────────────────────────
  Future<void> _pickPhoto() async {
    final completer = Completer<Uint8List?>();
    bool done = false;
    // Only accept image formats, NOT SVG
    final input = html.FileUploadInputElement()
      ..accept = 'image/png,image/jpeg,image/jpg';

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!done) { done = true; completer.complete(null); }
        return;
      }

      final file = files.first;
      final fileName = file.name.toLowerCase();

      // Validate file type - reject SVG
      if (fileName.endsWith('.svg') || file.type == 'image/svg+xml') {
        if (!done) {
          done = true;
          completer.complete(null);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('SVG files are not allowed for photos. Please use PNG or JPG.',
                    style: StyleText.fontSize14Weight400
                        .copyWith(color: Colors.white)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            );
          }
        }
        return;
      }

      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (!done) {
          done = true;
          if (result is List<int>) {
            completer.complete(Uint8List.fromList(result));
          } else {
            completer.complete(null);
          }
        }
      });
      reader.onError.listen((_) {
        if (!done) { done = true; completer.complete(null); }
      });
      reader.readAsArrayBuffer(files.first);
    });

    input.click();

    Future.delayed(const Duration(minutes: 5), () {
      if (!done) { done = true; completer.complete(null); }
    });

    final bytes = await completer.future;
    if (bytes != null && mounted) setState(() => _photoBytes = bytes);
  }
  // ── Validate all fields ────────────────────────────────────────────────────
  bool _validateAllFields() {
    // Required fields
    if (_firstNameCtrl.text.trim().isEmpty) return false;
    if (_lastNameCtrl.text.trim().isEmpty) return false;
    if (_whatLearnedCtrl.text.trim().isEmpty) return false;
    // BUG-248: interns are bilingual — the Arabic name and "What have I
    // learned" are required too (the Arabic site showed English cards).
    if (_firstNameArCtrl.text.trim().isEmpty) return false;
    if (_lastNameArCtrl.text.trim().isEmpty) return false;
    if (_whatLearnedArCtrl.text.trim().isEmpty) return false;

    // Photo is required for new interns
    if (!_isEdit && _photoBytes == null) return false;

    // Joined date is required
    if (_joinedDate == null) return false;

    return true;
  }

  // BUG-74 / BUG-248: Arabic text field. Name and "What have I learned" are
  // required (isRequired), position / degrees stay optional like in English.
  Widget _arField(String label, TextEditingController ctrl,
      {double height = 44, int maxLines = 1, bool isRequired = false}) {
    return CustomValidatedTextFieldMaster(
      label:         label,
      isRequired:    isRequired,
      hint:          'أدخل النص هنا', // BUG-173: same spelling everywhere
      fillColor:     AppColors.white,
      controller:    ctrl,
      height:        height,
      maxLines:      maxLines,
      submitted:     _submitted,
      primaryColor:  ColorPick.primary,
      textDirection: ui.TextDirection.rtl,
      textAlign:     TextAlign.right,
    );
  }

  // ── Perform Save (create / update) ─────────────────────────────────────────
  Future<void> _performSave() async {
    setState(() => _isSaving = true);
    final cubit = context.read<InternCubit>();

    final tags = _positionCtrl.text.trim().isEmpty
        ? <String>[]
        : _positionCtrl.text.trim().split(' ').take(2).toList();

    final model = InternModel(
      id:               _isEdit ? widget.existing!.id : '',
      photoUrl:         _photoUrl,
      firstName:        _firstNameCtrl.text.trim(),
      lastName:         _lastNameCtrl.text.trim(),
      position:         _positionCtrl.text.trim(),
      degrees:          _degreesCtrl.text.trim(),
      joinedDate:       _joinedDate,
      whatHaveILearned: _whatLearnedCtrl.text.trim(),
      firstNameAr:        _firstNameArCtrl.text.trim(),
      lastNameAr:         _lastNameArCtrl.text.trim(),
      positionAr:         _positionArCtrl.text.trim(),
      degreesAr:          _degreesArCtrl.text.trim(),
      whatHaveILearnedAr: _whatLearnedArCtrl.text.trim(),
      // tags:             tags,
    );

    try {
      if (_isEdit) {
        await cubit.update(model, photoBytes: _photoBytes);
      } else {
        await cubit.create(model, photoBytes: _photoBytes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: StyleText.fontSize14Weight400
                    .copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Handle Publish with confirmation dialog ─────────────────────────────────
  Future<void> _handlePublish() async {
    setState(() => _submitted = true);

    if (!_validateAllFields()) {
      // Show validation error message
      String errorMessage = 'Please fill all required fields';
      if (!_isEdit && _photoBytes == null) {
        errorMessage = 'Please upload a photo (PNG or JPG)';
      } else if (_joinedDate == null) {
        errorMessage = 'Please select joined date';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage,
              style: StyleText.fontSize14Weight400
                  .copyWith(color: Colors.white)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r)),
        ),
      );
      return;
    }

    // Show confirmation dialog
    await showPublishConfirmDialog(
      context: context,
      title: _isEdit ? 'UPDATE INTERN' : 'PUBLISH NEW INTERN',
      subtitle: _isEdit
          ? 'Do you want to save the changes made to this intern?'
          : 'Do you want to publish this new intern?',
      confirmLabel: _isEdit ? 'Save' : 'Publish',
      backLabel: 'Back',
      onConfirm: _performSave,
    );
  }

  Future<void> _remove() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DeleteInternDialog(
        internName: '${widget.existing!.firstName} ${widget.existing!.lastName}',
        onDelete: () async {
          setState(() => _isRemoving = true);
          final cubit = context.read<InternCubit>();
          await cubit.delete(widget.existing!.id);
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternCubit, InternState>(
      listener: (context, state) {
        // These three outcomes used to be floating SnackBars. A snackbar for a
        // destructive result is easy to miss — it fades on its own while the
        // page is already navigating away — and it was the only place in the
        // admin that reported a result that way. All three now use the shared
        // dialogs, so the user has to acknowledge the result, and the page pops
        // only after they do.
        if (state is InternCreated || state is InternUpdated) {
          setState(() { _isSaving = false; _isRemoving = false; });
          showSuccessDialog(
            context:  context,
            title:    _isEdit ? 'Intern Updated' : 'Intern Created',
            subtitle: _isEdit
                ? 'The intern details have been saved.'
                : 'The new intern has been added.',
            onClose:  () => Navigator.pop(context),
          );
        }
        if (state is InternDeleted) {
          setState(() => _isRemoving = false);
          showSuccessDialog(
            context:  context,
            title:    'Intern Removed',
            subtitle: 'The intern has been removed from the list.',
            onClose:  () => Navigator.pop(context),
          );
        }
        if (state is InternError) {
          setState(() { _isSaving = false; _isRemoving = false; });
          showErrorDialog(
            context:  context,
            title:    'Something went wrong',
            subtitle: state.message,
            onClose:  () {},
          );
        }
      },
      builder: (context, state) {
        final busy = _isSaving || _isRemoving;

        return Stack(
          children: [
            Scaffold(

              body: AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  children: [


                        AppAdminNavbar(
                          activeLabel: 'Web Page',
                          homePage: MainMainPage(),
                          webPage: MainMainPage(),
                          jobListingPage: MainMainPage(),
                        ),
                        AdminSubNavBar(activeIndex: 5),
                        SizedBox(
                          width: 1000.w,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Page title ──────────────────────────────
                              Text(
                                _isEdit
                                    ? 'Editing Intern Details'
                                    : 'Adding New Intern',
                                style: StyleText.fontSize45Weight600.copyWith(
                                  color:      ColorPick.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 15.h),
                              Row(
                                children: [
                                  const Spacer(),
                                  // Remove button — edit mode only
                                  if (_isEdit)
                                    GestureDetector(
                                      onTap: busy ? null : _remove,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 18.w,
                                            vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: _isRemoving
                                              ? Colors.red
                                              .withValues(alpha: 0.6)
                                              : Colors.red,
                                          borderRadius:
                                          BorderRadius.circular(6.r),
                                        ),
                                        child: _isRemoving
                                            ? SizedBox(
                                          width:  14.w,
                                          height: 14.h,
                                          child:
                                          const CircleProgress(),
                                        )
                                            : Text(
                                          'Remove',
                                          style: StyleText
                                              .fontSize13Weight600
                                              .copyWith(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 15.h),
                              // ── Card ────────────────────────────────────
                              Container(
                                width: double.infinity,

                                decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Photo + Joined Date ─────────────────
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _photoPicker()),
                                        SizedBox(width: 20.w),
                                        Expanded(child: _dateField()),
                                      ],
                                    ),
                                    SizedBox(height: 20.h),

                                    // ── First Name / Last Name ──────────────
                                    Row(children: [
                                      Expanded(
                                        child: CustomValidatedTextFieldMaster(
                                          label:        'First Name',
                                          hint:         'Text Here',
                                          controller:   _firstNameCtrl,
                                          fillColor: AppColors.white,
                                          height:       44,
                                          submitted:    _submitted,
                                          primaryColor: ColorPick.primary,
                                          isRequired:   true,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: CustomValidatedTextFieldMaster(
                                          label:        'Last Name',
                                          fillColor: AppColors.white,
                                          hint:         'Text Here',
                                          controller:   _lastNameCtrl,
                                          height:       44,
                                          submitted:    _submitted,
                                          primaryColor: ColorPick.primary,
                                          isRequired:   true,
                                        ),
                                      ),
                                    ]),
                                    SizedBox(height: 14.h),

                                    // ── Position / Degrees ──────────────────
                                    Row(children: [
                                      Expanded(
                                        child: CustomValidatedTextFieldMaster(
                                          label:        'Position',
                                          hint:         'Text Here',
                                          fillColor: AppColors.white,
                                          controller:   _positionCtrl,
                                          height:       44,
                                          submitted:    _submitted,
                                          primaryColor: ColorPick.primary,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: CustomValidatedTextFieldMaster(
                                          label:        'Degrees',
                                          hint:         'Text Here',
                                          fillColor: AppColors.white,
                                          controller:   _degreesCtrl,
                                          height:       44,
                                          submitted:    _submitted,
                                          primaryColor: ColorPick.primary,
                                        ),
                                      ),
                                    ]),
                                    SizedBox(height: 14.h),

                                    // ── What Have I Learned ─────────────────
                                    CustomValidatedTextFieldMaster(
                                      label:        'What Have I Learned',
                                      hint:         'Text Here',
                                      fillColor: AppColors.white,
                                      controller:   _whatLearnedCtrl,
                                      height:       100,
                                      maxLines:     5,
                                      submitted:    _submitted,
                                      primaryColor: ColorPick.primary,
                                      isRequired:   true,
                                    ),

                                    // ── BUG-74: Arabic fields ───────────────
                                    SizedBox(height: 20.h),
                                    Directionality(
                                      textDirection: ui.TextDirection.rtl,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(child: _arField('الاسم الأول', _firstNameArCtrl, isRequired: true)),
                                            SizedBox(width: 16.w),
                                            Expanded(child: _arField('اسم العائلة', _lastNameArCtrl, isRequired: true)),
                                          ]),
                                          SizedBox(height: 14.h),
                                          Row(children: [
                                            Expanded(child: _arField('المسمى', _positionArCtrl)),
                                            SizedBox(width: 16.w),
                                            Expanded(child: _arField('المؤهلات', _degreesArCtrl)),
                                          ]),
                                          SizedBox(height: 14.h),
                                          _arField('ماذا تعلمت', _whatLearnedArCtrl,
                                              height: 100, maxLines: 5,
                                              isRequired: true),
                                        ],
                                      ),
                                    ),
                                    // ── Discard / Publish buttons ───────────

                                  ],
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Row(children: [
                                Expanded(
                                  child: GestureDetector(
                                    // BUG-292: ask before dropping the form.
                                    onTap: busy
                                        ? null
                                        : () => confirmDiscard(context,
                                            onDiscard: () => Navigator.pop(context)),
                                    child: Container(
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: busy
                                            ? ColorPick.discard.withValues(alpha: 0.5)
                                            : ColorPick.discard,
                                        borderRadius:
                                        BorderRadius.circular(4.r),
                                      ),
                                      child: Center(
                                        child: Text('Discard',
                                            style: StyleText
                                                .fontSize16Weight600
                                                .copyWith(
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ),
                                AdminButtonGap(desktop: 400), // BUG-265
                                Expanded(
                                  child: GestureDetector(
                                    onTap: busy ? null : _handlePublish,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: busy
                                            ? ColorPick.primary.withValues(alpha: 0.5)
                                            : ColorPick.primary,
                                        borderRadius:
                                        BorderRadius.circular(8.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _isEdit ? 'Save' : 'Publish',
                                          style: StyleText
                                              .fontSize16Weight600
                                              .copyWith(
                                              color:
                                              Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ],
),
            ),

            // ── Full-screen saving overlay ─────────────────────────────────
            if (busy)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 40.w, vertical: 32.h),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleProgress(),
                        SizedBox(height: 16.h),
                        Text(
                          _isRemoving ? 'Removing...' : 'Saving...',
                          style: StyleText.fontSize14Weight600.copyWith(
                            color: _isRemoving ? Colors.red : ColorPick.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
