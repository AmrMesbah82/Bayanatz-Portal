// ******************* FILE INFO *******************
// File Name: strategy_edit.dart
// Screen 2 of 3 — Our Strategy CMS: Edit page
// UPDATED: Multi-device image support (Desktop, Tablet, Mobile) for both EN and AR
// UPDATED: Each device has separate upload button and preview
// UPDATED: Validation requires all 3 device images for each language on publish
// Ported from beauty_admin strategy_edit.dart

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/widget/auto_close_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/button.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/features/about_us/presentation/ui/pages/strategy_page/strategy_preview.dart';

import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom/circle_progress.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../data/models/about_us_model.dart';
import '../../../controller/about_us_cubit.dart';
import '../../../controller/about_us_state.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';

part '../../widgets/strategy_edit/strategy_edit_image_widgets.dart';
part '../../widgets/strategy_edit/strategy_edit_form_helpers.dart';


// ── Device type enum for image uploads ────────────────────────────────────────
enum DeviceType { desktop, tablet, mobile }

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.desktop: return 'Desktop';
      case DeviceType.tablet: return 'Tablet';
      case DeviceType.mobile: return 'Mobile';
    }
  }

  String get storagePathSuffix {
    switch (this) {
      case DeviceType.desktop: return 'desktop';
      case DeviceType.tablet: return 'tablet';
      case DeviceType.mobile: return 'mobile';
    }
  }

  double get previewWidth {
    switch (this) {
      case DeviceType.desktop: return double.infinity;
      case DeviceType.tablet: return 600;
      case DeviceType.mobile: return 320;
    }
  }
}

// ── Device preview tab enum for display ───────────────────────────────────────
enum DisplayDeviceTab { largeScreen, tablet, mobile }

// ═══════════════════════════════════════════════════════════════════════════════

class StrategyEditPage extends StatefulWidget {
  const StrategyEditPage({super.key});

  @override
  State<StrategyEditPage> createState() => _StrategyEditPageState();
}

class _StrategyEditPageState extends State<StrategyEditPage> {
  // ── Navigation Label ──
  final _navTitleEnCtrl = TextEditingController();
  final _navTitleArCtrl = TextEditingController();
  Uint8List? _navIconBytes;
  String _navIconUrl = '';
  bool _navIconIsSvg = false;

  // ── Strategic House — ENG (3 devices) ──
  // Desktop
  Uint8List? _strategicHouseEnDesktopBytes;
  String _strategicHouseEnDesktopUrl = '';
  bool _strategicHouseEnDesktopIsSvg = false;

  // Tablet
  Uint8List? _strategicHouseEnTabletBytes;
  String _strategicHouseEnTabletUrl = '';
  bool _strategicHouseEnTabletIsSvg = false;

  // Mobile
  Uint8List? _strategicHouseEnMobileBytes;
  String _strategicHouseEnMobileUrl = '';
  bool _strategicHouseEnMobileIsSvg = false;

  // ── Strategic House — ARB (3 devices) ──
  // Desktop
  Uint8List? _strategicHouseArDesktopBytes;
  String _strategicHouseArDesktopUrl = '';
  bool _strategicHouseArDesktopIsSvg = false;

  // Tablet
  Uint8List? _strategicHouseArTabletBytes;
  String _strategicHouseArTabletUrl = '';
  bool _strategicHouseArTabletIsSvg = false;

  // Mobile
  Uint8List? _strategicHouseArMobileBytes;
  String _strategicHouseArMobileUrl = '';
  bool _strategicHouseArMobileIsSvg = false;

  bool _navLabelOpen        = true;
  bool _strategicHouseEnOpen = true;
  bool _strategicHouseArOpen = true;

  bool _submitted = false;
  bool _seeded    = false;
  bool _isSaving  = false;

  /// Whether the data currently loaded came from a draft document.
  bool _isEditingDraft = false;

  // ── Validation errors per device ──
  String? _navIconError;

  // EN device errors
  String? _strategicHouseEnDesktopError;
  String? _strategicHouseEnTabletError;
  String? _strategicHouseEnMobileError;

  // AR device errors
  String? _strategicHouseArDesktopError;
  String? _strategicHouseArTabletError;
  String? _strategicHouseArMobileError;

  // ── Display preview tabs for each section ──
  DisplayDeviceTab _strategicHouseEnDisplayTab = DisplayDeviceTab.largeScreen;
  DisplayDeviceTab _strategicHouseArDisplayTab = DisplayDeviceTab.largeScreen;

  // ── Cache for loaded SVG URLs to prevent reloading ──
  final Map<String, Uint8List> _svgCache = {};

  // ── Keys to prevent unnecessary rebuilds ──
  final _navIconKey = GlobalKey();

  // ── Field change listener for reactive validation ──
  List<TextEditingController> get _allControllers => [
    _navTitleEnCtrl,
    _navTitleArCtrl,
  ];

  void _onFieldChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    for (final ctrl in _allControllers) {
      ctrl.addListener(_onFieldChanged);
    }
    context.read<StrategyCubit>().load();
  }

  @override
  void dispose() {
    for (final ctrl in _allControllers) {
      ctrl.removeListener(_onFieldChanged);
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Validation helpers ────────────────────────────────────────────────────
  // Language enforcement removed — valid when non-empty, any language.
  bool _isValidEnglish(String text) => text.trim().isNotEmpty;

  bool _isValidArabic(String text) => text.trim().isNotEmpty;

  // ── SVG validation helpers ────────────────────────────────────────────────
  bool _isSvgUrl(String url) {
    if (url.isEmpty) return false;
    final decodedUrl = Uri.decodeFull(url).toLowerCase();
    return decodedUrl.contains('.svg') ||
        decodedUrl.contains('%2Esvg') ||
        decodedUrl.contains('image/svg+xml');
  }

  // ── File picker - SVG or PNG ──────────────────────────────────────────────
  Future<Uint8List?> _pickSvgImage() async {
    final c = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()
      ..accept = 'image/svg+xml,image/png,image/jpeg,image/webp,.svg,.png,.jpg,.jpeg,.webp';

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        c.complete(null);
        return;
      }

      final file = files.first;

      // Validate file type (SVG or raster image)
      if (!(file.type.startsWith('image/') ||
          file.name.toLowerCase().endsWith('.svg'))) {
        c.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((_) {
        final r = reader.result;
        Uint8List? bytes;
        if (r is ByteBuffer) {
          bytes = r.asUint8List();
        } else if (r is Uint8List) {
          bytes = r;
        }

        if (bytes != null) {
          c.complete(bytes);
        } else {
          c.complete(null);
        }
      });

      reader.onError.listen((e) {
        c.complete(null);
      });
    });

    input.click();
    return c.future;
  }

  // ── Upload SVG for the device currently selected in the Desktop/Tablet/
  //    Mobile tab bar. Tapping the preview triggers this. ────────────────────
  Future<void> _uploadStrategicHouseForSelectedTab({required bool isAr}) async {
    final b = await _pickSvgImage();
    if (b == null) return;
    final tab = isAr ? _strategicHouseArDisplayTab : _strategicHouseEnDisplayTab;
    setState(() {
      if (isAr) {
        switch (tab) {
          case DisplayDeviceTab.largeScreen:
            _strategicHouseArDesktopBytes = b;
            _strategicHouseArDesktopIsSvg = true;
            _strategicHouseArDesktopError = null;
            break;
          case DisplayDeviceTab.tablet:
            _strategicHouseArTabletBytes = b;
            _strategicHouseArTabletIsSvg = true;
            _strategicHouseArTabletError = null;
            break;
          case DisplayDeviceTab.mobile:
            _strategicHouseArMobileBytes = b;
            _strategicHouseArMobileIsSvg = true;
            _strategicHouseArMobileError = null;
            break;
        }
      } else {
        switch (tab) {
          case DisplayDeviceTab.largeScreen:
            _strategicHouseEnDesktopBytes = b;
            _strategicHouseEnDesktopIsSvg = true;
            _strategicHouseEnDesktopError = null;
            break;
          case DisplayDeviceTab.tablet:
            _strategicHouseEnTabletBytes = b;
            _strategicHouseEnTabletIsSvg = true;
            _strategicHouseEnTabletError = null;
            break;
          case DisplayDeviceTab.mobile:
            _strategicHouseEnMobileBytes = b;
            _strategicHouseEnMobileIsSvg = true;
            _strategicHouseEnMobileError = null;
            break;
        }
      }
    });
  }

  // Error (if any) for the device currently selected in the tab bar.
  String? _strategicHouseSelectedError({required bool isAr}) {
    if (isAr) {
      switch (_strategicHouseArDisplayTab) {
        case DisplayDeviceTab.largeScreen: return _strategicHouseArDesktopError;
        case DisplayDeviceTab.tablet:      return _strategicHouseArTabletError;
        case DisplayDeviceTab.mobile:      return _strategicHouseArMobileError;
      }
    } else {
      switch (_strategicHouseEnDisplayTab) {
        case DisplayDeviceTab.largeScreen: return _strategicHouseEnDesktopError;
        case DisplayDeviceTab.tablet:      return _strategicHouseEnTabletError;
        case DisplayDeviceTab.mobile:      return _strategicHouseEnMobileError;
      }
    }
  }

  // ── Seed ─────────────────────────────────────────────────────────────────
  void _seed(OurStrategyModel m, {bool isFromDraft = false}) {
    if (_seeded) return;
    _seeded = true;
    _isEditingDraft = isFromDraft;


    // Remove listeners temporarily
    for (final ctrl in _allControllers) {
      ctrl.removeListener(_onFieldChanged);
    }

    _navTitleEnCtrl.text = m.navigationLabel.title.en;
    _navTitleArCtrl.text = m.navigationLabel.title.ar;
    _navIconUrl = m.navigationLabel.iconUrl;
    _navIconIsSvg = _isSvgUrl(m.navigationLabel.iconUrl);

    // EN device URLs
    _strategicHouseEnDesktopUrl = m.strategicHouseEnDesktopUrl;
    _strategicHouseEnDesktopIsSvg = _isSvgUrl(m.strategicHouseEnDesktopUrl);

    _strategicHouseEnTabletUrl = m.strategicHouseEnTabletUrl;
    _strategicHouseEnTabletIsSvg = _isSvgUrl(m.strategicHouseEnTabletUrl);

    _strategicHouseEnMobileUrl = m.strategicHouseEnMobileUrl;
    _strategicHouseEnMobileIsSvg = _isSvgUrl(m.strategicHouseEnMobileUrl);

    // AR device URLs
    _strategicHouseArDesktopUrl = m.strategicHouseArDesktopUrl;
    _strategicHouseArDesktopIsSvg = _isSvgUrl(m.strategicHouseArDesktopUrl);

    _strategicHouseArTabletUrl = m.strategicHouseArTabletUrl;
    _strategicHouseArTabletIsSvg = _isSvgUrl(m.strategicHouseArTabletUrl);

    _strategicHouseArMobileUrl = m.strategicHouseArMobileUrl;
    _strategicHouseArMobileIsSvg = _isSvgUrl(m.strategicHouseArMobileUrl);

    // Re-add listeners
    for (final ctrl in _allControllers) {
      ctrl.addListener(_onFieldChanged);
    }

    setState(() {});
  }

  // ── Build Model ───────────────────────────────────────────────────────────
  OurStrategyModel _buildModel(String status) => OurStrategyModel(
    publishStatus: status,
    navigationLabel: AboutNavigationLabel(
      iconUrl: _navIconUrl,
      title: AboutBilingualText(
        en: _navTitleEnCtrl.text.trim(),
        ar: _navTitleArCtrl.text.trim(),
      ),
    ),
    vision: const StrategySection(),
    strategicHouseEnDesktopUrl: _strategicHouseEnDesktopUrl,
    strategicHouseEnTabletUrl: _strategicHouseEnTabletUrl,
    strategicHouseEnMobileUrl: _strategicHouseEnMobileUrl,
    strategicHouseArDesktopUrl: _strategicHouseArDesktopUrl,
    strategicHouseArTabletUrl: _strategicHouseArTabletUrl,
    strategicHouseArMobileUrl: _strategicHouseArMobileUrl,
  );

  Map<String, Uint8List> _collectUploads() {
    final uploads = <String, Uint8List>{};

    // Navigation icon
    if (_navIconBytes != null && _navIconIsSvg)
      uploads['strategy_cms/navLabel/icon'] = _navIconBytes!;

    // EN device uploads
    if (_strategicHouseEnDesktopBytes != null && _strategicHouseEnDesktopIsSvg)
      uploads['strategy_cms/strategicHouse/en/desktop'] = _strategicHouseEnDesktopBytes!;

    if (_strategicHouseEnTabletBytes != null && _strategicHouseEnTabletIsSvg)
      uploads['strategy_cms/strategicHouse/en/tablet'] = _strategicHouseEnTabletBytes!;

    if (_strategicHouseEnMobileBytes != null && _strategicHouseEnMobileIsSvg)
      uploads['strategy_cms/strategicHouse/en/mobile'] = _strategicHouseEnMobileBytes!;

    // AR device uploads
    if (_strategicHouseArDesktopBytes != null && _strategicHouseArDesktopIsSvg)
      uploads['strategy_cms/strategicHouse/ar/desktop'] = _strategicHouseArDesktopBytes!;

    if (_strategicHouseArTabletBytes != null && _strategicHouseArTabletIsSvg)
      uploads['strategy_cms/strategicHouse/ar/tablet'] = _strategicHouseArTabletBytes!;

    if (_strategicHouseArMobileBytes != null && _strategicHouseArMobileIsSvg)
      uploads['strategy_cms/strategicHouse/ar/mobile'] = _strategicHouseArMobileBytes!;

    return uploads;
  }

  // ── Check if a device image is present ─────────────────────────────────────
  bool _hasEnDeviceImage(DeviceType device) {
    switch (device) {
      case DeviceType.desktop:
        return _strategicHouseEnDesktopBytes != null || _strategicHouseEnDesktopUrl.isNotEmpty;
      case DeviceType.tablet:
        return _strategicHouseEnTabletBytes != null || _strategicHouseEnTabletUrl.isNotEmpty;
      case DeviceType.mobile:
        return _strategicHouseEnMobileBytes != null || _strategicHouseEnMobileUrl.isNotEmpty;
    }
  }

  bool _hasArDeviceImage(DeviceType device) {
    switch (device) {
      case DeviceType.desktop:
        return _strategicHouseArDesktopBytes != null || _strategicHouseArDesktopUrl.isNotEmpty;
      case DeviceType.tablet:
        return _strategicHouseArTabletBytes != null || _strategicHouseArTabletUrl.isNotEmpty;
      case DeviceType.mobile:
        return _strategicHouseArMobileBytes != null || _strategicHouseArMobileUrl.isNotEmpty;
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool _validate({bool forPublish = false}) {
    bool isValid = true;

    // Clear previous errors
    setState(() {
      _navIconError = null;
      _strategicHouseEnDesktopError = null;
      _strategicHouseEnTabletError = null;
      _strategicHouseEnMobileError = null;
      _strategicHouseArDesktopError = null;
      _strategicHouseArTabletError = null;
      _strategicHouseArMobileError = null;
    });

    // Validate text fields
    if (!_isValidEnglish(_navTitleEnCtrl.text)) {
      isValid = false;
    }
    if (!_isValidArabic(_navTitleArCtrl.text)) {
      isValid = false;
    }

    // Validate Navigation Icon (any image format allowed)
    final hasNavIcon = _navIconBytes != null || _navIconUrl.isNotEmpty;
    if (!hasNavIcon) {
      setState(() => _navIconError = 'Navigation icon is required');
      isValid = false;
    }

    // For publish, ALL 6 Strategic House images are REQUIRED (EN & AR x 3 devices)
    if (forPublish) {
      if (!_hasEnDeviceImage(DeviceType.desktop)) {
        setState(() => _strategicHouseEnDesktopError = 'Strategic House (ENG) Desktop image is required for publishing');
        isValid = false;
      }
      if (!_hasEnDeviceImage(DeviceType.tablet)) {
        setState(() => _strategicHouseEnTabletError = 'Strategic House (ENG) Tablet image is required for publishing');
        isValid = false;
      }
      if (!_hasEnDeviceImage(DeviceType.mobile)) {
        setState(() => _strategicHouseEnMobileError = 'Strategic House (ENG) Mobile image is required for publishing');
        isValid = false;
      }
      if (!_hasArDeviceImage(DeviceType.desktop)) {
        setState(() => _strategicHouseArDesktopError = 'Strategic House (ARB) Desktop image is required for publishing');
        isValid = false;
      }
      if (!_hasArDeviceImage(DeviceType.tablet)) {
        setState(() => _strategicHouseArTabletError = 'Strategic House (ARB) Tablet image is required for publishing');
        isValid = false;
      }
      if (!_hasArDeviceImage(DeviceType.mobile)) {
        setState(() => _strategicHouseArMobileError = 'Strategic House (ARB) Mobile image is required for publishing');
        isValid = false;
      }
    }

    return isValid;
  }

  // ── Check if form is valid for publishing ────────────────────────────────
  bool get _isFormValid {
    // Check text fields
    if (!_isValidEnglish(_navTitleEnCtrl.text)) return false;
    if (!_isValidArabic(_navTitleArCtrl.text)) return false;

    // Check navigation icon (any image format allowed)
    final hasNavIcon = _navIconBytes != null || _navIconUrl.isNotEmpty;
    if (!hasNavIcon) return false;

    // Check all 6 strategic house images exist (any image format allowed)
    // EN
    if (!_hasEnDeviceImage(DeviceType.desktop)) return false;
    if (!_hasEnDeviceImage(DeviceType.tablet)) return false;
    if (!_hasEnDeviceImage(DeviceType.mobile)) return false;

    // AR
    if (!_hasArDeviceImage(DeviceType.desktop)) return false;
    if (!_hasArDeviceImage(DeviceType.tablet)) return false;
    if (!_hasArDeviceImage(DeviceType.mobile)) return false;

    // Check for validation errors
    if (_navIconError != null) return false;
    if (_strategicHouseEnDesktopError != null) return false;
    if (_strategicHouseEnTabletError != null) return false;
    if (_strategicHouseEnMobileError != null) return false;
    if (_strategicHouseArDesktopError != null) return false;
    if (_strategicHouseArTabletError != null) return false;
    if (_strategicHouseArMobileError != null) return false;

    return true;
  }

  // ── Get missing fields for error dialog ──────────────────────────────────
  List<String> _getMissingFields() {
    final missing = <String>[];

    if (_navTitleEnCtrl.text.trim().isEmpty) missing.add('Navigation Title (EN)');
    if (_navTitleArCtrl.text.trim().isEmpty) missing.add('Navigation Title (AR)');

    final hasNavIcon = _navIconBytes != null || _navIconUrl.isNotEmpty;
    if (!hasNavIcon) missing.add('Navigation Icon');

    // EN devices
    if (!_hasEnDeviceImage(DeviceType.desktop)) {
      missing.add('Strategic House (ENG) Desktop image');
    }
    if (!_hasEnDeviceImage(DeviceType.tablet)) {
      missing.add('Strategic House (ENG) Tablet image');
    }
    if (!_hasEnDeviceImage(DeviceType.mobile)) {
      missing.add('Strategic House (ENG) Mobile image');
    }

    // AR devices
    if (!_hasArDeviceImage(DeviceType.desktop)) {
      missing.add('Strategic House (ARB) Desktop image');
    }
    if (!_hasArDeviceImage(DeviceType.tablet)) {
      missing.add('Strategic House (ARB) Tablet image');
    }
    if (!_hasArDeviceImage(DeviceType.mobile)) {
      missing.add('Strategic House (ARB) Mobile image');
    }

    return missing;
  }

  // ── Show validation error dialog ──────────────────────────────────────────
  void _showValidationError() {
    final missing = _getMissingFields();
    if (missing.isEmpty) return;

    // Closes itself after 3 s (AutoCloseDialog) — no OK button.
    showDialog(
      context: context,
      builder: (context) => AutoCloseDialog(child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: const Color(0xFFD32F2F), size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Validation Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please fill all required fields correctly:'),
            const SizedBox(height: 12),
            ...missing.map((field) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: const Color(0xFFD32F2F))),
                  Expanded(child: Text(field)),
                ],
              ),
            )),
          ],
        ),
      )),
    );
  }

  // ── Preview ───────────────────────────────────────────────────────────────
  void _onPreview() {
    setState(() => _submitted = true);
    if (!_validate(forPublish: false)) return;

    final cubit   = context.read<StrategyCubit>();
    final model   = _buildModel('draft');
    final uploads = _collectUploads();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: StrategyPreviewPage(model: model, imageUploads: uploads),
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save(String status) async {
    // For publish, validate all 6 images are present
    if (status == 'published') {
      setState(() => _submitted = true);
      if (!_validate(forPublish: true)) {
        _showValidationError();
        return;
      }
    }

    setState(() => _isSaving = true);

    final model = _buildModel(status);
    final uploads = _collectUploads();


    await context.read<StrategyCubit>().save(
      model: model,
      imageUploads: uploads.isEmpty ? null : uploads,
    );
  }

  // ── Load SVG from URL with caching ────────────────────────────────────────
  Future<Uint8List> _loadSvgBytes(String url) async {
    if (_svgCache.containsKey(url)) {
      return _svgCache[url]!;
    }

    try {
      final res = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'arraybuffer',
      );
      if (res.status != 200) {
        throw Exception('Failed to load SVG: ${res.status}');
      }
      final bytes = (res.response as ByteBuffer).asUint8List();

      _svgCache[url] = bytes;
      return bytes;
    } catch (e) {
      rethrow;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StrategyCubit, StrategyState>(
      listener: (context, state) {

        if (state is StrategyLoaded) {
          _seed(state.data);
        }

        if (state is StrategySaved) {
          setState(() => _isSaving = false);

          setState(() {
            _navIconUrl = state.data.navigationLabel.iconUrl;
            _navIconIsSvg = _isSvgUrl(state.data.navigationLabel.iconUrl);

            // EN device URLs
            _strategicHouseEnDesktopUrl = state.data.strategicHouseEnDesktopUrl;
            _strategicHouseEnDesktopIsSvg = _isSvgUrl(state.data.strategicHouseEnDesktopUrl);

            _strategicHouseEnTabletUrl = state.data.strategicHouseEnTabletUrl;
            _strategicHouseEnTabletIsSvg = _isSvgUrl(state.data.strategicHouseEnTabletUrl);

            _strategicHouseEnMobileUrl = state.data.strategicHouseEnMobileUrl;
            _strategicHouseEnMobileIsSvg = _isSvgUrl(state.data.strategicHouseEnMobileUrl);

            // AR device URLs
            _strategicHouseArDesktopUrl = state.data.strategicHouseArDesktopUrl;
            _strategicHouseArDesktopIsSvg = _isSvgUrl(state.data.strategicHouseArDesktopUrl);

            _strategicHouseArTabletUrl = state.data.strategicHouseArTabletUrl;
            _strategicHouseArTabletIsSvg = _isSvgUrl(state.data.strategicHouseArTabletUrl);

            _strategicHouseArMobileUrl = state.data.strategicHouseArMobileUrl;
            _strategicHouseArMobileIsSvg = _isSvgUrl(state.data.strategicHouseArMobileUrl);

            // Clear bytes after successful upload
            _navIconBytes = null;
            _strategicHouseEnDesktopBytes = null;
            _strategicHouseEnTabletBytes = null;
            _strategicHouseEnMobileBytes = null;
            _strategicHouseArDesktopBytes = null;
            _strategicHouseArTabletBytes = null;
            _strategicHouseArMobileBytes = null;

            // Clear cache for updated URLs
            _svgCache.remove(_navIconUrl);
            _svgCache.remove(_strategicHouseEnDesktopUrl);
            _svgCache.remove(_strategicHouseEnTabletUrl);
            _svgCache.remove(_strategicHouseEnMobileUrl);
            _svgCache.remove(_strategicHouseArDesktopUrl);
            _svgCache.remove(_strategicHouseArTabletUrl);
            _svgCache.remove(_strategicHouseArMobileUrl);
          });

          if (mounted) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && Navigator.canPop(context)) Navigator.pop(context);
            });
          }
        }

        if (state is StrategyError) {
          setState(() => _isSaving = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${state.message}',
                  style: StyleText.fontSize14Weight400.copyWith(color: Colors.white)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      },
      builder: (context, state) {
        final loading = state is StrategyLoading || state is StrategyInitial;
        final canPublish = _isFormValid;

        return Scaffold(
          backgroundColor: ColorPick.background,
          body: Stack(
            children: [
              AdminStickyBody(
  contentWidth: 1000.w,
  children: [
                            AppAdminNavbar(
                              activeLabel:    'Web Page',
                              homePage:       CareersMainPageDashboard(),
                              webPage:        MainMainPage(),
                              jobListingPage: JobListingMainPage(),
                            ),
                            SizedBox(height: 20.h),
                            AdminSubNavBar(activeIndex: 3),
                            loading
                                ? Center(
                                child: CircleProgress())
                                : _buildForm(canPublish),
                          ],
),
              if (_isSaving) _savingOverlay(),
            ],
          ),
        );
      },
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm(bool canPublish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row with draft badge ─────────────────────────────────────
        Row(
          children: [
            Text('Editing Our Strategy',
                style: StyleText.fontSize45Weight600.copyWith(
                    color: ColorPick.primary, fontWeight: FontWeight.w700)),
            if (_isEditingDraft) ...[
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'EDITING DRAFT',
                  style: StyleText.fontSize12Weight600.copyWith(
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_isEditingDraft)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              'You are editing a saved draft. The published version is still live.',
              style: StyleText.fontSize12Weight400.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        SizedBox(height: 24.h),

        // ── Navigation Label ──────────────────────────────────────────────
        _accordion(
          title: 'Navigation Label',
          isOpen: _navLabelOpen,
          onToggle: () =>
              setState(() => _navLabelOpen = !_navLabelOpen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NavIconUploadWidget(
                key: _navIconKey,
                bytes: _navIconBytes,
                url: _navIconUrl,
                isSvg: _navIconIsSvg,
                errorText: _navIconError,
                loadSvgBytes: _loadSvgBytes,
                onTap: () async {
                  final b = await _pickSvgImage();
                  if (b != null) {
                    setState(() {
                      _navIconBytes = b;
                      _navIconIsSvg = true;
                      _navIconError = null;
                    });
                  }
                },
                onRemove: (_navIconBytes != null || _navIconUrl.isNotEmpty)
                    ? () => setState(() {
                  _navIconBytes = null;
                  _navIconUrl = '';
                  _navIconIsSvg = false;
                })
                    : null,
              ),
              SizedBox(height: 16.h),
              _fieldLabel('Title'),
              SizedBox(height: 8.h),
              _bilingualRow(
                  enCtrl: _navTitleEnCtrl,
                  arCtrl: _navTitleArCtrl,
                  enHint: 'Text Here',
                  arHint: 'أدخل النص هنا'),
            ],
          ),
        ),
        _navLabelOpen ? SizedBox(height: 0) : SizedBox(height: 16.h),
        // ── Strategic House — ENG (3 devices) ─────────────────────────────────────────
        _accordion(
          title: 'Strategic House - EN',
          isOpen: _strategicHouseEnOpen,
          onToggle: () =>
              setState(() => _strategicHouseEnOpen = !_strategicHouseEnOpen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device selector tabs - aligned to the right (same as main page)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _deviceDisplayTabBar(
                    selected: _strategicHouseEnDisplayTab,
                    onChanged: (tab) =>
                        setState(() => _strategicHouseEnDisplayTab = tab),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Current display preview — TAP to upload/replace the SVG for
              // the device selected in the tab bar above.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _uploadStrategicHouseForSelectedTab(isAr: false),
                child: _StrategicHouseDisplayWidget(
                  displayTab: _strategicHouseEnDisplayTab,
                  desktopBytes: _strategicHouseEnDesktopBytes,
                  desktopUrl: _strategicHouseEnDesktopUrl,
                  desktopIsSvg: _strategicHouseEnDesktopIsSvg,
                  tabletBytes: _strategicHouseEnTabletBytes,
                  tabletUrl: _strategicHouseEnTabletUrl,
                  tabletIsSvg: _strategicHouseEnTabletIsSvg,
                  mobileBytes: _strategicHouseEnMobileBytes,
                  mobileUrl: _strategicHouseEnMobileUrl,
                  mobileIsSvg: _strategicHouseEnMobileIsSvg,
                  loadSvgBytes: _loadSvgBytes,
                ),
              ),
              SizedBox(height: 8.h),

              if (_strategicHouseSelectedError(isAr: false) != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _strategicHouseSelectedError(isAr: false)!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // ── Strategic House — ARB (3 devices) ─────────────────────────────────────────
        _accordion(
          title: 'Strategic House - AR',
          isOpen: _strategicHouseArOpen,
          onToggle: () =>
              setState(() => _strategicHouseArOpen = !_strategicHouseArOpen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device selector tabs - aligned to the right (same as main page)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _deviceDisplayTabBar(
                    selected: _strategicHouseArDisplayTab,
                    onChanged: (tab) =>
                        setState(() => _strategicHouseArDisplayTab = tab),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Current display preview — TAP to upload/replace the SVG for
              // the device selected in the tab bar above.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _uploadStrategicHouseForSelectedTab(isAr: true),
                child: _StrategicHouseDisplayWidget(
                  displayTab: _strategicHouseArDisplayTab,
                  desktopBytes: _strategicHouseArDesktopBytes,
                  desktopUrl: _strategicHouseArDesktopUrl,
                  desktopIsSvg: _strategicHouseArDesktopIsSvg,
                  tabletBytes: _strategicHouseArTabletBytes,
                  tabletUrl: _strategicHouseArTabletUrl,
                  tabletIsSvg: _strategicHouseArTabletIsSvg,
                  mobileBytes: _strategicHouseArMobileBytes,
                  mobileUrl: _strategicHouseArMobileUrl,
                  mobileIsSvg: _strategicHouseArMobileIsSvg,
                  loadSvgBytes: _loadSvgBytes,
                ),
              ),

              if (_strategicHouseSelectedError(isAr: true) != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _strategicHouseSelectedError(isAr: true)!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 32.h),

        // ── Action buttons ────────────────────────────────────────────────
        _actionButtons(canPublish),
        SizedBox(height: 48.h),
      ],
    );
  }

  // ── Action Buttons (shared widget — one place for ALL edit pages) ────────
  Widget _actionButtons(bool canPublish) {
    return EditActionButtons(
      publishEnabled: canPublish,
      onPreview: _onPreview,
      onPublish: () {
        showPublishConfirmDialog(
          context: context,
          title: 'PUBLISHING STRATEGY',
          subtitle: 'Do you want to publish this strategy?',
          onConfirm: () async => _save('published'),
        );
      },
      onDiscard: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _accordion({
    required String title,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: onToggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: child,
      ),
    );
  }

  // ── Device Display Tab Bar ────────────────────────────────────────────────
  // Same UI as _deviceSelector on strategy_main.dart — compact white pill,
  // right-aligned at the call sites.
  Widget _deviceDisplayTabBar({
    required DisplayDeviceTab selected,
    required ValueChanged<DisplayDeviceTab> onChanged,
  }) {
    Widget tab(String label, DisplayDeviceTab value) {
      final isSelected = selected == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? ColorPick.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab('Large Screen', DisplayDeviceTab.largeScreen),
          tab('Tablet', DisplayDeviceTab.tablet),
          tab('Mobile', DisplayDeviceTab.mobile),
        ],
      ),
    );
  }

  Widget _bilingualRow({
    required TextEditingController enCtrl,
    required TextEditingController arCtrl,
    required String enHint,
    required String arHint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomValidatedTextFieldMaster(
            hint: enHint,
            controller: enCtrl,
            height: 42,
            maxLines: 1,
            fillColor: Colors.white,
            maxLength: 200,
            submitted: _submitted,
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.start,
            onChanged: (_) {},
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomValidatedTextFieldMaster(
            hint: arHint,
            controller: arCtrl,
            height: 42,
            fillColor: Colors.white,
            maxLines: 1,
            maxLength: 200,
            submitted: _submitted,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String t) => Text(t,
      style: StyleText.fontSize13Weight400.copyWith(
        color: AppColors.text
      )

  );

  Widget _btn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 48.h,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6.r)),
          child: Center(
            child: Text(label,
                style: StyleText
                    .fontSize14Weight600
                    .copyWith(
                    color:
                    Colors.white)),
          ),
        ),
      );

  Widget _savingOverlay() => Container(
    color: Colors.black54,
    child: Center(
      child: Container(
        width: 180.w,
        height: 100.h,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleProgress(),
            SizedBox(height: 12.h),
            Text('Saving...',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: Colors.black87)),
          ],
        ),
      ),
    ),
  );
}
