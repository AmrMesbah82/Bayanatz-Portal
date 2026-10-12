part of '../../pages/why_join_edit.dart';

extension _WhyJoinEditUi on _CareersSectionEditPageState {
  Widget _itemEditWidget(int index, _ItemEdit item) {
    final iconHasError = _submitted && index == 0 && !item.icon.hasImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
        ] else
          SizedBox(height: 12.h),

        if (index == 0) ...[
          Row(children: [
            Text('Icon', style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
            Text(' *', style: StyleText.fontSize12Weight600.copyWith(color: Colors.red)),
          ]),
          SizedBox(height: 6.h),
          _imgBox(picked: item.icon, isAdd: true, hasError: iconHasError, onPick: () async {
            final p = await _pickImage();
            if (p != null) setState(() => item.icon = p);
          }),
          if (iconHasError) ...[
            SizedBox(height: 4.h),
            Text('Icon (SVG) is required', style: StyleText.fontSize11Weight400.copyWith(color: Colors.red)),
          ],
          SizedBox(height: 14.h),
          Row(children: [
            Expanded(
              child: CustomValidatedTextFieldMaster(
                label: 'Title', hint: 'Text Here', controller: item.titleEn,
                height: 36, fillColor: Colors.white, submitted: _submitted,
                textDirection: TextDirection.ltr, textAlign: TextAlign.left,
                primaryColor: ColorPick.primary, isRequired: true,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: CustomValidatedTextFieldMaster(
                  label: 'العنوان', hint: 'أدخل النص هنا', controller: item.titleAr,
                  height: 36, fillColor: Colors.white, submitted: _submitted,
                  textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                  primaryColor: ColorPick.primary, isRequired: true,
                ),
              ),
            ),
          ]),
          SizedBox(height: 14.h),
        ],

        // First reason is mandatory — it can never be removed.
        if (index > 0) ...[
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _items.removeAt(index)),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(color: ColorPick.red, borderRadius: BorderRadius.circular(4.r)),
                  child: Text('Remove', style: StyleText.removeButton.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
        ],

        // BUG-211: per-reason illustration (Figma "Editing Why Join Our Team
        // Details" — an "SVG" circle on every reason). Optional; the public
        // page shows it beside the text (Items_N_Svg_Url) instead of an
        // empty gap.
        Text('SVG (illustration, optional)',
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _imgBox(picked: item.svg, onPick: () async {
              final p = await _pickImage();
              if (p != null) setState(() => item.svg = p);
            }),
            if (item.svg.hasImage) ...[
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: () => setState(() => item.svg = const _PickedImage()),
                child: Text('Remove image',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: ColorPick.red)),
              ),
            ],
          ],
        ),
        SizedBox(height: 14.h),

        CustomValidatedTextFieldMaster(
          showCharCount: false, maxLength: 500,
          label: 'Description', hint: 'Text Here', controller: item.descEn,
          height: 80, maxLines: 3, fillColor: Colors.white, submitted: _submitted,
          textDirection: TextDirection.ltr, textAlign: TextAlign.left,
          primaryColor: ColorPick.primary, isRequired: true,
        ),
        SizedBox(height: 8.h),

        Directionality(
          textDirection: TextDirection.rtl,
          child: CustomValidatedTextFieldMaster(
            showCharCount: false, maxLength: 500,
            label: 'الوصف', hint: 'أدخل النص هنا', controller: item.descAr,
            height: 80, maxLines: 3, fillColor: Colors.white, submitted: _submitted,
            textDirection: TextDirection.rtl, textAlign: TextAlign.right,
            primaryColor: ColorPick.primary, isRequired: true,
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _imgBox({required _PickedImage picked, bool isAdd = false, bool hasError = false, VoidCallback? onPick}) {
    // Delegates to the single shared image-upload circle (core/custom).
    return imageUploadCircleBare(
      bytes: picked.bytes,
      url: picked.url ?? '',
      onTap: onPick ?? () {},
    );
  }

  // Was a hand-rolled header bar with a Material chevron icon, its own radius
  // and its own padding — one of two accordions in careers that did not match
  // the rest of the app. Now the shared component, with no overrides, so every
  // accordion in the admin looks and animates the same.
  Widget _accordion({required String title, required List<Widget> children}) {
    return CustomAccordion(
      title:    title,
      isOpen:   _accordionOpen,
      onToggle: () => setState(() => _accordionOpen = !_accordionOpen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _bottomButtons(CareersSectionCubit cubit) {
    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return EditActionButtons(
      isSaving: _isSaving,
      onPreview: () {
        // BUG-53 (same issue here): the preview reads the cubit, so copy the
        // unsaved form into it first — otherwise it shows the old text.
        _syncToCubit(cubit);
        Navigator.push(context, MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CareersSectionPreviewPage(
              sectionKey: widget.sectionKey, sectionTitle: widget.sectionTitle),
        ),
        ));
      },
      onPublish: () => _handlePublish(cubit),
      // BUG-105: ask before throwing the edits away (same dialog as Main).
      onDiscard: () => confirmDiscard(context, onDiscard: () {
        // Preview copies unsaved edits into the cubit; drop them on Discard.
        cubit.load();
        Navigator.pop(context);
      }),
      // BUG-63: adding / removing a Reason or picking an icon never marked
      // the page as changed, so Publish stayed dead. Validation still runs.
      requireChanges: false,
    );
  }
}
