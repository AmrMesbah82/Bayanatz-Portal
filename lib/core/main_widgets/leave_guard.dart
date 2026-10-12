// ******************* FILE INFO *******************
// File Name: leave_guard.dart
// Purpose: BUG-267 — leaving an editor with unsaved changes asks first
//          (same "DISCARD CHANGES" dialog the CMS uses for its Discard
//          button). Used by the top menu and the Web Page tabs.
// Created by: Amr Mesbah

import 'package:flutter/widgets.dart';

import '../custom_dialog.dart';
import 'form_dirty_scope.dart';

/// Runs [go] at once, or after the user confirms discarding the edits when
/// the current page is a guarded editor with unsaved changes.
Future<void> guardedLeave(BuildContext context, VoidCallback go) async {
  if (!UnsavedChangesGuard.hasUnsavedEdits(context)) {
    go();
    return;
  }
  await confirmDiscard(context, onDiscard: go);
}
