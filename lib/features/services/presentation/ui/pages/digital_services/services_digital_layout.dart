// ******************* FILE INFO *******************
// File Name: services_digital_layout.dart
// Screen: Digital Journey — row / card LAYOUT editor.
//
//   Opened by tapping any Digital Journey card on the Services main page.
//   Implements the Figma screen "Preview Digital Journy Details"
//   (MESBAH · node 7126:63100):
//
//     • Rows, each with a "N Card" dropdown — 1 to 4 cards across.
//     • Drag a ROW by its handle onto another row to swap the two.
//     • Drag a CARD by its handle onto another card to swap them — only
//       inside the same row, which is what the design allows.
//     • Minus icon removes a card from its slot; the slot then offers the
//       "Select Digital Journey" picker to fill it with any unplaced item.
//     • Add Row appends an empty row.
//     • Save writes the order to journeyItems and the shape to rowSizes.
//
//   Colors come from ColorPick, dropdowns from the app's CustomDropdown.
//
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import '../../../../../../core/constant/color.dart';
import '../../../../../../core/custom/1-custom_dropdwon.dart';
import '../../../../../../core/custom_dialog.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../../../core/two_tab.dart';
import '../../../../data/models/services_model.dart';
import '../../../controller/services_cubit.dart';
import '../../../controller/services_state.dart';

/// Cards a row may hold, per the design.
const List<int> kRowCardOptions = [1, 2, 3, 4];

/// Shape a new row starts with.
const int kDefaultRowCards = 3;

/// Where a dragged card came from. A drop is only accepted inside the same row.
class _CardRef {
  const _CardRef(this.row, this.index);
  final int row;
  final int index;
}

class ServicesDigitalLayoutPage extends StatefulWidget {
  const ServicesDigitalLayoutPage({super.key, required this.model});

  final ServicePageModel model;

  @override
  State<ServicesDigitalLayoutPage> createState() =>
      _ServicesDigitalLayoutPageState();
}

class _ServicesDigitalLayoutPageState extends State<ServicesDigitalLayoutPage> {
  /// The layout being edited: one list per row, one slot per card. A null slot
  /// is an empty place waiting for a pick.
  List<List<JourneyItemModel?>> _rows = [];

  bool _isAr     = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _buildInitialRows();
  }

  // ── Layout state ───────────────────────────────────────────────────────────

  void _buildInitialRows() {
    final items = List<JourneyItemModel>.from(widget.model.journeyItems);
    final sizes = widget.model.rowSizes
        .where((n) => n >= kRowCardOptions.first && n <= kRowCardOptions.last)
        .toList();

    final rows = <List<JourneyItemModel?>>[];
    var i = 0;

    // Saved shape first — it decides how many cards each row holds.
    for (final n in sizes) {
      final row = <JourneyItemModel?>[];
      for (var k = 0; k < n; k++) {
        row.add(i < items.length ? items[i++] : null);
      }
      rows.add(row);
    }

    // Anything the saved shape did not cover (or a document saved before this
    // screen existed) falls into default rows.
    while (i < items.length) {
      final row = <JourneyItemModel?>[];
      for (var k = 0; k < kDefaultRowCards; k++) {
        row.add(i < items.length ? items[i++] : null);
      }
      rows.add(row);
    }

    if (rows.isEmpty) {
      rows.add(List<JourneyItemModel?>.filled(kDefaultRowCards, null,
          growable: true));
    }
    _rows = rows;
  }

  /// Journey items not placed in any slot — what the picker offers.
  List<JourneyItemModel> get _unplaced {
    final placed = _rows
        .expand((r) => r)
        .whereType<JourneyItemModel>()
        .map((e) => e.id)
        .toSet();
    return widget.model.journeyItems
        .where((j) => !placed.contains(j.id))
        .toList();
  }

  void _setRowSize(int rowIndex, int size) {
    setState(() {
      final row = _rows[rowIndex];
      if (size > row.length) {
        row.addAll(
            List<JourneyItemModel?>.filled(size - row.length, null));
      } else if (size < row.length) {
        // Cards dropped off the end simply become unplaced again.
        row.removeRange(size, row.length);
      }
    });
  }

  void _addRow() => setState(() => _rows.add(
      List<JourneyItemModel?>.filled(kDefaultRowCards, null, growable: true)));

  void _removeRow(int rowIndex) => setState(() => _rows.removeAt(rowIndex));

  void _swapRows(int a, int b) {
    if (a == b) return;
    setState(() {
      final tmp = _rows[a];
      _rows[a] = _rows[b];
      _rows[b] = tmp;
    });
  }

  void _swapCards(int row, int a, int b) {
    if (a == b) return;
    setState(() {
      final r = _rows[row];
      final tmp = r[a];
      r[a] = r[b];
      r[b] = tmp;
    });
  }

  void _clearSlot(int row, int index) =>
      setState(() => _rows[row][index] = null);

  void _fillSlot(int row, int index, JourneyItemModel item) =>
      setState(() => _rows[row][index] = item);

  // ── Save ───────────────────────────────────────────────────────────────────

  void _onSave() {
    showPublishConfirmDialog(
      context: context,
      title: 'EDITING DIGITAL JOURNEY LAYOUT',
      subtitle: 'Do you want to save the changes made to this layout?',
      confirmLabel: 'Confirm',
      onConfirm: () async {
        if (!mounted) return;
        setState(() => _isSaving = true);
        try {
          final cubit = context.read<ServiceCmsCubit>();
          final items =
              _rows.expand((r) => r).whereType<JourneyItemModel>().toList();
          final sizes = _rows.map((r) => r.length).toList();
          cubit.replaceModel(widget.model.copyWith(
            journeyItems: items,
            rowSizes:     sizes,
          ));
          await cubit.save(publishStatus: 'published');
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceCmsCubit, ServiceCmsState>(
      listener: (context, state) {
        if (state is ServiceCmsSaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
        if (state is ServiceCmsError) {
          setState(() => _isSaving = false);
          showConfirmDialog(
            context: context,
            title: 'Error',
            subtitle: state.message,
            confirmLabel: 'OK',
            cancelLabel: '',
            onConfirm: () {},
            iconWidget: Container(
              width: 60.r,
              height: 60.r,
              decoration: const BoxDecoration(
                  color: Color(0xFFE53935), shape: BoxShape.circle),
              child: Icon(Icons.error_outline, color: Colors.white, size: 36.r),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: ColorPick.background,
            body: AdminStickyBody(
              crossAxisAlignment: CrossAxisAlignment.start,
              contentWidth: 1000.w,
              children: [
                AppAdminNavbar(
                  activeLabel:    'Web Page',
                  homePage:       CareersMainPageDashboard(),
                  webPage:        MainMainPage(),
                  jobListingPage: JobListingMainPage(),
                ),
                SizedBox(height: 20.h),
                AdminSubNavBar(activeIndex: 2),

                Text(
                  'Preview Digital Journey Details',
                  style: StyleText.fontSize45Weight600.copyWith(
                      color: ColorPick.primary, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),

                // ── Language toggle ────────────────────────────────────────
                Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: 95.w,
                      height: 36.h,
                      child: CustomSegmentedTabs(
                        tabs: const ['ENG', 'AR'],
                        selectedIndex: _isAr ? 1 : 0,
                        onTabSelected: (i) => setState(() => _isAr = i == 1),
                        selectedColor: ColorPick.primary,
                        unselectedColor: Colors.white,
                        selectedTextColor: Colors.white,
                        unselectedTextColor: AppColors.text,
                        equalWidth: false,
                        containerPadding: EdgeInsets.symmetric(
                            horizontal: 8.sp, vertical: 4.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // ── Section heading, as the visitor sees it ────────────────
                Text(
                  _bi(widget.model.journeyTitle),
                  style: StyleText.fontSize22Weight700
                      .copyWith(color: ColorPick.primary),
                ),
                SizedBox(height: 16.h),

                // ── Rows ───────────────────────────────────────────────────
                ...List.generate(_rows.length, (i) => _rowBlock(i)),

                SizedBox(height: 8.h),
                _addRowButton(),
                SizedBox(height: 24.h),

                _actions(),
                SizedBox(height: 40.h),
              ],
            ),
          ),

          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircleProgress()),
            ),
        ],
      ),
    );
  }

  // ── One row: header + its cards, both drop targets for a row swap ──────────
  Widget _rowBlock(int rowIndex) {
    final row = _rows[rowIndex];

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != rowIndex,
      onAcceptWithDetails: (d) => _swapRows(d.data, rowIndex),
      builder: (context, candidate, __) {
        final hovered = candidate.isNotEmpty;
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(hovered ? 4.r : 0),
          decoration: BoxDecoration(
            color: hovered
                ? ColorPick.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowHeader(rowIndex),
              SizedBox(height: 8.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      Expanded(child: _slot(rowIndex, i)),
                      if (i != row.length - 1) SizedBox(width: 12.w),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Row header: drag handle + label + "N Card" dropdown ───────────────────
  Widget _rowHeader(int rowIndex) {
    final header = Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          _dragHandle(),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _rowLabel(rowIndex),
              style: StyleText.fontSize16Weight600
                  .copyWith(color: AppColors.text),
            ),
          ),
          SizedBox(
            width: 300.w,
            child: CustomDropdown<int>(
              value: _rows[rowIndex].length,
              items: kRowCardOptions
                  .map((n) => DropdownItem<int>(
                        value: n,
                        label: n == 1 ? '1 Card' : '$n Cards',
                      ))
                  .toList(),
              onChanged: (n) => _setRowSize(rowIndex, n),
              fillColor: ColorPick.background,
              borderRadius: BorderRadius.circular(4.r),
              triggerPadding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              valueStyle: StyleText.fontSize12Weight400
                  .copyWith(color: ColorPick.discard),
              itemStyle: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.text),
            ),
          ),
          SizedBox(width: 8.w),
          // Remove the whole row — never the last one, a page needs a row.
          IconButton(
            tooltip: 'Remove row',
            onPressed:
                _rows.length == 1 ? null : () => _removeRow(rowIndex),
            icon: Icon(Icons.delete_outline,
                size: 20.sp, color: ColorPick.removedColor),
            splashRadius: 18.r,
          ),
        ],
      ),
    );

    // The header is the row's drag handle.
    return Draggable<int>(
      data: rowIndex,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(width: 1000.w, child: header),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: header),
      child: header,
    );
  }

  // ── One card slot: a card, or the picker when the slot is empty ───────────
  Widget _slot(int rowIndex, int index) {
    final item = _rows[rowIndex][index];

    return DragTarget<_CardRef>(
      // Cards only swap with cards in the SAME row.
      onWillAcceptWithDetails: (d) =>
          d.data.row == rowIndex && d.data.index != index,
      onAcceptWithDetails: (d) => _swapCards(rowIndex, d.data.index, index),
      builder: (context, candidate, __) {
        final hovered = candidate.isNotEmpty;
        final child = item == null
            ? _emptySlot(rowIndex, index)
            : _card(rowIndex, index, item);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: hovered ? ColorPick.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: child,
        );
      },
    );
  }

  Widget _card(int rowIndex, int index, JourneyItemModel item) {
    final card = Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _clearSlot(rowIndex, index),
                child: Icon(Icons.remove_circle,
                    size: 20.sp, color: ColorPick.removedColor),
              ),
              const Spacer(),
              _dragHandle(),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: ColorPick.preview,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: item.iconUrl.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.all(8.r),
                        child: NetworkImageView(
                          url: item.iconUrl,
                          width: 24.w,
                          height: 24.w,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(Icons.miscellaneous_services_outlined,
                        size: 20.sp, color: ColorPick.primary),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _bi(item.title, fallback: 'Title'),
                  style: StyleText.fontSize16Weight600
                      .copyWith(color: AppColors.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _bi(item.description, fallback: 'Description'),
            style: StyleText.fontSize14Weight400
                .copyWith(color: AppColors.secondaryText, height: 1.6),
          ),
        ],
      ),
    );

    return Draggable<_CardRef>(
      data: _CardRef(rowIndex, index),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(width: 320.w, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }

  // ── Empty slot: pick which journey item goes here ─────────────────────────
  Widget _emptySlot(int rowIndex, int index) {
    final options = _unplaced;

    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdown<String>(
            hint: 'Select Digital Journey',
            items: options
                .map((j) => DropdownItem<String>(
                      value: j.id,
                      label: _bi(j.title, fallback: 'Untitled'),
                    ))
                .toList(),
            onChanged: (id) => _fillSlot(
              rowIndex,
              index,
              options.firstWhere((j) => j.id == id),
            ),
            fillColor: ColorPick.background,
            borderRadius: BorderRadius.circular(4.r),
            triggerPadding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            hintStyle: StyleText.fontSize12Weight400
                .copyWith(color: ColorPick.discard),
            itemStyle:
                StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
            emptyWidget: Padding(
              padding: EdgeInsets.all(12.r),
              child: Text('No unplaced items',
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add row ───────────────────────────────────────────────────────────────
  Widget _addRowButton() {
    return GestureDetector(
      onTap: _addRow,
      child: Container(
        width: 130.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: ColorPick.primary,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16.sp, color: Colors.white),
            SizedBox(width: 6.w),
            Text('Row',
                style: StyleText.fontSize14Weight500
                    .copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Back + Save ───────────────────────────────────────────────────────────
  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(6.r)),
              child: Center(
                child: Text('Back',
                    style: StyleText.fontSize14Weight600
                        .copyWith(color: Colors.white)),
              ),
            ),
          ),
        ),
        SizedBox(width: 300.w),
        Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : _onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44.h,
              decoration: BoxDecoration(
                  color: _isSaving
                      ? ColorPick.primary.withValues(alpha: 0.5)
                      : ColorPick.primary,
                  borderRadius: BorderRadius.circular(6.r)),
              child: Center(
                child: _isSaving
                    ? SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: const CircleProgress(),
                      )
                    : Text('Save',
                        style: StyleText.fontSize14Weight600
                            .copyWith(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Small pieces ──────────────────────────────────────────────────────────

  /// The three-bar grip the design uses on rows and cards.
  Widget _dragHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Container(
            width: 18.w,
            height: 3.h,
            margin: EdgeInsets.only(bottom: i == 2 ? 0 : 4.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF969494),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ),
    );
  }

  String _rowLabel(int i) {
    const names = [
      'First', 'Second', 'Third', 'Fourth', 'Fifth',
      'Sixth', 'Seventh', 'Eighth', 'Ninth', 'Tenth',
    ];
    return i < names.length ? '${names[i]} Row' : '${i + 1}th Row';
  }

  /// The active language's text, falling back to the other one.
  String _bi(BilingualText t, {String fallback = ''}) {
    final primary   = _isAr ? t.ar : t.en;
    final secondary = _isAr ? t.en : t.ar;
    if (primary.isNotEmpty) return primary;
    if (secondary.isNotEmpty) return secondary;
    return fallback;
  }
}
