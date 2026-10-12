/// ******************* FILE INFO *******************
/// File Name: custom_dialogs.dart
/// Description: Reusable dialog widgets:
///   - showConfirmDialog   → Request To Cancellation / any confirm
///   - showSuccessDialog   → Success feedback
///   - showCommentDialog   → Justifications / any text-area comment
///   - showUploadDialog    → Adding Attachment (drag & drop / browse)
/// Created by: Amr Mesbah
/// Last Update: 08/3/2026

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_app_admin/core/constant/color.dart';
import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/theme/appcolors.dart';
import 'package:web_app_admin/core/theme/new_theme.dart';
import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/widget/auto_close_dialog.dart';



// ─────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────

/// Rounded dialog shell used by every dialog.
class _DialogShell extends StatelessWidget {
  final Widget child;
  final double? width;

  const _DialogShell({required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Container(
        width: width ?? 420.w,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : AppColors.background,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(-3, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.r),
        child: child,
      ),
    );
  }
}

/// Yellow primary button (matches your customButton style).
Widget _primaryBtn({
  required String label,
  required VoidCallback onTap,
  double? width,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: width,
      height: 38.h,
      decoration: BoxDecoration(
        color: ColorPick.primary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Text(
          label,
          style: StyleText.fontSize14Weight500.copyWith(color: Colors.white),
        ),
      ),
    ),
  );
}

/// Grey/neutral secondary button.
Widget _secondaryBtn({
  required String label,
  required VoidCallback onTap,
  double? width,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: width,
      height: 38.h,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Text(
          label,
          style: StyleText.fontSize14Weight500.copyWith(color: Colors.black),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  1.  CONFIRM DIALOG
// ─────────────────────────────────────────────
///
/// Usage:
/// ```dart
/// showConfirmDialog(
///   context: context,
///   title: 'Request To Cancellation',
///   subtitle: 'Are You Sure You Want to Cancel This Request?',
///   onConfirm: () { /* your action */ },
/// );
/// ```
Future<void> showConfirmDialog({
  required BuildContext context,
  String title = 'Confirm',
  String subtitle = 'Are you sure you want to proceed?',
  String confirmLabel = 'Yes',
  String cancelLabel = 'No',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  /// Pass a custom SVG asset path for the icon, e.g. 'assets/icons/cancel.svg'
  String? iconAsset,
  /// Fallback icon widget if no SVG asset is given
  Widget? iconWidget,
}) async {
  // cancelLabel: '' = a one-button MESSAGE dialog. App rule (29/9/2026):
  // messages have no button and close themselves after 3 s; [onConfirm]
  // runs once the dialog has closed.
  final bool isMessage = cancelLabel.isEmpty;
  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) {
      final dialog = _ConfirmDialog(
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        iconAsset: iconAsset,
        iconWidget: iconWidget,
        showButtons: !isMessage,
      );
      return isMessage ? AutoCloseDialog(child: dialog) : dialog;
    },
  );
  if (isMessage) onConfirm?.call();
}

/// BUG-89 / BUG-105: ONE "discard changes?" confirmation for every edit page
/// (Post / Edit Job, Contact Us, Add New Read, Our Teams …). Without changes
/// it discards straight away.
///
/// Uses the Figma confirm dialog (BAYANATZ WEB › DIALOGS, node 7126:34139:
/// illustration, upper-case title, grey text, Back + Confirm) — the same
/// dialog as Publish / Save. [onDiscard] runs after the dialog has closed,
/// so a Navigator.pop() inside it closes the page, not the dialog.
Future<void> confirmDiscard(
  BuildContext context, {
  required VoidCallback onDiscard,
  bool hasChanges = true,
}) async {
  if (!hasChanges) {
    onDiscard();
    return;
  }
  var confirmed = false;
  await showPublishConfirmDialog(
    context: context,
    title: 'DISCARD CHANGES',
    subtitle: 'Are you sure you want to discard all changes? '
        'Everything you entered on this page will be lost.',
    confirmLabel: 'Confirm',
    backLabel: 'Back',
    onConfirm: () async => confirmed = true,
  );
  if (confirmed) onDiscard();
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? iconAsset;
  final Widget? iconWidget;
  final bool showButtons;

  const _ConfirmDialog({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.iconAsset,
    this.iconWidget,
    this.showButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 411.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          // Icon
          _buildIcon(),
          SizedBox(height: 16.h),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 8.h),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: showButtons ? 24.h : 12.h),
          // Buttons row (hidden for auto-closing message dialogs)
          if (showButtons)
          Row(
            children: [
              // BUG-75: confirm dialogs (e.g. "Discard Changes") had no way
              // to back out except clicking outside. Cancel is back.
              // (Pass cancelLabel: '' for a one-button message dialog.)
              if (cancelLabel.isNotEmpty) ...[
                Expanded(
                  child: _secondaryBtn(
                    label: cancelLabel,
                    onTap: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: _primaryBtn(
                  label: confirmLabel,
                  onTap: () {
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (iconWidget != null) return iconWidget!;
    if (iconAsset != null) {
      return SvgPicture.asset(iconAsset!, width: 60.r, height: 60.r);
    }
    // Default: red X circle (matches Figma design)
    return Container(
      width: 60.r,
      height: 60.r,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.close_rounded, color: Colors.white, size: 36.r),
    );
  }
}

// ─────────────────────────────────────────────
//  2.  SUCCESS DIALOG
// ─────────────────────────────────────────────
///
/// Usage:
/// ```dart
/// showSuccessDialog(
///   context: context,
///   title: 'Request Cancelation',
///   subtitle: 'You Successfully Requested Cancelation For This Request',
/// );
/// ```
Future<void> showSuccessDialog({
  required BuildContext context,
  String title = 'Success',
  String subtitle = 'Operation completed successfully.',
  String closeLabel = 'Close',
  VoidCallback? onClose,
  /// Optional custom SVG icon path
  String? iconAsset,
  /// Draw the icon as an ERROR (red ! ) instead of a green tick. Prefer
  /// [showErrorDialog] over setting this by hand.
  bool isError = false,
}) async {
  // App rule (29/9/2026): success / error messages have no button and close
  // themselves after 3 s; [onClose] runs once the dialog has closed.
  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => AutoCloseDialog(
      child: _SuccessDialog(
        title: title,
        subtitle: subtitle,
        closeLabel: closeLabel,
        iconAsset: iconAsset,
        isError: isError,
      ),
    ),
  );
  onClose?.call();
}

/// Same shell, red icon. Use this for "Required Fields Missing" and anything
/// else that reports a problem — a green tick above an error message reads as
/// "saved successfully", which is the opposite of what happened.
Future<void> showErrorDialog({
  required BuildContext context,
  String title = 'Something went wrong',
  String subtitle = '',
  String closeLabel = 'Close',
  VoidCallback? onClose,
}) =>
    showSuccessDialog(
      context: context,
      title: title,
      subtitle: subtitle,
      closeLabel: closeLabel,
      onClose: onClose,
      isError: true,
    );

class _SuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String closeLabel;
  final VoidCallback? onClose;
  final String? iconAsset;
  final bool isError;

  const _SuccessDialog({
    required this.title,
    required this.subtitle,
    required this.closeLabel,
    this.onClose,
    this.iconAsset,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 410.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16.h),
          // Green check, or a red ! when this dialog reports a problem.
          _buildIcon(),
          SizedBox(height: 16.h),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 8.h),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (iconAsset != null) {
      return SvgPicture.asset(iconAsset!, width: 60.r, height: 60.r);
    }
    return Container(
      width: 60.r,
      height: 60.r,
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isError ? Icons.priority_high_rounded : Icons.check_rounded,
        color: Colors.white,
        size: 36.r,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  3.  COMMENT / JUSTIFICATION DIALOG
// ─────────────────────────────────────────────
///
/// Usage:
/// ```dart
/// showCommentDialog(
///   context: context,
///   title: 'Reason Of Cancellation',
///   fieldLabel: 'Justifications',
///   onSubmit: (text) { /* use text */ },
/// );
/// ```
Future<void> showCommentDialog({
  required BuildContext context,
  String title = 'Comment',
  String fieldLabel = 'Justifications',
  String hint = 'Text here',
  String submitLabel = 'Submit',
  int maxLength = 500,
  TextDirection textDirection = TextDirection.ltr,
  /// Pass SVG asset for the title icon, or leave null for default X icon
  String? titleIconAsset,
  void Function(String comment)? onSubmit,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => _CommentDialog(
      title: title,
      fieldLabel: fieldLabel,
      hint: hint,
      submitLabel: submitLabel,
      maxLength: maxLength,
      textDirection: textDirection,
      titleIconAsset: titleIconAsset,
      onSubmit: onSubmit,
    ),
  );
}

class _CommentDialog extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String hint;
  final String submitLabel;
  final int maxLength;
  final TextDirection textDirection;
  final String? titleIconAsset;
  final void Function(String)? onSubmit;

  const _CommentDialog({
    required this.title,
    required this.fieldLabel,
    required this.hint,
    required this.submitLabel,
    required this.maxLength,
    required this.textDirection,
    this.titleIconAsset,
    this.onSubmit,
  });

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    if (_controller.text.trim().isEmpty) return;
    Navigator.of(context).pop();
    widget.onSubmit?.call(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 539.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              _TitleIcon(assetPath: widget.titleIconAsset),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  widget.title,
                  style: StyleText.fontSize14Weight600
                      .copyWith(color: AppColors.text),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, size: 18.r, color: AppColors.text),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Text field ──
          CustomValidatedTextFieldMaster(
            label: widget.fieldLabel,
            hint: widget.hint,
            controller: _controller,
            height: 100,
            maxLines: 5,
            maxLength: widget.maxLength,
            showCharCount: false,
            submitted: _submitted,
            textDirection: widget.textDirection,
            onChanged: (_) => setState(() {}),
          ),

          SizedBox(height: 16.h),

          // ── Submit button ──
          Align(
            alignment: Alignment.centerRight,
            child: _primaryBtn(
              label: widget.submitLabel,
              onTap: _handleSubmit,
              width: 120.w,
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  4.  UPLOAD / ATTACHMENT DIALOG
// ─────────────────────────────────────────────
///
/// Usage:
/// ```dart
/// showUploadDialog(
///   context: context,
///   onSubmit: (file, title) { /* handle upload */ },
/// );
/// ```
Future<void> showUploadDialog({
  required BuildContext context,
  String dialogTitle = 'Adding Attachment',
  String titleFieldLabel = 'Title Name',
  String titleFieldHint = 'Text here',
  String submitLabel = 'Submit',
  String discardLabel = 'Discard',
  TextDirection textDirection = TextDirection.ltr,
  /// SVG asset for the attachment icon in the header
  String? headerIconAsset,
  /// Allowed file extensions e.g. ['pdf','png','jpg']
  List<String>? allowedExtensions,
  void Function(PlatformFile file, String titleName)? onSubmit,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => _UploadDialog(
      dialogTitle: dialogTitle,
      titleFieldLabel: titleFieldLabel,
      titleFieldHint: titleFieldHint,
      submitLabel: submitLabel,
      discardLabel: discardLabel,
      textDirection: textDirection,
      headerIconAsset: headerIconAsset,
      allowedExtensions: allowedExtensions,
      onSubmit: onSubmit,
    ),
  );
}

class _UploadDialog extends StatefulWidget {
  final String dialogTitle;
  final String titleFieldLabel;
  final String titleFieldHint;
  final String submitLabel;
  final String discardLabel;
  final TextDirection textDirection;
  final String? headerIconAsset;
  final List<String>? allowedExtensions;
  final void Function(PlatformFile, String)? onSubmit;

  const _UploadDialog({
    required this.dialogTitle,
    required this.titleFieldLabel,
    required this.titleFieldHint,
    required this.submitLabel,
    required this.discardLabel,
    required this.textDirection,
    this.headerIconAsset,
    this.allowedExtensions,
    this.onSubmit,
  });

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  PlatformFile? _pickedFile;
  final TextEditingController _titleCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: widget.allowedExtensions != null
          ? FileType.custom
          : FileType.any,
      allowedExtensions: widget.allowedExtensions,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    if (_pickedFile == null) return;
    if (_titleCtrl.text.trim().isEmpty) return;
    Navigator.of(context).pop();
    widget.onSubmit?.call(_pickedFile!, _titleCtrl.text.trim());
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;

    return _DialogShell(
      width: 910.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              _TitleIcon(
                assetPath: widget.headerIconAsset,
                fallback: Icon(Icons.attach_file,
                    size: 18.r, color: AppColors.primary),
              ),
              SizedBox(width: 8.w),
              Text(
                widget.dialogTitle,
                style:
                StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Drop zone OR file card ──
          _pickedFile == null ? _buildDropZone(lightMode) : _buildFileCard(),

          SizedBox(height: 16.h),

          // ── Title field ──
          Text(
            widget.titleFieldLabel,
            style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 6.h),
          CustomValidatedTextFieldMaster(
            hint: widget.titleFieldHint,
            controller: _titleCtrl,
            height: 36,
            submitted: _submitted,
            textDirection: widget.textDirection,
            onChanged: (_) => setState(() {}),
          ),

          SizedBox(height: 20.h),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: _primaryBtn(
                  label: widget.submitLabel,
                  onTap: _handleSubmit,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildDropZone(bool lightMode) {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        height: 150.h,
        decoration: BoxDecoration(
          color: lightMode ? const Color(0xFFF1F2ED) : AppColors.background,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 48.r, color: Colors.grey.shade500),
            SizedBox(height: 8.h),
            Text(
              'Drag & Drop files here',
              style: StyleText.fontSize14Weight400
                  .copyWith(color: Colors.grey.shade600),
            ),
            SizedBox(height: 4.h),
            Text(
              'Or',
              style: StyleText.fontSize12Weight400
                  .copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    final file = _pickedFile!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: const Color(0xFFFFDE59), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, size: 28.r, color: Colors.orange.shade400),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatBytes(file.size),
                  style: StyleText.fontSize10Weight400
                      .copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _pickedFile = null),
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 12.r, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED: Title row icon widget
// ─────────────────────────────────────────────
class _TitleIcon extends StatelessWidget {
  final String? assetPath;
  final Widget? fallback;

  const _TitleIcon({this.assetPath, this.fallback});

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return SvgPicture.asset(assetPath!, width: 20.r, height: 20.r);
    }
    return fallback ??
        Container(
          width: 20.r,
          height: 20.r,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close, size: 12.r, color: Colors.white),
        );
  }
}

// ─────────────────────────────────────────────
//  5.  PUBLISH CONFIRM DIALOG  (Figma: "Editing Main Details")
// ─────────────────────────────────────────────
///
/// CHANGED: onConfirm is now Future<void> Function()? so the dialog can
/// await the full async _save() and show a CircularProgressIndicator
/// inside the dialog while saving — no full-screen overlay needed.
///
/// Usage:
/// ```dart
/// showPublishConfirmDialog(
///   context: context,
///   onConfirm: () => _save(cubit, publishStatus: 'published'),
/// );
/// ```
Future<void> showPublishConfirmDialog({
  required BuildContext context,
  String title = 'EDITING MAIN DETAILS',
  String subtitle = 'Do you want to save the changes made to this Main?',
  String confirmLabel = 'Confirm',
  String backLabel = 'Back',
  // ── CHANGED: was VoidCallback? — now Future<void> Function()? ──
  Future<void> Function()? onConfirm,
  VoidCallback? onBack,
  /// Optional custom illustration asset path (SVG or PNG)
  String? illustrationAsset,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // prevent accidental dismiss while saving
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => _PublishConfirmDialog(
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      backLabel: backLabel,
      onConfirm: onConfirm,
      onBack: onBack,
      illustrationAsset: illustrationAsset,
    ),
  );
}

class _PublishConfirmDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String backLabel;
  // ── CHANGED: was VoidCallback? — now Future<void> Function()? ──
  final Future<void> Function()? onConfirm;
  final VoidCallback? onBack;
  final String? illustrationAsset;

  const _PublishConfirmDialog({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.backLabel,
    this.onConfirm,
    this.onBack,
    this.illustrationAsset,
  });

  @override
  State<_PublishConfirmDialog> createState() => _PublishConfirmDialogState();
}

class _PublishConfirmDialogState extends State<_PublishConfirmDialog> {
  bool _loading = false;

  /// Called when the user taps Confirm.
  /// Shows CircularProgressIndicator inside the dialog while _save() runs.
  /// Closes the dialog automatically when done.
  Future<void> _handleConfirm() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // Directly await the async _save() — no microtask wrapper
      await widget.onConfirm?.call();
    } catch (e) {
      // _save() handles its own error logging; we just ensure loading resets
      debugPrint('[PublishConfirmDialog] onConfirm error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back-swipe / back button while saving
      canPop: !_loading,
      // BUG-287: same size as the job / status confirm dialogs (CMS Main
      // dialogs were 632 px wide, 474 px everywhere else).
      child: _DialogShell(
        width: 450.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),

            // ── Illustration ──────────────────────────────────────
            _buildIllustration(),
            SizedBox(height: 24.h),

            // ── Title ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: StyleText.fontSize16Weight600.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // ── Subtitle ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: StyleText.fontSize13Weight400.copyWith(
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // ── Buttons / Loader ──────────────────────────────────
            // When _loading is true  → show CircularProgressIndicator
            //                          centered where the buttons were.
            // When _loading is false → show Back + Confirm buttons.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: SizedBox(
                height: 48.h,
                child: _loading
                    ? const Center(
                  child: CircleProgress(),
                )
                    : Row(
                  children: [
                    // ── Back button ──────────────────────────
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onBack?.call();
                        },
                        child: Container(
                          height: 48.h,
                          // BUG-287: light-grey "Back" with dark text, like
                          // every other admin dialog (was dark grey #7B7B7B).
                          decoration: BoxDecoration(
                            color:  const Color(0xFFDCDCDC),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              widget.backLabel,
                              style: StyleText.fontSize14Weight600
                                  .copyWith(color: AppColors.text),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // ── Confirm button ───────────────────────
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleConfirm,
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: ColorPick.primary,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              widget.confirmLabel,
                              style: StyleText.fontSize14Weight600
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    if (widget.illustrationAsset != null) {
      return widget.illustrationAsset!.endsWith('.svg')
          ? SvgPicture.asset(widget.illustrationAsset!,
          width: 180.w, height: 160.h, fit: BoxFit.contain)
          : Image.asset(widget.illustrationAsset!,
          width: 180.w, height: 160.h, fit: BoxFit.contain);
    }
    return SizedBox(
      width: 180.w,
      height: 160.h,
      child: CustomSvg(
          assetPath: "assets/images/edit_main_page_dialog.svg"),
    );
  }
}

// ── Back button (grey, matches Figma) ────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BackBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: const Color(0xFF9E9E9E),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            label,
            style: StyleText.fontSize14Weight600.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Confirm button (green, matches Figma) ────────────────────────────────────
class _ConfirmGreenBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ConfirmGreenBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: const Color(0xFF008037),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            label,
            style: StyleText.fontSize14Weight600.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Simple CustomPainter fallback illustration ────────────────────────────────
class _PersonIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green  = Paint()..color = const Color(0xFF008037);
    final skin   = Paint()..color = const Color(0xFFFFCC99);
    final dark   = Paint()..color = const Color(0xFF3E2723);
    final white  = Paint()..color = Colors.white;
    final screen = Paint()..color = const Color(0xFF4CAF50);
    final grey   = Paint()..color = const Color(0xFFBDBDBD);

    final cx = size.width * 0.55;
    final cy = size.height * 0.30;

    // Monitor frame
    final monRect = Rect.fromLTWH(
        size.width * 0.28, size.height * 0.05,
        size.width * 0.55, size.height * 0.50);
    canvas.drawRRect(
        RRect.fromRectAndRadius(monRect, const Radius.circular(10)),
        Paint()..color = const Color(0xFF424242));
    // Screen
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            monRect.deflate(6), const Radius.circular(6)),
        screen);
    // Monitor stand
    canvas.drawRect(
        Rect.fromLTWH(cx - 6, monRect.bottom, 12, size.height * 0.08),
        grey);
    canvas.drawRect(
        Rect.fromLTWH(cx - 20, monRect.bottom + size.height * 0.08,
            40, 6),
        grey);

    // Body (green sweater)
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.08,
                size.height * 0.52, size.width * 0.38, size.height * 0.40),
            const Radius.circular(12)),
        green);

    // Head
    canvas.drawCircle(
        Offset(size.width * 0.27, size.height * 0.36), size.width * 0.13,
        skin);

    // Hair
    final hairPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width * 0.27, size.height * 0.27),
          radius: size.width * 0.11))
      ..close();
    canvas.drawPath(hairPath, dark);

    // Paper in hand
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.38, size.height * 0.55,
                size.width * 0.16, size.height * 0.20),
            const Radius.circular(3)),
        white);
    // Lines on paper
    final linePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.5;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * 0.55 + i * size.height * 0.04;
      canvas.drawLine(
          Offset(size.width * 0.41, y),
          Offset(size.width * 0.51, y),
          linePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}