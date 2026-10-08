// ******************* FILE INFO *******************
// Part of: services_digital_main.dart
// Contains: _buildItemAccordion, _buildAccordion, _actionButtons,
//           _iconPreview, _labelStyle, _ordinal

part of '../../pages/digital_services/services_digital_main.dart';

extension _DigitalEditUi on _ServicesDigitalJourneyEditPageState {
  // ── Ordinal helper ────────────────────────────────────────────────────────────
  String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  // ── Per-item accordion ────────────────────────────────────────────────────────
  Widget _buildItemAccordion(int i) {
    final c      = _itemCtrls[i];
    final isOpen = _itemOpen[i];

    return _buildAccordion(
      title: '${_ordinal(i + 1)} Digital Journey',
      isOpen: isOpen,
      onToggle: () => setState(() => _itemOpen[i] = !isOpen),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon row ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Icon', style: _labelStyle()),
                GestureDetector(
                  onTap: () => _removeItem(i),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                        color: Colors.red, borderRadius: BorderRadius.circular(6.r)),
                    child: Text('Remove',
                        style: StyleText.fontSize12Weight600
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _iconPreview(c.iconUrl,
                isLoading: c.iconUrl == 'loading', onPick: () => _uploadIcon(i)),
            SizedBox(height: 6.h),

            // ── Title fields ────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Title *', style: _labelStyle()),
              Text('العنوان *', style: _labelStyle()),
            ]),
            SizedBox(height: 6.h),
            Row(children: [
              Expanded(
                child: CustomTextField(
                  controller: c.titleEnCtrl,
                  hint: 'Text Here',
                  isRequired: true,
                  submitted: _submitted,
                  primaryColor: ColorPick.primary,
                  fillColor: Colors.white,
                  textDirection: TextDirection.ltr,
                  height: 36,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextField(
                  controller: c.titleArCtrl,
                  hint: 'أدخل النص هنا',
                  isRequired: true,
                  submitted: _submitted,
                  primaryColor: ColorPick.primary,
                  fillColor: Colors.white,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  height: 36,
                ),
              ),
            ]),
            SizedBox(height: 14.h),

            // ── Description fields ──────────────────────────────────────────
            Text('Description *', style: _labelStyle()),
            SizedBox(height: 6.h),
            CustomTextField(
              controller: c.descEnCtrl,
              hint: 'Text Here',
              isRequired: true,
              submitted: _submitted,
              primaryColor: ColorPick.primary,
              textDirection: TextDirection.ltr,
              maxLines: 4,
              height: 100,
              fillColor: Colors.white,
              showCharCount: false,
              maxLength: 500,
            ),
            SizedBox(height: 14.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text('الوصف *', style: _labelStyle()),
            ),
            SizedBox(height: 6.h),
            CustomTextField(
              controller: c.descArCtrl,
              hint: 'أدخل النص هنا',
              isRequired: true,
              submitted: _submitted,
              fillColor: Colors.white,
              primaryColor: ColorPick.primary,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 4,
              height: 100,
              showCharCount: false,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable accordion ────────────────────────────────────────────────────────
  Widget _buildAccordion({
    required String       title,
    required bool         isOpen,
    required VoidCallback onToggle,
    required Widget       child,
  }) {
    // Thin wrapper kept so the existing call sites stay unchanged. The widget
    // itself now lives in core/custom/3-custom_accordion.dart and is shared
    // across the app.
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: onToggle,
      child:    child,
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────────
  // This page used to hand-roll its own ElevatedButtons (green Preview, 8.r
  // corners, a one-off grey Discard). They no longer matched Home or any other
  // edit page. Now it uses the SAME shared widget as every other edit page, so
  // the radius, the colours and the disabled behaviour are defined once in
  // core/main_widgets/edit_action_buttons.dart.
  Widget _actionButtons() {
    return EditActionButtons(
      onPreview: _onPreview,
      onDiscard: _onDiscard,
      isSaving:  _isSaving,
      publishLabel:   'Publish', // BUG-80: was 'Published'
      publishEnabled: _isFormValid(),
      publishDisabledTooltip:
          'Fill in all required fields and add an icon to publish',
      onPublish: () => showPublishConfirmDialog(
        context: context,
        title: 'EDITING SERVICES DETAILS',
        subtitle:
            'Do you want to save the changes made to this Service Details?',
        confirmLabel: 'Publish', // BUG-80
        onConfirm: _onSave,
      ),
      // Tapping a blocked Publish already paints the red borders; this also
      // flips the page's own _submitted flag so its per-field checks agree.
      onPublishBlocked: () => setState(() => _submitted = true),
    );
  }

  // ── Icon preview widget ───────────────────────────────────────────────────────
  // Delegates to the single shared image-upload circle (core/custom).
  Widget _iconPreview(String url, {bool isLoading = false, VoidCallback? onPick}) {
    if (isLoading || url == 'loading') {
      return Container(
        width: 60.w, height: 60.h,
        decoration: const BoxDecoration(color: Color(0xFFD9D9D9), shape: BoxShape.circle),
        child: Center(
          child: SizedBox(
            width: 24.w, height: 24.h,
            child: CircleProgress(),
          ),
        ),
      );
    }

    return imageUploadCircleBare(
      bytes: null,
      url: (url.isNotEmpty && url.startsWith('http')) ? url : '',
      onTap: onPick ?? () {},
    );
  }

  TextStyle _labelStyle() =>
      StyleText.fontSize12Weight600.copyWith(color: AppColors.text);
}
