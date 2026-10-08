part of '../../pages/terms_page/terms_edit.dart';

extension _TermsEditWidgets on _TermsEditPageState {
  // ── Standardized Image Widget ─────────────────────────────────────────────
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

  // ── Section Editor ────────────────────────────────────────────────────────
  Widget _sectionEditor({
    required _PickedImage iconPicked,
    required TextEditingController titleEnCtrl,
    required TextEditingController titleArCtrl,
    required VoidCallback onPickIcon,
    required TextEditingController descEnCtrl,
    required TextEditingController descArCtrl,
    required _DocItem docEn,
    required _DocItem docAr,
    required VoidCallback onPickDocEn,
    required VoidCallback onPickDocAr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        // ── Navigation icon + title (drives the section's tab) ──────────────
        _fieldLabel('Icon'),
        SizedBox(height: 8.h),
        _imgBox(picked: iconPicked, onPick: onPickIcon),
        SizedBox(height: 16.h),
        _fieldLabel('Title'),
        SizedBox(height: 8.h),
        _bilingualRow(
          enCtrl: titleEnCtrl,
          arCtrl: titleArCtrl,
          enHint: 'Text Here',
          arHint: 'أدخل النص هنا',
        ),
        SizedBox(height: 16.h),
        _fieldLabel('Description'),
        SizedBox(height: 8.h),
        CustomValidatedTextFieldMaster(
          fillColor: Colors.white,

          hint: 'Text Here',
          controller: descEnCtrl,
          height: 120,
          maxLines: 5,
          maxLength: 100000,
          showCharCount: false,
          submitted: false,
          isRequired: false,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          primaryColor: ColorPick.primary,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 8.h),
        _fieldLabelAr('الوصف'),
        SizedBox(height: 4.h),
        CustomValidatedTextFieldMaster(
          fillColor: Colors.white,
          hint: 'أدخل النص هنا',
          controller: descArCtrl,
          height: 120,
          maxLines: 5,
          maxLength: 100000,
          showCharCount: false,
          submitted: false,
          isRequired: false,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          primaryColor: ColorPick.primary,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _docUploadField(
              label: 'Attach English Document',
              docItem: docEn,
              onPick: onPickDocEn,
              onRemove: () => setState(() {
                docEn.bytes = null;
                docEn.fileName = '';
                docEn.existingUrl = '';
                _checkForChanges();
              }),
            )),
            SizedBox(width: 16.w),
            Expanded(child: _docUploadField(
              label: 'Attach Arabic Document',
              docItem: docAr,
              onPick: onPickDocAr,
              onRemove: () => setState(() {
                docAr.bytes = null;
                docAr.fileName = '';
                docAr.existingUrl = '';
                _checkForChanges();
              }),
            )),
          ],
        ),
      ],
    );
  }

  // ── Doc Upload Field ──────────────────────────────────────────────────────
  Widget _docUploadField({
    required String label,
    required _DocItem docItem,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        SizedBox(height: 8.h),
        docItem.hasFile
            ? Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r)),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/pdf 1.svg',
                width: 28.w,
                height: 28.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(docItem.displayName,
                    style: StyleText.fontSize16Weight400
                        .copyWith(color: AppColors.text),
                    overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 16.w, height: 16.h,
                  decoration: BoxDecoration(
                      color: _kRed, shape: BoxShape.circle),
                  child: Icon(Icons.remove,
                      color: Colors.white, size: 14.sp),
                ),
              ),
            ],
          ),
        )
            : GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            height: 34.h,
            decoration: BoxDecoration(
                color: ColorPick.primary,
                borderRadius: BorderRadius.circular(4.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomSvg(assetPath: "assets/Upload.svg"),
                SizedBox(width: 8.w),
                Text('Attach Document',
                    style: StyleText.fontSize13Weight600
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Accordion ─────────────────────────────────────────────────────────────
  Widget _accordion({
    required String title,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    // No style overrides — the shared accordion exactly as every other page in
    // the admin uses it, so the header colour, radius and chevron all come from
    // core/custom/3-custom_accordion.dart.
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: onToggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(12.r))),
        child: child,
      ),
    );
  }

  // ── Bilingual Row ─────────────────────────────────────────────────────────
  Widget _bilingualRow({
    required TextEditingController enCtrl,
    required TextEditingController arCtrl,
    required String enHint,
    required String arHint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomValidatedTextFieldMaster(
            fillColor: Colors.white,
            hint: enHint,
            controller: enCtrl,
            height: 42,
            maxLines: 1,
            maxLength: 100000,
            submitted: false,
            isRequired: false,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            primaryColor: ColorPick.primary,
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomValidatedTextFieldMaster(
            fillColor: Colors.white,
            hint: arHint,
            controller: arCtrl,
            height: 42,
            maxLines: 1,
            maxLength: 100000,
            submitted: false,
            isRequired: false,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            primaryColor: ColorPick.primary,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ── Field Labels ──────────────────────────────────────────────────────────
  Widget _fieldLabel(String t) => Text(t,
      style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text));

  Widget _fieldLabelAr(String t) => Align(
    alignment: Alignment.centerRight,
    child: Text(t,
        style: StyleText.fontSize13Weight600
            .copyWith(color: Colors.black87)),
  );

  // ── Button ────────────────────────────────────────────────────────────────
  Widget _btn({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 48.h,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8.r)),
          child: Center(
            child: Text(label,
                style: StyleText.fontSize16Weight400
                    .copyWith(color: AppColors.white)),
          ),
        ),
      );

  // ── Saving Overlay ────────────────────────────────────────────────────────
  Widget _savingOverlay() => Container(
    color: Colors.black54,
    child: Center(
      child: Container(
        width: 180.w, height: 100.h,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleProgress(),
            SizedBox(height: 12.h),
            Text('Saving...',
                style: StyleText.fontSize14Weight400
                    .copyWith(color: Colors.black87)),
          ],
        ),
      ),
    ),
  );
}
