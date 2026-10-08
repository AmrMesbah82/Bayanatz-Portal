part of '../../pages/our_teams_edit.dart';

extension _OurTeamsEditUi on _OurTeamsEditPageState {
  Widget _itemWidget(int index, _TeamItemEdit item) {
    final iconHasError = _submitted && !item.icon.hasImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
          Divider(color: const Color(0xFFE8E8E8), height: 1),
          SizedBox(height: 12.h),
        ] else
          SizedBox(height: 12.h),

        // ── Section header (icon + title) — first team only ─────────────────
        if (index == 0) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1 — SVG icon
              Row(children: [
                Text('Icon',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: AppColors.text)),
              ]),
              SizedBox(height: 6.h),
              _imgBox(
                picked: _headerIcon,
                hasError: _submitted && !_headerIcon.hasImage,
                onPick: () async {
                  final p = await _pickSvg();
                  if (p != null) setState(() => _headerIcon = p);
                },
              ),
              if (_submitted && !_headerIcon.hasImage) ...[
                SizedBox(height: 4.h),
                Text('Icon (SVG) is required',
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: Colors.red)),
              ],
              SizedBox(height: 14.h),
              // Row 2 — Title EN / AR
              Row(children: [
                Expanded(
                  child: CustomValidatedTextFieldMaster(
                    label: 'Title', hint: 'Text Here',
                    controller: _headerTitleEnCtrl,
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
                      label: 'العنوان', hint: 'أدخل النص هنا',
                      controller: _headerTitleArCtrl,
                      height: 36, fillColor: Colors.white, submitted: _submitted,
                      textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                      primaryColor: ColorPick.primary, isRequired: true,
                    ),
                  ),
                ),
              ]),
            ],
          ),
          SizedBox(height: 12.h),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Icon', style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
                ]),
                SizedBox(height: 6.h),
                _imgBox(
                  picked: item.icon,
                  hasError: iconHasError,
                  onPick: () async {
                    final p = await _pickSvg();
                    if (p != null) setState(() { _isDirty = true; item.icon = p; });
                  },
                ),
                if (iconHasError) ...[
                  SizedBox(height: 4.h),
                  Text('Icon (SVG) is required', style: StyleText.fontSize11Weight400.copyWith(color: ColorPick.red)),
                ],
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() { _isDirty = true; _items.removeAt(index); }),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(color: ColorPick.red, borderRadius: BorderRadius.circular(4.r)),
                child: Text('Remove', style: StyleText.fontSize12Weight500.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
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
                height: 36, fillColor: AppColors.card, submitted: _submitted,
                textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                primaryColor: ColorPick.primary, isRequired: true,
              ),
            ),
          ),
        ]),
        SizedBox(height: 0.h),

        CustomValidatedTextFieldMaster(
          label: 'Description', hint: 'Text Here', controller: item.descEn,
          height: 80, maxLines: 3, fillColor: Colors.white, submitted: _submitted,
          textDirection: TextDirection.ltr, textAlign: TextAlign.left,
          primaryColor: ColorPick.primary, isRequired: true,
        ),
        SizedBox(height: 8.h),

        Directionality(
          textDirection: TextDirection.rtl,
          child: CustomValidatedTextFieldMaster(
            label: 'الوصف', hint: 'أدخل النص هنا', controller: item.descAr,
            height: 80, maxLines: 3, fillColor: Colors.white, submitted: _submitted,
            textDirection: TextDirection.rtl, textAlign: TextAlign.right,
            primaryColor: ColorPick.primary, isRequired: true,
          ),
        ),
        SizedBox(height: 14.h),

        ...item.deliverables.asMap().entries.map((e) => _deliverableRow(e.key, e.value, item)),
        SizedBox(height: 8.h),

        GestureDetector(
          onTap: () => setState(() { _isDirty = true; item.deliverables.add(_DeliverableEdit(id: const Uuid().v4())); }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(color: const Color(0xFF797979), borderRadius: BorderRadius.circular(4.r)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 16.sp),
                SizedBox(width: 6.w),
                Text('Deliverables', style: StyleText.fontSize13Weight500.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _deliverableRow(int index, _DeliverableEdit d, _TeamItemEdit item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: CustomValidatedTextFieldMaster(
              label: index == 0 ? 'Deliverable' : '', hint: 'Text Here',
              controller: d.enCtrl, height: 36, fillColor: Colors.white,
              submitted: _submitted, textDirection: TextDirection.ltr,
              textAlign: TextAlign.left, primaryColor: ColorPick.primary, isRequired: true,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CustomValidatedTextFieldMaster(
                label: index == 0 ? 'المخرجات' : '', hint: 'أدخل النص هنا',
                controller: d.arCtrl, height: 36, fillColor: Colors.white,
                submitted: _submitted, textDirection: TextDirection.rtl,
                textAlign: TextAlign.right, primaryColor: ColorPick.primary, isRequired: true,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => setState(() { _isDirty = true; item.deliverables.removeAt(index); }),
            child: Container(
              width: 20.w, height: 20.h,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Icon(Icons.remove, color: Colors.white, size: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgBox({required _PickedImage picked, bool hasError = false, VoidCallback? onPick}) {
    // Delegates to the single shared image-upload circle (core/custom).
    return imageUploadCircleBare(
      bytes: picked.bytes,
      url: picked.url ?? '',
      onTap: onPick ?? () {},
    );
  }



  // Was a hand-rolled header bar whose chevron rotated the wrong way (0.5 turns
  // when OPEN, so it pointed down while expanded). Now the shared component,
  // which rotates the other way and matches every other accordion in the app.
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

  Widget _bottomButtons(OurTeamsCubit cubit) {
    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return EditActionButtons(
      isSaving: _isSaving,
      onPreview: () {
        // BUG-53: show the unsaved edits, not the saved teams.
        _syncToCubit(cubit);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) =>
              BlocProvider.value(value: cubit, child: const OurTeamsPreviewPage()),
        ));
      },
      onPublish: () => _handlePublish(cubit),
      // BUG-105: ask before throwing the edits away (same dialog as Main).
      onDiscard: () => confirmDiscard(context, onDiscard: () {
        cubit.load(); // drop edits the preview copied into the cubit
        Navigator.pop(context);
      }),
      // BUG-64: adding a team / deliverable or picking an icon never marked
      // the page as changed. Publish now always runs (and validates, with a
      // message) instead of being silently blocked.
      requireChanges: false,
    );
  }
}
