import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:web_app_admin/core/theme/appcolors.dart';
import 'package:web_app_admin/core/theme/new_theme.dart';
import 'package:web_app_admin/core/constant/color.dart'; // BUG-28: brand red, not the theme yellow


class CustomDropdownCalendar extends StatefulWidget {
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool required;
  final bool enabled;
  final Color? fillColor;

  /// Fixed trigger height (interpreted in .h). Matches CustomTextField /
  /// CustomDropdown so a date field lines up with adjacent fields.
  final double? height;
  final BorderRadius? borderRadius;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String Function(DateTime)? dateFormatter;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;

  const CustomDropdownCalendar({
    super.key,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.required = false,
    this.enabled = true,
    this.fillColor,
    this.height,
    this.borderRadius,
    this.firstDate,
    this.lastDate,
    this.dateFormatter,
    this.labelStyle,
    this.valueStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
  });

  @override
  State<CustomDropdownCalendar> createState() => _CustomDropdownCalendarState();
}

class _CustomDropdownCalendarState extends State<CustomDropdownCalendar> {
  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      dialogBackgroundColor: AppColors.card,
      barrierDismissible: true,
      value: [widget.value],
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: widget.firstDate ?? DateTime(1900),
        lastDate: widget.lastDate ?? DateTime(2100),
        calendarType: CalendarDatePicker2Type.single,
        calendarViewMode: CalendarDatePicker2Mode.day,
        closeDialogOnCancelTapped: true,
        closeDialogOnOkTapped: true,
        // Open on a selectable month: a stored date earlier than firstDate
        // (e.g. an old end date) would otherwise open on a fully disabled month.
        currentDate: (widget.firstDate != null &&
                (widget.value ?? DateTime.now()).isBefore(widget.firstDate!))
            ? widget.firstDate
            : (widget.value ?? DateTime.now()),
        centerAlignModePicker: true,
        dayBorderRadius: BorderRadius.circular(8.r),
        dayBuilder: _buildDay,
        customModePickerIcon: SvgPicture.asset(
          'assets/arrowdown.svg',
          fit: BoxFit.fitHeight,
          colorFilter: ColorFilter.mode(ColorPick.primary, BlendMode.srcIn),
          height: 14.sp,
        ),
        lastMonthIcon: Transform.rotate(
          angle: Get.locale.toString().contains('ar') ? 3.14 : 0,
          child: SvgPicture.asset(
            'assets/arrow.svg',
            colorFilter: ColorFilter.mode(ColorPick.primary, BlendMode.srcIn),
          ),
        ),
        nextMonthIcon: Transform.rotate(
          angle: Get.locale.toString().contains('ar') ? 0 : 3.14,
          child: SvgPicture.asset(
            'assets/arrow.svg',
            colorFilter: ColorFilter.mode(ColorPick.primary, BlendMode.srcIn),
          ),
        ),
        okButton: _buildActionButton('Set Date'.tr),
        cancelButton: _buildActionButton('Cancel'.tr, isCancel: true),
        weekdayLabelTextStyle: StyleText.fontSize16Weight400
            .copyWith(color: ColorPick.primary),
        controlsTextStyle: StyleText.fontSize14Weight400
            .copyWith(color: ColorPick.primary),
        selectedYearTextStyle: StyleText.fontSize14Weight400
            .copyWith(color: ColorPick.primary),
        selectedDayHighlightColor: ColorPick.primary,
        dayTextStyle:
        StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
        selectedDayTextStyle: StyleText.fontSize14Weight400
            .copyWith(color: Colors.white),
        yearTextStyle:
        StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
        todayTextStyle:
        StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
        buttonPadding: EdgeInsets.symmetric(horizontal: 14.sp),
      ),
      dialogSize: Size(320.w, 320.h),
      borderRadius: BorderRadius.circular(10.r),
      useSafeArea: true,
    );
    if (result != null && result.isNotEmpty) {
      widget.onChanged?.call(result.first);
    }
  }

  Widget _buildDay({
    required DateTime date,
    BoxDecoration? decoration,
    bool? isDisabled,
    bool? isSelected,
    bool? isToday,
    TextStyle? textStyle,
  }) {
    final now = DateTime.now();
    final isTodayDate =
        date.day == now.day && date.month == now.month && date.year == now.year;
    return Center(
      child: Container(
        width: 25.sp,
        height: 25.sp,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: isSelected == true ? ColorPick.primary : AppColors.field,
          border: Border.all(
            color: isTodayDate ? ColorPick.primary : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: StyleText.fontSize14Weight400.copyWith(
              color: isSelected == true
                  ? Colors.white
                  : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, {bool isCancel = false}) {
    return GestureDetector(
      child: Container(
        height: 38.sp,
        width: 120.sp,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: isCancel ? AppColors.secondaryButton : ColorPick.primary,
        ),
        child: Center(
          child: Text(
            label,
            style: StyleText.fontSize14Weight400.copyWith(
              color: isCancel ? AppColors.text : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      widget.dateFormatter?.call(d) ?? DateFormat('d MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final radius = widget.borderRadius ?? BorderRadius.circular(8.r);
    final isDisabled = !widget.enabled;
    final displayText = widget.value != null ? _formatDate(widget.value!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label,
              style: widget.labelStyle ??
                  StyleText.fontSize14Weight500.copyWith(
                    color: hasError
                        ? AppColors.red
                        : isDisabled
                        ? AppColors.text.withOpacity(0.4)
                        : AppColors.text,
                  ),
              children: widget.required
                  ? [TextSpan(text: ' *', style: StyleText.fontSize14Weight500.copyWith(color: AppColors.red))]
                  : [],
            ),
          ),
          SizedBox(height: 1.h),
        ],
        GestureDetector(
          onTap: _openPicker,
          child: SizedBox(
            height: widget.height?.h,
            child: InputDecorator(
            isFocused: false,
            isEmpty: displayText == null,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              filled: true,
              fillColor: isDisabled
                  ? (widget.fillColor ?? AppColors.card).withOpacity(0.5)
                  : widget.fillColor ?? AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: radius, borderSide: BorderSide.none),
              enabledBorder: hasError
                  ? OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(color: AppColors.red, width: 1.5.w))
                  : OutlineInputBorder(
                  borderRadius: radius, borderSide: BorderSide.none),
              focusedBorder: hasError
                  ? OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(color: AppColors.red, width: 1.5.w))
                  : OutlineInputBorder(
                  borderRadius: radius, borderSide: BorderSide.none),
              disabledBorder: OutlineInputBorder(
                  borderRadius: radius, borderSide: BorderSide.none),
              prefixIcon: null,
              prefixIconConstraints: const BoxConstraints(),
              // ── calendar icon now on the right, arrow removed ──
              suffixIcon: Padding(
                padding: EdgeInsets.only(left: 8.w, right: 12.w),
                child: SvgPicture.asset(
                  'assets/images/calender.svg',
                  width: 18.sp,
                  height: 18.sp,
                  colorFilter: ColorFilter.mode(
                    hasError
                        ? AppColors.red
                        : isDisabled
                        ? AppColors.text.withOpacity(0.3)
                        : AppColors.text.withOpacity(0.5),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(),
              hintText: displayText == null ? (widget.hint ?? '') : null,
              hintStyle: widget.hintStyle ??
                  StyleText.fontSize14Weight400.copyWith(color: AppColors.text.withOpacity(0.4)),
              errorText: null,
            ),
            child: displayText != null
                ? Text(
              displayText,
              style: widget.valueStyle ??
                  StyleText.fontSize14Weight400.copyWith(
                    color: isDisabled
                        ? AppColors.text.withOpacity(0.4)
                        : AppColors.text,
                  ),
              overflow: TextOverflow.ellipsis,
            )
                : const SizedBox.shrink(),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 4.h),
          Text(widget.errorText!,
              style: widget.errorStyle ??
                  StyleText.fontSize12Weight400.copyWith(color: AppColors.red)),
        ] else if (widget.helperText != null) ...[
          SizedBox(height: 4.h),
          Text(widget.helperText!,
              style: widget.helperStyle ??
                  StyleText.fontSize12Weight400.copyWith(
                      color: AppColors.text.withOpacity(0.5))),
        ],
      ],
    );
  }
}

/*
// ── Usage ─────────────────────────────────────────────────────────────────────
DateTime? _date;

CustomDropdownCalendar(
  label: 'Birth Date',
  hint: 'Select date',
  required: true,
  value: _date,
  // errorText: 'Date is required',
  onChanged: (d) => setState(() => _date = d),
)
*/
