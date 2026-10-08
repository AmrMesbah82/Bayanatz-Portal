part of '../../pages/contact_us_edit.dart';

extension _ContactUsEditUi on _ContactUsCmsEditPageState {
  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editing Contact Us Details',
          style: StyleText.fontSize28Weight600.copyWith(
            fontSize:   36.sp,
            color:      ColorPick.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 24.h),

        _accordion(
          title:    'Info',
          isOpen:   _infoOpen,
          onToggle: () => setState(() => _infoOpen = !_infoOpen),
          child:    _infoSection(),
        ),
        _infoOpen ? SizedBox() :  SizedBox(height: 16.h),
        _accordion(
          title:    'Office Locations',
          isOpen:   _officesOpen,
          onToggle: () => setState(() => _officesOpen = !_officesOpen),
          child:    _officeLocationsSection(),
        ),
         SizedBox(height: 16.h),

        _accordion(
          title:    'Confirm Message',
          isOpen:   _confirmOpen,
          onToggle: () => setState(() => _confirmOpen = !_confirmOpen),
          child:    _confirmMessageSection(),
        ),
        SizedBox(height: 32.h),

        _actionButtons(),
        SizedBox(height: 48.h),
      ],
    );
  }

  // ── Accordion ─────────────────────────────────────────────────────────────

  Widget _accordion({
    required String   title,
    required bool     isOpen,
    required VoidCallback onToggle,
    required Widget   child,
  }) {
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: onToggle,
      child:    child,
    );
  }

  // ── Info Section ──────────────────────────────────────────────────────────

  Widget _infoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.h),
        _fieldLabel('Short Description'), // BUG-157
        SizedBox(height: 8.h),
        CustomValidatedTextFieldMaster(
          hint:          'Text Here',
          fillColor: Colors.white,
          controller:    _subDescEnCtrl,
          height:        100,
          maxLines:      4,
          maxLength:     10000,
          showCharCount: false,
          submitted:     _submitted,
          textDirection: TextDirection.ltr,
          textAlign:     TextAlign.start,
          onChanged:     (_) => setState(() {}),
        ),
        SizedBox(height: 8.h),
        _fieldLabelAr('وصف فرعي'),
        SizedBox(height: 4.h),
        CustomValidatedTextFieldMaster(
          hint:          'أدخل النص هنا',
          controller:    _subDescArCtrl,
          fillColor: Colors.white,
          height:        100,
          maxLines:      4,
          maxLength:     10000,
          showCharCount: false,
          submitted:     _submitted,
          textDirection: TextDirection.rtl,
          textAlign:     TextAlign.right,
          onChanged:     (_) => setState(() {}),
        ),
        SizedBox(height: 20.h),

        // ── Email ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Email'),
                  SizedBox(height: 8.h),
                  CustomValidatedTextFieldMaster(
                    hint:          'Text Here',
                    fillColor: Colors.white,
                    controller:    _emailCtrl,
                    height:        42,
                    maxLines:      1,
                    maxLength:     10000,
                    submitted:     _submitted,
                    textDirection: TextDirection.ltr,
                    textAlign:     TextAlign.start,
                    onChanged:     (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SizedBox(width: 30.sp),
            const Expanded(child: Center()),
          ],
        ),
        SizedBox(height: 20.h),

        // ── Social Icons Grid ──
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_socialIconItems.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics:    const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:  2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing:  10.h,
                  mainAxisExtent:   60.sp,
                ),
                itemCount:    _socialIconItems.length,
                itemBuilder:  (context, index) =>
                    _socialIconWidget(_socialIconItems[index]),
              ),

            // NOTE: "Add Icon" removed — icons are auto-filled from the
            // MAIN page social links; manage them on the Main edit page.
            SizedBox(height: 16.h),
          ],
        ),
      ],
    );
  }

  // ── Social Icon Widget ────────────────────────────────────────────────────

  Widget _socialIconWidget(_SocialIconItem s) {
    // AUTO-FILLED from the MAIN page social links (edit_sections2 →
    // MainCmsCubit) — read-only, no selection, no add/remove.
    final link = (s.selectedIndex != null &&
            s.selectedIndex! < _footerSocialLinks.length)
        ? _footerSocialLinks[s.selectedIndex!]
        : null;

    String truncateUrl(String url) {
      final clean = url
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll('www.', '');
      return clean.length > 38 ? '${clean.substring(0, 38)}…' : clean;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Link'),
          SizedBox(height: 8.h),
          Container(
            height: 36.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  child: Center(
                    child: (link != null && link.iconUrl.isNotEmpty)
                        ? NetworkImageView(
                            url: link.iconUrl,
                            width: 20.w, height: 20.w, fit: BoxFit.contain,
                          )
                        : Icon(Icons.link,
                            size: 16.sp, color: ColorPick.primary),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    link != null ? truncateUrl(link.url) : '—',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Office Locations Section ──────────────────────────────────────────────

  Widget _officeLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._officeLocationItems.map(_officeLocationWidget).toList(),
        Padding(
          padding: EdgeInsets.only(top: 10.sp),
          child: GestureDetector(
            onTap: _addOfficeLocation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                  color: const Color(0xFF797979),
                  borderRadius: BorderRadius.circular(4.r)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CustomSvg(
                  assetPath: 'assets/add.svg',
                  width:  14.sp,
                  height: 14.sp,
                  color:  Colors.white,
                ),
                SizedBox(width: 4.w),
                Text('Location',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: Colors.white)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _officeLocationWidget(_OfficeLocationItem o) {
    return Container(
      margin: EdgeInsets.only(bottom: 0.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _imageUploadCircle(
                label: 'Icon',
                bytes: o.iconBytes,
                url:   o.iconUrl,
                onTap: () async {
                  final b = await _pickImage(allowSvg: true);
                  if (b != null) setState(() => o.iconBytes = b);
                },
                isSvg: true,
              ),
              GestureDetector(
                onTap: () => _removeOfficeLocation(o.id),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color:        ColorPick.red,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Remove',
                    style: StyleText.fontSize12Weight600.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Location Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Location Name'),
                    SizedBox(height: 8.h),
                    CustomValidatedTextFieldMaster(
                      hint:          'Text Here',
                      controller:    o.locationNameEnCtrl,
                      height:        42,
                      maxLines:      1,
                      fillColor: Colors.white,
                      maxLength:     10000,
                      submitted:     _submitted,
                      textDirection: TextDirection.ltr,
                      textAlign:     TextAlign.start,
                      onChanged:     (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _fieldLabelAr('اسم الموقع'),
                    SizedBox(height: 8.h),
                    CustomValidatedTextFieldMaster(
                      hint:          'أدخل النص هنا',
                      controller:    o.locationNameArCtrl,
                      fillColor: Colors.white,
                      height:        42,
                      maxLines:      1,
                      maxLength:     10000,
                      submitted:     _submitted,
                      textDirection: TextDirection.rtl,
                      textAlign:     TextAlign.right,
                      onChanged:     (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Text'),
                    SizedBox(height: 8.h),
                    CustomValidatedTextFieldMaster(
                      hint:          'Text Here',
                      fillColor: Colors.white,
                      controller:    o.text1EnCtrl,
                      height:        42,
                      maxLines:      1,
                      maxLength:     10000,
                      submitted:     _submitted,
                      textDirection: TextDirection.ltr,
                      textAlign:     TextAlign.start,
                      onChanged:     (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _fieldLabelAr('النص'),
                    SizedBox(height: 8.h),
                    CustomValidatedTextFieldMaster(
                      hint:          'أدخل النص هنا',
                      fillColor: Colors.white,
                      controller:    o.text1ArCtrl,
                      height:        42,
                      maxLines:      1,
                      maxLength:     10000,
                      submitted:     _submitted,
                      textDirection: TextDirection.rtl,
                      textAlign:     TextAlign.right,
                      onChanged:     (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),

          _fieldLabel('Google Maps Link'),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  hint:          'https://maps.google.com/?q=...',
                  controller:    o.mapLinkCtrl,
                  height:        42,
                  fillColor: Colors.white,
                  maxLines:      1,
                  maxLength:     10000,
                  submitted:     false,
                  textDirection: TextDirection.ltr,
                  textAlign:     TextAlign.start,
                  onChanged:     (_) => setState(() {}),
                ),
              ),
              SizedBox(width: 15.sp),
              Expanded(child: Container())
            ],
          ),
        ],
      ),
    );
  }

  Widget _confirmMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.h),
        _imageUploadCircle(
          label: 'SVG',
          bytes: _confirmSvgBytes,
          url:   _confirmSvgUrl,
          onTap: () async {
            final b = await _pickSvgFile();
            if (b != null) setState(() => _confirmSvgBytes = b);
          },
          isSvg: true,
        ),
        SizedBox(height: 20.h),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Title'),
                  SizedBox(height: 8.h),
                  CustomValidatedTextFieldMaster(
                    hint:          'Text Here',
                    fillColor: Colors.white,
                    controller:    _confirmTitleEnCtrl,
                    height:        42,
                    maxLines:      1,
                    maxLength:     10000,
                    submitted:     _submitted,
                    textDirection: TextDirection.ltr,
                    textAlign:     TextAlign.start,
                    onChanged:     (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _fieldLabelAr('العنوان'),
                  SizedBox(height: 8.h),
                  CustomValidatedTextFieldMaster(
                    hint:          'أدخل النص هنا',
                    controller:    _confirmTitleArCtrl,
                    height:        42,
                    fillColor: Colors.white,
                    maxLines:      1,
                    maxLength:     10000,
                    submitted:     _submitted,
                    textDirection: TextDirection.rtl,
                    textAlign:     TextAlign.right,
                    onChanged:     (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Description'),
            SizedBox(height: 8.h),
            CustomValidatedTextFieldMaster(
              hint:          'Text Here',
              controller:    _confirmDescEnCtrl,
              height:        100,
              fillColor: Colors.white,
              maxLines:      4,
              maxLength:     10000,
              showCharCount: false,
              submitted:     _submitted,
              textDirection: TextDirection.ltr,
              textAlign:     TextAlign.start,
              onChanged:     (_) => setState(() {}),
            ),
            SizedBox(height: 16.h),
            _fieldLabelAr('الوصف'),
            SizedBox(height: 8.h),
            CustomValidatedTextFieldMaster(
              hint:          'أدخل النص هنا',
              controller:    _confirmDescArCtrl,
              fillColor: Colors.white,
              height:        100,
              maxLines:      4,
              maxLength:     500,
              showCharCount: false,
              submitted:     _submitted,
              textDirection: TextDirection.rtl,
              textAlign:     TextAlign.right,
              onChanged:     (_) => setState(() {}),
            ),
          ],
        ),
      ],
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────

  Widget _actionButtons() {
    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return EditActionButtons(
      onPreview: _openDraftPreview, // BUG-52 / BUG-53
      onPublish: _handlePublish,
      // BUG-105: same "Discard Changes?" dialog as Main / Home.
      onDiscard: () => confirmDiscard(
        context,
        onDiscard: () => context.goNamed('contact-cms'),
      ),
    );
  }

  // ── Saving Overlay ────────────────────────────────────────────────────────

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width:  180.w,
          height: 100.h,
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleProgress(),
              SizedBox(height: 12.h),
              Text(
                'Saving...',
                style: StyleText.fontSize14Weight400.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Helpers ────────────────────────────────────────────────────────

  Widget _imageUploadCircle({
    required String       label,
    required Uint8List?   bytes,
    required String       url,
    required VoidCallback onTap,
    bool isSvg = false,
  }) {
    // Delegates to the single shared image-upload circle (core/custom).
    return imageUploadCircle(label: label, bytes: bytes, url: url, onTap: onTap);
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: StyleText.fontSize13Weight600.copyWith(
      color: Colors.black87,
    ),
  );

  Widget _fieldLabelAr(String text) => Align(
    alignment: Alignment.centerRight,
    child: Text(
      text,
      style: StyleText.fontSize13Weight600.copyWith(
        color: Colors.black87,
      ),
    ),
  );

  Widget _btn({
    required String       label,
    required Color        color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Center(
          child: Text(
            label,
            style: StyleText.fontSize15Weight600.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
