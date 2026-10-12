// ******************* FILE INFO *******************
// File Name: form_dirty_scope.dart
// Purpose: "Nothing to publish" — Publish stays disabled until the user has
//          actually changed something, app-wide, with no per-page wiring.
//
//          A complete form is not the same thing as a CHANGED form. Opening an
//          edit page and hitting Publish used to re-upload byte-identical
//          content, because the gate only asked "is everything filled in?".
//
//          HOW IT KNOWS A REAL EDIT FROM A LOAD:
//          Seeding a page sets `controller.text` directly, which does NOT fire
//          onChanged. Only a human typing does. So marking dirty from the
//          widgets' onChanged path distinguishes the two for free — no
//          before/after snapshot to maintain.
//
//          WHY IT NEEDS NO PAGE CHANGES:
//          AdminStickyBody wraps every admin page body and owns the flag.
//          CustomTextField, CustomDropdown and the image pickers mark it;
//          customPublishButton reads it. Same seam as ValidationScope.
//
//          Anything this cannot see — a FlutterSwitch, a colour picker, a
//          bespoke control — should call markDirty itself:
//
//            FormDirtyScope.markDirty(context);
//
//          A page that must allow publishing an untouched form opts out:
//
//            EditActionButtons(requireChanges: false, ...)
//
// Created by: Amr Mesbah

import 'package:flutter/widgets.dart';

class FormDirtyScope extends InheritedNotifier<ValueNotifier<bool>> {
  const FormDirtyScope({
    super.key,
    required ValueNotifier<bool> controller,
    required super.child,
  }) : super(notifier: controller);

  /// Has anything on this page changed since it loaded?
  ///
  /// Defaults to TRUE when there is no scope above — a screen outside the admin
  /// shell (a dialog, a standalone route) keeps its old behaviour rather than
  /// being locked out.
  static bool isDirty(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormDirtyScope>()
          ?.notifier
          ?.value ??
      true;

  static ValueNotifier<bool>? _controllerOf(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<FormDirtyScope>();
    if (element == null) return null;
    return (element.widget as FormDirtyScope).notifier;
  }

  /// Record that the user changed something. Safe to call repeatedly and from
  /// inside a build-adjacent callback — it no-ops once already dirty.
  static void markDirty(BuildContext context) {
    final c = _controllerOf(context);
    if (c != null && !c.value) c.value = true;
  }

  /// Back to "untouched" — call after a successful save so Publish goes quiet
  /// again until the next real edit.
  static void reset(BuildContext context) {
    final c = _controllerOf(context);
    if (c != null && c.value) c.value = false;
  }
}

/// BUG-267: marks a page as an EDITOR whose unsaved changes must not be
/// thrown away silently. AdminStickyBody(guardUnsavedChanges: true) puts it
/// above the page; the top menu / Web Page tabs then ask "Discard changes?"
/// before leaving, and the browser warns on refresh / close.
class UnsavedChangesGuard extends InheritedWidget {
  const UnsavedChangesGuard({super.key, required super.child});

  static bool _enabled(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<UnsavedChangesGuard>() !=
      null;

  /// True on a guarded editor that has a real (typed / picked) change.
  static bool hasUnsavedEdits(BuildContext context) {
    if (!_enabled(context)) return false;
    final element =
        context.getElementForInheritedWidgetOfExactType<FormDirtyScope>();
    if (element == null) return false;
    return (element.widget as FormDirtyScope).notifier?.value ?? false;
  }

  @override
  bool updateShouldNotify(UnsavedChangesGuard oldWidget) => false;
}
