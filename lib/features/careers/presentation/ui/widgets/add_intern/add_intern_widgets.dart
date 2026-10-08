part of '../../pages/add_intern.dart';

extension _AddInternWidgets on _AddInternPageState {
  Future<void> _pickDate() async {
    final bool isTablet = MediaQuery.of(context).size.shortestSide > 600;

    final result = await showCalendarDatePicker2Dialog(
      context: context,
      dialogBackgroundColor: Colors.white,
      barrierDismissible: true,
      value: [_joinedDate],
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        currentDate: _joinedDate ?? DateTime.now(),
        calendarType: CalendarDatePicker2Type.single,
        centerAlignModePicker: true,
        closeDialogOnCancelTapped: true,
        closeDialogOnOkTapped: true,
        dayBuilder: ({required DateTime date, BoxDecoration? decoration, bool? isDisabled, bool? isSelected, bool? isToday, TextStyle? textStyle}) {
          final isNow = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
          return Center(
            child: Container(
              width: 28.sp, height: 28.sp,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                color: isSelected == true ? ColorPick.primary : const Color(0xFFF5F5F5),
                border: Border.all(color: isNow ? ColorPick.primary : Colors.transparent, width: 1.5),
              ),
              child: Center(
                child: Text(date.day.toString(),
                    style: (isSelected == true
                            ? StyleText.fontSize11Weight600
                            : StyleText.fontSize11Weight400)
                        .copyWith(
                  fontSize: 11.sp,
                  color: isSelected == true ? Colors.white : isDisabled == true ? AppColors.secondaryText : AppColors.text,
                )),
              ),
            ),
          );
        },
        okButton: Material(
          color: Colors.transparent,
          child: Container(
            height: 38.sp, width: isTablet ? 140.sp : 110.sp,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r), color: ColorPick.primary),
            child: Center(child: Text('Set Date', style: StyleText.fontSize13Weight600.copyWith(color: Colors.white))),
          ),
        ),
        cancelButton: Material(
          color: Colors.transparent,
          child: Container(
            height: 38.sp, width: isTablet ? 140.sp : 110.sp,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r), color: const Color(0xFFE0E0E0)),
            child: Center(child: Text('Cancel', style: StyleText.fontSize13Weight600.copyWith(color: ColorPick.discard))),
          ),
        ),
        selectedDayHighlightColor: ColorPick.primary,
        selectedRangeHighlightColor: ColorPick.primary.withValues(alpha: 0.15),
        weekdayLabelTextStyle: StyleText.fontSize12Weight600.copyWith(color: ColorPick.primary),
        controlsTextStyle: StyleText.fontSize13Weight600.copyWith(color: ColorPick.primary),
        dayTextStyle: StyleText.fontSize11Weight400.copyWith(color: AppColors.text),
        selectedDayTextStyle: StyleText.fontSize11Weight600.copyWith(color: Colors.white),
        todayTextStyle: StyleText.fontSize11Weight400.copyWith(color: ColorPick.primary),
        yearTextStyle: StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
        buttonPadding: EdgeInsets.symmetric(horizontal: isTablet ? 30.sp : 12.sp),
      ),
      dialogSize: isTablet ? Size(440.sp, 310.sp) : Size(320.w, 320.h),
      borderRadius: BorderRadius.circular(12),
      useSafeArea: true,
    );

    if (result != null && result.isNotEmpty && result.first != null && mounted) {
      setState(() => _joinedDate = result.first);
    }
  }

  Widget _photoPicker() {
    // Delegates to the single shared image-upload circle (core/custom).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Photo', style: StyleText.fontSize12Weight600.copyWith(color: AppColors.text)),
        ]),
        SizedBox(height: 6.h),
        imageUploadCircleBare(
          bytes: _photoBytes,
          url: _photoUrl,
          onTap: _pickPhoto,
        ),
      ],
    );
  }

  Widget _dateField() {
    final label = _joinedDate != null ? DateFormat('dd MMM yyyy').format(_joinedDate!) : 'Select Date';
    final hasError = _submitted && _joinedDate == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Joined Date', style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        ]),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity, height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color:  AppColors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: hasError ? Colors.red : Colors.transparent, width: hasError ? 1.5 : 0),
            ),
            child: Row(children: [
              Expanded(
                child: Text(label, style: StyleText.fontSize12Weight400.copyWith(
                    color: _joinedDate != null ? AppColors.text : AppColors.secondaryText)),
              ),
              CustomSvg(assetPath: "assets/control/Calendar.svg", width: 16.w, height: 16.h,
                  fit: BoxFit.scaleDown, color: hasError ? Colors.red : null),
            ]),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 4.h),
          Text('Joined date is required', style: StyleText.fontSize11Weight400.copyWith(color: Colors.red)),
        ],
      ],
    );
  }
}
