// ******************* FILE INFO *******************
// File Name: why_join_edit.dart
// Edit page for Why Join Our Team / Our Interns / Our Teams
// Figma: Editing {SectionTitle} Details
// Accordion with editable items: Icon, Title EN/AR, SVG, Description EN/AR
// + Remove per item, + Reason button, Preview / Save / Discard bottom buttons
// UPDATED: Added validation, SVG-only restriction, and publish confirmation dialog

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_app_admin/core/constant/color.dart';
import 'package:web_app_admin/core/custom/image_upload_circle.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/why_join_preview.dart';

import '../../../../../core/custom_dialog.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/careers_section_model.dart';
import '../../controller/careers_section_cubit.dart';
import '../../controller/careers_section_state.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/why_join_edit/picked_image.dart';
part '../widgets/why_join_edit/item_edit.dart';
part '../widgets/why_join_edit/why_join_edit_ui.dart';


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color remove    = Color(0xFFE53935);
//   static const Color back      = Color(0xFFF1F2ED);
// }

class CareersSectionEditPage extends StatefulWidget {
  final String sectionKey;
  final String sectionTitle;

  const CareersSectionEditPage({
    super.key,
    required this.sectionKey,
    required this.sectionTitle,
  });

  @override
  State<CareersSectionEditPage> createState() => _CareersSectionEditPageState();
}

class _CareersSectionEditPageState extends State<CareersSectionEditPage> {
  bool _submitted = false;
  bool _isSaving  = false;
  bool _accordionOpen = true;

  final List<_ItemEdit> _items = [];
  int? _seededHash;

  // ── Seed from model ─────────────────────────────────────────────────────────
  int _hashOf(CareersSectionModel data) => Object.hashAll([
        data.items.length,
        ...data.items.map((i) =>
            '${i.id}${i.iconUrl}${i.svgUrl}${i.title.en}${i.title.ar}'
            '${i.description.en}${i.description.ar}'),
      ]);

  void _seedFromModel(CareersSectionModel data) {
    final hash = _hashOf(data);
    if (_seededHash == hash) return;
    _seededHash = hash;

    for (final item in _items) item.dispose();
    _items.clear();

    for (final item in data.items) {
      _items.add(_ItemEdit(
        id:      item.id,
        icon:    item.iconUrl.isNotEmpty
            ? _PickedImage(url: item.iconUrl)
            : const _PickedImage(),
        titleEn: item.title.en,
        titleAr: item.title.ar,
        svg:     item.svgUrl.isNotEmpty
            ? _PickedImage(url: item.svgUrl)
            : const _PickedImage(),
        descEn:  item.description.en,
        descAr:  item.description.ar,
      ));
    }

    // Always show at least one reason form — no need to click "+ Reason".
    if (_items.isEmpty) {
      _items.add(_ItemEdit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    }
  }

  // ── Validation ──────────────────────────────────────────────────────────────
  bool _validateAllFields() {
    if (_items.isEmpty) return false;

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];

      // Icon & Title only required on first item
      if (i == 0) {
        if (!item.icon.hasImage) return false;
        if (item.titleEn.text.trim().isEmpty) return false;
        if (item.titleAr.text.trim().isEmpty) return false;
      }

      if (item.descEn.text.trim().isEmpty) return false;
      if (item.descAr.text.trim().isEmpty) return false;
      // The per-reason SVG picker was removed from the form — the section icon
      // above is the only image. An existing svgUrl is still carried through on
      // save, so nothing already published is lost; it just can't block
      // Publish any more.
    }

    return true;
  }

  // ── Pick SVG image (SVG only) ───────────────────────────────────────────────
  Future<_PickedImage?> _pickImage() async {
    final completer = Completer<_PickedImage?>();
    bool completed = false;
    final input = html.FileUploadInputElement()
      ..accept = '.svg,image/svg+xml';

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completed) { completed = true; completer.complete(null); }
        return;
      }
      final file = files.first;
      final fileName = file.name.toLowerCase();

      // Strict SVG validation
      if (!fileName.endsWith('.svg') && file.type != 'image/svg+xml') {
        if (!completed) {
          completed = true;
          completer.complete(null);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Only SVG files are allowed',
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
        if (!completed) {
          completed = true;
          if (result is List<int>) {
            completer.complete(_PickedImage(bytes: Uint8List.fromList(result)));
          } else {
            completer.complete(null);
          }
        }
      });
      reader.onError.listen((_) {
        if (!completed) { completed = true; completer.complete(null); }
      });
      reader.readAsArrayBuffer(file);
    });

    input.click();

    Future.delayed(const Duration(minutes: 5), () {
      if (!completed) { completed = true; completer.complete(null); }
    });

    return completer.future;
  }

  // ── Copy the form into the cubit (BUG-63) ───────────────────────────────────
  //
  // BUG-63 — extra "Reason" paragraphs were saved EMPTY. Save used to add the
  // missing items to the cubit (each addItem() emits a state), then walk the
  // form while awaiting icon uploads. The emitted state rebuilt the page, the
  // builder re-seeded the form from the cubit — whose new items were still
  // blank — and the loop went on reading those blank controllers. Only the
  // first reason survived.
  //
  // Now every value is snapshotted FIRST, the cubit is updated in one
  // synchronous pass, the seed hash is moved to the result, and the builder
  // does not re-seed while a save is running.
  void _syncToCubit(CareersSectionCubit cubit) {
    final snapshot = [
      for (final it in _items)
        (
          titleEn: it.titleEn.text.trim(),
          titleAr: it.titleAr.text.trim(),
          descEn:  it.descEn.text.trim(),
          descAr:  it.descAr.text.trim(),
        ),
    ];

    while (cubit.current.items.length < snapshot.length) cubit.addItem();
    while (cubit.current.items.length > snapshot.length) {
      cubit.removeItem(cubit.current.items.last.id);
    }
    for (var i = 0; i < snapshot.length; i++) {
      final id = cubit.current.items[i].id;
      cubit.updateTitle(id, en: snapshot[i].titleEn, ar: snapshot[i].titleAr);
      cubit.updateDescription(id,
          en: snapshot[i].descEn, ar: snapshot[i].descAr);
    }
    _seededHash = _hashOf(cubit.current);
  }

  // ── Perform Save ────────────────────────────────────────────────────────────
  Future<void> _performSave(CareersSectionCubit cubit) async {
    setState(() => _isSaving = true);

    try {
      _syncToCubit(cubit); // BUG-63

      // Upload images (the form is not re-seeded while _isSaving is true)
      for (var i = 0; i < _items.length; i++) {
        final localItem = _items[i];
        final cubitItem = cubit.current.items[i];

        if (localItem.icon.bytes != null) {
          await cubit.uploadIcon(cubitItem.id, localItem.icon.bytes!);
        }
        if (localItem.svg.bytes != null) {
          await cubit.uploadSvg(cubitItem.id, localItem.svg.bytes!);
        }
      }

      await cubit.save();

      if (mounted) {
        setState(() => _isSaving = false);
        _seededHash = null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.sectionTitle} saved!',
                style: StyleText.fontSize14Weight400
                    .copyWith(color: Colors.white)),
            backgroundColor: ColorPick.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ),
        );

        Navigator.pop(context);
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
  Future<void> _handlePublish(CareersSectionCubit cubit) async {
    setState(() => _submitted = true);

    if (!_validateAllFields()) {
      // Validation failed - errors will show under text fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields and upload all images',
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
      title: 'PUBLISH ${widget.sectionTitle.toUpperCase()}',
      subtitle: 'Do you want to publish the changes made to this ${widget.sectionTitle}?',
      confirmLabel: 'Publish',
      backLabel: 'Back',
      onConfirm: () => _performSave(cubit),
    );
  }

  @override
  void dispose() {
    for (final item in _items) item.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CareersSectionCubit, CareersSectionState>(
      listener: (context, state) {
        if (state is CareersSectionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}',
                  style: StyleText.fontSize14Weight400
                      .copyWith(color: Colors.white)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<CareersSectionCubit>();

        // BUG-63: seed from the cubit's CURRENT model (an emitted state can be
        // older than the model), and never while a save is uploading.
        if (!_isSaving &&
            (state is CareersSectionLoaded || state is CareersSectionSaved)) {
          _seedFromModel(cubit.current);
        }

        if (state is CareersSectionInitial || state is CareersSectionLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(
                child: CircleProgress()),
          );
        }

        return Stack(
          children: [
            Scaffold(
              body: AdminStickyBody(
  children: [
                      AppAdminNavbar(
                        activeLabel: 'Web Page',
                        homePage: MainMainPage(),
                        webPage: MainMainPage(),
                        jobListingPage: MainMainPage(),
                      ),
                      AdminSubNavBar(activeIndex: 5),
                      Container(
                        width: 1000.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20.h),
                            Text(
                              'Editing ${widget.sectionTitle} Details',
                              style: StyleText.fontSize45Weight600.copyWith(
                                color:      ColorPick.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            // ── Accordion ────────────────────────────────────
                            _accordion(
                              title: widget.sectionTitle,
                              children: [
                                ..._items.asMap().entries.map((entry) {
                                  final i    = entry.key;
                                  final item = entry.value;
                                  return _itemEditWidget(i, item);
                                }),
                                // + Reason button
                                Padding(
                                  padding:  EdgeInsets.symmetric(vertical: 15.sp),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        final newItem = _ItemEdit(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        );
                                        _items.add(newItem);
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF797979),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, color: Colors.white, size: 16.sp),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Reason',
                                            style: StyleText.fontSize13Weight500
                                                .copyWith(color:Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),

                            // ── Bottom buttons ──────────────────────────────
                            _bottomButtons(cubit),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ],
),
            ),

            // ── Saving overlay ───────────────────────────────────────────────
            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 40.w, vertical: 32.h),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: .15),
                            blurRadius: 24),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleProgress(),
                        SizedBox(height: 20.h),
                        Text('Saving...',
                            style: StyleText.fontSize14Weight600
                                .copyWith(color: ColorPick.primary)),
                        SizedBox(height: 6.h),
                        Text('Uploading images & saving data',
                            style: StyleText.fontSize12Weight400
                                .copyWith(color: AppColors.secondaryText)),
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
