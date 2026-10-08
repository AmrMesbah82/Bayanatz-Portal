// ******************* FILE INFO *******************
// File Name: blog_edit.dart
// Created by: Amr Mesbah
// UPDATED:
//   • Publish button disabled until ALL fields valid + SVG image present
//   • SVG ONLY - Only SVG images are allowed
//   • Real-time validation drives button enable/disable state
//   • After publish → navigates to ServicesMainPageMaster (pushAndRemoveUntil)
//   • After successful save (any status) → navigates to ServicesMainPageMaster
//   • showPublishConfirmDialog with async onConfirm (loader inside dialog)
// Last Update: 21/04/2026

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';

import 'package:web_app_admin/core/custom_dialog.dart';
import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/core/widget/custom_field.dart';

import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom/image_upload_circle.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../../core/main_widgets/form_dirty_scope.dart';
import '../../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../../main/presentation/ui/pages/main_main.dart';
import '../../../../data/models/blog_model.dart';
import '../../../controller/blog_cubit.dart';
import '../services_main/services_main.dart';
import 'blog_preview.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import '../../../../../../core/custom/14-custom_delete_icon.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../../widgets/blog_edit/xhr_circle_image.dart';
part '../../widgets/blog_edit/blog_edit_sections.dart';

class BlogCreateEditPage extends StatefulWidget {
  final BlogPostModel? existing;
  final bool isFromDraft;

  
  const BlogCreateEditPage({super.key, this.existing, this.isFromDraft = false});

  @override
  State<BlogCreateEditPage> createState() => _BlogCreateEditPageState();
}

class _BlogCreateEditPageState extends State<BlogCreateEditPage> {
  final Map<String, bool> _open = {
    'postInfo':    true,
    'button':      true,
    'description': true,
  };

  bool _submitted      = false;
  bool _isEditingDraft = false;
  bool _isActive       = true; // switch: Active ↔ Inactive

  // Image
  Uint8List? _imageBytes;
  String     _existingImageUrl = '';
  bool       _isPickedSvg      = false;

  // Controllers
  late final TextEditingController _questionEnCtrl;
  late final TextEditingController _questionArCtrl;
  late final TextEditingController _shortDescEnCtrl;
  late final TextEditingController _shortDescArCtrl;
  late final TextEditingController _btnLabelEnCtrl;
  late final TextEditingController _btnLabelArCtrl;
  late final TextEditingController _descTitleEnCtrl;
  late final TextEditingController _descTitleArCtrl;

  final List<Map<String, dynamic>> _blocks         = [];
  final ScrollController           _scrollController = ScrollController();

  bool get _isEdit => widget.existing != null;

  /// BUG-60 / BUG-61: controls the shared dirty-check can't see (switches).
  void _markDirty() => FormDirtyScope.markDirty(context);

  // NOTE: No language validation - every field accepts Arabic AND English.

  bool get _isPublishEnabled {
    if (_imageBytes == null && _existingImageUrl.isEmpty) return false;

    // Question
    if (_questionEnCtrl.text.trim().isEmpty) return false;
    if (_questionArCtrl.text.trim().isEmpty) return false;

    // Short description
    if (_shortDescEnCtrl.text.trim().isEmpty) return false;
    if (_shortDescArCtrl.text.trim().isEmpty) return false;

    // Button label
    if (_btnLabelEnCtrl.text.trim().isEmpty) return false;
    if (_btnLabelArCtrl.text.trim().isEmpty) return false;

    // Description title
    if (_descTitleEnCtrl.text.trim().isEmpty) return false;
    if (_descTitleArCtrl.text.trim().isEmpty) return false;

    // Blocks
    for (final b in _blocks) {
      final en = (b['enCtrl'] as TextEditingController).text.trim();
      final ar = (b['arCtrl'] as TextEditingController).text.trim();
      if (en.isEmpty || ar.isEmpty) return false;
    }
    return true;
  }

  // Draft only needs question fields
  bool get _isDraftEnabled =>
      _questionEnCtrl.text.trim().isNotEmpty &&
          _questionArCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _isEditingDraft = widget.isFromDraft;

    final e = widget.existing;
    _isActive = e?.status != 'inactive';

    _questionEnCtrl  = TextEditingController(text: e?.question.en ?? '');
    _questionArCtrl  = TextEditingController(text: e?.question.ar ?? '');
    _shortDescEnCtrl = TextEditingController(text: e?.shortDescription.en ?? '');
    _shortDescArCtrl = TextEditingController(text: e?.shortDescription.ar ?? '');
    _btnLabelEnCtrl  = TextEditingController(text: e?.buttonLabel.en ?? '');
    _btnLabelArCtrl  = TextEditingController(text: e?.buttonLabel.ar ?? '');
    _descTitleEnCtrl = TextEditingController(text: e?.descriptionTitle.en ?? '');
    _descTitleArCtrl = TextEditingController(text: e?.descriptionTitle.ar ?? '');
    _existingImageUrl = e?.imageUrl ?? '';

    if (e != null) {
      for (final b in e.blocks) {
        _blocks.add({
          'id':     b.id,
          'type':   b.type,
          'enCtrl': TextEditingController(text: b.content.en),
          'arCtrl': TextEditingController(text: b.content.ar),
        });
      }
    }

    // Listen to ALL controllers so button reactively enables/disables
    for (final ctrl in _allControllers) {
      ctrl.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _allControllers => [
    _questionEnCtrl,
    _questionArCtrl,
    _shortDescEnCtrl,
    _shortDescArCtrl,
    _btnLabelEnCtrl,
    _btnLabelArCtrl,
    _descTitleEnCtrl,
    _descTitleArCtrl,
  ];

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _scrollController.dispose();
    for (final ctrl in _allControllers) {
      ctrl.removeListener(_onFieldChanged);
      ctrl.dispose();
    }
    for (final b in _blocks) {
      (b['enCtrl'] as TextEditingController).dispose();
      (b['arCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // ── Build model ────────────────────────────────────────────────────────────
  BlogPostModel _buildModel({required String status}) {
    final blocks = _blocks.map((b) => BlogDescriptionBlock(
      id:      b['id'] as String,
      type:    b['type'] as BlogBlockType,
      content: BlogBilingualText(
        en: (b['enCtrl'] as TextEditingController).text.trim(),
        ar: (b['arCtrl'] as TextEditingController).text.trim(),
      ),
    )).toList();

    return BlogPostModel(
      id:               widget.existing?.id ?? '',
      status:           status,
      imageUrl:         _existingImageUrl,
      question:         BlogBilingualText(en: _questionEnCtrl.text.trim(),  ar: _questionArCtrl.text.trim()),
      shortDescription: BlogBilingualText(en: _shortDescEnCtrl.text.trim(), ar: _shortDescArCtrl.text.trim()),
      buttonLabel:      BlogBilingualText(en: _btnLabelEnCtrl.text.trim(),  ar: _btnLabelArCtrl.text.trim()),
      descriptionTitle: BlogBilingualText(en: _descTitleEnCtrl.text.trim(), ar: _descTitleArCtrl.text.trim()),
      blocks:           blocks,
      createdAt:        widget.existing?.createdAt ?? DateTime.now(),
    );
  }

  // ── SVG-only image picker ──────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.svg,image/svg+xml';
    uploadInput.click();

    await uploadInput.onChange.first;
    if (uploadInput.files == null || uploadInput.files!.isEmpty) return;

    final file = uploadInput.files!.first;

    // 1. Check file extension
    final fileName = file.name.toLowerCase();
    if (!fileName.endsWith('.svg')) {
      if (mounted) {
        _showErrorDialog(
          title: 'Invalid File Type',
          subtitle: 'Only SVG files are allowed. Please select an SVG file.',
        );
      }
      return;
    }

    // 2. Check MIME type
    if (file.type.isNotEmpty && file.type != 'image/svg+xml') {
      if (mounted) {
        _showErrorDialog(
          title: 'Invalid File Type',
          subtitle: 'Only SVG files are allowed. Please select an SVG file.',
        );
      }
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    final result = reader.result;
    if (result == null) return;

    final bytes = Uint8List.fromList((result as List<int>));
    final fileContent = String.fromCharCodes(bytes.take(100)).toLowerCase().trimLeft();

    // 3. Validate SVG content (must start with <svg or <?xml)
    if (!fileContent.startsWith('<svg') && !fileContent.startsWith('<?xml')) {
      if (mounted) {
        _showErrorDialog(
          title: 'Invalid SVG File',
          subtitle: 'The selected file is not a valid SVG image. Please select a valid SVG file.',
        );
      }
      return;
    }

    // 4. Success - update the state
    setState(() {
      _imageBytes = bytes;
      _isPickedSvg = true;
      _existingImageUrl = '';
    });
  }

  // Helper method for error dialogs
  void _showErrorDialog({required String title, required String subtitle}) {
    showConfirmDialog(
      context: context,
      title: title,
      subtitle: subtitle,
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

  // ── Block mutations ────────────────────────────────────────────────────────
  void _addBlock(BlogBlockType type) {
    final enCtrl = TextEditingController();
    final arCtrl = TextEditingController();
    // Hook into reactive rebuild so publish button updates when blocks change
    enCtrl.addListener(_onFieldChanged);
    arCtrl.addListener(_onFieldChanged);
    setState(() {
      _blocks.add({
        'id':     'blk_${DateTime.now().microsecondsSinceEpoch}',
        'type':   type,
        'enCtrl': enCtrl,
        'arCtrl': arCtrl,
      });
    });
  }

  void _removeBlock(int index) {
    final b = _blocks.removeAt(index);
    (b['enCtrl'] as TextEditingController)
      ..removeListener(_onFieldChanged)
      ..dispose();
    (b['arCtrl'] as TextEditingController)
      ..removeListener(_onFieldChanged)
      ..dispose();
    setState(() {});
  }

  // ── Core save logic (called by dialog's onConfirm) ─────────────────────────
  Future<void> _doSave({required String status}) async {
    try {
      final model = _buildModel(status: status);
      final cubit = context.read<BlogCubit>();

      if (_isEdit) {
        await cubit.updatePost(post: model, imageBytes: _imageBytes);
      } else {
        await cubit.createPost(post: model, imageBytes: _imageBytes);
      }

      await cubit.load();

      // Navigate after dialog closes (postFrameCallback avoids navigator
      // assertion). Navigate to ServicesMainPageMaster on ANY successful save.
      if (mounted) {
        // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
          if (!mounted) return;

          // Navigate to ServicesMainPageMaster, clearing the entire stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const ServicesMainPageMaster(),
            ),
                (route) => false,
          );
        });
      }
    } catch (e) {
      rethrow; // Let dialog catch it and reset loader
    }
  }

  // ── Publish button handler ─────────────────────────────────────────────────
  Future<void> _publish() async {
    setState(() => _submitted = true);

    // Guard (button should already be disabled, but double-check)
    if (!_isPublishEnabled) return;

    await showPublishConfirmDialog(
      context: context,
      title: 'PUBLISH POST',
      subtitle: _isActive
          ? 'Do you want to publish this post? It will go live immediately.'
          : 'This post is set to Inactive. It will be saved but not shown publicly.',
      confirmLabel: 'Publish',
      backLabel: 'Cancel',
      onConfirm: () => _doSave(status: _isActive ? 'published' : 'inactive'),
    );
  }

  // ── Remove handler ─────────────────────────────────────────────────────────
  Future<void> _confirmRemove() async {
    if (!_isEdit) return; // nothing to remove for a new post
    await showPublishConfirmDialog(
      context: context,
      title: 'REMOVE POST',
      subtitle: 'Are you sure you want to remove this post?',
      confirmLabel: 'Remove',
      backLabel: 'Cancel',
      onConfirm: () async {
        final cubit = context.read<BlogCubit>();
        await cubit.deletePost(widget.existing!.id);
        await cubit.load();
        if (mounted) {
          Future.delayed(Duration.zero, () {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ServicesMainPageMaster()),
                  (route) => false,
            );
          });
        }
      },
    );
  }

  // ── Save for later handler ─────────────────────────────────────────────────
  Future<void> _saveForLater() async {
    setState(() => _submitted = true);
    if (!_isDraftEnabled) {
      showErrorDialog(
        context: context,
        title: 'Required Fields Missing',
        subtitle: 'Please fill in the question fields before saving as draft.',
      );
      return;
    }
    await showPublishConfirmDialog(
      context: context,
      title: 'SAVE AS DRAFT',
      subtitle: _isEdit && widget.existing?.status == 'published'
          ? 'Your changes will be saved as a draft. The published version will remain live.'
          : 'Are you sure you want to save this post as a draft?',
      confirmLabel: 'Save Draft',
      backLabel: 'Cancel',
      onConfirm: () => _doSave(status: 'draft'),
    );
  }

  // ── Discard ────────────────────────────────────────────────────────────────
  void _discard() {
    if (_isEditingDraft && _isEdit) {
      showPublishConfirmDialog(
        context: context,
        title: 'DISCARD DRAFT',
        subtitle: 'Are you sure you want to discard this draft? The published version will remain unchanged.',
        confirmLabel: 'Discard',
        backLabel: 'Cancel',
        onConfirm: () async {
          final cubit = context.read<BlogCubit>();
          await cubit.discardDraft(widget.existing!.id);
          await cubit.load();
          if (mounted) {
            // Navigate to ServicesMainPageMaster after discarding draft as well
            // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const ServicesMainPageMaster(),
                ),
                    (route) => false,
              );
            });
          }
        },
      );
    } else {
      // BUG-105: Add New Read / edit dropped the typed text without asking.
      confirmDiscard(context, onDiscard: () => Navigator.pop(context));
    }
  }

  // ── Preview ────────────────────────────────────────────────────────────────
  void _preview() {
    setState(() => _submitted = true);
    if (_questionEnCtrl.text.trim().isEmpty || _questionArCtrl.text.trim().isEmpty) {
      showErrorDialog(
        context: context,
        title: 'Required Fields Missing',
        subtitle: 'Please fill in the question fields before previewing.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BlogCubit>(),
          child: BlogPreviewPage(
            draft:       _buildModel(status: 'draft'),
            imageBytes:  _imageBytes,
            isPickedSvg: _isPickedSvg,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPick.background,
      body: AdminStickyBody(
  crossAxisAlignment: CrossAxisAlignment.start,
  contentWidth: 1000.w,
  children: [
                AppAdminNavbar(
                  activeLabel:     'Web Page',
                  homePage:       CareersMainPageDashboard(),
                  webPage:        MainMainPage(),
                  jobListingPage: JobListingMainPage(),
                ),
                AdminSubNavBar(activeIndex: 2),
                _removeAndStatusRow(),
                SizedBox(height: 10.h),

                // ── Title row with draft badge ─────────────────────────
                Row(
                  children: [
                    Text(
                      _isEdit ? 'Edit Important Reads' : 'Create New Important Reads',
                      style: StyleText.fontSize45Weight600.copyWith(
                          color: ColorPick.primary, fontWeight: FontWeight.w700),
                    ),
                    if (_isEditingDraft) ...[
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: ColorPick.discard.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text('EDITING DRAFT',
                            style: StyleText.fontSize12Weight600
                                .copyWith(color: ColorPick.discard)),
                      ),
                    ],
                  ],
                ),
                if (_isEditingDraft)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'You are editing a saved draft. The published version is still live.',
                      style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                    ),
                  ),
                SizedBox(height: 24.h),

                _accordion(key: 'postInfo',    title: 'Post Information',
                    children: [SizedBox(height: 16.h), _postInfoContent()]),
                SizedBox(height: 16.h),
                _accordion(key: 'button',      title: 'Button',
                    children: [SizedBox(height: 16.h), _buttonContent()]),
                SizedBox(height: 16.h),
                _accordion(key: 'description', title: 'Description',
                    children: [SizedBox(height: 16.h), _descriptionContent()]),
                SizedBox(height: 20.h),

                _actionButtons(),
                SizedBox(height: 40.h),
              ],
),
    );
  }

}

// ══════════════════════════════════════════════════════════════════════════════
// XHR circle SVG image loader
// ══════════════════════════════════════════════════════════════════════════════
