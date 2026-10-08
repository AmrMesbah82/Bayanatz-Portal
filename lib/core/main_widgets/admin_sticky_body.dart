// ******************* FILE INFO *******************
// File Name: admin_sticky_body.dart
// Purpose: Keeps the two top bars pinned on EVERY admin page while the rest of
//          the page scrolls underneath them.
//
//          Every page used to be built as:
//
//            Scaffold(
//              body: SingleChildScrollView(
//                child: SizedBox(width: double.infinity,
//                  child: Column(children: [
//                    AppAdminNavbar(...),
//                    SizedBox(height: 20.h),
//                    AdminSubNavBar(activeIndex: n),
//                    SizedBox(width: 1000.w, child: <page content>),
//                  ]))))
//
//          — both bars sat INSIDE the scroll view, so they scrolled away as
//          soon as you moved down a long form and you lost the navigation.
//
//          Swap that whole SingleChildScrollView for this widget, keeping the
//          same children list:
//
//            Scaffold(
//              body: AdminStickyBody(children: [
//                AppAdminNavbar(...),
//                SizedBox(height: 20.h),
//                AdminSubNavBar(activeIndex: n),
//                SizedBox(width: 1000.w, child: <page content>),
//              ]))
//
//          WHICH CHILDREN GET PINNED IS DECIDED AT RUNTIME, so no page has to
//          declare it: leading AppAdminNavbar / AdminSubNavBar widgets are
//          pinned, along with any bare spacer SizedBox between them (one with
//          no child). The first real content widget and everything after it
//          scrolls. A SizedBox that wraps content — SizedBox(width: 1000.w,
//          child: ...) — has a child, so it is correctly treated as content.
//
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'admin_layout.dart';
import 'admin_sub_navbar.dart';
import 'app_admin_navbar.dart';
import 'form_dirty_scope.dart';
import 'validation_scope.dart';

class AdminStickyBody extends StatefulWidget {
  const AdminStickyBody({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.contentWidth,
    this.pinnedCount,
    this.scrollController,
    this.padding,
    this.reflowOnPhone = false,
  });

  /// BUG-06 / BUG-16: the page has its own phone layout (see AdminLayout),
  /// so on a phone it is laid out at screen width instead of the scrolling
  /// desktop canvas.
  final bool reflowOnPhone;

  /// Set when the page used to wrap this Column in a fixed-width box, e.g.
  /// `Center(child: SizedBox(width: 1000.w, child: Column(...)))`. Replacing
  /// the scroll view removes that wrapper, so the width is re-applied here —
  /// to the pinned bars and the scrolling content alike — and the page keeps
  /// the layout it had.
  final double? contentWidth;

  /// Exactly the children the page's Column used to have — navbars first,
  /// content after.
  final List<Widget> children;

  /// Alignment for the scrolling part. Pages that used
  /// `crossAxisAlignment: CrossAxisAlignment.start` should pass it through.
  final CrossAxisAlignment crossAxisAlignment;

  /// Override the automatic split. Leave null unless a page needs something
  /// unusual pinned.
  final int? pinnedCount;

  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  @override
  State<AdminStickyBody> createState() => _AdminStickyBodyState();
}

class _AdminStickyBodyState extends State<AdminStickyBody> {
  /// Owns the "show me what's missing" flag for this page. EditActionButtons
  /// flips it when a disabled Publish is tapped; every required field below
  /// reads it. See validation_scope.dart.
  final ValueNotifier<bool> _showMissing = ValueNotifier<bool>(false);

  /// Owns the "has anything changed?" flag for this page. The field widgets
  /// set it on a real edit; customPublishButton reads it. See
  /// form_dirty_scope.dart.
  final ValueNotifier<bool> _dirty = ValueNotifier<bool>(false);

  /// BUG-06 / BUG-07 / BUG-16: horizontal scroll for narrow screens.
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _showMissing.dispose();
    _dirty.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  /// BUG-06 / BUG-07 / BUG-16 — every admin page lays its content out in a
  /// `SizedBox(width: 1000.w)`. On a phone (390 px) or a portrait tablet
  /// (820 px) that box was silently squeezed to the screen width, so KPI
  /// cards lost their labels, chart titles wrapped one letter per line, job
  /// cards overlapped and stage cards broke.
  ///
  /// When the screen is narrower than the page canvas, the scrolling content
  /// now keeps its full designed width inside a horizontal scroll view (with
  /// a visible scrollbar as the hint). Nothing is clipped or squeezed; the
  /// navbars above keep their own tablet / mobile layouts.
  Widget _fitCanvas(Widget content) {
    if (widget.reflowOnPhone && AdminLayout.isPhone(context)) return content;
    return LayoutBuilder(builder: (context, c) {
      final double canvas = 1000.w + 48.w;
      if (!c.hasBoundedWidth || c.maxWidth >= canvas) return content;
      // BUG-100: on a TABLET (820 px) the right side of every page was off
      // screen ("Post Job", "Filter", the 3rd card column, "Edit Details"…).
      // Tablets now get the whole desktop canvas scaled down to the screen
      // width — nothing is cut and nothing needs sideways scrolling. Phones
      // keep the sideways scroll (scaling to 390 px would be unreadable).
      if (c.maxWidth >= AdminLayout.phoneMaxWidth) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(width: canvas, child: content),
        );
      }
      return Scrollbar(
        controller:      _hScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller:      _hScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: canvas, child: content),
        ),
      );
    });
  }

  List<Widget> get children => widget.children;
  CrossAxisAlignment get crossAxisAlignment => widget.crossAxisAlignment;
  double? get contentWidth => widget.contentWidth;
  int? get pinnedCount => widget.pinnedCount;
  ScrollController? get scrollController => widget.scrollController;
  EdgeInsetsGeometry? get padding => widget.padding;

  /// A spacer — a SizedBox that only reserves space. A SizedBox WITH a child
  /// is a content wrapper and must scroll.
  static bool _isSpacer(Widget w) => w is SizedBox && w.child == null;

  static bool _isBar(Widget w) => w is AppAdminNavbar || w is AdminSubNavBar;

  int _resolvePinnedCount() {
    if (pinnedCount != null) return pinnedCount!.clamp(0, children.length);

    int i = 0;
    int lastBar = -1;
    while (i < children.length &&
        (_isBar(children[i]) || _isSpacer(children[i]))) {
      if (_isBar(children[i])) lastBar = i;
      i++;
    }
    // Pin up to and including the last bar — never a trailing spacer, so the
    // gap the page put after the sub-navbar scrolls with the content and the
    // spacing looks unchanged.
    return lastBar + 1;
  }

  /// Re-applies the fixed width the removed wrapper used to provide.
  Widget _constrain(Widget child) {
    if (contentWidth == null) return child;
    return Center(child: SizedBox(width: contentWidth, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final int split = _resolvePinnedCount();

    // No bars on this page — behave exactly like the SingleChildScrollView it
    // replaced.
    if (split == 0) {
      return _scoped(SingleChildScrollView(
        controller: scrollController,
        padding: padding,
        child: _fitCanvas(_constrain(Column(
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        ))),
      ));
    }

    final pinned    = children.sublist(0, split);
    final scrolling = children.sublist(split);

    return _scoped(Column(
      children: [
        // Pinned bars keep the page's width constraint so they line up with
        // the content scrolling beneath them.
        _constrain(Column(
          crossAxisAlignment: crossAxisAlignment,
          children: pinned,
        )),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: padding,
            child: _fitCanvas(_constrain(Column(
              crossAxisAlignment: crossAxisAlignment,
              children: scrolling,
            ))),
          ),
        ),
      ],
    ));
  }

  /// Makes the missing-field and has-changed flags available to everything on
  /// this page.
  Widget _scoped(Widget child) => ValidationScope(
        controller: _showMissing,
        child: FormDirtyScope(controller: _dirty, child: child),
      );
}
