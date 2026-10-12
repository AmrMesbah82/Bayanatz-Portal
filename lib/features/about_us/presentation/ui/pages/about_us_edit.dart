// ******************* FILE INFO *******************
// File Name: about_us_edit.dart
// Screen 2 — About Us CMS: Edit all sections
// Navigates to: AboutPreviewPage (screen 3)
// UPDATE: Values section — first item labeled "Main Icon", rest labeled "Icon"
//         matching Figma design exactly.
// UPDATED: Added custom dialogs for publish/save
// UPDATED: Proper validation with error messages under text fields
// UPDATED: All text fields have isRequired: true for inline validation
// UPDATED: Added Navigation Label section (between Headings and Vision)
// UPDATED: Publish button disabled until all fields valid. Error text only
//          appears after first submit attempt. Button reactively enables/disables.
// FIXED:   Vision onPickIcon was writing to _missionIconBytes → now _visionIconBytes
// FIXED:   Mission onPickIcon was writing to _visionIconBytes → now _missionIconBytes
// FIXED:   Navigation Label onTap called _pickSvgFile() → now _pickImageIcon()

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/constant/color.dart';

import 'package:web_app_admin/core/custom/image_upload_circle.dart';
import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/textfield.dart';

import '../../../../../core/custom_dialog.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/about_us_model.dart';
import '../../controller/about_us_cubit.dart';
import '../../controller/about_us_state.dart';
import 'about_us_main.dart';
import 'about_us_preview.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/about_us_edit/value_item.dart';
part '../widgets/about_us_edit/about_edit_file_pickers.dart';
part '../widgets/about_us_edit/about_edit_image_helpers.dart';
part '../widgets/about_us_edit/about_edit_builders.dart';

// const Color _kGreen = Color(0xFF2D8C4E);
// const Color ColorPick.primary = Color(0xFF008037);
// const Color _kGreenLight = Color(0xFFE8F5EE);
// const Color _kRed = Color(0xFFD32F2F);
// const Color _kSurface = Color(0xFFFFFFFF);
// const Color _kBg = Color(0xFFF2F2F2);

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class AboutEditPageMaster extends StatefulWidget {
  const AboutEditPageMaster({super.key});

  @override
  State<AboutEditPageMaster> createState() => _AboutEditPageMasterState();
}

class _AboutEditPageMasterState extends State<AboutEditPageMaster> {
  // ── Headings ──
  final _titleEnCtrl = TextEditingController();
  final _titleArCtrl = TextEditingController();

  // ── Navigation Label ──
  final _navTitleEnCtrl = TextEditingController();
  final _navTitleArCtrl = TextEditingController();
  Uint8List? _navIconBytes;

  /// BUG-219: an icon / SVG picked on this page is a change on its own — the
  /// shared "has the user typed anything?" check only sees text fields.
  bool _imageChanged = false;
  String _navIconUrl = '';

  // ── Vision ──
  final _visionSubEnCtrl = TextEditingController();
  final _visionSubArCtrl = TextEditingController();
  final _visionDescEnCtrl = TextEditingController();
  final _visionDescArCtrl = TextEditingController();
  Uint8List? _visionIconBytes;
  Uint8List? _visionSvgBytes;
  String _visionIconUrl = '';
  String _visionSvgUrl = '';

  // ── Mission ──
  final _missionSubEnCtrl = TextEditingController();
  final _missionSubArCtrl = TextEditingController();
  final _missionDescEnCtrl = TextEditingController();
  final _missionDescArCtrl = TextEditingController();
  Uint8List? _missionIconBytes;
  Uint8List? _missionSvgBytes;
  String _missionIconUrl = '';
  String _missionSvgUrl = '';

  // ── Values ──
  final List<_ValueItem> _valueItems = [];
  int _valueCounter = 0;

  // ── Accordion open/close ──
  bool _headingsOpen = true;
  bool _navigationLabelOpen = true;
  bool _visionOpen = true;
  bool _missionOpen = true;
  bool _valuesOpen = true;

  /// True only after user has attempted to submit at least once.
  /// Error text under fields only appears when this is true.
  bool _submitted = false;

  bool _seeded = false;
  bool _isSaving = false;

  // ── URL → bytes cache (avoids re-fetching on every rebuild) ──
  final Map<String, Future<Uint8List>> _urlBytesCache = {};

  /// Computed live — true when every required field has a value.
  bool get _isFormValid => _validateFields();

  @override
  void initState() {
    super.initState();
    // The first (Main Icon) value must exist from the very first frame,
    // without clicking "Add Point". _seedFromModel keeps the same guarantee
    // after data loads.
    _valueItems.add(
      _ValueItem(
        id: 'val_${DateTime.now().millisecondsSinceEpoch}',
        counter: ++_valueCounter,
      ),
    );
    context.read<AboutCubit>().load();
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _navTitleEnCtrl.dispose();
    _navTitleArCtrl.dispose();
    _visionSubEnCtrl.dispose();
    _visionSubArCtrl.dispose();
    _visionDescEnCtrl.dispose();
    _visionDescArCtrl.dispose();
    _missionSubEnCtrl.dispose();
    _missionSubArCtrl.dispose();
    _missionDescEnCtrl.dispose();
    _missionDescArCtrl.dispose();
    for (final v in _valueItems) {
      v.titleEnCtrl.dispose();
      v.titleArCtrl.dispose();
      v.shortDescEnCtrl.dispose();
      v.shortDescArCtrl.dispose();
    }
    super.dispose();
  }

  // ── Seed from loaded model ─────────────────────────────────────────────────
  void _seedFromModel(AboutPageModel m) {
    if (_seeded) return;
    _seeded = true;

    _titleEnCtrl.text = m.title.en;
    _titleArCtrl.text = m.title.ar;

    // ── Navigation Label ──
    _navTitleEnCtrl.text = m.navigationLabel.title.en;
    _navTitleArCtrl.text = m.navigationLabel.title.ar;
    _navIconUrl = m.navigationLabel.iconUrl;

    _visionSubEnCtrl.text = m.vision.subDescription.en;
    _visionSubArCtrl.text = m.vision.subDescription.ar;
    _visionDescEnCtrl.text = m.vision.description.en;
    _visionDescArCtrl.text = m.vision.description.ar;
    _visionIconUrl = m.vision.iconUrl;
    _visionSvgUrl = m.vision.svgUrl;

    _missionSubEnCtrl.text = m.mission.subDescription.en;
    _missionSubArCtrl.text = m.mission.subDescription.ar;
    _missionDescEnCtrl.text = m.mission.description.en;
    _missionDescArCtrl.text = m.mission.description.ar;
    _missionIconUrl = m.mission.iconUrl;
    _missionSvgUrl = m.mission.svgUrl;

    _valueItems.clear();
    for (final v in m.values) {
      final item = _ValueItem(id: v.id, counter: ++_valueCounter);
      item.titleEnCtrl.text = v.title.en;
      item.titleArCtrl.text = v.title.ar;
      item.shortDescEnCtrl.text = v.shortDescription.en;
      item.shortDescArCtrl.text = v.shortDescription.ar;
      item.iconUrl = v.iconUrl;
      _valueItems.add(item);
    }

    // Always show the first (Main Icon) value — no need to click "Add Point".
    if (_valueItems.isEmpty) {
      _valueItems.add(
        _ValueItem(
          id: 'val_${DateTime.now().millisecondsSinceEpoch}',
          counter: ++_valueCounter,
        ),
      );
    }
  }

  // ── Build model from current state ────────────────────────────────────────
  AboutPageModel _buildModel(String status) {
    return AboutPageModel(
      publishStatus: status,
      title: AboutBilingualText(
        en: _titleEnCtrl.text.trim(),
        ar: _titleArCtrl.text.trim(),
      ),
      navigationLabel: AboutNavigationLabel(
        iconUrl: _navIconUrl,
        title: AboutBilingualText(
          en: _navTitleEnCtrl.text.trim(),
          ar: _navTitleArCtrl.text.trim(),
        ),
      ),
      vision: AboutSection(
        iconUrl: _visionIconUrl,
        svgUrl: _visionSvgUrl,
        subDescription: AboutBilingualText(
          en: _visionSubEnCtrl.text.trim(),
          ar: _visionSubArCtrl.text.trim(),
        ),
        description: AboutBilingualText(
          en: _visionDescEnCtrl.text.trim(),
          ar: _visionDescArCtrl.text.trim(),
        ),
      ),
      mission: AboutSection(
        iconUrl: _missionIconUrl,
        svgUrl: _missionSvgUrl,
        subDescription: AboutBilingualText(
          en: _missionSubEnCtrl.text.trim(),
          ar: _missionSubArCtrl.text.trim(),
        ),
        description: AboutBilingualText(
          en: _missionDescEnCtrl.text.trim(),
          ar: _missionDescArCtrl.text.trim(),
        ),
      ),
      values: _valueItems
          .map(
            (v) => AboutValueItem(
          id: v.id,
          iconUrl: v.iconUrl,
          title: AboutBilingualText(
            en: v.titleEnCtrl.text.trim(),
            ar: v.titleArCtrl.text.trim(),
          ),
          shortDescription: AboutBilingualText(
            en: v.shortDescEnCtrl.text.trim(),
            ar: v.shortDescArCtrl.text.trim(),
          ),
        ),
      )
          .toList(),
    );
  }

  // ── Collect image uploads ──────────────────────────────────────────────────
  Map<String, Uint8List> _collectUploads() {
    final uploads = <String, Uint8List>{};
    if (_navIconBytes != null)
      uploads['about_cms/navLabel/icon'] = _navIconBytes!;
    if (_visionIconBytes != null)
      uploads['about_cms/vision/icon'] = _visionIconBytes!;
    if (_visionSvgBytes != null)
      uploads['about_cms/vision/svg'] = _visionSvgBytes!;
    if (_missionIconBytes != null)
      uploads['about_cms/mission/icon'] = _missionIconBytes!;
    if (_missionSvgBytes != null)
      uploads['about_cms/mission/svg'] = _missionSvgBytes!;
    for (final v in _valueItems) {
      if (v.iconBytes != null)
        uploads['about_cms/values/${v.id}/icon'] = v.iconBytes!;
    }
    return uploads;
  }

  // ── Validate fields — pure check, no side effects ──────────────────────────
  bool _validateFields() {
    // Check Headings
    if (_titleEnCtrl.text.trim().isEmpty) return false;
    if (_titleArCtrl.text.trim().isEmpty) return false;

    // Check Navigation Label
    if (_navTitleEnCtrl.text.trim().isEmpty) return false;
    if (_navTitleArCtrl.text.trim().isEmpty) return false;
    if (_navIconBytes == null && _navIconUrl.isEmpty) return false;

    // Check Vision
    if (_visionSubEnCtrl.text.trim().isEmpty) return false;
    if (_visionSubArCtrl.text.trim().isEmpty) return false;
    if (_visionDescEnCtrl.text.trim().isEmpty) return false;
    if (_visionDescArCtrl.text.trim().isEmpty) return false;
    if (_visionIconBytes == null && _visionIconUrl.isEmpty) return false;
    if (_visionSvgBytes == null && _visionSvgUrl.isEmpty) return false;

    // Check Mission
    if (_missionSubEnCtrl.text.trim().isEmpty) return false;
    if (_missionSubArCtrl.text.trim().isEmpty) return false;
    if (_missionDescEnCtrl.text.trim().isEmpty) return false;
    if (_missionDescArCtrl.text.trim().isEmpty) return false;
    if (_missionIconBytes == null && _missionIconUrl.isEmpty) return false;
    if (_missionSvgBytes == null && _missionSvgUrl.isEmpty) return false;

    // Check Values
    for (var i = 0; i < _valueItems.length; i++) {
      final v = _valueItems[i];
      final bool isMain = i == 0;
      // Main Icon (first item) has NO title fields — not used on user site.
      if (!isMain) {
        if (v.titleEnCtrl.text.trim().isEmpty) return false;
        if (v.titleArCtrl.text.trim().isEmpty) return false;
      }
      if (v.shortDescEnCtrl.text.trim().isEmpty) return false;
      if (v.shortDescArCtrl.text.trim().isEmpty) return false;
      if (v.iconBytes == null && v.iconUrl.isEmpty) return false;
    }

    return true;
  }

  // ── Show validation error dialog with missing fields ──────────────────────
  void _showValidationError() {
    final List<String> missingFields = [];

    // Check Headings
    if (_titleEnCtrl.text.trim().isEmpty) missingFields.add('Title (English)');
    if (_titleArCtrl.text.trim().isEmpty) missingFields.add('Title (Arabic)');

    // Check Navigation Label
    if (_navTitleEnCtrl.text.trim().isEmpty)
      missingFields.add('Navigation Label - Title (English)');
    if (_navTitleArCtrl.text.trim().isEmpty)
      missingFields.add('Navigation Label - Title (Arabic)');
    if (_navIconBytes == null && _navIconUrl.isEmpty)
      missingFields.add('Navigation Label - Icon');

    // Check Vision
    if (_visionSubEnCtrl.text.trim().isEmpty)
      missingFields.add('Vision Sub Description (English)');
    if (_visionSubArCtrl.text.trim().isEmpty)
      missingFields.add('Vision Sub Description (Arabic)');
    if (_visionDescEnCtrl.text.trim().isEmpty)
      missingFields.add('Vision Description (English)');
    if (_visionDescArCtrl.text.trim().isEmpty)
      missingFields.add('Vision Description (Arabic)');
    if (_visionIconBytes == null && _visionIconUrl.isEmpty)
      missingFields.add('Vision Icon Image');
    if (_visionSvgBytes == null && _visionSvgUrl.isEmpty)
      missingFields.add('Vision SVG Icon');

    // Check Mission
    if (_missionSubEnCtrl.text.trim().isEmpty)
      missingFields.add('Mission Sub Description (English)');
    if (_missionSubArCtrl.text.trim().isEmpty)
      missingFields.add('Mission Sub Description (Arabic)');
    if (_missionDescEnCtrl.text.trim().isEmpty)
      missingFields.add('Mission Description (English)');
    if (_missionDescArCtrl.text.trim().isEmpty)
      missingFields.add('Mission Description (Arabic)');
    if (_missionIconBytes == null && _missionIconUrl.isEmpty)
      missingFields.add('Mission Icon Image');
    if (_missionSvgBytes == null && _missionSvgUrl.isEmpty)
      missingFields.add('Mission SVG Icon');

    // Check Values
    for (var i = 0; i < _valueItems.length; i++) {
      final v = _valueItems[i];
      final bool isMain = i == 0;
      final prefix = isMain ? 'Main Icon' : 'Value ${i + 1}';
      // Main Icon (first item) has NO title fields — not used on user site.
      if (!isMain && v.titleEnCtrl.text.trim().isEmpty)
        missingFields.add('$prefix - Title (English)');
      if (!isMain && v.titleArCtrl.text.trim().isEmpty)
        missingFields.add('$prefix - Title (Arabic)');
      if (v.shortDescEnCtrl.text.trim().isEmpty)
        missingFields.add('$prefix - Short Description (English)');
      if (v.shortDescArCtrl.text.trim().isEmpty)
        missingFields.add('$prefix - Short Description (Arabic)');
      if (v.iconBytes == null && v.iconUrl.isEmpty)
        missingFields.add('$prefix - Icon Image');
    }

    final message = missingFields.isEmpty
        ? 'Please check all required fields.'
        : 'Please fill the following required fields:\n\n• ${missingFields.join('\n• ')}';

    showConfirmDialog(
      context: context,
      title: 'Required Fields Missing',
      subtitle: message,
      confirmLabel: 'OK',
      cancelLabel: '',
      onConfirm: () {},
      iconWidget: Container(
        width: 60.r,
        height: 60.r,
        decoration: const BoxDecoration(
          color: Color(0xFFE53935),
          shape: BoxShape.circle,
        ),
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

    final model = _buildModel('draft');
    final uploads = _collectUploads();
    final cubit = context.read<AboutCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AboutPreviewPageLast(model: model, imageUploads: uploads),
        ),
      ),
    );
  }

  // ── Save / Publish with custom dialog ─────────────────────────────────────
  Future<void> _save(String status) async {
    setState(() => _submitted = true);
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_validateFields()) {
      _showValidationError();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final model = _buildModel(status);
      final uploads = _collectUploads();
      await context.read<AboutCubit>().save(
        model: model,
        imageUploads: uploads.isEmpty ? null : uploads,
      );

      // if (mounted) {
      //   if (status == 'published') {
      //     await Future.delayed(const Duration(milliseconds: 1500));
      //     if (mounted) context.go('/');
      //   }
      // }
    } catch (e) {
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
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Add / remove value item ────────────────────────────────────────────────
  void _addValueItem() {
    setState(() {
      _valueItems.add(
        _ValueItem(
          id: 'val_${DateTime.now().millisecondsSinceEpoch}',
          counter: ++_valueCounter,
        ),
      );
    });
  }

  void _removeValueItem(String id) {
    setState(() => _valueItems.removeWhere((v) => v.id == id));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AboutCubit, AboutState>(
      listener: (context, state) {
        if (state is AboutLoaded) _seedFromModel(state.data);
        if (state is AboutSaved) {
          // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const AboutMainPageMasterDashboard(),
                ),
                    (route) => false,
              );
            }
          });
        }
        if (state is AboutError) {
          setState(() => _isSaving = false);
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
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child:
              Icon(Icons.error_outline, color: Colors.white, size: 36.r),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AboutLoading || state is AboutInitial;

        return Scaffold(
          backgroundColor: Color(0xFFF1F2ED),
          body: AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  children: [
                  AppAdminNavbar(
                    activeLabel: 'Web Page',
                    homePage: CareersMainPageDashboard(),
                    webPage: MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),
                  AdminSubNavBar(activeIndex: 3),
                  SizedBox(
                    width: 1000.w,
                    child: isLoading
                        ? const Center(
                      child: CircleProgress(),
                    )
                        : _buildForm(),
                  ),
                ],
),
        );
      },
    );
  }

}

// ── Value item helper class ────────────────────────────────────────────────────
