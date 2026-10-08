// ******************* FILE INFO *******************
// File Name: admin_layout.dart
// Purpose: BUG-06 / BUG-16 — real phone layouts for the admin list pages
//          (Home dashboard, Job Listing, Departments, Applications,
//          Inquiries).
//
//          On a phone (< 700 px wide) those pages no longer use the fixed
//          1000.w desktop canvas: content takes the screen width, card rows
//          become 1–2 columns and side-by-side charts stack vertically.
//          Tablets and desktops keep the existing layout.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminLayout {
  AdminLayout._();

  /// Below this width a page switches to its phone layout.
  static const double phoneMaxWidth = 700;

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < phoneMaxWidth;

  /// Width of the page's content column.
  static double contentWidth(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return w < phoneMaxWidth ? w - 32 : 1000.w;
  }

  /// Horizontal padding around the content column.
  static double sidePadding(BuildContext context) =>
      isPhone(context) ? 16 : 20.w;
}

/// A row of equal-width cards on tablet / desktop that wraps into
/// [phoneColumns] columns on a phone.
///
/// Pass the cards themselves — NOT wrapped in `Expanded`.
class AdminCardsRow extends StatelessWidget {
  const AdminCardsRow({
    super.key,
    required this.children,
    this.gap,
    this.phoneColumns = 1,
    this.stretch = false,
  });

  final List<Widget> children;
  final double? gap;
  final int phoneColumns;

  /// Give every card in a row the height of the tallest one.
  final bool stretch;

  Widget _row(List<Widget> items, int columns, double g) {
    final cells = <Widget>[];
    for (var i = 0; i < columns; i++) {
      if (i > 0) cells.add(SizedBox(width: g));
      cells.add(Expanded(child: i < items.length ? items[i] : const SizedBox()));
    }
    final row = Row(
      crossAxisAlignment:
          stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: cells,
    );
    return stretch ? IntrinsicHeight(child: row) : row;
  }

  @override
  Widget build(BuildContext context) {
    final double g = gap ?? 10.w;
    if (!AdminLayout.isPhone(context)) {
      return _row(children, children.length, g);
    }
    final int cols = phoneColumns < 1 ? 1 : phoneColumns;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: g));
      final end = (i + cols) > children.length ? children.length : i + cols;
      rows.add(cols == 1
          ? children[i]
          : _row(children.sublist(i, end), cols, g));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
