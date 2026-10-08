// ******************* FILE INFO *******************
// File Name: services_digital_main.dart
// UPDATED: Subtitle accordion now edits model.journeyTitle (the
//          "Reasons to Choose..." section heading) instead of
//          model.shortDescription (which belongs to the header only).
// UPDATED: Added custom dialogs for publish/save
// UPDATED: Proper validation with error messages under text fields
// UPDATED: SVG-only image picker with validation
// UPDATED: Preview always enabled — no validation gate on preview
// UPDATED: Removed AR/EN script validation — only non-empty check remains

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/widget/button.dart';
import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/core/widget/custom_field.dart';

import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import '../../../../../../core/custom/image_upload_circle.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../data/models/services_model.dart';
import '../../../controller/services_cubit.dart';
import '../../../controller/services_state.dart';
import 'services_digital_preview.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';

part '../../widgets/services_digital_main/item_controllers.dart';
part '../../widgets/services_digital_main/original_item_data.dart';
part '../../widgets/services_digital_edit/digital_edit_ui.dart';

// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFDDE8DD);
//   static const Color labelText = Color(0xFF1A1A1A);
//   static const Color grey      = Color(0xFF9E9E9E);
//   static const Color back      = Color(0xFFF1F2ED);
// }

class ServicesDigitalJourneyEditPage extends StatefulWidget {
  final ServicePageModel model;
  const ServicesDigitalJourneyEditPage({super.key, required this.model});

  @override
  State<ServicesDigitalJourneyEditPage> createState() =>
      _ServicesDigitalJourneyEditPageState();
}

class _ServicesDigitalJourneyEditPageState
    extends State<ServicesDigitalJourneyEditPage> {
  // ── journeyTitle controllers ───────────────────────────────────────────────
  late final TextEditingController _journeyTitleEnCtrl;
  late final TextEditingController _journeyTitleArCtrl;

  // ── Per-item controllers ───────────────────────────────────────────────────
  late List<_ItemControllers> _itemCtrls;

  // ── Accordion open states ──────────────────────────────────────────────────
  bool _headerOpen = true;
  late List<bool> _itemOpen;

  // ── Submitted flag — revealed only on Publish attempt ─────────────────────
  bool _submitted = false;

  // ── Track changes ─────────────────────────────────────────────────────────
  bool _hasChanges = false;

  // ── Saving state ──────────────────────────────────────────────────────────
  bool _isSaving = false;

  // ── Store original values ─────────────────────────────────────────────────
  late String _originalJourneyTitleEn;
  late String _originalJourneyTitleAr;
  late List<_OriginalItemData> _originalItems;

  @override
  void initState() {
    super.initState();

    _originalJourneyTitleEn = widget.model.journeyTitle.en;
    _originalJourneyTitleAr = widget.model.journeyTitle.ar;

    _originalItems = widget.model.journeyItems
        .map((item) => _OriginalItemData(
      id: item.id,
      titleEn: item.title.en,
      titleAr: item.title.ar,
      descEn: item.description.en,
      descAr: item.description.ar,
      iconUrl: item.iconUrl,
    ))
        .toList();

    _journeyTitleEnCtrl = TextEditingController(text: widget.model.journeyTitle.en);
    _journeyTitleArCtrl = TextEditingController(text: widget.model.journeyTitle.ar);

    _itemCtrls = widget.model.journeyItems
        .map((item) => _ItemControllers.fromModel(item))
        .toList();
    if (_itemCtrls.isEmpty) _itemCtrls.add(_ItemControllers.empty());
    _itemOpen = List.generate(_itemCtrls.length, (_) => true);

    // ADD LISTENERS TO ALL EXISTING ITEMS
    for (final item in _itemCtrls) {
      item.titleEnCtrl.addListener(_checkForChanges);
      item.titleArCtrl.addListener(_checkForChanges);
      item.descEnCtrl.addListener(_checkForChanges);
      item.descArCtrl.addListener(_checkForChanges);
    }

    _journeyTitleEnCtrl.addListener(_checkForChanges);
    _journeyTitleArCtrl.addListener(_checkForChanges);
  }
  // ── Change detection ───────────────────────────────────────────────────────
  void _checkForChanges() {
    final hasChanges = _hasAnyChanges();
    // Same fix as BUG-62: always rebuild so Publish follows the validity.
    if (mounted) setState(() => _hasChanges = hasChanges);
  }

  bool _hasAnyChanges() {
    if (_journeyTitleEnCtrl.text != _originalJourneyTitleEn ||
        _journeyTitleArCtrl.text != _originalJourneyTitleAr) {
      return true;
    }
    if (_itemCtrls.length != _originalItems.length) {
      return true;
    }
    for (int i = 0; i < _itemCtrls.length; i++) {
      final cur = _itemCtrls[i];
      final ori = _originalItems[i];

      // Skip comparison if icon is still loading
      if (cur.iconUrl == 'loading') continue;

      if (cur.titleEnCtrl.text != ori.titleEn ||
          cur.titleArCtrl.text != ori.titleAr ||
          cur.descEnCtrl.text != ori.descEn ||
          cur.descArCtrl.text != ori.descAr ||
          cur.iconUrl != ori.iconUrl) {
        return true;
      }
    }
    return false;
  }

  // ── Validation: non-empty only, no script checks ───────────────────────────
  // Used for Publish gate only. Preview is always allowed.
  bool _isFormValid() {
    if (_journeyTitleEnCtrl.text.trim().isEmpty ||
        _journeyTitleArCtrl.text.trim().isEmpty) {
      return false;
    }
    for (final item in _itemCtrls) {
      if (item.titleEnCtrl.text.trim().isEmpty ||
          item.titleArCtrl.text.trim().isEmpty) {
        return false;
      }
      if (item.descEnCtrl.text.trim().isEmpty ||
          item.descArCtrl.text.trim().isEmpty) {
        return false;
      }
      if (item.iconUrl.isEmpty || item.iconUrl == 'loading') {
        return false;
      }
    }
    return true;
  }

  void _showValidationError() {
    final List<String> missing = [];

    if (_journeyTitleEnCtrl.text.trim().isEmpty)
      missing.add('Section Title (English)');
    if (_journeyTitleArCtrl.text.trim().isEmpty)
      missing.add('Section Title (Arabic)');

    for (int i = 0; i < _itemCtrls.length; i++) {
      final item = _itemCtrls[i];
      final p = 'Item ${i + 1}';
      if (item.titleEnCtrl.text.trim().isEmpty) missing.add('$p - Title (English)');
      if (item.titleArCtrl.text.trim().isEmpty) missing.add('$p - Title (Arabic)');
      if (item.descEnCtrl.text.trim().isEmpty)  missing.add('$p - Description (English)');
      if (item.descArCtrl.text.trim().isEmpty)  missing.add('$p - Description (Arabic)');
      if (item.iconUrl.isEmpty || item.iconUrl == 'loading')
        missing.add('$p - SVG Icon');
    }

    showConfirmDialog(
      context: context,
      title: 'Required Fields Missing',
      subtitle: missing.isEmpty
          ? 'Please check all required fields.'
          : 'Please fill the following required fields:\n\n• ${missing.join('\n• ')}',
      confirmLabel: 'OK',
      cancelLabel: '',
      onConfirm: () {},
      iconWidget: Container(
        width: 60.r,
        height: 60.r,
        decoration: const BoxDecoration(
            color: Color(0xFFE53935), shape: BoxShape.circle),
        child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
      ),
    );
  }

  @override
  void dispose() {
    _journeyTitleEnCtrl.removeListener(_checkForChanges);
    _journeyTitleArCtrl.removeListener(_checkForChanges);
    for (final c in _itemCtrls) {
      c.titleEnCtrl.removeListener(_checkForChanges);
      c.titleArCtrl.removeListener(_checkForChanges);
      c.descEnCtrl.removeListener(_checkForChanges);
      c.descArCtrl.removeListener(_checkForChanges);
      c.dispose();
    }
    _journeyTitleEnCtrl.dispose();
    _journeyTitleArCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final item = _ItemControllers.empty();
      item.titleEnCtrl.addListener(_checkForChanges);
      item.titleArCtrl.addListener(_checkForChanges);
      item.descEnCtrl.addListener(_checkForChanges);
      item.descArCtrl.addListener(_checkForChanges);
      _itemCtrls.add(item);
      _itemOpen.add(true);
      _hasChanges = _hasAnyChanges();
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _itemCtrls[index];
      item.titleEnCtrl.removeListener(_checkForChanges);
      item.titleArCtrl.removeListener(_checkForChanges);
      item.descEnCtrl.removeListener(_checkForChanges);
      item.descArCtrl.removeListener(_checkForChanges);
      item.dispose();
      _itemCtrls.removeAt(index);
      _itemOpen.removeAt(index);
      _hasChanges = _hasAnyChanges();
    });
  }

  ServicePageModel get _edited {
    final items = _itemCtrls
        .map((c) => JourneyItemModel(
      id: c.itemId,
      iconUrl: c.iconUrl,
      title: BilingualText(
          en: c.titleEnCtrl.text, ar: c.titleArCtrl.text),
      description: BilingualText(
          en: c.descEnCtrl.text, ar: c.descArCtrl.text),
    ))
        .toList();
    return widget.model.copyWith(
      journeyTitle: BilingualText(
        en: _journeyTitleEnCtrl.text,
        ar: _journeyTitleArCtrl.text,
      ),
      journeyItems: items,
    );
  }

  // ── Preview — always enabled, no validation ────────────────────────────────
  void _onPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ServiceCmsCubit>(),
          child: ServicesDigitalJourneyPreviewPage(model: _edited),
        ),
      ),
    );
  }

  // ── SVG picker ────────────────────────────────────────────────────────────
  Future<Uint8List?> _pickSvgFile() async {
    final completer = Completer<Uint8List?>();
    bool completed = false;

    final input = html.FileUploadInputElement()..accept = '.svg,image/svg+xml';

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completed) {
          completed = true;
          completer.complete(null);
        }
        return;
      }
      final file = files.first;
      if (!file.name.toLowerCase().endsWith('.svg') &&
          file.type != 'image/svg+xml') {
        if (!completed) {
          completed = true;
          completer.complete(null);
          if (mounted) {
            showConfirmDialog(
              context: context,
              title: 'Invalid File',
              subtitle:
              'Only SVG files are allowed. Please select an SVG file.',
              confirmLabel: 'OK',
              cancelLabel: '',
              onConfirm: () {},
              iconWidget: Container(
                width: 60.r,
                height: 60.r,
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
                child:
                Icon(Icons.error_outline, color: Colors.white, size: 36.r),
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
            completer.complete(Uint8List.fromList(result));
          } else {
            completer.complete(null);
          }
        }
      });
      reader.onError.listen((_) {
        if (!completed) {
          completed = true;
          completer.complete(null);
        }
      });
      reader.readAsArrayBuffer(file);
    });

    input.click();

    Future.delayed(
        const Duration(minutes: 5), () {
      if (!completed) {
        completed = true;
        completer.complete(null);
      }
    });

    return completer.future;
  }

  // ── Upload icon — atomically sets URL + re-evaluates form in one setState ──
  Future<void> _uploadIcon(int index) async {
    try {
      final bytes = await _pickSvgFile();
      if (bytes == null) return;

      setState(() => _itemCtrls[index].iconUrl = 'loading');

      final fileName =
          'journey_icon_${DateTime.now().millisecondsSinceEpoch}.svg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('services/journey_icons/$fileName');
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/svg+xml'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // ✅ Single setState: URL + _hasChanges evaluated together so
      //    _isFormValid() sees the new URL in the same rebuild that
      //    re-draws the Publish button.
      setState(() {
        _itemCtrls[index].iconUrl = downloadUrl;
        _hasChanges = _hasAnyChanges();
      });
    } catch (e) {
      setState(() {
        _itemCtrls[index].iconUrl = '';
        _hasChanges = _hasAnyChanges();
      });
      if (mounted) {
        showConfirmDialog(
          context: context,
          title: 'Upload Failed',
          subtitle: 'Error: ${e.toString()}',
          confirmLabel: 'OK',
          cancelLabel: '',
          onConfirm: () {},
          iconWidget: Container(
            width: 60.r,
            height: 60.r,
            decoration: const BoxDecoration(
                color: Color(0xFFE53935), shape: BoxShape.circle),
            child:
            Icon(Icons.error_outline, color: Colors.white, size: 36.r),
          ),
        );
      }
    }
  }

  Future<void> _onSave() async {
    setState(() => _submitted = true);

    if (!_isFormValid()) {
      _showValidationError();
      return;
    }

    setState(() => _isSaving = true);

    try {
      context.read<ServiceCmsCubit>().replaceModel(_edited);
      await context.read<ServiceCmsCubit>().save(publishStatus: 'published');

      _originalJourneyTitleEn = _journeyTitleEnCtrl.text;
      _originalJourneyTitleAr = _journeyTitleArCtrl.text;
      _originalItems
        ..clear()
        ..addAll(_itemCtrls.map((item) => _OriginalItemData(
          id: item.itemId,
          titleEn: item.titleEnCtrl.text,
          titleAr: item.titleArCtrl.text,
          descEn: item.descEnCtrl.text,
          descAr: item.descArCtrl.text,
          iconUrl: item.iconUrl,
        )));

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        // REMOVED: showSuccessDialog
        // Just navigate back directly or show a different confirmation
        // If you want to keep the navigation, uncomment the line below:
        // await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context);
      }
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
            width: 60.r,
            height: 60.r,
            decoration: const BoxDecoration(
                color: Color(0xFFE53935), shape: BoxShape.circle),
            child:
            Icon(Icons.error_outline, color: Colors.white, size: 36.r),
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

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPick.background,
      body: BlocListener<ServiceCmsCubit, ServiceCmsState>(
        listener: (context, state) {
          if (state is ServiceCmsError) {
            showConfirmDialog(
              context: context,
              title: 'Error',
              subtitle: state.message,
              confirmLabel: 'OK',
              cancelLabel: '',
              onConfirm: () {},
              iconWidget: Container(
                width: 60.r,
                height: 60.r,
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
                child:
                Icon(Icons.error_outline, color: Colors.white, size: 36.r),
              ),
            );
          }
        },
        child: Stack(
          children: [
            AdminStickyBody(
  crossAxisAlignment: CrossAxisAlignment.start,
  contentWidth: 1000.w,
  children: [
                          AppAdminNavbar(
                            activeLabel:    'Web Page',
                            homePage:       CareersMainPageDashboard(),
                            webPage:        MainMainPage(),
                            jobListingPage: JobListingMainPage(),
                          ),
                          SizedBox(height: 20.h),
                          AdminSubNavBar(activeIndex: 2),
                          Text(
                            'Editing Digital Journey Details',
                            style: StyleText.fontSize45Weight600.copyWith(
                              color: ColorPick.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // ── Section title accordion ──────────────────────
                          _buildAccordion(
                            title: 'Digital Journey Section Title',
                            isOpen: _headerOpen,
                            onToggle: () =>
                                setState(() => _headerOpen = !_headerOpen),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Section Title',
                                          style: _labelStyle()),
                                      Text('عنوان القسم',
                                          style: _labelStyle()),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Row(children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _journeyTitleEnCtrl,
                                        hint: 'Text Here',
                                        isRequired: true,
                                        submitted: _submitted,
                                        primaryColor: ColorPick.primary,
                                        fillColor: Colors.white,
                                        textDirection: TextDirection.ltr,
                                        height: 36,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _journeyTitleArCtrl,
                                        hint: 'أدخل النص هنا',
                                        isRequired: true,
                                        submitted: _submitted,
                                        primaryColor: ColorPick.primary,
                                        fillColor: Colors.white,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        height: 36,
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // ── Per-item accordions ──────────────────────────
                          ...List.generate(
                            _itemCtrls.length,
                                (i) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildItemAccordion(i),
                            ),
                          ),

                          // ── Add button ───────────────────────────────────
                          GestureDetector(
                            onTap: _addItem,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF797979),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // The app's own add asset, not the Material
                                  // glyph — same icon every other "add" control
                                  // in the admin uses.
                                  CustomSvg(
                                    assetPath: 'assets/add.svg',
                                    width:  14.w,
                                    height: 14.w,
                                    fit:    BoxFit.scaleDown,
                                    color:  Colors.white,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Digital Journey',
                                    style: StyleText.fontSize12Weight600
                                        .copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),

                          _actionButtons(),
                          SizedBox(height: 40.h),
                        ],
),

            // ── Loading overlay ──────────────────────────────────────────
            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 40.w, vertical: 32.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .15),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleProgress(),
                        SizedBox(height: 20.h),
                        Text(
                          'Saving...',
                          style: StyleText.fontSize14Weight600
                              .copyWith(color: ColorPick.primary),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Uploading icons & saving data',
                          style: StyleText.fontSize12Weight400
                              .copyWith(color: ColorPick.back),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

// ── Per-item controller holder ─────────────────────────────────────────────
