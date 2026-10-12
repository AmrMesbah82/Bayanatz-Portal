// ******************* FILE INFO *******************
// File Name: edit_action_buttons.dart
// Purpose: SINGLE source of truth for the action buttons used on ALL
//          admin edit pages:
//
//            Row 1:  [ Preview ]        [ Publish ]
//            Row 2:  [ Discard ]        [ Save For Later ]
//
//          Buttons come from core/custom/15-custom_action_buttons.dart
//          (built on customButton — NOT ElevatedButton).
//          Change the style ONCE there — every edit page follows.
//
// Usage:
//   EditActionButtons(
//     onPreview:       _preview,
//     onPublish:       _publish,
//     onDiscard:       _discard,
//     onSaveForLater:  _saveForLater,     // omit → button hidden
//     publishEnabled:  _isPublishEnabled, // false → greyed + tooltip
//   )

import 'package:flutter/material.dart';
import 'admin_layout.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom/15-custom_action_buttons.dart';
import 'validation_scope.dart';

class EditActionButtons extends StatelessWidget {
  final VoidCallback? onPreview;
  final VoidCallback? onPublish;
  final VoidCallback? onDiscard;
  final VoidCallback? onSaveForLater;

  /// false → Publish is greyed out and [publishDisabledTooltip] shows on hover.
  final bool   publishEnabled;
  final String publishLabel;
  final String discardLabel;
  final String previewLabel;
  final String saveForLaterLabel;

  /// Override Publish color (e.g. ColorPick.scheduled for "Schedule").
  final Color?  publishColor;
  final String  publishDisabledTooltip;

  /// Greys out Publish + Save For Later while a save is in flight.
  final bool isSaving;

  /// Horizontal gap between the two buttons in a row.
  final double? gapWidth;

  /// Publish also needs something to publish: it stays disabled until the user
  /// changes something. Set false for a screen that may legitimately
  /// re-publish an untouched form.
  final bool requireChanges;

  /// Extra hook for a page that wants to react when a blocked Publish is
  /// tapped (e.g. also set its own _submitted flag). The red borders are
  /// handled automatically and do NOT need this.
  final VoidCallback? onPublishBlocked;

  const EditActionButtons({
    super.key,
    this.onPreview,
    this.onPublish,
    this.onDiscard,
    this.onSaveForLater,
    this.publishEnabled         = true,
    this.publishLabel           = 'Publish',
    this.discardLabel           = 'Discard',
    this.previewLabel           = 'Preview',
    this.saveForLaterLabel      = 'Save For Later',
    this.publishColor,
    this.publishDisabledTooltip = 'Fill in all required fields to publish',
    this.isSaving               = false,
    this.gapWidth,
    this.onPublishBlocked,
    this.requireChanges = true,
  });

  @override
  Widget build(BuildContext context) {
    // BUG-265: a 400 px gap is wider than a phone screen.
    final double gap =
        AdminLayout.isPhone(context) ? 12 : (gapWidth ?? 400.w);
    final bool canPublish = publishEnabled && !isSaving && onPublish != null;

    return Column(
      children: [
        // ── Row 1: Preview | Publish ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: customPreviewButton(
                title: previewLabel,
                onTap: onPreview,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Tooltip(
                message: canPublish ? '' : publishDisabledTooltip,
                child: customPublishButton(
                  title:          publishLabel,
                  color:          publishColor,
                  enabled:        canPublish,
                  requireChanges: requireChanges,
                  onTap:   onPublish,
                  // Publish is disabled until the form is complete. Tapping it
                  // anyway paints a red border on every required field that is
                  // still empty, so the user can see WHAT is missing instead of
                  // hunting a dead button.
                  onBlockedTap: () {
                    ValidationScope.reveal(context);
                    onPublishBlocked?.call();
                  },
                ),
              ),
            ),
          ],
        ),

        if (onDiscard != null || onSaveForLater != null) ...[
          SizedBox(height: 10.h),

          // ── Row 2: Discard | Save For Later ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: customDiscardButton(
                  title: discardLabel,
                  onTap: onDiscard,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: onSaveForLater == null
                    ? const SizedBox()
                    : customSaveForLaterButton(
                        title:   saveForLaterLabel,
                        enabled: !isSaving,
                        onTap:   onSaveForLater,
                      ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
