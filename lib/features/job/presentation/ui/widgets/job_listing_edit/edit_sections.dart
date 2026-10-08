// ******************* FILE INFO *******************
// Part of: job_listing_edit.dart
// Contains: _jobInfoSection, _jobDetailsSection, _benefitsSection
// NOTE: the confirm dialog now comes from the shared
//       core/custom/16-custom_dialog_manager.dart (CustomDialogManager).

part of '../../pages/job_listing_edit.dart';

/// The ONE label style for every field title in the job edit form — text
/// fields, dropdowns and date pickers alike. Because every control renders
/// its label the same way (label line + 6.h gap), one shared style is what
/// keeps the titles of a row aligned on the same horizontal line.
///
/// It lives in the theme (StyleText.fieldLabel) so the read-only Job Details
/// tab renders its titles with exactly the same size and weight.
TextStyle get _kFieldLabelStyle => StyleText.fieldLabel;

extension _JobEditSections on _JobListingEditPageState {
  // ── Departments come from the Departments feature (Firestore), not a
  //    static list. Falls back to _kDepartments while loading / on error. ──
  List<Map<String, String>> _departmentItems(BuildContext context) {
    final state = context.watch<DepartmentCubit>().state;
    List<DepartmentModel> deps = [];
    if (state is DepartmentLoaded) {
      deps = state.departments;
    } else if (state is DepartmentError && state.lastDepartments != null) {
      deps = state.lastDepartments!;
    }
    if (deps.isEmpty) return _kDepartments;
    final items = deps
        .where((d) => d.nameEn.isNotEmpty)
        .map((d) => {'key': d.nameEn, 'value': d.nameEn})
        .toList();
    // Keep the currently selected department visible even if it was
    // deleted from the Departments feature (legacy jobs).
    if (_department != null &&
        _department!.isNotEmpty &&
        !items.any((m) => m['key'] == _department)) {
      items.add({'key': _department!, 'value': _department!});
    }
    return items;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  1. JOB INFORMATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _jobInfoSection() {
    return Padding(
      padding: EdgeInsets.only(top:  16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Figma (Create New Job Post): "Text Here" placeholders.
              Expanded(child: _field('Job Title', 'Text Here', _titleEn)),
              SizedBox(width: 16.w),
              Expanded(
                child: _fieldRtl('المسمى الوظيفي', 'أدخل النص هنا', _titleAr),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomDropdownFormFieldInvMaster(
                  label: 'Department',
                  labelStyle: _kFieldLabelStyle,
                  hint: Text('Select Department',
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText)),
                  selectedValue: _department,
                  items: _departmentItems(context),
                  primaryColor: _cmsPrimary(context),
                  widthIcon: 18,
                  heightIcon: 18,
                  height: 36,
                  //dropdownColor: AppColors.card,
                  onChanged: (val) => setState(() => _department = val),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomDropdownFormFieldInvMaster(
                        label: 'Work Type',
                        labelStyle: _kFieldLabelStyle,
                        // dropdownColor: AppColors.background,
                        hint: Text('Select Work Type',
                            style: StyleText.fontSize12Weight400
                                .copyWith(color: AppColors.secondaryText)),
                        selectedValue: _workType,
                        items: _kWorkTypes,
                        primaryColor: _cmsPrimary(context),
                        widthIcon: 18,
                        heightIcon: 18,
                        height: 36,
                        onChanged: (val) => setState(() {
                          _workType = val;
                          // Location only applies to On Site / Hybrid
                          if (val == 'Remotely') _jobLocation = null;
                        }),
                      ),
                    ),
                    // ── Location — only for On Site / Hybrid, items come
                    //    from the Contact Us office locations ──
                    if (_workType == 'On Site' || _workType == 'Hybrid') ...[
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomDropdownFormFieldInvMaster(
                          label: 'Location',
                          labelStyle: _kFieldLabelStyle,
                          hint: Text('Select Location',
                              style: StyleText.fontSize12Weight400
                                  .copyWith(color: AppColors.secondaryText)),
                          // BUG-47: offices from Contact Us + "Other location…"
                          // (the list used to offer only "Cairo, Egypt").
                          selectedValue: _locationIsCustom
                              ? _kOtherLocationKey
                              : _jobLocation,
                          items: _locationItems(context),
                          primaryColor: _cmsPrimary(context),
                          widthIcon: 18,
                          heightIcon: 18,
                          height: 36,
                          onChanged: (val) => setState(() {
                            if (val == _kOtherLocationKey) {
                              _locationIsCustom = true;
                              _jobLocation = _otherLocation.text.trim().isEmpty
                                  ? null
                                  : _otherLocation.text.trim();
                            } else {
                              _locationIsCustom = false;
                              _jobLocation = val;
                            }
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // BUG-47: free-text location when "Other location…" is picked.
          if (_locationIsCustom &&
              (_workType == 'On Site' || _workType == 'Hybrid')) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(width: 16.w),
                Expanded(
                  child: CustomTextField(
                    controller: _otherLocation,
                    hint: 'Text Here',
                    height: 36,
                    submitted: _submitted,
                    onChanged: (v) => setState(() =>
                        _jobLocation = v.trim().isEmpty ? null : v.trim()),
                    valueStyle: StyleText.fontSize12Weight400
                        .copyWith(fontSize: 12.sp, color: AppColors.text),
                    hintStyle: StyleText.fontSize12Weight400.copyWith(
                        fontSize: 12.sp, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ],
          Row(
            children: [
              Expanded(child: _requiredError(_submitted && _department == null)),
              SizedBox(width: 16.w),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _requiredError(_submitted && _workType == null)),
                    if (_workType == 'On Site' || _workType == 'Hybrid') ...[
                      SizedBox(width: 8.w),
                      Expanded(
                          child: _requiredError(
                              _submitted && _jobLocation == null)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomDropdownFormFieldInvMaster(
                  label: 'Employment Type',
                  labelStyle: _kFieldLabelStyle,
                  //dropdownColor: AppColors.card,
                  hint: Text('Select Employment Type',
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText)),
                  selectedValue: _employmentType,
                  items: _kEmploymentTypes,
                  widthIcon: 18,
                  primaryColor: _cmsPrimary(context),
                  heightIcon: 18,
                  height: 36,
                  onChanged: (val) => setState(() => _employmentType = val),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                // No wrapper Column / manual top offset: the label line of
                // every control has the same height, so the row aligns itself.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field('Employment Duration', 'Text Number', _durationText,
                          onlyDigits: true), // numbers only (Figma hint "Text Number")
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 120.w,
                      child: CustomDropdownFormFieldInvMaster(
                        // Empty (not null) label: reserves the same label line
                        // so the control lines up with the one beside it.
                        label: '',
                        labelStyle: _kFieldLabelStyle,
                        hint: Text('Duration',
                            style: StyleText.fontSize12Weight400
                                .copyWith(color: AppColors.secondaryText)),
                        primaryColor: _cmsPrimary(context),
                        selectedValue: _durationType,
                        items: _kDurations,
                        // dropdownColor: AppColors.background,
                        widthIcon: 18,
                        heightIcon: 18,
                        height: 36,
                        onChanged: (val) =>
                            setState(() => _durationType = val),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _requiredError(_submitted && _employmentType == null)),
              SizedBox(width: 16.w),
              Expanded(child: _requiredError(_submitted && _durationType == null)),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomDropdownFormFieldInvMaster(
                  label: 'Experience Levels',
                  labelStyle: _kFieldLabelStyle,
                  // dropdownColor: AppColors.background,
                  hint: Text('Select Experience Level',
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText)),
                  primaryColor: _cmsPrimary(context),
                  selectedValue: _experienceLevel,
                  items: _kExperienceLevels,
                  widthIcon: 18,
                  heightIcon: 18,
                  height: 36,
                  onChanged: (val) => setState(() => _experienceLevel = val),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field('Salary Range', 'Min Salary', _salaryMin,
                          onlyDigits: true), // numbers only
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                        child: _field('  ', 'Max Salary', _salaryMax,
                            onlyDigits: true)), // numbers only
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 90.w,
                      child: CustomDropdownFormFieldInvMaster(
                        label: '',
                        labelStyle: _kFieldLabelStyle,
                        hint: Text('Currency',
                            style: StyleText.fontSize12Weight400
                                .copyWith(color: AppColors.secondaryText)),
                        selectedValue: _currency,
                        items: _kCurrencies,
                        widthIcon: 18,
                        primaryColor: _cmsPrimary(context),
                        heightIcon: 18,
                        height: 36,
                        // dropdownColor: AppColors.background,
                        onChanged: (val) => setState(() => _currency = val),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _requiredError(_submitted && _experienceLevel == null)),
              SizedBox(width: 16.w),
              Expanded(child: _requiredError(_submitted && (_currency == null || _currency!.isEmpty))),
            ],
          ),
          // BUG-28: max salary must be ≥ min salary.
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(width: 16.w),
              Expanded(child: _inlineError(_salaryError)),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field('Required Qualification', 'Text Here', _qualificationEn),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _fieldRtl('المؤهلات المطلوبة', 'أدخل النص هنا', _qualificationAr),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          // BUG-08: the "Required Skills" row used to be built from
          // `TextEditingController()` created inside build() — a throw-away
          // controller nobody read, so the first skill was never saved. The
          // first row is now simply the first entry of _skills and carries
          // the section label.
          ...List.generate(
            _skills.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              // BUG-156: the Arabic field reached only to the (−) button, so
              // its label ended 34 px before every other Arabic label, and the
              // (−) showed even with a single skill. The (−) now sits BETWEEN
              // the two fields and only when there is more than one skill.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _field(i == 0 ? 'Required Skills' : '',
                        'Text Here',
                        _skills[i]['en']!,
                        required: false),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 24.sp,
                    child: _skills.length > 1
                        ? Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _skills[i]['en']!.dispose();
                                _skills[i]['ar']!.dispose();
                                _skills.removeAt(i);
                              }),
                              child: Tooltip(
                                message: 'Remove skill',
                                // Figma zondicons:minus-solid (20×20, red).
                                child: Icon(Icons.remove_circle,
                                    size: 20.sp, color: ColorPick.red),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _fieldRtl(i == 0 ? 'المهارات المطلوبة' : '',
                        'أدخل النص هنا', _skills[i]['ar']!,
                        required: false),
                  ),
                ],
              ),
            ),
          ),
          // A half-filled skill row (only one language) is flagged.
          if (_submitted && !_skillsOk)
            _inlineError('Fill in both the English and Arabic skill name.'),

          GestureDetector(
            onTap: () => setState(
              () => _skills.add({
                'en': TextEditingController(),
                'ar': TextEditingController(),
              }),
            ),
            child: _addButton('Skill'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  2. JOB DETAILS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _jobDetailsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical:  16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Figma (Create New Job Post): "Text Here" placeholders.
          _field('About This Position', 'Text Here', _aboutEn, maxLines: 4, height: 100),
          SizedBox(height: 10.sp),
          _fieldRtl('', 'أدخل النص هنا', _aboutAr, maxLines: 4, height: 100),
          SizedBox(height: 10.sp),
          _field('Requirements', 'Text Here', _requirementsEn, maxLines: 4, height: 100),
          SizedBox(height: 10.sp),
          _fieldRtl('', 'أدخل النص هنا', _requirementsAr, maxLines: 4, height: 100),
          SizedBox(height: 10.sp),
          _field('Preferred Skills', 'Text Here', _prefSkillsEn, maxLines: 4, height: 100),
          SizedBox(height: 10.sp),
          _fieldRtl('', 'أدخل النص هنا', _prefSkillsAr, maxLines: 4, height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  3. BENEFITS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _benefitsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical:  16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_benefits.length, (i) {
            final b = _benefits[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Benefit ${i + 1}',
                      style: StyleText.fontSize13Weight600.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        b.values.forEach((c) => c.dispose());
                        _benefits.removeAt(i);
                      }),
                      child: Container(
                        width: 20.sp,
                        height: 20.sp,
                        decoration: const BoxDecoration(
                          color: ColorPick.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.remove, color: Colors.white, size: 14.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.sp),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field('Title', 'Text Here', b['titleEn']!),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _fieldRtl('العنوان', 'أدخل النص هنا', b['titleAr']!),
                    ),
                  ],
                ),
                SizedBox(height: 10.sp),
                _field('Short Description', 'One or two sentences about this benefit', b['descEn']!, maxLines: 3, height: 80),
                SizedBox(height: 10.sp),
                _fieldRtl('وصف مختصر', 'جملة أو جملتان عن هذه الميزة', b['descAr']!, maxLines: 3, height: 80),
                SizedBox(height: 16.h),
                if (i < _benefits.length - 1)
                  const Divider(color: Color(0xFFE8E8E8)),
              ],
            );
          }),
          GestureDetector(
            onTap: () => setState(
              () => _benefits.add({
                'titleEn': TextEditingController(),
                'titleAr': TextEditingController(),
                'descEn': TextEditingController(),
                'descAr': TextEditingController(),
              }),
            ),
            child: _addButton('Benefits'),
          ),
        ],
      ),
    );
  }
}
