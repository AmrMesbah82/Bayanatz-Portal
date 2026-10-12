/// ******************* FILE INFO *******************
/// File Name: main_edit.dart
/// Page 2 — "Editing Main Details"
///
/// ✅ FIXES APPLIED:
///   1. SVG ByteBuffer fix — readAsArrayBuffer returns ByteBuffer, not List<int>
///   2. Validation gate — Publish blocked until ALL required fields are valid
///   3. Only showPublishConfirmDialog used — no success/error snackbars or dialogs
///   4. Navigation via BlocConsumer listener → MainMainPage (pushAndRemoveUntil)
///   5. _submitted flag reveals inline field errors on first publish attempt

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_app_admin/core/widget/success_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:web_app_admin/features/main/data/models/main_model.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/image_upload_circle.dart';
import '../../../../../core/custom_dialog.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/widget/circle_progress.dart';
import '../../../../../core/widget/custom_dropdwon.dart';
import '../../../../../core/widget/custom_dropdown_new.dart';
import '../../../../../core/widget/custom_field.dart';
import '../../../../../core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/widget/textfield.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../home/data/models/home_model.dart';
import '../../../../home/presentation/controller/home_cubit.dart';
import '../../../../home/presentation/controller/home_state.dart';
import '../../controller/main_cubit.dart';
import '../../controller/main_state.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import 'main_main.dart';
import 'main_preview.dart'; // adjust import path as needed
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/main_edit/picked_image.dart';
part '../widgets/main_edit/link_item.dart';
part '../widgets/main_edit/color_picker_field.dart';
part '../widgets/main_edit/color_wheel_overlay.dart';
part '../widgets/main_edit/edit_save.dart';
part '../widgets/main_edit/edit_sections1.dart';
part '../widgets/main_edit/edit_sections2.dart';
part '../widgets/main_edit/edit_helpers.dart';

/// BUG-275: only #RRGGBB is a valid colour ("#12zz" / "#xyz" were accepted
/// and Publish went straight to the confirm dialog).
final RegExp _kHexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');
bool _isHexColor(String v) => _kHexColor.hasMatch(v.trim());


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color divider   = Color(0xFFE8E8E8);
//   static const Color remove    = Color(0xFFE53935);
//   static const Color back      = Color(0xFFF1F2ED);
//   static const Color error     = Color(0xFFE53935);
// }

// ── Route dropdown used only for nav-section route picker ──────────────────
const List<Map<String, String>> _kRoutes = [
  {'key': '',          'value': 'None'},
  {'key': '/',         'value': 'Home (/)'},
  {'key': '/services', 'value': 'Services (/services)'},
  {'key': '/about',    'value': 'About Us (/about)'},
  {'key': '/contact',  'value': 'Contact Us (/contact)'},
  {'key': '/careers',  'value': 'Careers (/careers)'},
  {'key': '/jobs',     'value': 'Jobs (/jobs)'},
];

// ── Fixed label-destination list ─────────────────────────────────────────────
const List<Map<String, String>> _kLabelDestinations = [
  {'key': '',                                    'value': 'None'},
  // BUG-66: a "Services" (or Home) column had no valid destination.
  {'key': '/',                                   'value': 'Home'},
  {'key': '/services',                           'value': 'Services'},
  {'key': '/about',                              'value': 'About Us'},
  {'key': '/careers',                            'value': 'Careers'},
  {'key': '/about?tab=our-strategy',             'value': 'Our Strategy'},
  {'key': '/about?tab=terms-and-conditions',     'value': 'Terms and Conditions'},
  {'key': '/about?tab=privacy-policy',           'value': 'Privacy Policy'},
  {'key': '/about?tab=vision',                   'value': 'Vision'},
  {'key': '/about?tab=mission',                  'value': 'Mission'},
  {'key': '/about?tab=values',                   'value': 'Values'},
  {'key': '/careers?tab=why-join-our-team',      'value': 'Why Join Our Team'},
  {'key': '/careers?tab=interns',                'value': 'Our Interns'},
  {'key': '/careers?tab=our-team',               'value': 'Our Team'},
  {'key': '/contact',                            'value': 'Contact Form'},
];

// ── Footer "Group Title" can also point to a Careers/About sub-tab ────────────
// Bilingual titles so the read-only Arabic group-title field auto-fills.
const List<Map<String, String>> _kGroupTitleDestinations = [
  {'key': '/careers?tab=why-join-our-team', 'value': 'Why Join Our Team', 'ar': 'لماذا تنضم إلى فريقنا'},
  {'key': '/careers?tab=interns',           'value': 'Our Interns',        'ar': 'المتدربون'},
  {'key': '/careers?tab=our-team',          'value': 'Our Team',           'ar': 'فريقنا'},
  {'key': '/about?tab=our-strategy',        'value': 'Our Strategy',       'ar': 'استراتيجيتنا'},
  {'key': '/about?tab=terms-and-conditions','value': 'Terms and Conditions', 'ar': 'الشروط والأحكام'},
];

const List<Map<String, String>> _kFonts = [
  {'key': 'Cairo',     'value': 'Cairo'},
  {'key': 'Roboto',    'value': 'Roboto'},
  {'key': 'Poppins',   'value': 'Poppins'},
  {'key': 'Tajawal',   'value': 'Tajawal'},
  {'key': 'Almarai',   'value': 'Almarai'},
  {'key': 'Noto Sans', 'value': 'Noto Sans'},
];

// BUG-78: the Arabic Font list offered Latin-only fonts (Roboto, Poppins,
// Noto Sans) that have no Arabic glyphs. Only fonts with Arabic support here.
const List<Map<String, String>> _kArabicFonts = [
  {'key': 'Cairo',                'value': 'Cairo'},
  {'key': 'Tajawal',              'value': 'Tajawal'},
  {'key': 'Almarai',              'value': 'Almarai'},
  {'key': 'Noto Sans Arabic',     'value': 'Noto Sans Arabic'},
  {'key': 'IBM Plex Sans Arabic', 'value': 'IBM Plex Sans Arabic'},
];

class MainEditPage extends StatefulWidget {
  const MainEditPage({super.key});

  @override
  State<MainEditPage> createState() => _MainEditPageState();
}

class _MainEditPageState extends State<MainEditPage> {
  /// Set to true the first time the user taps Publish, to reveal inline errors.
  bool _submitted = false;

  // ── Nav Buttons ───────────────────────────────────────────────────────────
  final List<Map<String, TextEditingController>> _navBtns = List.of(
    List.generate(3, (_) => {
      'nameEn': TextEditingController(),
      'nameAr': TextEditingController(),
    }),
  );
  final List<String?> _navRoutes = List.of([null, null, null]);
  final List<bool>    _navStatus = List.of([true,  true,  true]);

  // ── Sections 1–4 ──────────────────────────────────────────────────────────
  final List<Map<String, TextEditingController>> _sections =
  List.generate(4, (_) => {
    'textBox':       TextEditingController(text: '#008037'),
    'description':   TextEditingController(),
    'descriptionAr': TextEditingController(),
  });

  final List<Map<String, _PickedImage>> _sectionImages = List.generate(
    4,
        (_) => {'image': const _PickedImage(), 'icon': const _PickedImage()},
  );

  // ── Footer columns ────────────────────────────────────────────────────────
  late final List<Map<String, dynamic>> _footerColumns;

  // ── Social links ──────────────────────────────────────────────────────────
  late final List<_LinkItem> _links;

  // ── Logo ──────────────────────────────────────────────────────────────────
  _PickedImage _logoPicked = const _PickedImage();

  // ── Branding ──────────────────────────────────────────────────────────────
  final _primaryColor      = TextEditingController(text: '#008037');
  final _secondaryColor    = TextEditingController(text: '#D9D9D9');
  final _bgColor           = TextEditingController(text: '#D9D9D9');
  final _headerFooterColor = TextEditingController(text: '#D9D9D9');
  final _mainWidgetColor   = TextEditingController(text: '#D9D9D9');
  String? _engFont = 'Cairo';
  String? _arFont  = 'Cairo';

  // ── Accordion open/close ──────────────────────────────────────────────────
  final Map<String, bool> _open = {
    'theme': true, 'footer': true, 'links': true,
    'headings': true, 'navBtn': true,
    's1': true, 's2': true, 's3': true, 's4': true,
  };

  // ── Seed-hash guard ───────────────────────────────────────────────────────
  int? _seededModelHash;

  // ── Dirty tracking ────────────────────────────────────────────────────────
  // A complete form is not the same thing as a CHANGED form. Opening this page
  // and hitting Publish used to re-upload byte-identical content, because the
  // gate only asked "is everything filled in?". It now also has to differ from
  // what was loaded.
  //
  // The signature is a cheap string of everything the form owns; it is captured
  // once in _seedFromModel and compared on every rebuild.
  String? _seedSignature;

  String _imgSig(_PickedImage img) =>
      '${img.url ?? ''}#${img.bytes?.length ?? 0}';

  String get _formSignature {
    final parts = <String>[
      _imgSig(_logoPicked),
      for (var i = 0; i < _navBtns.length; i++)
        '${_navBtns[i]['nameEn']!.text}|${_navBtns[i]['nameAr']!.text}'
            '|${_navRoutes[i] ?? ''}|${_navStatus[i]}',
      for (final col in _footerColumns) ...[
        '${col['route'] ?? ''}',
        '${(col['titleEn'] as TextEditingController?)?.text ?? ''}',
        '${(col['titleAr'] as TextEditingController?)?.text ?? ''}',
        for (final label in (col['labels'] as List<Map<String, dynamic>>))
          '${label['route'] ?? ''}'
              '|${(label['en'] as TextEditingController).text}'
              '|${(label['ar'] as TextEditingController).text}',
      ],
      for (final l in _links)
        '${_imgSig(l.icon)}|${l.text.text}|${l.visibility}',
      _primaryColor.text,
      _secondaryColor.text,
      _bgColor.text,
      _headerFooterColor.text,
      _mainWidgetColor.text,
      _engFont ?? '',
      _arFont ?? '',
    ];
    return parts.join('~');
  }

  /// True once the user has actually changed something since the page loaded.
  bool get _isDirty =>
      _seedSignature != null && _formSignature != _seedSignature;

  Color get _resolvedPrimaryColor {
    try {
      final hex = _primaryColor.text.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return ColorPick.primary;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ✅ VALIDATION GATE
  //    Returns true ONLY when ALL required fields are filled and valid.
  //    Publish button is disabled (dimmed + tap-blocked) until this is true.
  // ─────────────────────────────────────────────────────────────────────────
  bool get _isFormValid {
    // NOTE: No language validation - every field accepts Arabic AND English.

    // Logo required
    if (_logoPicked.isEmpty) return false;

    // BUG-275: every colour must be a real #RRGGBB value.
    for (final c in [_primaryColor, _secondaryColor, _bgColor,
        _headerFooterColor, _mainWidgetColor]) {
      if (!_isHexColor(c.text)) return false;
    }

    // Nav buttons
    for (int i = 0; i < _navBtns.length; i++) {
      final route = _navRoutes[i];
      if (route == null || route.isEmpty) return false;

      final en = _navBtns[i]['nameEn']!.text;
      final ar = _navBtns[i]['nameAr']!.text;
      if (en.trim().isEmpty) return false;
      if (ar.trim().isEmpty) return false;
    }

    // Footer columns
    for (final col in _footerColumns) {
      final colRoute = col['route'] as String?;
      if (colRoute == null || colRoute.isEmpty) return false;
      // BUG-212: typed column title (EN + AR) is required.
      if ((col['titleEn'] as TextEditingController).text.trim().isEmpty ||
          (col['titleAr'] as TextEditingController).text.trim().isEmpty) {
        return false;
      }

      final labels = col['labels'] as List<Map<String, dynamic>>;
      for (final label in labels) {
        // BUG-59: "None" ('') is offered in the list and means "plain text,
        // no link". Only a label with NO choice at all (null) is incomplete.
        final labelRoute = label['route'] as String?;
        if (labelRoute == null) return false;

        final en = (label['en'] as TextEditingController).text;
        final ar = (label['ar'] as TextEditingController).text;
        if (en.trim().isEmpty) return false;
        if (ar.trim().isEmpty) return false;
      }
    }

    // Social links
    for (final link in _links) {
      if (link.icon.isEmpty) return false;
      if (link.text.text.trim().isEmpty) return false;
    }

    // Fonts
    if (_engFont == null || _engFont!.isEmpty) return false;
    if (_arFont  == null || _arFont!.isEmpty)  return false;

    return true;
  }

  // Collects the first validation error message to display in the dialog.
  String? _getValidationError() {
    if (_logoPicked.isEmpty) {
      return 'Please upload a logo image';
    }

    // BUG-275
    final colours = {
      'Primary Color': _primaryColor,
      'Secondary Color': _secondaryColor,
      'Background': _bgColor,
      'Header and Footer': _headerFooterColor,
      'Main Widget Color': _mainWidgetColor,
    };
    for (final e in colours.entries) {
      if (!_isHexColor(e.value.text)) {
        return '${e.key}: enter a colour as #RRGGBB (e.g. #008037)';
      }
    }

    for (int i = 0; i < _navBtns.length; i++) {
      final route = _navRoutes[i];
      if (route == null || route.isEmpty) {
        return 'Please select a route for navigation button ${i + 1}';
      }
      if (_navBtns[i]['nameEn']!.text.trim().isEmpty) {
        return 'Please enter English title for navigation button ${i + 1}';
      }
      if (_navBtns[i]['nameAr']!.text.trim().isEmpty) {
        return 'Please enter Arabic title for navigation button ${i + 1}';
      }
    }

    for (int i = 0; i < _footerColumns.length; i++) {
      final col = _footerColumns[i];
      final colRoute = col['route'] as String?;
      if (colRoute == null || colRoute.isEmpty) {
        return 'Please select a navigation route for Footer Column ${i + 1}';
      }
      // BUG-212: the column title is typed, so it must be filled in.
      if ((col['titleEn'] as TextEditingController).text.trim().isEmpty ||
          (col['titleAr'] as TextEditingController).text.trim().isEmpty) {
        return 'Please enter the Group Title (English and Arabic) for Footer Column ${i + 1}';
      }

      final labels = col['labels'] as List<Map<String, dynamic>>;
      for (int j = 0; j < labels.length; j++) {
        final label = labels[j];
        final labelRoute = label['route'] as String?;
        if (labelRoute == null) { // BUG-59: '' (None) is allowed
          return 'Please select a destination for Label ${j + 1} in Footer Column ${i + 1}';
        }
        if ((label['en'] as TextEditingController).text.trim().isEmpty) {
          return 'Please enter English text for Label ${j + 1} in Footer Column ${i + 1}';
        }
        if ((label['ar'] as TextEditingController).text.trim().isEmpty) {
          return 'Please enter Arabic text for Label ${j + 1} in Footer Column ${i + 1}';
        }
      }
    }

    for (int i = 0; i < _links.length; i++) {
      if (_links[i].icon.isEmpty) {
        return 'Please upload an icon for Social Link ${i + 1}';
      }
      if (_links[i].text.text.trim().isEmpty) {
        return 'Please enter a URL for Social Link ${i + 1}';
      }
    }

    if (_engFont == null || _engFont!.isEmpty) {
      return 'Please select an English Font';
    }
    if (_arFont == null || _arFont!.isEmpty) {
      return 'Please select an Arabic Font';
    }

    return null;
  }

  // ── Helpers: build a nav-items dropdown list from current local state ──────
  List<Map<String, String>> _buildNavDropdownItems() {
    final items = <Map<String, String>>[
      {'key': '', 'value': 'None'},
    ];
    for (var i = 0; i < _navBtns.length; i++) {
      final en    = _navBtns[i]['nameEn']!.text.trim();
      final route = _navRoutes[i] ?? '';
      if (route.isEmpty) continue;
      var label = en.isNotEmpty ? en : route;
      // Display rule: the About page is always shown as "About Us".
      if (route == '/about' && (label == 'About' || label == '/about')) {
        label = 'About Us';
      }
      items.add({'key': route, 'value': label});
    }
    // Also allow a footer Group Title to link to a Careers/About sub-tab.
    for (final d in _kGroupTitleDestinations) {
      items.add({'key': d['key']!, 'value': d['value']!});
    }
    return items;
  }

  /// BUG-67: a footer column whose Group Title points at a menu item shows
  /// that item's names. The Arabic title field is read-only, but it kept the
  /// value saved long ago ("اتصل بنا") while the menu item said "تواصل معنا".
  /// Titles are now re-synced from the menu item on load, on every edit of a
  /// menu name, and right before saving.
  ///
  /// BUG-212: footer column titles are now FREE TEXT (EN + AR), chosen
  /// separately from the link — the Figma footer has columns such as
  /// "Terms of Service" that are not a menu item name, and renaming the
  /// "Careers" menu item renamed the footer column too. Nothing is synced
  /// any more; the method is kept so existing call sites stay valid.
  void _syncFooterTitlesFromNav() {}

  /// BUG-75: after Discard, stay on Web Page → Main (not the Home dashboard).
  void _goToMainTab() {
    // BUG-53: Preview copies unsaved edits into the cubit — throw them away.
    context.read<MainCmsCubit>().load();
    GoRouter.of(context).go('/admin/dashboard');
  }

  void _onFieldChanged() {
    _syncFooterTitlesFromNav(); // BUG-67
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _seededModelHash = null;
    _footerColumns = List.generate(3, (_) => _newFooterColumn());
    _links         = List.generate(4, (_) => _LinkItem());

    // Listen to all text controllers so _isFormValid re-evaluates on change
    for (final m in _sections) {
      for (final c in m.values) c.addListener(_onFieldChanged);
    }
    _primaryColor.addListener(_onFieldChanged);
    _secondaryColor.addListener(_onFieldChanged);
    _bgColor.addListener(_onFieldChanged);
    _headerFooterColor.addListener(_onFieldChanged);
    _mainWidgetColor.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MainCmsCubit>().load();
        context.read<HomeCmsCubit>().load(); // nav buttons live in HOME
      }
    });
  }

  // ── Image picker (SVG only) ───────────────────────────────────────────────
  // ✅ FIX: readAsArrayBuffer returns ByteBuffer, not List<int>.
  //    We must cast to ByteBuffer and wrap with Uint8List.view().
  /// BUG-68: [allowRaster] lets the logo take PNG / JPG / WebP too (it used
  /// to silently ignore a PNG — no preview, no message).
  Future<_PickedImage?> _pickImage({bool allowRaster = false}) async {
    final completer = Completer<_PickedImage?>();
    bool completed  = false;

    final input = html.FileUploadInputElement()
      ..accept = allowRaster
          ? '.svg,.png,.jpg,.jpeg,.webp,image/svg+xml,image/png,image/jpeg,image/webp'
          : '.svg,image/svg+xml';

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completed) { completed = true; completer.complete(null); }
        return;
      }
      final file = files.first;

      // ── Format guard ────────────────────────────────────────────────────
      final name = file.name.toLowerCase();
      final isSvg = name.endsWith('.svg') || file.type == 'image/svg+xml';
      final isRaster = RegExp(r'\.(png|jpe?g|webp)$').hasMatch(name) ||
          const ['image/png', 'image/jpeg', 'image/webp'].contains(file.type);
      if (!isSvg && !(allowRaster && isRaster)) {
        if (!completed) {
          completed = true;
          completer.complete(null);
          // BUG-68: say why the file was ignored.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(allowRaster
                  ? 'Please choose an SVG, PNG, JPG or WebP image.'
                  : 'Only SVG files are allowed here.'),
              backgroundColor: ColorPick.primary,
            ));
          }
        }
        return;
      }

      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (!completed) {
          completed = true;
          // ✅ ByteBuffer fix: readAsArrayBuffer returns a ByteBuffer object,
          //    not List<int>. Use Uint8List.view() to wrap it correctly.
          if (result is ByteBuffer) {

            completer.complete(
                _PickedImage(bytes: Uint8List.view(result)));
          } else if (result is List<int>) {
            // Fallback — should not normally happen with readAsArrayBuffer

            completer.complete(
                _PickedImage(bytes: Uint8List.fromList(result)));
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
      if (!completed) {
        completed = true;
        completer.complete(null);
      }
    });

    return completer.future;
  }

  // ── Footer/label helpers ──────────────────────────────────────────────────
  // BUG-212: the titles are typed now — repaint Publish while typing.
  Map<String, dynamic> _newFooterColumn() => {
    'titleEn': TextEditingController()..addListener(_onFieldChanged),
    'titleAr': TextEditingController()..addListener(_onFieldChanged),
    'route':   null as String?,
    'labels':  <Map<String, dynamic>>[_newLabelRow()],
  };

  Map<String, dynamic> _newLabelRow() => {
    'en':    TextEditingController(),
    'ar':    TextEditingController(),
    'route': null as String?,
  };

  void _disposeColumn(Map<String, dynamic> col) {
    (col['titleEn'] as TextEditingController).dispose();
    (col['titleAr'] as TextEditingController).dispose();
    for (final l in col['labels'] as List<Map<String, dynamic>>) {
      _disposeLabel(l);
    }
  }

  void _disposeLabel(Map<String, dynamic> label) {
    (label['en'] as TextEditingController).dispose();
    (label['ar'] as TextEditingController).dispose();
  }

  @override
  void dispose() {
    for (final m in _navBtns) {
      for (final c in m.values) {
        c.removeListener(_onFieldChanged);
        c.dispose();
      }
    }
    for (final m in _sections) {
      for (final c in m.values) {
        c.removeListener(_onFieldChanged);
        c.dispose();
      }
    }
    for (final col in _footerColumns) _disposeColumn(col);
    for (final link in _links) link.dispose();
    _primaryColor..removeListener(_onFieldChanged)..dispose();
    _secondaryColor..removeListener(_onFieldChanged)..dispose();
    _bgColor..removeListener(_onFieldChanged)..dispose();
    _headerFooterColor..removeListener(_onFieldChanged)..dispose();
    _mainWidgetColor..removeListener(_onFieldChanged)..dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainCmsCubit, MainCmsState>(
      listener: (context, state) {

        // ── Published / Saved successfully → navigate to MainMainPage ──────
        // ✅ Uses pushAndRemoveUntil to clear the entire back stack,
        //    exactly like master_edit_page.dart does.
        if (state is MainCmsSaved) {
          // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
            if (mounted) {
              // BUG-276: back to the VIEW URL — a pushed MaterialPageRoute
              // left the address on /admin/dashboard/edit after Publish.
              // BUG-293: one success toast for every save.
              showSuccessToast(context, 'Main page published');
              GoRouter.of(context).go('/admin/dashboard');
            }
          });
        }

        // ── Error state ───────────────────────────────────────────────────
        if (state is MainCmsError) {
          // Errors are visible to the user through the cubit state;
          // add a snackbar/dialog here if you want, but no success dialogs.
        }
      },
      builder: (context, state) {

        final homeModel = context.watch<HomeCmsCubit>().current;
        if (state is MainCmsLoaded) {
          _seedFromModel(state.data, homeModel);
        } else if (state is MainCmsSaved) {
          _seedFromModel(state.data, homeModel);
        }
        final cubit = context.read<MainCmsCubit>();

        if (state is MainCmsInitial || state is MainCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(
                child: CircleProgress()),
          );
        }

        return Scaffold(
          backgroundColor: ColorPick.background,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  contentWidth: 1000.w,
  children: [

                          AppAdminNavbar(
                            activeLabel:    'Web Page', // BUG-82: was 'Home' while editing Main
                            homePage:       CareersMainPageDashboard(),
                            webPage:        MainMainPage(),
                            jobListingPage: JobListingMainPage(),
                          ),

                          SizedBox(width: 20.w),
                          AdminSubNavBar(activeIndex: 0),
                          SizedBox(
                            width: 1050.w,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                  bottom: 20.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Editing Main Details',
                                    style: StyleText.fontSize45Weight600.copyWith(
                                      color: ColorPick.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // ── Theme & Logo ─────────────────────────
                                  _accordion(
                                      key: 'theme',
                                      title: 'Theme and Logo',
                                      children: [_logoAndBrandingSection()]),
                                  _gap(),

                                  // ── Navigation Items ─────────────────────
                                  _navSection(),
                                  _gap(),

                                  // ── Footer ───────────────────────────────
                                  _footerSection(cubit),
                                  _gap(),

                                  // ── Social Links ─────────────────────────
                                  _linksSection(),
                                  _gap(),
                                  // ── Actions ──────────────────────────────
                                  _bottomActions(cubit),
                                  _gap(),
                                  SizedBox(height: 40.h),
                                ],
                              ),
                            ),
                          ),
                        ],
),
          ),
        );
      },
    );
  }

}
