part of '../../pages/home_edit.dart';

extension _HomeEditBuilders on _HomeEditPageMasterState {
  // ── Headings ──────────────────────────────────────────────────────────────
  Widget _headingsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 10.h),
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              label: 'Title',
              hint: 'Text Here',
              required: true,
              controller: _titleEn,
              height: 36,
              fillColor: Colors.white,
              submitted: _submitted,
              textDirection: ui.TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Directionality(
              textDirection: ui.TextDirection.rtl,
              child: CustomTextField(
                label: 'العنوان',
                required: true,
                hint: 'أكتب هنا',
                controller: _titleAr,
                fillColor: Colors.white,
                height: 36,
                submitted: _submitted,
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 16.h),
      CustomTextField(
        label: 'Short Description',
        hint: 'Text Here',
        required: true,
        controller: _shortDescEn,
        height: 80,
        maxLines: 3,
        submitted: _submitted,
        textDirection: ui.TextDirection.ltr,
        fillColor: Colors.white,
        textAlign: TextAlign.left,
      ),
      SizedBox(height: 16.h),
      Directionality(
        textDirection: ui.TextDirection.rtl,
        child: CustomTextField(
          label: 'وصف مختصر',
          hint: 'أكتب هنا',
          required: true,
          fillColor: Colors.white,
          controller: _shortDescAr,
          height: 80,
          maxLines: 3,
          submitted: _submitted,
          textDirection: ui.TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );

  Widget _navButtonsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...List.generate(_navBtns.length, (i) {
        final btn = _navBtns[i];
        return Column(
          key: ValueKey(btn),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 15.sp),

            Row(
              children: [
                Text(
                  '${_ordinal(i + 1)} Button',
                  style: StyleText.fontSize14Weight600.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _navBtns[i].dispose();
                    _navBtns.removeAt(i);
                  }),
                  child: Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.remove, color: Colors.white, size: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Button Name',
                    hint: 'Text Here',
                    controller: btn.nameEn,
                    height: 36,
                    fillColor: Colors.white,
                    submitted: _submitted,
                    textDirection: ui.TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: CustomTextField(
                      label: 'عنوان الزر',
                      hint: 'أكتب هنا',
                      controller: btn.nameAr,
                      height: 36,
                      fillColor: Colors.white,
                      submitted: _submitted,
                      textDirection: ui.TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.sp),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    valueStyle: StyleText.fontSize12Weight400.copyWith(
                      color: AppColors.text
                    ),
                    label: 'Navigate To',
                    value:
                    _kNavRouteOptions.any((o) => o['route'] == btn.route)
                        ? btn.route
                        : null,
                    items: _kNavRouteOptions
                        .map((opt) => DropdownItem<String>(
                        value: opt['route']!, label: opt['label']!))
                        .toList(),
                    onChanged: (val) => setState(() => btn.route = val),
                    hint: 'Select destination',
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(child: SizedBox()),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        );
      }),
      if (_navBtns.length < 6)
        Padding(
          padding:  EdgeInsets.only(top: 15.sp),
          child: GestureDetector(
            onTap: () => setState(() => _navBtns.add(_NavBtnItem())),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF797979),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Button',
                    style: StyleText.fontSize12Weight500.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      SizedBox(height: 15.sp),
    ],
  );

  Widget _sectionEdit(int i) {
    final sec = _sections[i];
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 10.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Image', style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
                  SizedBox(height: 6.h),
                  _imgBox(
                    picked: sec.image,
                    onPick: () async {
                      final p = await _pickImage(allowRaster: true); // BUG-68
                      if (p != null) setState(() => sec.image = p);
                    },
                  ),
                  if (_submitted && sec.image.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('Image required (SVG, PNG, JPG or WebP)',
                          style: StyleText.fontSize12Weight400.copyWith(color: ColorPick.red)),
                    ),
                ],
              ),
              SizedBox(width: 24.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Icon', style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
                  SizedBox(height: 6.h),
                  _imgBox(
                    picked: sec.icon,
                    isAdd: true,
                    onPick: () async {
                      final p = await _pickImage();
                      if (p != null) setState(() => sec.icon = p);
                    },
                  ),
                  if (_submitted && sec.icon.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('Icon (SVG) required',
                          style: StyleText.fontSize12Weight400.copyWith(color: ColorPick.red)),
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Visibility',
                          style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
                      SizedBox(width: 8.w),
                      FlutterSwitch(
                        width: 35.sp,
                        height: 20.sp,
                        padding: 3.sp,
                        borderRadius: 20.sp,
                        toggleSize: 16.sp,
                        activeColor: ColorPick.primary,
                        inactiveColor: Colors.grey.withValues(alpha: .16),
                        value: sec.visibility,
                        onToggle: (val) {
                          setState(() => sec.visibility = val);
                          _markDirty(); // BUG-76
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          CustomTextField(
            label: 'Description',
            required: true,
            hint: 'Text Here',
            controller: sec.descEn,
            maxLength: 500,
            showCharCount: false,
            height: 80,
            maxLines: 3,
            submitted: _submitted,
            fillColor: Colors.white,
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 16.h),
          Directionality(
            textDirection: ui.TextDirection.rtl,
            child: CustomTextField(
              label: 'الوصف',
              hint: 'أكتب هنا',
              required: true,
              controller: sec.descAr,
              maxLength: 500,
              showCharCount: false,
              height: 80,
              maxLines: 3,
              fillColor: Colors.white,
              submitted: _submitted,
              textDirection: ui.TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgBox({
    required _PickedImage picked,
    bool isAdd = false,
    VoidCallback? onPick,
  }) {
    // Delegates to the single shared image-upload circle (core/custom).
    return imageUploadCircleBare(
      bytes: picked.bytes,
      url: picked.url ?? '',
      onTap: onPick ?? () {},
    );
  }
}
