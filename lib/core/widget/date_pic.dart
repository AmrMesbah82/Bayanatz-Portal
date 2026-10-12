import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';


import '../theme/appcolors.dart';
import '../constant/color.dart'; // BUG-28/48: admin red, not the theme yellow
import '../theme/text.dart';


class DatePicker {
  Future<List<DateTime?>?> showDatePicker(
      BuildContext context,
      List<DateTime?> rangeDatePickerValueWithDefaultValue,
      DateTime? currentDate,
      CalendarDatePicker2Type? calendarType,
      {DateTime? firstDate, DateTime? lastDate}) {
    bool isTablet = MediaQuery.of(context).size.shortestSide > 600;
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return showCalendarDatePicker2Dialog(
        context: context,
        dialogBackgroundColor: AppColors.card,
        barrierDismissible: true,
        value: rangeDatePickerValueWithDefaultValue,
        config: CalendarDatePicker2WithActionButtonsConfig(
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100),
          // BUG-48: today used to be NOT selectable, while callers opened the
          // picker with today pre-selected — an invalid initial value, so the
          // dialog failed to open at all ("Calendar opens nothing").
          dayBuilder: ({
            required DateTime date,
            BoxDecoration? decoration,
            bool? isDisabled,
            bool? isSelected,
            bool? isToday,
            TextStyle? textStyle,
          }) {
            return Center(
              child: Container(
                  width: 25.sp,
                  height: 25.sp,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: isSelected == true
                          ? ColorPick.primary
                          : AppColors.field,
                      border: Border.all(
                        color: date.day == DateTime.now().day &&
                            date.month == DateTime.now().month &&
                            date.year == DateTime.now().year
                            ? ColorPick.primary
                            : Colors.transparent,
                      )),
                  child: Center(
                      child: Text(
                        date.day.toString(),
                        style: AppTextStyles.font14BlackCairoRegular.copyWith(
                          color: isSelected == true
                              ? Colors.white
                              : AppColors.text,
                        ),
                      ))),
            );
          },
          calendarViewMode: CalendarDatePicker2Mode.day,
          closeDialogOnCancelTapped: true,
          closeDialogOnOkTapped: true,
          currentDate: currentDate, //widget.dateTimeNow ?? DateTime.now(),
          centerAlignModePicker: true,
          dayBorderRadius: BorderRadius.circular(8),

          // BUG-153: same icons as the Post Job picker
          // (CustomDropdownCalendar). This picker pointed at
          // assets/images/downArrow.svg and assets/icons/back_icon.svg,
          // which do not exist — so it had NO month arrows.
          customModePickerIcon: SvgPicture.asset(
            'assets/arrowdown.svg',
            fit: BoxFit.fitHeight,
            colorFilter: ColorFilter.mode(ColorPick.primary, BlendMode.srcIn),
            height: 14.sp,
          ),

          okButton: Material(
            color: Colors.transparent,
            child: GestureDetector(
              child: Padding(
                padding: EdgeInsets.only(bottom: 0.sp),
                child: Container(
                  height: 38.sp,
                  width: isTablet ? 150.sp : 120.sp,
                  decoration: BoxDecoration(

                    borderRadius: BorderRadius.circular(8.r),
                    color: ColorPick.primary,

                  ),
                  child: Center(
                    child: Text(
                      'Set Date'.tr,
                      style: AppTextStyles.font14BlackCairoRegular
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),

          cancelButton: Material(
            color: Colors.transparent,
            child: GestureDetector(
              child: Padding(
                padding: EdgeInsets.only(bottom: 0.sp),
                child: Container(
                  height: 38.sp,
                  width: isTablet ? 150.sp : 120.sp,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: AppColors.secondaryButton,
                  ),
                  child: Center(
                    child: Text(
                      'Cancel'.tr,
                      style: AppTextStyles.font14BlackCairoRegular.copyWith(),
                    ),
                  ),
                ),
              ),
            ),
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
          weekdayLabelTextStyle: AppTextStyles.font16BlackRegularCairo
              .copyWith(color: ColorPick.primary),

          controlsTextStyle: AppTextStyles.font14BlackCairoRegular
              .copyWith(color: ColorPick.primary),
          selectedYearTextStyle: AppTextStyles.font14BlackCairoRegular
              .copyWith(color: ColorPick.primary),
          selectedDayHighlightColor: ColorPick.primary,
          dayTextStyle: AppTextStyles.font14BlackCairoRegular
              .copyWith(color: Colors.white),
          selectedDayTextStyle: AppTextStyles.font14BlackCairoRegular
              .copyWith(color: Colors.white),

          yearTextStyle: AppTextStyles.font14BlackCairoRegular
              .copyWith(color: AppColors.text),
          todayTextStyle: AppTextStyles.font14BlackCairoRegular
              .copyWith(color: AppColors.text),
          buttonPadding:
          EdgeInsets.symmetric(horizontal: isTablet ? 35.sp : 14.sp),
          selectedRangeHighlightColor: ColorPick.primary.withValues(alpha: 0.25),
          calendarType: calendarType, //CalendarDatePicker2Type.range,
        ),
        // BUG-153: same size as the Post Job picker.
        dialogSize: Size(320.w, 320.h),
        borderRadius: BorderRadius.circular(10),
        useSafeArea: true);
  }
}

/// BUG-153: Applications "Time Frame" and Inquiries "Calendar" opened the
/// FULL-SCREEN Material range picker (admin menu hidden) and behaved
/// differently (future days blocked in one, allowed in the other). Both now
/// use this dialog-size picker with the same rule: any day from 5 years ago
/// up to today (nothing is received in the future).
Future<DateTimeRange?> showAdminDateRangePicker(
  BuildContext context, {
  DateTimeRange? initial,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final res = await DatePicker().showDatePicker(
    context,
    initial == null ? <DateTime?>[] : <DateTime?>[initial.start, initial.end],
    today,
    CalendarDatePicker2Type.range,
    firstDate: DateTime(now.year - 5, 1, 1),
    lastDate: today,
  );
  if (res == null || res.isEmpty || res.first == null) return null;
  final start = res.first!;
  final end = (res.length > 1 && res[1] != null) ? res[1]! : start;
  return end.isBefore(start)
      ? DateTimeRange(start: end, end: start)
      : DateTimeRange(start: start, end: end);
}
