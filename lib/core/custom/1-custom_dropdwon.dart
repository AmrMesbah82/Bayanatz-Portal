// ******************* FILE INFO *******************
// File Name: 1-custom_dropdwon.dart
// Description: The single shared dropdown widget. EVERY dropdown in the
//              app must use this widget — no raw DropdownButton anywhere.
// Created by: Amr Mesbah

/// Module: core › custom

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constant/color.dart';
import '../main_widgets/form_dirty_scope.dart';
import '../main_widgets/validation_scope.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

/// A dropdown item model
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;

  const DropdownItem({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.enabled = true,
  });
}

/// Custom dropdown widget
class CustomDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? hint;
  final String? label;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool required;
  final Color? fillColor;
  final double? maxOverlayHeight;
  final EdgeInsetsGeometry? triggerPadding;
  final BorderRadius? borderRadius;
  final TextStyle? valueStyle;
  final TextStyle? hintStyle;
  final TextStyle? itemStyle;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final double? itemHeight;

  /// BUG-289: fixed trigger height (in design units, scaled with .h) so a
  /// dropdown is exactly as tall as the CustomTextField(height: …) beside it
  /// — dropdowns were 38–39 px next to 48 px text fields.
  final double? fieldHeight;
  final double overlayElevation;
  final double? overlayOffset;
  final bool showDivider;
  final Color? dividerColor;
  final Widget? emptyWidget;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const CustomDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.label,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.required = false,
    this.fillColor,
    this.maxOverlayHeight,
    this.triggerPadding,
    this.borderRadius,
    this.valueStyle,
    this.hintStyle,
    this.itemStyle,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.itemHeight,
    this.fieldHeight,
    this.overlayElevation = 4,
    this.overlayOffset,
    this.showDivider = false,
    this.dividerColor,
    this.emptyWidget,
    this.onOpen,
    this.onClose,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>>
    with SingleTickerProviderStateMixin {
  /// QA-Oct11 #25: value + hint on the middle of a fixed-height trigger
  /// (Cairo's tall ascent sat them low).
  TextStyle _centred(TextStyle s) => widget.fieldHeight != null
      ? s.copyWith(height: 1.4, leadingDistribution: TextLeadingDistribution.even)
      : s;

  // ── CompositedTransformTarget link ──────────────────────
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  // BUG-36 / BUG-48: only ONE dropdown may be open at a time — opening one
  // closes the other. They used to stack on top of each other.
  static _CustomDropdownState? _currentlyOpen;

  // Set when an outside pointer-down closed the menu, so the tap that follows
  // on this dropdown's own trigger doesn't immediately re-open it.
  DateTime? _closedByOutsideAt;

  // Drives the always-visible scrollbar of long option lists (BUG-48).
  final ScrollController _listScroll = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // We need the trigger height to position the follower below it.
  // We read it after layout via a GlobalKey on the trigger Container.
  final _triggerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    // Remove the overlay IMMEDIATELY (no reverse animation): during route
    // changes (e.g. navigation right after Publish) animating here leaves a
    // stale overlay entry behind and can re-enter the mouse tracker while
    // it is updating devices (mouse_tracker !_debugDuringDeviceUpdate).
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (identical(_currentlyOpen, this)) _currentlyOpen = null;
    _animController.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    final closedAt = _closedByOutsideAt;
    if (!_isOpen &&
        closedAt != null &&
        DateTime.now().difference(closedAt) < const Duration(milliseconds: 300)) {
      // This tap is the one that just closed us from "outside" — our trigger.
      _closedByOutsideAt = null;
      return;
    }
    _isOpen ? _closeOverlay() : _openOverlay();
  }

  void _openOverlay() {
    final other = _currentlyOpen;
    if (other != null && !identical(other, this) && other.mounted) {
      other._closeOverlay();
    }
    _currentlyOpen = this;
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final triggerSize = renderBox.size;
    final verticalOffset = widget.overlayOffset ?? 2.h; // ← 2.h gap

    // Determine whether to open upward or downward
    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - globalOffset.dy - triggerSize.height;
    final spaceAbove = globalOffset.dy;
    final openUpward = spaceBelow < 150.h && spaceAbove > spaceBelow;

    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay<T>(
        layerLink: _layerLink,
        triggerSize: triggerSize,
        verticalOffset: verticalOffset,
        openUpward: openUpward,
        items: widget.items,
        maxHeight: widget.maxOverlayHeight ?? 240.h,
        itemHeight: widget.itemHeight ?? 36.sp,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(4.r),
        elevation: widget.overlayElevation,
        itemStyle: widget.itemStyle,
        showDivider: widget.showDivider,
        dividerColor: widget.dividerColor,
        emptyWidget: widget.emptyWidget,
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
        selectedValue: widget.value,
        onSelected: (item) {
          _closeOverlay();
          // A pick is always a user action — seeding goes through `value`.
          FormDirtyScope.markDirty(context);
          widget.onChanged?.call(item.value);
        },
        onDismiss: _closeOverlay,
        onOutsidePointerDown: () {
          _closedByOutsideAt = DateTime.now();
          _closeOverlay();
        },
        scrollController: _listScroll,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() => _isOpen = true);
    widget.onOpen?.call();
  }

  void _closeOverlay() {
    if (identical(_currentlyOpen, this)) _currentlyOpen = null;
    if (_overlayEntry == null) return;
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
    if (mounted) setState(() => _isOpen = false);
    widget.onClose?.call();
  }

  DropdownItem<T>? get _selectedItem {
    try {
      return widget.items.firstWhere((e) => e.value == widget.value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Red border when the caller set an error, OR when a blocked Publish asked
    // the page to reveal what is missing and this required dropdown is empty.
    final bool missingRequired = widget.required &&
        _selectedItem == null &&
        ValidationScope.revealed(context);
    final hasError =
        (widget.errorText != null && widget.errorText!.isNotEmpty) ||
            missingRequired;
    final radius = widget.borderRadius ?? BorderRadius.circular(4.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ──────────────────────────────────────────
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label,
              style: widget.labelStyle ??
                  StyleText.label.copyWith(
                    color: hasError
                        ? AppColors.red
                        : widget.enabled
                            ? AppColors.text
                            : AppColors.text.withOpacity(0.4),
                  ),
              children: widget.required
                  ? [
                      TextSpan(
                        text: ' *',
                        style: StyleText.label
                            .copyWith(color: AppColors.red),
                      )
                    ]
                  : [],
            ),
          ),
          SizedBox(height: 6.h),
        ],

        // ── Trigger ────────────────────────────────────────
        // Uses InputDecorator so the rendered height is pixel-identical
        // to a CustomTextField with the same contentPadding.
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: SizedBox(
             height: widget.fieldHeight?.h,
             child: InputDecorator(
              key: _triggerKey,
              isFocused: false,
              isEmpty: _selectedItem == null,
              // BUG-289: fill the fixed height like the text field does.
              expands: widget.fieldHeight != null,
              textAlignVertical: widget.fieldHeight != null
                  ? TextAlignVertical.center
                  : null,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: widget.triggerPadding ??
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                filled: true,
                fillColor: widget.enabled
                    ? (widget.fillColor ?? AppColors.card)
                    : AppColors.card.withOpacity(0.5),
                // ── No border rule — red only on error ──────
                // InputDecorator does not trigger errorBorder on its own
                // (no errorText), so we drive the border via enabledBorder.
                border: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: hasError
                    ? OutlineInputBorder(
                        borderRadius: radius,
                        borderSide:
                            BorderSide(color: AppColors.red, width: 1.5.w),
                      )
                    : OutlineInputBorder(
                        borderRadius: radius,
                        borderSide: BorderSide.none,
                      ),
                focusedBorder: hasError
                    ? OutlineInputBorder(
                        borderRadius: radius,
                        borderSide:
                            BorderSide(color: AppColors.red, width: 1.5.w),
                      )
                    : OutlineInputBorder(
                        borderRadius: radius,
                        borderSide: BorderSide.none,
                      ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide.none,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: EdgeInsets.only(left: 12.w, right: 8.w),
                        child: widget.prefixIcon,
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 12.w),
                  child: widget.suffixIcon ??
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: SvgPicture.asset(
                          'assets/arrowdown.svg',
                          width: 20.sp,
                          height: 20.sp,
                          colorFilter: ColorFilter.mode(
                            hasError
                                ? AppColors.red
                                : widget.enabled
                                    ? AppColors.text.withOpacity(0.6)
                                    : AppColors.text.withOpacity(0.3),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                ),
                suffixIconConstraints: const BoxConstraints(),
                hintText: _selectedItem == null ? (widget.hint ?? '') : null,
                hintStyle: _centred(widget.hintStyle ?? StyleText.hint),
                // Suppress built-in error text — we render our own below
                errorText: null,
              ),
              child: _selectedItem != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedItem!.leading != null) ...[
                          _selectedItem!.leading!,
                          SizedBox(width: 8.w),
                        ],
                        Expanded(
                          child: Text(
                            _selectedItem!.label,
                            style: _centred(widget.valueStyle ??
                                StyleText.value.copyWith(
                                  color: widget.enabled
                                      ? AppColors.text
                                      : AppColors.text.withOpacity(0.4),
                                )),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  // InputDecorator shows hintText automatically when child
                  // isEmpty — but we still need a zero-height child.
                  : const SizedBox.shrink(),
             ),
            ),
          ),
        ),

        // ── Error / Helper ─────────────────────────────────
        if (hasError && widget.errorText != null) ...[
          SizedBox(height: 4.h),
          Text(
            widget.errorText!,
            style: widget.errorStyle ??
                StyleText.subTitle.copyWith(color: AppColors.red),
          ),
        ] else if (widget.helperText != null) ...[
          SizedBox(height: 4.h),
          Text(
            widget.helperText!,
            style: widget.helperStyle ??
                StyleText.subTitle
                    .copyWith(color: AppColors.text.withOpacity(0.5)),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay widget — now uses CompositedTransformFollower for pixel-perfect
// positioning directly below (or above) the trigger.
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownOverlay<T> extends StatelessWidget {
  final LayerLink layerLink;
  final Size triggerSize;
  final double verticalOffset;
  final bool openUpward;
  final List<DropdownItem<T>> items;
  final double maxHeight;
  final double itemHeight;
  final BorderRadius borderRadius;
  final double elevation;
  final TextStyle? itemStyle;
  final bool showDivider;
  final Color? dividerColor;
  final Widget? emptyWidget;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final T? selectedValue;
  final ValueChanged<DropdownItem<T>> onSelected;
  final VoidCallback onDismiss;
  final VoidCallback onOutsidePointerDown;
  final ScrollController scrollController;

  const _DropdownOverlay({
    required this.onOutsidePointerDown,
    required this.scrollController,
    required this.layerLink,
    required this.triggerSize,
    required this.verticalOffset,
    required this.openUpward,
    required this.items,
    required this.maxHeight,
    required this.itemHeight,
    required this.borderRadius,
    required this.elevation,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.onSelected,
    required this.onDismiss,
    this.itemStyle,
    this.showDivider = false,
    this.dividerColor,
    this.emptyWidget,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    // BUG-36: Escape closes the menu.
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onDismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox.expand(
      child: Stack(
        children: [
          // Full-screen dismiss layer. BUG-36: a raw pointer-down (not a tap
          // gesture competing in the arena) so ANY click outside closes the
          // menu — including a click on another dropdown, which then opens.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => onOutsidePointerDown(),
            ),
          ),

          // ── CompositedTransformFollower keeps the overlay
          //    anchored directly to the trigger at all times ──
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            // When opening downward: anchor top-left of trigger → offset by
            // triggerHeight + gap so overlay top sits right below trigger.
            // When opening upward: anchor top-left of trigger → offset is
            // negative so overlay bottom sits right above trigger.
            targetAnchor: openUpward ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor:
                openUpward ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(
              0,
              openUpward ? -verticalOffset : verticalOffset,
            ),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                alignment:
                    openUpward ? Alignment.bottomCenter : Alignment.topCenter,
                child: Material(
                  elevation: elevation,
                  borderRadius: borderRadius,
                  color: AppColors.card,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      minWidth: triggerSize.width,
                      maxWidth: triggerSize.width,
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: items.isEmpty
                          ? SizedBox(
                              height: itemHeight,
                              child: emptyWidget ??
                                  Center(
                                    child: Text(
                                      'No options',
                                      style: StyleText.subTitle
                                          .copyWith(
                                        color:
                                            AppColors.text.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                            )
                          : Scrollbar(
                              // BUG-48: long lists (e.g. 10 statuses) now
                              // show that they scroll.
                              controller: scrollController,
                              thumbVisibility: items.length * itemHeight > maxHeight,
                              child: ListView.separated(
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => showDivider
                                  ? Divider(
                                      height: 1.h,
                                      thickness: 1.h,
                                      color: dividerColor ??
                                          AppColors.text.withOpacity(0.08),
                                    )
                                  : const SizedBox.shrink(),
                              itemBuilder: (_, i) {
                                final item = items[i];
                                final isSelected =
                                    item.value == selectedValue;
                                return _DropdownItemTile<T>(
                                  item: item,
                                  isSelected: isSelected,
                                  height: itemHeight,
                                  style: itemStyle,
                                  onTap: item.enabled
                                      ? () => onSelected(item)
                                      : null,
                                );
                              },
                            ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item tile with hover state
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownItemTile<T> extends StatefulWidget {
  final DropdownItem<T> item;
  final bool isSelected;
  final double height;
  final TextStyle? style;
  final VoidCallback? onTap;

  const _DropdownItemTile({
    required this.item,
    required this.isSelected,
    required this.height,
    this.style,
    this.onTap,
  });

  @override
  State<_DropdownItemTile<T>> createState() => _DropdownItemTileState<T>();
}

class _DropdownItemTileState<T> extends State<_DropdownItemTile<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return MouseRegion(
      cursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          color: widget.isSelected
              ? ColorPick.primary
              : (_hovered && !isDisabled)
                  ? ColorPick.primary
                  : Colors.transparent,
          child: Row(
            children: [
              if (widget.item.leading != null) ...[
                widget.item.leading!,
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: (widget.style ??
                          (widget.isSelected
                              ? StyleText.value.copyWith(
                                  fontWeight: FontWeight.w600)
                              : StyleText.value))
                      .copyWith(
                    color: isDisabled
                        ? AppColors.text.withOpacity(0.3)
                        : (widget.isSelected || _hovered)
                            ? ColorPick.white
                            : AppColors.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.item.trailing != null) ...[
                SizedBox(width: 8.w),
                widget.item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
