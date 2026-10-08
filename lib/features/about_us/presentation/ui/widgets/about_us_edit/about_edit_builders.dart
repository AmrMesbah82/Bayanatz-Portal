part of '../../pages/about_us_edit.dart';

extension _AboutEditBuilders on _AboutEditPageMasterState {
  // ═════════════════════════════════════════════════════════════════════════
  // FORM
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Row(
          children: [
            Text(
              'Editing About Us',
              style: StyleText.fontSize45Weight600.copyWith(
                color: ColorPick.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),




        // ── Headings ──
        _accordion(
          title: 'Headings',
          isOpen: _headingsOpen,
          onToggle: () => setState(() => _headingsOpen = !_headingsOpen),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _headingsSection(),
          ),
        ),
        SizedBox(height: 15.h),
        // ── Navigation Label ──
        _accordion(
          title: 'Navigation Label',
          isOpen: _navigationLabelOpen,
          onToggle: () =>
              setState(() => _navigationLabelOpen = !_navigationLabelOpen),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _navigationLabelSection(),
          ),
        ),



        SizedBox(height: 15.h),

        // ── Vision ──
        _accordion(
          title: 'Vision',
          isOpen: _visionOpen,
          onToggle: () => setState(() => _visionOpen = !_visionOpen),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _sectionEditor(
              iconBytes: _visionIconBytes,
              svgBytes: _visionSvgBytes,
              iconUrl: _visionIconUrl,
              svgUrl: _visionSvgUrl,
              onPickIcon: () async {
                final b = await _pickImageIcon();
                if (b != null) setState(() => _visionIconBytes = b);
              },
              onPickSvg: () async {
                final b = await _pickSvgFile();
                if (b != null) setState(() => _visionSvgBytes = b);
              },
              subEnCtrl: _visionSubEnCtrl,
              subArCtrl: _visionSubArCtrl,
              descEnCtrl: _visionDescEnCtrl,
              descArCtrl: _visionDescArCtrl,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // ── Mission ──
        _accordion(
          title: 'Mission',
          isOpen: _missionOpen,
          onToggle: () => setState(() => _missionOpen = !_missionOpen),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _sectionEditor(
              iconBytes: _missionIconBytes,
              svgBytes: _missionSvgBytes,
              iconUrl: _missionIconUrl,
              svgUrl: _missionSvgUrl,
              onPickIcon: () async {
                final b = await _pickImageIcon();
                if (b != null) setState(() => _missionIconBytes = b);
              },
              onPickSvg: () async {
                final b = await _pickSvgFile();
                if (b != null) setState(() => _missionSvgBytes = b);
              },
              subEnCtrl: _missionSubEnCtrl,
              subArCtrl: _missionSubArCtrl,
              descEnCtrl: _missionDescEnCtrl,
              descArCtrl: _missionDescArCtrl,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // ── Values ──
        _accordion(
          title: 'Values',
          isOpen: _valuesOpen,
          onToggle: () => setState(() => _valuesOpen = !_valuesOpen),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _valuesSection(),
          ),
        ),
        SizedBox(height: 16.h),

        _actionButtons(),
        SizedBox(height: 48.h),
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
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: onToggle,
      child:    child,
    );
  }

  // ── Headings section ───────────────────────────────────────────────────────
  Widget _headingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _fieldLabel('Title'),
            Spacer(),
            _fieldLabelAr("العنوان"),
          ],
        ),
        SizedBox(height: 8.h),
        _bilingualRow(
          enCtrl: _titleEnCtrl,
          arCtrl: _titleArCtrl,
          enHint: 'Text Here',
          arHint: 'أدخل النص هنا',
        ),
      ],
    );
  }

  // ── Navigation Label section ───────────────────────────────────────────────
  Widget _navigationLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imageUploadCircle(
          label: 'Icon',
          bytes: _navIconBytes,
          url: _navIconUrl,
          onTap: () async {
            final b = await _pickImageIcon();
            if (b != null) setState(() => _navIconBytes = b);
          },
          isSvg: false,
          showError:
              _submitted && _navIconBytes == null && _navIconUrl.isEmpty,
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            _fieldLabel('Title'),
            Spacer(),
            _fieldLabelAr("العنوان"),
          ],
        ),
        SizedBox(height: 8.h),
        _bilingualRow(
          enCtrl: _navTitleEnCtrl,
          arCtrl: _navTitleArCtrl,
          enHint: 'Text Here',
          arHint: 'أدخل النص هنا',
        ),
      ],
    );
  }

  // ── Vision / Mission section editor ───────────────────────────────────────
  Widget _sectionEditor({
    required Uint8List? iconBytes,
    required Uint8List? svgBytes,
    required String iconUrl,
    required String svgUrl,
    required VoidCallback onPickIcon,
    required VoidCallback onPickSvg,
    required TextEditingController subEnCtrl,
    required TextEditingController subArCtrl,
    required TextEditingController descEnCtrl,
    required TextEditingController descArCtrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _imageUploadCircle(
              label: 'Icon',
              bytes: iconBytes,
              url: iconUrl,
              onTap: onPickIcon,
              isSvg: false,
              showError: _submitted && iconBytes == null && iconUrl.isEmpty,
            ),
            SizedBox(width: 24.w),
            _imageUploadCircle(
              label: 'SVG',
              bytes: svgBytes,
              url: svgUrl,
              onTap: onPickSvg,
              isSvg: true,
              showError: _submitted && svgBytes == null && svgUrl.isEmpty,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _fieldLabel('Sub description'),
        SizedBox(height: 8.h),
        CustomValidatedTextFieldMaster(
          hint: 'Text Here',
          controller: subEnCtrl,
          fillColor: Colors.white,
          height: 100,
          maxLines: 4,
          maxLength: 10000,
          showCharCount: false,
          submitted: _submitted,
          isRequired: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          primaryColor: ColorPick.primary,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        _fieldLabelAr('وصف فرعي'),
        SizedBox(height: 4.h),
        CustomValidatedTextFieldMaster(
          hint: 'أدخل النص هنا',
          fillColor: Colors.white,
          controller: subArCtrl,
          height: 100,
          maxLines: 4,
          maxLength: 10000,
          showCharCount: false,
          submitted: _submitted,
          isRequired: true,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          primaryColor: ColorPick.primary,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        _fieldLabel('Description'),
        SizedBox(height: 8.h),
        CustomValidatedTextFieldMaster(
          hint: 'Text Here',
          controller: descEnCtrl,
          fillColor: Colors.white,
          height: 100,
          maxLines: 4,
          maxLength: 500,
          showCharCount: false,
          submitted: _submitted,
          isRequired: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          primaryColor: ColorPick.primary,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        _fieldLabelAr('الوصف'),
        SizedBox(height: 4.h),
        CustomValidatedTextFieldMaster(
          hint: 'أدخل النص هنا',
          controller: descArCtrl,
          height: 100,
          fillColor: Colors.white,
          maxLines: 4,
          maxLength: 500,
          showCharCount: false,
          submitted: _submitted,
          isRequired: true,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          primaryColor: ColorPick.primary,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VALUES SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _valuesSection() {
    if (_valueItems.isEmpty) {
      return Column(
        children: [
          _addValueButton(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_valueItems.length, (index) {
          final v = _valueItems[index];
          final bool isMain = index == 0;
          return _valueItemWidget(v, isMain: isMain);
        }),
        SizedBox(height: 16.h),
        _addValueButton(),
      ],
    );
  }

  Widget _addValueButton() {
    return GestureDetector(
      onTap: _addValueItem,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFF797979),
          // 4.r — the app's button radius. This one was 8.r and read as a
          // different, rounder button than the identical "add" chips elsewhere.
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The app's own plus asset, not the Material glyph — same icon the
            // Bullet Point / Paragraph / Numbering chips use.
            CustomSvg(
              assetPath: 'assets/plus.svg',
              width:  14.w,
              height: 14.w,
              fit:    BoxFit.scaleDown,
              color:  Colors.white,
            ),
            SizedBox(width: 6.w),
            Text(
              'Add Value',
              style: StyleText.label.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueItemWidget(_ValueItem v, {required bool isMain}) {
    final String itemLabel = isMain ? 'Main Icon' : 'Icon';
    final bool showIconError =
        _submitted && v.iconBytes == null && v.iconUrl.isEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _imageUploadCircle(
                label: itemLabel,
                bytes: v.iconBytes,
                url: v.iconUrl,
                isSvg: false,
                showError: showIconError,
                onTap: () async {
                  final b = await _pickImageIcon();
                  if (b != null) setState(() => v.iconBytes = b);
                },
              ),
              // Main (first) value is mandatory — it can never be removed.
              if (!isMain)
                GestureDetector(
                  onTap: () => _removeValueItem(v.id),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Remove',
                      style: StyleText.removeButton
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          // Title (EN + AR) is NOT used for the Main Icon on the user site —
          // only "Add Point" items show/need it.
          if (!isMain) ...[
            Row(
              children: [
                _fieldLabel('Title'),
                Spacer(),
                _fieldLabelAr("العنوان"),
              ],
            ),
            SizedBox(height: 8.h),
            _bilingualRow(
              enCtrl: v.titleEnCtrl,
              arCtrl: v.titleArCtrl,
              enHint: 'Text Here',
              arHint: 'أدخل النص هنا',
            ),
            SizedBox(height: 16.h),
          ],
          _fieldLabel('Short Description'),
          SizedBox(height: 8.h),
          CustomValidatedTextFieldMaster(
            hint: 'Text Here',
            controller: v.shortDescEnCtrl,
            height: 100,
            fillColor: Colors.white,
            maxLines: 4,
            maxLength: 10000,
            showCharCount: false,
            submitted: _submitted,
            isRequired: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            primaryColor: ColorPick.primary,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16.h),
          _fieldLabelAr('وصف مختصر'),
          SizedBox(height: 4.h),
          CustomValidatedTextFieldMaster(
            hint: 'أدخل النص هنا',
            controller: v.shortDescArCtrl,
            fillColor: Colors.white,
            height: 100,
            maxLines: 4,
            maxLength: 10000,
            showCharCount: false,
            submitted: _submitted,
            isRequired: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            primaryColor: ColorPick.primary,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _actionButtons() {
    final bool formValid = _isFormValid;

    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return EditActionButtons(
      publishEnabled: formValid,
      onPreview:      formValid ? _onPreview : null,
      onPublish:      () => _showPublishConfirmDialog(),
      onSaveForLater: () { if (formValid) _showSaveDraftDialog(); },
      onDiscard: () {
        confirmDiscard(context, onDiscard: () => Navigator.of(context).pop());
      },
    );
  }

  void _showPublishConfirmDialog() {
    setState(() => _submitted = true);

    if (!_validateFields()) {
      _showValidationError();
      return;
    }

    showPublishConfirmDialog(
      context: context,
      title: 'EDITING ABOUT US DETAILS',
      subtitle: 'Do you want to save the changes made to this About Us?',
      confirmLabel: 'Publish',
      onConfirm: () => _save('published'),
    );
  }

  void _showSaveDraftDialog() {
    setState(() => _submitted = true);

    if (!_validateFields()) {
      _showValidationError();
      return;
    }

    showPublishConfirmDialog(
      context: context,
      title: 'SAVE AS DRAFT',
      subtitle: 'Do you want to save this page as a draft?',
      confirmLabel: 'Save Draft',
      onConfirm: () => _save('draft'),
    );
  }
}
