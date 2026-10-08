// ******************* FILE INFO *******************
// File Name: validation_scope.dart
// Purpose: "Show me what's missing" — app-wide, with no per-page wiring.
//
//          Publish is disabled until every required field is filled. A dead
//          button tells you nothing, so tapping a disabled Publish now flips
//          this scope on, and every required-but-empty text field, dropdown and
//          image picker underneath paints a red border. Nothing else changes:
//          no snackbar, no dialog, no scrolling — just a red outline on exactly
//          the inputs that still need an answer.
//
//          WHY IT NEEDS NO PAGE CHANGES:
//          AdminStickyBody wraps the body of every admin page, and both the
//          action buttons and the fields sit underneath it. So AdminStickyBody
//          owns the flag, EditActionButtons flips it, and the fields read it —
//          all through the tree that already exists.
//
//          Manual use, if a page ever needs its own trigger:
//            ValidationScope.reveal(context);   // turn the borders on
//            ValidationScope.clear(context);    // turn them off (after a save)
//            ValidationScope.revealed(context); // are we showing them?
//
// Created by: Amr Mesbah

import 'package:flutter/widgets.dart';

class ValidationScope extends InheritedNotifier<ValueNotifier<bool>> {
  const ValidationScope({
    super.key,
    required ValueNotifier<bool> controller,
    required super.child,
  }) : super(notifier: controller);

  /// True while the "what's missing" borders should be shown.
  ///
  /// Call this from a widget's build — it subscribes, so the field repaints the
  /// moment a blocked Publish is tapped.
  static bool revealed(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ValidationScope>()
          ?.notifier
          ?.value ??
      false;

  /// Read without subscribing — for callbacks, not build methods.
  static ValueNotifier<bool>? _controllerOf(BuildContext context) => context
      .getElementForInheritedWidgetOfExactType<ValidationScope>()
      ?.widget
      .let((w) => (w as ValidationScope).notifier);

  /// Start showing the red borders on every empty required input below.
  static void reveal(BuildContext context) =>
      _controllerOf(context)?.value = true;

  /// Stop showing them — call after a successful save so the next visit to the
  /// form starts clean.
  static void clear(BuildContext context) =>
      _controllerOf(context)?.value = false;
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
