// ******************* FILE INFO *******************
// Part of: application_detail.dart
// Contains: _buildPersonalInfoCard, _buildTagsScoringCard,
//           _sectionTitle, _readOnlyField, _fileCard

part of '../../pages/application_detail.dart';

extension _ApplicationDetailCards on _ApplicationDetailPageState {
  // ═══════════════════════════════════════════════════════════════════════════
  //  PERSONAL INFORMATION + PROFILE INFORMATION CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPersonalInfoCard(ApplicationModel app) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: ColorPick.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information'),
          SizedBox(height: 12.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _readOnlyField('First Name', app.firstName)),
              SizedBox(width: 16.w),
              Expanded(child: _readOnlyField('Last Name', app.lastName)),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _readOnlyField('Email', app.email, capitalize: false)),
              SizedBox(width: 16.w),
              Expanded(
                child: _readOnlyField('Phone', '${app.countryCode} ${app.phone}'),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _readOnlyField('Year Of Graduation', app.yearOfGraduation),
              ),
              SizedBox(width: 16.w),
              const Expanded(child: SizedBox()),
            ],
          ),

          SizedBox(height: 20.h),

          _sectionTitle('Profile Information'),
          SizedBox(height: 12.h),
          _profileDocuments(app),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAGS + SCORING INTERVIEW CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTagsScoringCard(ApplicationModel app, Color cmsPrimary) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information'),
          SizedBox(height: 12.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                         
                  child: CustomDropdownFormFieldInvMaster(
                    label: 'Tags',
                    selectedValue: _selectedTag,
                    items: _kTagItems,
                    widthIcon: 18,
                    heightIcon: 18,
                    height: 36,
                    primaryColor: cmsPrimary,
                    dropdownColor: const Color(0xFFF1F2ED),
                    itemColors: _kTagColors,
                    showColorDots: true,
                    hint: Text(
                      'Select Tag',
                      style: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
                    ),
                    onChanged: (v) => setState(() => _selectedTag = v),
                  ),
                ),
              ),
              SizedBox(width: 10.sp),
              Expanded(child: SizedBox())
            ],
          ),
          SizedBox(height: 24.h),

          _sectionTitle('Scoring Interview'),
          SizedBox(height: 12.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  label: 'Technical Skills',
                  hint: 'Text Here, 1-5 Scoring',
                  controller: _technicalCtrl,
                  height: 36,
                  onlyDigits: true,
                  submitted: false,
                  primaryColor: cmsPrimary,
                  fillColor: const Color(0xFFF1F2ED),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  label: 'Communication Skills',
                  hint: 'Text Here, 1-5 Scoring',
                  controller: _communicationCtrl,
                  height: 36,
                  onlyDigits: true,
                  submitted: false,
                  primaryColor: cmsPrimary,
                  fillColor: const Color(0xFFF1F2ED),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  label: 'Experience & Background',
                  hint: 'Text Here, 1-5 Scoring',
                  controller: _experienceCtrl,
                  height: 36,
                  onlyDigits: true,
                  submitted: false,
                  primaryColor: cmsPrimary,
                  fillColor: const Color(0xFFF1F2ED),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  label: 'Culture Fit',
                  hint: 'Text Here, 1-5 Scoring',
                  controller: _cultureFitCtrl,
                  height: 36,
                  onlyDigits: true,
                  submitted: false,
                  primaryColor: cmsPrimary,
                  fillColor: const Color(0xFFF1F2ED),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomValidatedTextFieldMaster(
                  label: 'Leadership Potential',
                  hint: 'Text Here, 1-5 Scoring',
                  controller: _leadershipCtrl,
                  height: 36,
                  onlyDigits: true,
                  submitted: false,
                  primaryColor: cmsPrimary,
                  fillColor: const Color(0xFFF1F2ED),
                ),
              ),
              SizedBox(width: 16.w),
              const Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 10.sp),

          CustomValidatedTextFieldMaster(
            label: 'Comments',
            hint: 'Text Here',
            controller: _commentsCtrl,
            height: 100,
            maxLines: 5,
            submitted: false,
            primaryColor: cmsPrimary,
            fillColor: const Color(0xFFF1F2ED),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionTitle(String title) => Text(
    title,
    style: StyleText.fontSize18Weight500.copyWith(
      fontSize: 18.sp,
      fontWeight: FontWeight.w700,
      color: ColorPick.primary,
    ),
  );

  Widget _readOnlyField(String label, String value, {bool capitalize = true}) {
    return CustomValidatedTextFieldMaster(
      label: label,
      hint: 'Text Here',
      controller: TextEditingController(
          text: capitalize ? FormatHelper.capitalize(value) : value),
      height: 36,
      enabled: false,
      submitted: false,
      primaryColor: ColorPick.primary,
      fillColor: const Color(0xFFF1F2ED),
      textStyle: StyleText.fontSize12Weight500.copyWith(
        color: AppColors.secondaryText,
      ),
    );
  }

  /// Renders the applicant's documents two per row. Extra documents wrap
  /// to a new row. PDF docs → file card, Link docs → link field.
  /// Falls back to legacy Resume + Cover Letter when the application has
  /// no dynamic documents array.
  Widget _profileDocuments(ApplicationModel app) {
    final List<Widget> cells = app.documents.isEmpty
        ? [
            _fileCard('Resume', app.resumeName, app.resumeUrl),
            _fileCard('Cover Letter', app.coverLetterName, app.coverLetterUrl),
          ]
        : app.documents
            .map((d) => d.docType == 'Link'
                ? _linkCard(d.name, d.url)
                : _fileCard(d.name, d.fileName, d.url))
            .toList();

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: 10.sp));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cells[i]),
          SizedBox(width: 16.w),
          Expanded(
            child: i + 1 < cells.length ? cells[i + 1] : const SizedBox(),
          ),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// Link-type document — shows the URL as a clickable link field.
  Widget _linkCard(String label, String url) {
    final bool hasLink = url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: StyleText.fontSize12Weight500.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 6.h),
        MouseRegion(
          cursor: hasLink ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: hasLink ? () => html.window.open(url, '_blank') : null,
            child: Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2ED),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 22.sp,
                    color: hasLink
                        ? Colors.blue.shade700
                        : AppColors.secondaryText,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLink ? url : 'No link',
                          style: StyleText.fontSize11Weight400.copyWith(
                            fontSize: 11.sp,
                            color: hasLink
                                ? Colors.blue.shade700
                                : AppColors.secondaryText,
                            decoration: hasLink
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasLink)
                          Text(
                            'Click to open',
                            style: StyleText.fontSize14Weight400.copyWith(
                                fontSize: 9.sp,
                                color: AppColors.secondaryText),
                          ),
                      ],
                    ),
                  ),
                  if (hasLink)
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14.sp,
                      color: AppColors.secondaryText,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fileCard(String label, String fileName, String fileUrl) {
    final bool hasFile = fileUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: StyleText.fontSize12Weight500.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 6.h),
        MouseRegion(
          cursor: hasFile ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: hasFile ? () => html.window.open(fileUrl, '_blank') : null,
            child: Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2ED),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  CustomSvg(
                    assetPath: "assets/images/pdf 1.svg",
                    width: 30.w,
                    height: 30.h,
                    fit: BoxFit.fill,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName.isEmpty ? 'No file' : fileName,
                          style: StyleText.fontSize11Weight400.copyWith(
                            fontSize: 11.sp,
                            color: hasFile
                                ? Colors.blue.shade700
                                : AppColors.secondaryText,
                            decoration: hasFile
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fileName.isNotEmpty)
                          Text(
                            'Click to open',
                            style: StyleText.fontSize14Weight400.copyWith(
                                fontSize: 9.sp, color: AppColors.secondaryText),
                          ),
                      ],
                    ),
                  ),
                  if (hasFile)
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14.sp,
                      color: AppColors.secondaryText,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
