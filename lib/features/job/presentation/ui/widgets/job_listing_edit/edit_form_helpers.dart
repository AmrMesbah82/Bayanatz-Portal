// ******************* FILE INFO *******************
// Part of: job_listing_edit.dart
// Contains: _applicationDetailsSection, _dateFieldCalendar, _docRow,
//           _bottomButtons (shared EditActionButtons), _accordion,
//           _field, _fieldRtl, _addButton

part of '../../pages/job_listing_edit.dart';

extension _JobEditFormHelpers on _JobListingEditPageState {
  // ═══════════════════════════════════════════════════════════════════════════
  //  4. APPLICATION DETAILS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _applicationDetailsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateFieldCalendar(
                  label: 'Hiring Timeline (Start Date)',
                  date: _hiringStart,
                  onPicked: _setHiringStart,
                  // BUG-28: no picking past days for a new start date.
                  firstDate: _today,
                  // Locked only once hiring has actually started (BUG-29).
                  enabled: !_timelineLocked,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _dateFieldCalendar(
                  label: 'Hiring Timeline (End Date)',
                  date: _hiringEnd,
                  onPicked: _setHiringEnd,
                  // BUG-28/29: end date is always editable (extend / shorten a
                  // deadline) but must be after the start and not in the past.
                  firstDate: _latest(
                    _today,
                    _hiringStart?.add(const Duration(days: 1)),
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _hiringStart == null
                    ? _requiredError(_submitted && _hiringStart == null)
                    : _inlineError(_submitted ? _startDateError : null),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _hiringEnd == null
                    ? _requiredError(_submitted && _hiringEnd == null)
                    : _inlineError(_endDateError),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Maximum Number of Applications for This Position',
                  'e.g. 100', // BUG-129
                  _maxApps,
                  onlyDigits: true, // numbers only
                ),
              ),
              SizedBox(width: 16.w),
              const Expanded(child: SizedBox()),
            ],
          ),
          _inlineError(_maxAppsError), // BUG-28
          SizedBox(height: 10.sp),
          Text(
            'Required Documents',
            style: _kFieldLabelStyle,
          ),
          SizedBox(height: 8.h),
          // One document per row — each has an English name, an Arabic name,
          // a type dropdown and a Required / Optional switch.
          ...List.generate(
            _requiredDocs.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _docRow(i),
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => setState(
              () => _requiredDocs.add({
                'name': TextEditingController(),
                'nameAr': TextEditingController(),
                'type': 'PDF',
                'required': true,
              }),
            ),
            child: _addButton('Required Document'),
          ),
        ],
      ),
    );
  }

  // Uses the shared CustomDropdownCalendar (core/custom/4-custom_dropdwon_calander.dart)
  Widget _dateFieldCalendar({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    bool enabled = true,
  }) {
    return CustomDropdownCalendar(
      label: label,
      enabled: enabled,
      hint: 'Select Date',
      value: date,
      height: 36,
      firstDate: firstDate,
      fillColor: AppColors.card,
      borderRadius: BorderRadius.circular(4.r),
      labelStyle: _kFieldLabelStyle,
      hintStyle: StyleText.fontSize12Weight400
          .copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
      valueStyle: StyleText.fontSize12Weight400
          .copyWith(fontSize: 12.sp, color: AppColors.text),
      dateFormatter: (d) => DateFormat('d MMM yyyy').format(d), // BUG-304
      onChanged: (d) {
        if (d != null) onPicked(d);
      },
    );
  }

  Widget _docRow(int i) {
    final bool isRequired = _requiredDocs[i]['required'] as bool? ?? true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Document name (English) ──────────────────────────────────────────
        Expanded(
          flex: 3,
          child: CustomTextField(
            controller: _requiredDocs[i]['name'] as TextEditingController,
            // BUG-88: an empty row blocked Save with nothing highlighted.
            submitted: _submitted,
            height: 36,
            valueStyle: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp),
            hint: 'Document Name',
            hintStyle:
                StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        // ── Document name (Arabic) ───────────────────────────────────────────
        Expanded(
          flex: 3,
          child: CustomTextField(
            controller: _requiredDocs[i]['nameAr'] as TextEditingController,
            height: 36,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.right,
            valueStyle: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp),
            hint: 'اسم المستند',
            hintStyle:
                StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        // ── Type ─────────────────────────────────────────────────────────────
        SizedBox(
          width: 90.w,
          child: CustomDropdownFormFieldInvMaster(
            dropdownColor: AppColors.card,
            selectedValue: _requiredDocs[i]['type'] as String? ?? 'PDF',
            items: _kDocTypes,
            widthIcon: 16,
            heightIcon: 16,
            primaryColor: _cmsPrimary(context),
            height: 36,
            hint: Text(
              'Type',
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
            onChanged: (v) => setState(() => _requiredDocs[i]['type'] = v),
          ),
        ),
        SizedBox(width: 12.w),
        // ── Required / Optional switch ───────────────────────────────────────
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isRequired ? 'Required' : 'Optional',
              style: StyleText.fontSize11Weight400
                  .copyWith(color: AppColors.text),
            ),
            SizedBox(height: 4.h),
            Transform.scale(
              scale: 0.8,
              child: FlutterSwitch(
                value: isRequired,
                activeColor: ColorPick.primary,
                activeToggleColor: Colors.white,
                inactiveColor: Colors.grey.shade400,
                inactiveToggleColor: Colors.white,
                width: 46.0,
                height: 27.0,
                toggleSize: 21.0,
                borderRadius: 13.5,
                padding: 3.0,
                onToggle: (val) =>
                    setState(() => _requiredDocs[i]['required'] = val),
              ),
            ),
          ],
        ),
        // ── BUG-88: remove this row (flowchart 1:9311 / 1:9668) ──────────────
        SizedBox(width: 8.w),
        if (_requiredDocs.length > 1)
          Tooltip(
            message: 'Remove document',
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => setState(() {
                final removed = _requiredDocs.removeAt(i);
                (removed['name'] as TextEditingController).dispose();
                (removed['nameAr'] as TextEditingController).dispose();
              }),
              child: Padding(
                padding: EdgeInsets.all(4.sp),
                child: Icon(Icons.remove_circle, // Figma zondicons:minus-solid 20×20
                    size: 20.sp, color: ColorPick.red),
              ),
            ),
          )
        else
          SizedBox(width: 20.sp + 8.sp),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _bottomButtons() {
    final bool isEdit = _editingJobId != null;

    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    //
    // Editing an existing post:
    //   • "Publish" becomes "Save" — the post already exists.
    //   • "Save For Later" is gone — drafting only applies to a new post.
    //   • Save stays disabled until something on the form actually changes.
    // The AnimatedBuilder listens to every text controller so typing flips
    // Save on without needing a listener on each field.
    return AnimatedBuilder(
      animation: Listenable.merge(_allControllers()),
      builder: (context, _) => EditActionButtons(
        onPreview: () => navigateTo(
          context,
          // BUG-09: preview what is on the form now, not a placeholder.
          JobListingPreviewPage(
            jobId: _editingJobId ?? 'new',
            draft: _buildModel(
              publishStatus: _editingJobId == null ? 'draft' : 'published',
            ),
            onSave: _publish, // BUG-91: Save in the preview really saves
          ),
        ),
        onPublish:      _publish,
        publishLabel:   isEdit ? 'Save' : 'Publish',
        publishEnabled: isEdit ? _hasChanges : true,
        publishDisabledTooltip:
            isEdit ? 'No changes to save' : 'Fill in all required fields to publish',
        isSaving:       _isSaving,
        // BUG-12: the app-wide "dirty" flag only notices text fields and
        // dropdowns, so flipping the Job Status switch (or picking a date)
        // never enabled Save. This page has its own exact change check
        // (_hasChanges covers every field, the switch and the dates).
        requireChanges: false,
        // BUG-89: Discard threw the whole form away without asking.
        onDiscard: () => confirmDiscard(
          context,
          hasChanges: _hasChanges,
          onDiscard: () => Navigator.of(context).maybePop(),
        ),
        // BUG-90: "Save For Later" in edit mode too (→ back to Draft).
        onSaveForLater: _saveDraft,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ACCORDION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _accordion({
    required String key,
    required String title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FIELD HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // The label is rendered by the shared CustomTextField via its own `label`
  // parameter — never as a separate Text widget stacked on top.
  Widget _field(
    String label,
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
    double height = 36,
    bool required = true,
    bool onlyDigits = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    final bool isMultiline = maxLines > 1;
    return CustomTextField(
      label: label.isNotEmpty ? label : null,
      labelStyle: _kFieldLabelStyle,
      hint: hint,
      controller: ctrl,
      // BUG-290 / BUG-274: cross-field errors (salary) use the field's own
      // red border + message, and the page re-checks them while typing.
      errorText: errorText,
      onChanged: onChanged,
      suffixIcon: suffixIcon,
      height: isMultiline ? null : height,
      maxLines: maxLines,
      // Multiline descriptions: no cap — supports long markdown content
      maxLength: isMultiline ? null : 500,
      submitted: _submitted && required, // inline "required" error after Post
      // Numeric fields: blocks non-digit input + validates value
      onlyDigits: onlyDigits,
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.start,
      valueStyle: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.text),
      hintStyle: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
    );
  }

  Widget _fieldRtl(
    String label,
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
    double height = 36,
    bool required = true,
    Widget? suffixIcon,
  }) {
    final bool isMultiline = maxLines > 1;
    // Directionality wrapper: AR label + hint + text all start from the RIGHT.
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: CustomTextField(
        label: label.isNotEmpty ? label : null,
        labelStyle: _kFieldLabelStyle,
        hint: hint,
        controller: ctrl,
        suffixIcon: suffixIcon,
        height: isMultiline ? null : height,
        maxLines: maxLines,
        // Multiline descriptions: no cap — supports long markdown content
        maxLength: isMultiline ? null : 500,
        submitted: _submitted && required, // inline "required" error after Post
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.start,
        valueStyle: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.text),
        hintStyle: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
      ),
    );
  }

  DateTime _latest(DateTime a, DateTime? b) =>
      (b != null && b.isAfter(a)) ? b : a;

  /// A cross-field validation message (BUG-28), shown as soon as it applies.
  Widget _inlineError(String? message) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            message,
            style: StyleText.fontSize11Weight400
                .copyWith(fontSize: 11.sp, color: ColorPick.red),
          ),
        );

  /// BUG-290: dropdowns now show this through their own errorText (red
  /// border + message, same as text fields).
  String? _reqMsg(bool show) => show ? 'This field is required.' : null;

  /// Inline "required" message shown under date pickers, which have no
  /// built-in error support.
  Widget _requiredError(bool show) => show
      ? Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            'This field is required.',
            style: StyleText.fontSize11Weight400
                .copyWith(fontSize: 11.sp, color: ColorPick.red),
          ),
        )
      : const SizedBox.shrink();

  Widget _addButton(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFF797979),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            label,
            style: StyleText.fontSize12Weight500.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
