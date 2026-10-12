part of '../../pages/job_listing_detail.dart';

class _JobDetailsTab extends StatelessWidget {
  final JobPostModel job;
  const _JobDetailsTab({required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(title: 'Job Information', child: _jobInfoContent()),
        SizedBox(height: 10.h),
        _SectionCard(title: 'Job Details', child: _jobDetailsContent()),
        SizedBox(height: 10.h),
        if (job.benefits.isNotEmpty) ...[
          _SectionCard(title: 'Benefits', child: _benefitsContent()),
          SizedBox(height: 10.h),
        ],
        _SectionCard(title: 'Application Details', child: _appDetailsContent()),
      ],
    );
  }

  Widget _jobInfoContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _row(
            _infoField('Job Title', job.title.en),
            _infoFieldRtl('المسمى الوظيفي', job.title.ar),
          ),
          SizedBox(height: 10.sp),
          _row(
            _infoField(
              'Department',
              job.department.isEmpty ? '—' : job.department,
            ),
            // QA-Oct11 #22: like the edit form — for Hybrid (and On Site)
            // the Work Type cell is split in two: Work Type + Location.
            _hasLocation
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _infoField('Work Type',
                            job.workType.displayLabel), // BUG-157
                      ),
                      SizedBox(width: 8.w),
                      Expanded(child: _infoField('Location', job.location)),
                    ],
                  )
                : _infoField('Work Type',
                    job.isUnset('workType') ? '—' : job.workType.displayLabel), // BUG-157
          ),
          SizedBox(height: 10.sp),
          _row(
            _infoField('Employment Type',
                job.isUnset('employmentType') ? '—' : job.employmentType.label),
            _infoField('Employment Duration', job.durationDisplay), // BUG-172
          ),
          SizedBox(height: 10.sp),
          _row(
            _infoField('Experience Level',
                job.isUnset('experienceLevel') ? '—' : job.experienceLevel.label),
            _infoField(
              'Salary Range',
              job.salaryDisplay, // BUG-304
            ),
          ),
          SizedBox(height: 10.sp),
          _row(
            _infoField('Required Qualification', job.requiredQualification.en),
            _infoFieldRtl('المؤهلات المطلوبة', job.requiredQualification.ar),
          ),
          if (job.requiredSkills.isNotEmpty) ...[
            SizedBox(height: 10.sp),
            _skillsRow(),
          ],
        ],
      ),
    );
  }

  Widget _jobDetailsContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // BUG-34: the Arabic text is shown too, exactly like the form.
          _infoField(
            'About This Position',
            job.aboutThisPosition.en,
            multi: true,
          ),
          SizedBox(height: 10.sp),
          _infoFieldRtl('', job.aboutThisPosition.ar, multi: true),
          SizedBox(height: 10.sp),
          _infoField('Requirements', job.requirements.en, multi: true),
          SizedBox(height: 10.sp),
          _infoFieldRtl('', job.requirements.ar, multi: true),
          SizedBox(height: 10.sp),
          _infoField('Preferred Skills', job.preferredSkills.en, multi: true),
          SizedBox(height: 10.sp),
          _infoFieldRtl('', job.preferredSkills.ar, multi: true),
        ],
      ),
    );
  }

  // Mirrors the edit page's Benefits section layout:
  // "Benefit N" header → Title EN | Title AR → Short Description EN → AR.
  Widget _benefitsContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...List.generate(job.benefits.length, (i) {
            final b = job.benefits[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefit ${i + 1}',
                  style: StyleText.fontSize13Weight600.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 10.sp),
                _row(
                  _infoField('Title', b.title.en),
                  _infoFieldRtl('العنوان', b.title.ar),
                ),
                SizedBox(height: 10.sp),
                _infoField('Short Description', b.shortDescription.en,
                    multi: true),
                SizedBox(height: 10.sp),
                _infoFieldRtl('وصف مختصر', b.shortDescription.ar, multi: true),
                SizedBox(height: 10.sp),
                if (i < job.benefits.length - 1)
                  const Divider(color: Color(0xFFE8E8E8)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _appDetailsContent() {
    String fmtDate(DateTime? dt) {
      if (dt == null) return '—';
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _row(
            _infoField('Hiring Timeline (Start Date)',
                fmtDate(job.hiringStartDate)),
            _infoField('Hiring Timeline (End Date)',
                fmtDate(job.hiringEndDate)),
          ),
          SizedBox(height: 10.sp),
          _row(
            _infoField(
              'Maximum Number of Applications for This Position',
              job.maxApplications > 0 ? job.maxApplications.toString() : '—',
            ),
            const SizedBox(),
          ),
          if (job.requiredDocuments.isNotEmpty) ...[
            SizedBox(height: 10.sp),
            Text('Required Documents', style: StyleText.fieldLabel),
            const SizedBox(height: 8),
            // One document per row — matches the edit page layout:
            // EN name | AR name | type | Required / Optional switch.
            ...List.generate(job.requiredDocuments.length, (i) {
              final d = job.requiredDocuments[i];
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: _infoField('', d.name)),
                    SizedBox(width: 8.w),
                    Expanded(flex: 3, child: _infoFieldRtl('', d.nameAr)),
                    SizedBox(width: 8.w),
                    SizedBox(width: 90.w, child: _infoField('', d.docType.label)),
                    SizedBox(width: 12.w),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          d.isRequired ? 'Required' : 'Optional',
                          style: StyleText.fontSize11Weight400
                              .copyWith(color: AppColors.text),
                        ),
                        SizedBox(height: 4.h),
                        IgnorePointer(
                          child: Transform.scale(
                            scale: 0.8,
                            child: FlutterSwitch(
                              value: d.isRequired,
                              activeColor: ColorPick.primary,
                              activeToggleColor: Colors.white,
                              inactiveColor: Colors.grey.shade400,
                              inactiveToggleColor: Colors.white,
                              width: 46.0,
                              height: 27.0,
                              toggleSize: 21.0,
                              borderRadius: 13.5,
                              padding: 3.0,
                              onToggle: (_) {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// QA-Oct11 #22: On Site / Hybrid jobs carry an office location.
  bool get _hasLocation =>
      !job.isUnset('workType') &&
      (job.workType == WorkType.hybrid || job.workType == WorkType.onSite);

  Widget _row(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: 16),
      Expanded(child: right),
    ],
  );

  Widget _skillsRow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Required Skills', style: StyleText.fieldLabel),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        // BUG-34: show both languages of each skill.
        children: job.requiredSkills
            .map((s) => _chip(s.name.ar.isEmpty
                ? s.name.en
                : (s.name.en.isEmpty ? s.name.ar : '${s.name.en} / ${s.name.ar}')))
            .toList(),
      ),
    ],
  );

  // Same height + style as _readOnlyField in application_detail/detail_cards.dart
  // Typography comes from the shared form styles (StyleText.field*), so this
  // read-only view matches the edit form's titles, values and hints exactly.
  Widget _infoField(String label, String value,
          {bool multi = false, bool rtl = false}) =>
      CustomValidatedTextFieldMaster(
        label: label.isNotEmpty ? label : null,
        labelStyle: StyleText.fieldLabel,
        hint: 'Text Here',
        controller: TextEditingController(text: value.isEmpty ? '—' : value),
        height: multi ? 100 : 36,
        maxLines: multi ? 5 : 1,
        enabled: false,
        readOnlyView: true, // BUG-294: white box, normal text
        submitted: false,
        // The field's own direction — an ambient Directionality is NOT enough,
        // because the widget defaults these to ltr/start and would keep the
        // Arabic value pinned to the left edge.
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        textAlign: TextAlign.start, // = right when the direction is rtl
        primaryColor: ColorPick.primary,
        // QA-Oct11 #16: page-grey field box (was white on the white card).
        fillColor: ColorPick.background,
        textStyle: StyleText.fieldValue,
        hintStyle: StyleText.fieldHint,
      );

  // Arabic side: label + value + hint all start from the RIGHT, same as
  // _fieldRtl in the edit form.
  Widget _infoFieldRtl(String label, String value, {bool multi = false}) =>
      Directionality(
        textDirection: TextDirection.rtl,
        child: _infoField(label, value, multi: multi, rtl: true),
      );

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: ColorPick.primary,
      borderRadius: BorderRadius.circular(8.r)
    ),
    child: Text(
      text,
      style: StyleText.fontSize11Weight400.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ColorPick.white,
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 2 — DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════
