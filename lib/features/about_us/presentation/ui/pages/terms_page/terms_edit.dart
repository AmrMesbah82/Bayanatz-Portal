// ******************* FILE INFO *******************
// File Name: terms_edit.dart
// Screen 2 of 3 — Terms of Service CMS: Edit page
// UPDATED: Fixed save/publish functionality
// UPDATED: Proper async/await handling with cubit
// UPDATED: Removed all field validation
// UPDATED: Removed success dialog — navigates back immediately on save

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/core/main_widgets/edit_action_buttons.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';

import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/custom/image_upload_circle.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../data/models/about_us_model.dart';
import '../../../controller/about_us_cubit.dart';
import '../../../controller/about_us_state.dart';
import 'terms_preview.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../../widgets/terms_edit/picked_image.dart';
part '../../widgets/terms_edit/doc_item.dart';
part '../../widgets/terms_edit/terms_edit_widgets.dart';

// The Terms screens used to carry their own green palette — the only admin
// screens that did. They now use ColorPick.primary like every other page, so
// the CMS reads as one product instead of two.
const Color _kRed = Color(0xFFD32F2F);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBg = Color(0xFFF1F2ED);

// ── Picked Image holder (SVG only) ─────────────────────────────────────────

class TermsEditPage extends StatefulWidget {
  const TermsEditPage({super.key});

  @override
  State<TermsEditPage> createState() => _TermsEditPageState();
}

class _TermsEditPageState extends State<TermsEditPage> {
  // Terms and Conditions (icon + title now belong to this section)
  final _termsTitleEnCtrl = TextEditingController();
  final _termsTitleArCtrl = TextEditingController();
  final _termsIcon = _PickedImage();
  final _termsDescEnCtrl = TextEditingController();
  final _termsDescArCtrl = TextEditingController();
  final _termsDocEn = _DocItem();
  final _termsDocAr = _DocItem();

  // Privacy Policy (now has its own icon + title too)
  final _privacyTitleEnCtrl = TextEditingController();
  final _privacyTitleArCtrl = TextEditingController();
  final _privacyIcon = _PickedImage();
  final _privacyDescEnCtrl = TextEditingController();
  final _privacyDescArCtrl = TextEditingController();
  final _privacyDocEn = _DocItem();
  final _privacyDocAr = _DocItem();

  bool _termsOpen = true;
  bool _privacyOpen = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _seeded = false;

  // Store original values to track changes
  String _originalTermsTitleEn = '';
  String _originalTermsTitleAr = '';
  String _originalTermsIconUrl = '';
  String _originalTermsDescEn = '';
  String _originalTermsDescAr = '';
  String _originalTermsDocEnUrl = '';
  String _originalTermsDocArUrl = '';
  String _originalPrivacyTitleEn = '';
  String _originalPrivacyTitleAr = '';
  String _originalPrivacyIconUrl = '';
  String _originalPrivacyDescEn = '';
  String _originalPrivacyDescAr = '';
  String _originalPrivacyDocEnUrl = '';
  String _originalPrivacyDocArUrl = '';

  @override
  void initState() {
    super.initState();
    context.read<TermsCubit>().load();

    _termsTitleEnCtrl.addListener(_checkForChanges);
    _termsTitleArCtrl.addListener(_checkForChanges);
    _termsDescEnCtrl.addListener(_checkForChanges);
    _termsDescArCtrl.addListener(_checkForChanges);
    _privacyTitleEnCtrl.addListener(_checkForChanges);
    _privacyTitleArCtrl.addListener(_checkForChanges);
    _privacyDescEnCtrl.addListener(_checkForChanges);
    _privacyDescArCtrl.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _termsTitleEnCtrl.dispose();
    _termsTitleArCtrl.dispose();
    _termsDescEnCtrl.dispose();
    _termsDescArCtrl.dispose();
    _privacyTitleEnCtrl.dispose();
    _privacyTitleArCtrl.dispose();
    _privacyDescEnCtrl.dispose();
    _privacyDescArCtrl.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    if (!_seeded) return;

    final bool hasTextChanges =
        _termsTitleEnCtrl.text != _originalTermsTitleEn ||
            _termsTitleArCtrl.text != _originalTermsTitleAr ||
            _termsDescEnCtrl.text != _originalTermsDescEn ||
            _termsDescArCtrl.text != _originalTermsDescAr ||
            _privacyTitleEnCtrl.text != _originalPrivacyTitleEn ||
            _privacyTitleArCtrl.text != _originalPrivacyTitleAr ||
            _privacyDescEnCtrl.text != _originalPrivacyDescEn ||
            _privacyDescArCtrl.text != _originalPrivacyDescAr;

    final bool hasImageChanges =
        (_termsIcon.url ?? '') != _originalTermsIconUrl ||
            (_privacyIcon.url ?? '') != _originalPrivacyIconUrl ||
            _termsIcon.bytes != null ||
            _privacyIcon.bytes != null;

    final bool hasDocChanges =
        _termsDocEn.bytes != null ||
            _termsDocAr.bytes != null ||
            _privacyDocEn.bytes != null ||
            _privacyDocAr.bytes != null ||
            (_termsDocEn.existingUrl != _originalTermsDocEnUrl &&
                _termsDocEn.bytes == null) ||
            (_termsDocAr.existingUrl != _originalTermsDocArUrl &&
                _termsDocAr.bytes == null) ||
            (_privacyDocEn.existingUrl != _originalPrivacyDocEnUrl &&
                _privacyDocEn.bytes == null) ||
            (_privacyDocAr.existingUrl != _originalPrivacyDocArUrl &&
                _privacyDocAr.bytes == null);

    final bool hasChanges = hasTextChanges || hasImageChanges || hasDocChanges;

    // Same fix as BUG-62: always rebuild so Publish follows the validity.
    if (mounted) setState(() => _hasChanges = hasChanges);
  }

  void _resetChangesTracking() {
    _originalTermsTitleEn = _termsTitleEnCtrl.text;
    _originalTermsTitleAr = _termsTitleArCtrl.text;
    _originalTermsIconUrl = _termsIcon.url ?? '';
    _originalTermsDescEn = _termsDescEnCtrl.text;
    _originalTermsDescAr = _termsDescArCtrl.text;
    _originalTermsDocEnUrl = _termsDocEn.existingUrl;
    _originalTermsDocArUrl = _termsDocAr.existingUrl;
    _originalPrivacyTitleEn = _privacyTitleEnCtrl.text;
    _originalPrivacyTitleAr = _privacyTitleArCtrl.text;
    _originalPrivacyIconUrl = _privacyIcon.url ?? '';
    _originalPrivacyDescEn = _privacyDescEnCtrl.text;
    _originalPrivacyDescAr = _privacyDescArCtrl.text;
    _originalPrivacyDocEnUrl = _privacyDocEn.existingUrl;
    _originalPrivacyDocArUrl = _privacyDocAr.existingUrl;

    _termsIcon.bytes = null;
    _privacyIcon.bytes = null;
    _termsDocEn.bytes = null;
    _termsDocAr.bytes = null;
    _privacyDocEn.bytes = null;
    _privacyDocAr.bytes = null;

    _hasChanges = false;
  }

  // ── File pickers ──────────────────────────────────────────────────────────
  Future<Uint8List?> _pickSvgOnly() async {
    final c = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()..accept = 'image/svg+xml';

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) { c.complete(null); return; }

      final file = files.first;

      if (!file.name.toLowerCase().endsWith('.svg')) {
        _showErrorDialog('Invalid File Type',
            'Please select an SVG file only. Selected: ${file.name}');
        c.complete(null);
        return;
      }
      if (file.type != 'image/svg+xml') {
        _showErrorDialog('Invalid File Type',
            'Please select a valid SVG file. Selected: ${file.name}');
        c.complete(null);
        return;
      }

      final reader = html.FileReader()..readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        final r = reader.result;
        Uint8List? bytes;
        if (r is ByteBuffer) bytes = r.asUint8List();
        else if (r is Uint8List) bytes = r;

        if (bytes != null) {
          final headerStr = String.fromCharCodes(
            bytes.sublist(0, bytes.length > 100 ? 100 : bytes.length),
          );
          if (!headerStr.contains('<svg') && !headerStr.contains('<?xml')) {
            _showErrorDialog('Invalid SVG',
                'The selected file does not appear to be a valid SVG image.');
            c.complete(null);
            return;
          }
          c.complete(bytes);
        } else {
          c.complete(null);
        }
      });
      reader.onError.listen((_) => c.complete(null));
    });
    input.click();
    return c.future;
  }

  Future<void> _pickDoc(_DocItem docItem) async {
    final c = Completer<void>();
    final input = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx';
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) { c.complete(); return; }
      final file = files.first;
      final reader = html.FileReader()..readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        final r = reader.result;
        Uint8List? bytes;
        if (r is ByteBuffer) bytes = r.asUint8List();
        else if (r is Uint8List) bytes = r;
        if (bytes != null) {
          setState(() {
            docItem.bytes = bytes;
            docItem.fileName = file.name;
            _checkForChanges();
          });
        }
        c.complete();
      });
      reader.onError.listen((_) => c.complete());
    });
    input.click();
    return c.future;
  }

  // ── Seed ──────────────────────────────────────────────────────────────────
  void _seed(TermsOfServiceModel m) {
    if (_seeded) return;
    _seeded = true;

    setState(() {
      // Terms icon + title now live on the terms section itself. Fall back to
      // the legacy navigationLabel so existing data migrates seamlessly.
      _originalTermsTitleEn = m.termsAndConditions.title.en.isNotEmpty
          ? m.termsAndConditions.title.en
          : m.navigationLabel.title.en;
      _originalTermsTitleAr = m.termsAndConditions.title.ar.isNotEmpty
          ? m.termsAndConditions.title.ar
          : m.navigationLabel.title.ar;
      _originalTermsIconUrl = m.termsAndConditions.iconUrl.isNotEmpty
          ? m.termsAndConditions.iconUrl
          : m.navigationLabel.iconUrl;

      _termsTitleEnCtrl.text = _originalTermsTitleEn;
      _termsTitleArCtrl.text = _originalTermsTitleAr;
      _termsIcon.url = _originalTermsIconUrl.isNotEmpty ? _originalTermsIconUrl : null;
      _termsIcon.bytes = null;
      _termsIcon.fileName = '';

      _originalTermsDescEn = m.termsAndConditions.description.en;
      _originalTermsDescAr = m.termsAndConditions.description.ar;
      _originalTermsDocEnUrl = m.termsAndConditions.attachEnUrl;
      _originalTermsDocArUrl = m.termsAndConditions.attachArUrl;

      _termsDescEnCtrl.text = _originalTermsDescEn;
      _termsDescArCtrl.text = _originalTermsDescAr;
      _termsDocEn.bytes = null;
      _termsDocEn.fileName = '';
      _termsDocEn.existingUrl = _originalTermsDocEnUrl;
      _termsDocAr.bytes = null;
      _termsDocAr.fileName = '';
      _termsDocAr.existingUrl = _originalTermsDocArUrl;

      _originalPrivacyTitleEn = m.privacyPolicy.title.en;
      _originalPrivacyTitleAr = m.privacyPolicy.title.ar;
      _originalPrivacyIconUrl = m.privacyPolicy.iconUrl;

      _privacyTitleEnCtrl.text = _originalPrivacyTitleEn;
      _privacyTitleArCtrl.text = _originalPrivacyTitleAr;
      _privacyIcon.url = _originalPrivacyIconUrl.isNotEmpty ? _originalPrivacyIconUrl : null;
      _privacyIcon.bytes = null;
      _privacyIcon.fileName = '';

      _originalPrivacyDescEn = m.privacyPolicy.description.en;
      _originalPrivacyDescAr = m.privacyPolicy.description.ar;
      _originalPrivacyDocEnUrl = m.privacyPolicy.attachEnUrl;
      _originalPrivacyDocArUrl = m.privacyPolicy.attachArUrl;

      _privacyDescEnCtrl.text = _originalPrivacyDescEn;
      _privacyDescArCtrl.text = _originalPrivacyDescAr;
      _privacyDocEn.bytes = null;
      _privacyDocEn.fileName = '';
      _privacyDocEn.existingUrl = _originalPrivacyDocEnUrl;
      _privacyDocAr.bytes = null;
      _privacyDocAr.fileName = '';
      _privacyDocAr.existingUrl = _originalPrivacyDocArUrl;

      _hasChanges = false;
    });
  }

  // ── Build model ───────────────────────────────────────────────────────────
  TermsOfServiceModel _buildModel(String status) => TermsOfServiceModel(
    publishStatus: status,
    // navigationLabel kept in sync with the Terms section for backward
    // compatibility with any older readers.
    navigationLabel: AboutNavigationLabel(
      iconUrl: _termsIcon.url ?? '',
      title: AboutBilingualText(
        en: _termsTitleEnCtrl.text.trim(),
        ar: _termsTitleArCtrl.text.trim(),
      ),
    ),
    termsAndConditions: TermsSection(
      iconUrl: _termsIcon.url ?? '',
      title: AboutBilingualText(
        en: _termsTitleEnCtrl.text.trim(),
        ar: _termsTitleArCtrl.text.trim(),
      ),
      svgUrl: '',
      description: AboutBilingualText(
        en: _termsDescEnCtrl.text.trim(),
        ar: _termsDescArCtrl.text.trim(),
      ),
      attachEnUrl: _termsDocEn.existingUrl,
      attachArUrl: _termsDocAr.existingUrl,
    ),
    privacyPolicy: TermsSection(
      iconUrl: _privacyIcon.url ?? '',
      title: AboutBilingualText(
        en: _privacyTitleEnCtrl.text.trim(),
        ar: _privacyTitleArCtrl.text.trim(),
      ),
      svgUrl: '',
      description: AboutBilingualText(
        en: _privacyDescEnCtrl.text.trim(),
        ar: _privacyDescArCtrl.text.trim(),
      ),
      attachEnUrl: _privacyDocEn.existingUrl,
      attachArUrl: _privacyDocAr.existingUrl,
    ),
  );

  // ── Collect uploads ───────────────────────────────────────────────────────
  Map<String, Uint8List> _collectImageUploads() {
    final u = <String, Uint8List>{};
    if (_termsIcon.bytes != null)   u['terms_cms/terms/icon']   = _termsIcon.bytes!;
    if (_privacyIcon.bytes != null) u['terms_cms/privacy/icon'] = _privacyIcon.bytes!;
    return u;
  }

  Map<String, DocUpload> _collectDocUploads() {
    final u = <String, DocUpload>{};
    if (_termsDocEn.bytes != null)
      u['terms_cms/terms/en'] = DocUpload(bytes: _termsDocEn.bytes!, fileName: _termsDocEn.fileName);
    if (_termsDocAr.bytes != null)
      u['terms_cms/terms/ar'] = DocUpload(bytes: _termsDocAr.bytes!, fileName: _termsDocAr.fileName);
    if (_privacyDocEn.bytes != null)
      u['terms_cms/privacy/en'] = DocUpload(bytes: _privacyDocEn.bytes!, fileName: _privacyDocEn.fileName);
    if (_privacyDocAr.bytes != null)
      u['terms_cms/privacy/ar'] = DocUpload(bytes: _privacyDocAr.bytes!, fileName: _privacyDocAr.fileName);
    return u;
  }

  void _showErrorDialog(String title, String message) {
    showConfirmDialog(
      context: context,
      title: title,
      subtitle: message,
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

  // ── Preview ───────────────────────────────────────────────────────────────
  void _onPreview() {
    final cubit = context.read<TermsCubit>();
    final model = _buildModel('draft');
    final imgUploads = _collectImageUploads();
    final docUps = _collectDocUploads();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: TermsPreviewPage(
            model: model,
            imageUploads: imgUploads,
            docUploads: docUps,
          ),
        ),
      ),
    );
  }

  // ── Save / Publish ─────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    setState(() => _isSaving = true);

    final imgs  = _collectImageUploads();
    final docs  = _collectDocUploads();
    final model = _buildModel('published');

    try {
      await context.read<TermsCubit>().save(
        model:        model,
        imageUploads: imgs.isEmpty ? null : imgs,
        docUploads:   docs.isEmpty ? null : docs,
      );
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
            decoration: const BoxDecoration(
                color: Color(0xFFE53935), shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
          ),
        );
      }
    }
  }

  void _showPublishConfirmDialog() {
    showPublishConfirmDialog(
      context: context,
      title: 'PUBLISH TERMS OF SERVICE',
      subtitle: 'Do you want to publish the Terms and Conditions page now?',
      confirmLabel: 'Publish',
      onConfirm: _onSave,
    );
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
    return BlocConsumer<TermsCubit, TermsState>(
      listener: (context, state) {
        if (state is TermsLoaded) {
          _seed(state.data);
        }

        if (state is TermsSaved) {
          setState(() => _isSaving = false);
          _resetChangesTracking();
          // Navigate back immediately — no success dialog
          if (mounted) Navigator.pop(context);
        }

        if (state is TermsError) {
          setState(() => _isSaving = false);
          if (mounted) {
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
                child: Icon(Icons.error_outline,
                    color: Colors.white, size: 36.r),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final loading = state is TermsLoading || state is TermsInitial;
        return Scaffold(
          backgroundColor: _kBg,
          body: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: AdminStickyBody(
  contentWidth: 1000.w,
  children: [
                        AppAdminNavbar(
                          activeLabel: 'Web Page',
                          homePage: MainMainPage(),
                          webPage: MainMainPage(),
                          jobListingPage: MainMainPage(),
                        ),
                        SizedBox(height: 10.h),
                        AdminSubNavBar(activeIndex: 3),
                        SizedBox(
                          width: 1000.w,
                          child: loading
                              ? const Center(child: CircleProgress())
                              : _buildForm(),
                        ),
                      ],
),
              ),
              if (_isSaving) _savingOverlay(),
            ],
          ),
        );
      },
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final bool canPublish = _hasChanges && !_isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editing Terms of Service Details',
          style: StyleText.fontSize45Weight600.copyWith(
              color: ColorPick.primary, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24.h),

        _accordion(
          title: 'Terms and Conditions',
          isOpen: _termsOpen,
          onToggle: () => setState(() => _termsOpen = !_termsOpen),
          child: _sectionEditor(
            iconPicked: _termsIcon,
            titleEnCtrl: _termsTitleEnCtrl,
            titleArCtrl: _termsTitleArCtrl,
            onPickIcon: () async {
              final b = await _pickSvgOnly();
              if (b != null) setState(() {
                _termsIcon.bytes = b;
                _termsIcon.url = null;
                _checkForChanges();
              });
            },
            descEnCtrl: _termsDescEnCtrl,
            descArCtrl: _termsDescArCtrl,
            docEn: _termsDocEn,
            docAr: _termsDocAr,
            onPickDocEn: () => _pickDoc(_termsDocEn),
            onPickDocAr: () => _pickDoc(_termsDocAr),
          ),
        ),
        SizedBox(height: 16.h),

        _accordion(
          title: 'Privacy Policy',
          isOpen: _privacyOpen,
          onToggle: () => setState(() => _privacyOpen = !_privacyOpen),
          child: _sectionEditor(
            iconPicked: _privacyIcon,
            titleEnCtrl: _privacyTitleEnCtrl,
            titleArCtrl: _privacyTitleArCtrl,
            onPickIcon: () async {
              final b = await _pickSvgOnly();
              if (b != null) setState(() {
                _privacyIcon.bytes = b;
                _privacyIcon.url = null;
                _checkForChanges();
              });
            },
            descEnCtrl: _privacyDescEnCtrl,
            descArCtrl: _privacyDescArCtrl,
            docEn: _privacyDocEn,
            docAr: _privacyDocAr,
            onPickDocEn: () => _pickDoc(_privacyDocEn),
            onPickDocAr: () => _pickDoc(_privacyDocAr),
          ),
        ),
        SizedBox(height: 32.h),

        // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
        EditActionButtons(
          publishEnabled: canPublish,
          onPreview: _onPreview,
          onPublish: _showPublishConfirmDialog,
          onDiscard: _onDiscard,
        ),
        SizedBox(height: 48.h),
      ],
    );
  }

}
