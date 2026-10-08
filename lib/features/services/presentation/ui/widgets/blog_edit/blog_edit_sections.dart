// ******************* FILE INFO *******************
// Part of: blog_edit.dart
// Contains: _postInfoContent, _buttonContent, _descriptionContent,
//           _blockWidget, _actionButtons, _accordion, _addChip, _labelStyle

part of '../../pages/blog_services/blog_edit.dart';

extension _BlogEditSections on _BlogCreateEditPageState {
  // ── Remove button (left) + Active/Inactive switch (right) ────────────────────
  Widget _removeAndStatusRow() {
    return Row(
      children: [
        // Remove button (only when editing an existing post)
        if (_isEdit)
          CustomDeleteIcon(
            svgColor: Colors.white,
            textStyle: StyleText.fontSize12Weight400.copyWith(
              color: Colors.white
            ),
            title: 'Remove',
            onTap: _confirmRemove,
          ),
        const Spacer(),
        // The Active/Inactive switch only makes sense for a post that already
        // exists. On "Create New" there is nothing to deactivate yet — a new
        // post is created active — so the toggle is hidden there.
        if (_isEdit) ...[
          Text(
            _isActive ? 'Active' : 'Inactive',
            style: StyleText.fontSize12Weight500.copyWith(
              color: _isActive
                  ? ColorPick.activeColor
                  : ColorPick.inactiveColor,
            ),
          ),
          SizedBox(width: 6.w),
          FlutterSwitch(
            width: 35.sp,
            height: 20.sp,
            padding: 3.sp,
            borderRadius: 20.sp,
            toggleSize: 16.sp,
            activeColor: ColorPick.primary,
            inactiveColor: Colors.grey.withValues(alpha: .16),
            value: _isActive,
            onToggle: (val) {
              setState(() => _isActive = val);
              // BUG-61: the switch alone is a change worth publishing.
              _markDirty();
            },
          ),
        ],
      ],
    );
  }

  // ── Post Info ─────────────────────────────────────────────────────────────────
  Widget _postInfoContent() {
    final bool imageError =
        _submitted && _imageBytes == null && _existingImageUrl.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SVG image picker (shared image-upload circle) ────────────────────
        imageUploadCircleBare(
          bytes: _imageBytes,
          url: _existingImageUrl,
          onTap: _pickImage,
        ),
        SizedBox(height: 10.h),

        // ── Question ──────────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Question', style: _labelStyle()),
          Text('سؤال',    style: _labelStyle()),
        ]),
        SizedBox(height: 6.h),
        Row(children: [
          Expanded(
            child: CustomTextField(
              controller: _questionEnCtrl,
              hint: 'Text Here', isRequired: true, submitted: _submitted,
              fillColor: Colors.white, primaryColor: ColorPick.primary,
              textDirection: TextDirection.ltr, height: 40,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomTextField(
              controller: _questionArCtrl,
              hint: 'أكتب هنا', submitted: _submitted, fillColor: Colors.white,
              isRequired: true, primaryColor: ColorPick.primary,
              textDirection: TextDirection.rtl, textAlign: TextAlign.right, height: 40,
            ),
          ),
        ]),
        SizedBox(height: 6.h),
        // ── Short description ─────────────────────────────────────────────────
        // BUG-70: the 150-character limit used to cut text silently. The
        // limit is now stated and a live "n / 150" note appears under each box.
        Text('Short Description (max 150 characters)', style: _labelStyle()),
        SizedBox(height: 6.h),
        CustomTextField(
          controller: _shortDescEnCtrl, hint: 'Text Here', fillColor: Colors.white,
          submitted: _submitted, maxLength: 150, showCharCount: false,
          isRequired: true, primaryColor: ColorPick.primary,
          textDirection: TextDirection.ltr, maxLines: 4, height: 100,
          onChanged: (_) => setState(() {}),
        ),
        _charLimitNote(_shortDescEnCtrl, 150, TextAlign.left),
        Align(alignment: Alignment.centerRight,
            child: Text('وصف مختصر (150 حرفًا كحد أقصى)', style: _labelStyle())),
        SizedBox(height: 6.h),
        CustomTextField(
          controller: _shortDescArCtrl, hint: 'أكتب هنا', fillColor: Colors.white,
          isRequired: true, submitted: _submitted, maxLength: 150, showCharCount: false,
          primaryColor: ColorPick.primary, textDirection: TextDirection.rtl,
          textAlign: TextAlign.right, maxLines: 4, height: 100,
          onChanged: (_) => setState(() {}),
        ),
        _charLimitNote(_shortDescArCtrl, 150, TextAlign.right),
      ],
    );
  }

  // ── Button ────────────────────────────────────────────────────────────────────
  Widget _buttonContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Label',  style: _labelStyle()),
        Text('تسمية', style: _labelStyle()),
      ]),
      SizedBox(height: 6.h),
      Row(children: [
        Expanded(
          child: CustomTextField(
            controller: _btnLabelEnCtrl, hint: 'Text Here', fillColor: Colors.white,
            submitted: _submitted, isRequired: true, primaryColor: ColorPick.primary,
            textDirection: TextDirection.ltr, height: 40,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomTextField(
            controller: _btnLabelArCtrl, fillColor: Colors.white, hint: 'أكتب هنا',
            submitted: _submitted, primaryColor: ColorPick.primary, isRequired: true,
            textDirection: TextDirection.rtl, textAlign: TextAlign.right, height: 40,
          ),
        ),
      ]),
    ]);
  }

  // ── Description ───────────────────────────────────────────────────────────────
  Widget _descriptionContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Title',    style: _labelStyle()),
        Text('العنوان', style: _labelStyle()),
      ]),
      SizedBox(height: 6.h),
      Row(children: [
        Expanded(
          child: CustomTextField(
            controller: _descTitleEnCtrl, hint: 'Text Here', isRequired: true,
            submitted: _submitted, primaryColor: ColorPick.primary,
            fillColor: Colors.white, textDirection: TextDirection.ltr, height: 40,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomTextField(
            controller: _descTitleArCtrl, hint: 'أكتب هنا', submitted: _submitted,
            fillColor: Colors.white, isRequired: true, primaryColor: ColorPick.primary,
            textDirection: TextDirection.rtl, textAlign: TextAlign.right, height: 40,
          ),
        ),
      ]),

      ..._blocks.asMap().entries.map((e) => Padding(
        padding:  EdgeInsets.only(top: 8.sp),
        child: _blockWidget(idx: e.key, blk: e.value),
      )),


      SizedBox(height: 10.h),
      Wrap(spacing: 10.w, runSpacing: 8.h, children: [
        _addChip('Bullet Point', () => _addBlock(BlogBlockType.bulletPoint)),
        _addChip('Paragraph',    () => _addBlock(BlogBlockType.paragraph)),
        _addChip('Numbering',    () => _addBlock(BlogBlockType.numbering)),
      ]),
    ]);
  }

  /// 1-based position of the numbering block at [idx] among the numbering
  /// blocks only — paragraphs and bullet points in between don't advance it.
  int _numberingOrdinal(int idx) {
    int n = 0;
    for (int i = 0; i <= idx && i < _blocks.length; i++) {
      if (_blocks[i]['type'] == BlogBlockType.numbering) n++;
    }
    return n == 0 ? 1 : n;
  }

  // ── Block widget ──────────────────────────────────────────────────────────────
  Widget _blockWidget({required int idx, required Map<String, dynamic> blk}) {
    final type   = blk['type'] as BlogBlockType;
    final enCtrl = blk['enCtrl'] as TextEditingController;
    final arCtrl = blk['arCtrl'] as TextEditingController;
    final int    enMaxLines = type == BlogBlockType.paragraph ? 20 : 6;
    final double enHeight   = type == BlogBlockType.paragraph ? 180 : 90;
    // A numbering block shows its position among the NUMBERING blocks, not its
    // position in the block list. `idx + 1` counted paragraphs and bullets too,
    // so adding the first numbered item after two paragraphs printed "3.".
    final String prefix = switch (type) {
      BlogBlockType.numbering   => '${_numberingOrdinal(idx)}.',
      BlogBlockType.bulletPoint => '•',
      BlogBlockType.paragraph   => '',
    };
    final String typeLabel = switch (type) {
      BlogBlockType.numbering   => 'Numbering',
      BlogBlockType.bulletPoint => 'Bullet Point',
      BlogBlockType.paragraph   => 'Paragraph',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (prefix.isNotEmpty)
            Text('$prefix  ',
                style: StyleText.fontSize13Weight500
                    .copyWith(color: AppColors.text, fontWeight: FontWeight.w600)),
          Text('$typeLabel',
              style: StyleText.fontSize12Weight500.copyWith(color: Colors.black)),
          const Spacer(),
          // Remove-block control: the minus mirrors the "+" on the Add chips
          // below, so add and remove read as the same pair.
          GestureDetector(
            onTap: () => _removeBlock(idx),
            child: CustomSvg(
              assetPath: 'assets/minus.svg',
              width:  14.w,
              height: 14.w,
              fit:    BoxFit.scaleDown,
              color:  ColorPick.red,
            ),
          ),
        ]),
        SizedBox(height: 6.h),
        CustomTextField(
          controller: enCtrl, fillColor: Colors.white, hint: 'Text Here',
          submitted: _submitted, isRequired: true, maxLength: 10000,
          primaryColor: ColorPick.primary, textDirection: TextDirection.ltr,
          maxLines: enMaxLines, height: enHeight,
        ),
        SizedBox(height: 8.h),
        Align(alignment: Alignment.centerRight,
            child: Text('بالعربية', style: _labelStyle())),
        SizedBox(height: 4.h),
        CustomTextField(
          controller: arCtrl, fillColor: Colors.white, hint: 'أكتب هنا',
          isRequired: true, submitted: _submitted, primaryColor: ColorPick.primary,
          maxLength: 10000, textDirection: TextDirection.rtl,
          textAlign: TextAlign.right, maxLines: enMaxLines, height: enHeight,
        ),
      ]),
    );
  }

  // BUG-70: "n / max" under a limited field; red when the limit is reached.
  Widget _charLimitNote(TextEditingController c, int max, TextAlign align) {
    final int n = c.text.characters.length;
    return Padding(
      padding: EdgeInsets.only(top: 2.h, bottom: 4.h),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          n >= max ? '$n / $max — limit reached' : '$n / $max',
          textAlign: align,
          style: StyleText.fontSize12Weight400.copyWith(
            color: n >= max ? ColorPick.red : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  // ── Action buttons (shared widget — one place for ALL edit pages) ─────────────
  Widget _actionButtons() {
    return EditActionButtons(
      onPreview:      _preview,
      onPublish:      _publish,
      onDiscard:      _discard,
      onSaveForLater: _saveForLater,
      publishEnabled: _isPublishEnabled,
      // BUG-60: publishing a Draft (or re-activating an Inactive read) IS the
      // change — it must not wait for a text edit. Only an already-live,
      // still-active post needs an actual edit before Publish lights up.
      requireChanges: _isEdit &&
          !_isEditingDraft &&
          widget.existing?.status == 'published' &&
          _isActive,
      publishDisabledTooltip:
          'Fill in all required fields and add an SVG image to publish',
    );
  }

  // ── Accordion ─────────────────────────────────────────────────────────────────
  Widget _accordion({
    required String       key,
    required String       title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _addChip(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: const Color(0xff797979), borderRadius: BorderRadius.circular(4.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomSvg(
            assetPath: 'assets/plus.svg',
            width: 14.w,
            height: 14.w,
            fit: BoxFit.scaleDown,
            color: Colors.white,
          ),
          SizedBox(width: 6.w),
          Text(label,
              style: StyleText.fontSize12Weight500.copyWith(color: Colors.white)),
        ],
      ),
    ),
  );

  TextStyle _labelStyle() =>
      StyleText.fontSize12Weight600.copyWith(color: AppColors.text);
}
