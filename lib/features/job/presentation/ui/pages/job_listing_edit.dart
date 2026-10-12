// ******************* FILE INFO *******************
// File Name: job_listing_edit.dart
// Created by: Amr Mesbah
// Purpose: Create / Edit Job Post — 4 accordion sections + publish dialogs
// Pattern: Same as home_edit.dart
// UPDATED: Firebase-backed via JobListingCubit.saveJob() — no static data
// FIXED: All dropdowns use CustomDropdownFormFieldInvMaster
// FIXED: All date pickers use CustomDropdownFormFieldCalender + DatePicker
// FIXED: BlocListener handles JobListingSaved — clears saving flag
// FIXED: _publish() and _saveDraft() no longer manually pop — main page handles it
// FIXED: Page title shows actual job title when editing
// FIXED: Hire Start Date must be before Hire End Date — guards both directions

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:web_app_admin/core/main_widgets/admin_back_link.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:web_app_admin/core/widget/calender_widget.dart';
import 'package:web_app_admin/core/widget/custom_dropdwon.dart';
import 'package:web_app_admin/core/widget/date_pic.dart';
import 'package:web_app_admin/core/widget/date_picker.dart';
import 'package:web_app_admin/core/widget/navigator.dart';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom_dialog.dart';
import '../../../../../core/widget/success_toast.dart';
import '../../../../../core/custom/16-custom_dialog_manager.dart';
import '../../../../../core/custom/2-custom_textfield.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../contact_us/presentation/controller/contact_us_location_cubit.dart';
import '../../../../contact_us/presentation/controller/contact_us_location_state.dart';
import '../../../../departments/data/models/department_model.dart';
import '../../../../departments/presentation/controller/department_cubit.dart';
import '../../../../departments/presentation/controller/department_state.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/job_listing_model.dart';
import '../../controller/job_listing_cubit.dart';
import '../../controller/job_listing_state.dart';
import 'job_listing_main.dart';
import 'job_listing_preview.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import '../../../../../core/custom/4-custom_dropdwon_calander.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/job_listing_edit/edit_sections.dart';
part '../widgets/job_listing_edit/edit_form_helpers.dart';


Color _cmsHexColor(String hex) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {}
  return const Color(0xFF008037);
}



const List<Map<String, String>> _kDepartments = [
  {'key': 'Design', 'value': 'Design'},
  {'key': 'Engineering', 'value': 'Engineering'},
  {'key': 'Marketing', 'value': 'Marketing'},
  {'key': 'HR', 'value': 'HR'},
  {'key': 'Finance', 'value': 'Finance'},
];

const List<Map<String, String>> _kWorkTypes = [
  {'key': 'On Site', 'value': 'On Site'},
  {'key': 'Remotely', 'value': 'Remote'}, // BUG-157: same word as the dashboard
  {'key': 'Hybrid', 'value': 'Hybrid'},
];

const List<Map<String, String>> _kEmploymentTypes = [
  {'key': 'Full Time', 'value': 'Full Time'},
  {'key': 'Part Time', 'value': 'Part Time'},
];

const List<Map<String, String>> _kExperienceLevels = [
  {'key': 'Intern', 'value': 'Intern'},
  {'key': 'Junior', 'value': 'Junior'},
  {'key': 'Senior', 'value': 'Senior'},
  {'key': 'Leadership', 'value': 'Leadership'},
];

const List<Map<String, String>> _kDurations = [
  {'key': 'Open', 'value': 'Open'},
  {'key': 'Month', 'value': 'Month'},
  {'key': 'Week', 'value': 'Week'},
  {'key': 'Year', 'value': 'Year'}, // BUG-47
];

const List<Map<String, String>> _kCurrencies = [
  {'key': 'EGP', 'value': 'EGP'}, // BUG-47: jobs are in Egypt
  {'key': 'SAR', 'value': 'SAR'},
  {'key': 'USD', 'value': 'USD'},
  {'key': 'EUR', 'value': 'EUR'},
];

/// BUG-47: dropdown key for a location typed by hand.
const String _kOtherLocationKey = '__other_location__';

const List<Map<String, String>> _kDocTypes = [
  {'key': 'PDF', 'value': 'PDF'},
  {'key': 'Link', 'value': 'Link'},
];

class JobListingEditPage extends StatefulWidget {
  final String? jobId;
  const JobListingEditPage({super.key, this.jobId});

  @override
  State<JobListingEditPage> createState() => _JobListingEditPageState();
}

class _JobListingEditPageState extends State<JobListingEditPage> {
  bool _submitted = false;
  bool _isSaving = false;
  bool _isActive = true; // tracks active/inactive toggle

  final _titleEn = TextEditingController();
  final _titleAr = TextEditingController();
  String? _department;
  String? _workType;
  String? _jobLocation; // office location — required for On Site / Hybrid
  // BUG-47: "Other location…" → typed location.
  bool _locationIsCustom = false;
  final _otherLocation = TextEditingController();
  String? _employmentType;
  final _durationText = TextEditingController();
  String? _durationType;
  String? _experienceLevel;
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  String? _currency = 'SAR';
  final _qualificationEn = TextEditingController();
  final _qualificationAr = TextEditingController();
  final List<Map<String, TextEditingController>> _skills = [];

  final _aboutEn = TextEditingController();
  final _aboutAr = TextEditingController();
  final _requirementsEn = TextEditingController();
  final _requirementsAr = TextEditingController();
  final _prefSkillsEn = TextEditingController();
  final _prefSkillsAr = TextEditingController();

  final List<Map<String, TextEditingController>> _benefits = [];

  DateTime? _hiringStart;
  DateTime? _hiringEnd;
  final _maxApps = TextEditingController();
  final List<Map<String, dynamic>> _requiredDocs = [];

  final Map<String, bool> _open = {
    'jobInfo': true,
    'jobDetails': true,
    'benefits': true,
    'appDetails': true,
  };

  String? _editingJobId;

  // ── Edit-mode state ───────────────────────────────────────────────────────
  // A published / active job's hiring window is already advertised to
  // applicants, so it is read-only once the post is live.
  bool _timelineLocked = false;

  /// Status the job had when the page opened (edit mode only).
  JobStatus? _originalStatus;

  /// Hiring dates as loaded — an unchanged past date on an existing job is
  /// not re-validated (you can still edit the rest of an ended job).
  DateTime? _originalHiringStart;
  DateTime? _originalHiringEnd;

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null &&
      a.year == b.year && a.month == b.month && a.day == b.day;

  // BUG-27: one key per accordion so a failed Publish can scroll to the
  // first section that still has a problem.
  final Map<String, GlobalKey> _sectionKeys = {
    'jobInfo': GlobalKey(),
    'jobDetails': GlobalKey(),
    'benefits': GlobalKey(),
    'appDetails': GlobalKey(),
  };

  /// Snapshot of the form right after it was seeded. Save stays disabled
  /// until the current form differs from it.
  String _initialSignature = '';

  bool get _hasChanges => _formSignature() != _initialSignature;

  /// Every value the form can change, flattened into one comparable string.
  String _formSignature() => [
        _titleEn.text,
        _titleAr.text,
        _department,
        _workType,
        _jobLocation,
        _employmentType,
        _durationText.text,
        _durationType,
        _experienceLevel,
        _salaryMin.text,
        _salaryMax.text,
        _currency,
        _qualificationEn.text,
        _qualificationAr.text,
        _skills.map((s) => '${s['en']!.text}|${s['ar']!.text}').join(','),
        _aboutEn.text,
        _aboutAr.text,
        _requirementsEn.text,
        _requirementsAr.text,
        _prefSkillsEn.text,
        _prefSkillsAr.text,
        _benefits
            .map((b) => '${b['titleEn']!.text}|${b['titleAr']!.text}'
                '|${b['descEn']!.text}|${b['descAr']!.text}')
            .join(','),
        _hiringStart?.toIso8601String(),
        _hiringEnd?.toIso8601String(),
        _maxApps.text,
        _isActive,
        _requiredDocs
            .map((d) => '${(d['name'] as TextEditingController).text}'
                '|${(d['nameAr'] as TextEditingController).text}'
                '|${d['type']}|${d['required']}')
            .join(','),
      ].join('~');

  /// Every text controller currently on the form — the bottom buttons listen
  /// to these so Save enables itself the moment something is typed.
  List<TextEditingController> _allControllers() => [
        _titleEn,
        _titleAr,
        _durationText,
        _salaryMin,
        _salaryMax,
        _qualificationEn,
        _qualificationAr,
        _aboutEn,
        _aboutAr,
        _requirementsEn,
        _requirementsAr,
        _prefSkillsEn,
        _prefSkillsAr,
        _maxApps,
        for (final s in _skills) ...[s['en']!, s['ar']!],
        for (final b in _benefits) ...b.values,
        for (final d in _requiredDocs) ...[
          d['name'] as TextEditingController,
          d['nameAr'] as TextEditingController,
        ],
      ];

  /// Office locations pulled from the Contact Us CMS data.
  List<Map<String, String>> _contactLocations(BuildContext context) {
    final state = context.watch<ContactUsCmsCubit>().state;
    final data = switch (state) {
      ContactUsCmsLoaded(:final data) => data,
      ContactUsCmsSaved(:final data) => data,
      _ => null,
    };
    if (data == null) return const [];
    return data.officeLocations
        .map((o) => o.locationName.en.trim())
        .where((n) => n.isNotEmpty)
        .map((n) => {'key': n, 'value': n})
        .toList();
  }

  /// BUG-47: Contact Us offices + the job's current location (if it is not an
  /// office) + "Other location…" so the admin is not stuck with one choice.
  List<Map<String, String>> _locationItems(BuildContext context) {
    final items = [..._contactLocations(context)];
    final cur = _jobLocation;
    if (!_locationIsCustom &&
        cur != null &&
        cur.isNotEmpty &&
        !items.any((m) => m['key'] == cur)) {
      items.add({'key': cur, 'value': cur});
    }
    items.add({'key': _kOtherLocationKey, 'value': 'Other location…'});
    return items;
  }

  Color _cmsPrimary(BuildContext context) {
    final state = context.read<MainCmsCubit>().state;
    return switch (state) {
      MainCmsLoaded(:final data) => _cmsHexColor(data.branding.primaryColor),
      MainCmsSaved(:final data)  => _cmsHexColor(data.branding.primaryColor),
      _                          => const Color(0xFF008037),
    };
  }

  @override
  void initState() {
    super.initState();
    // Departments dropdown is dynamic — ensure they're loaded.
    final deptCubit = context.read<DepartmentCubit>();
    if (deptCubit.state is DepartmentInitial) deptCubit.loadDepartments();
    _editingJobId = widget.jobId;
    if (_editingJobId != null) {
      _seedFromExisting();
    } else {
      _requiredDocs.addAll([
        {
          'name': TextEditingController(text: 'Resume'),
          'nameAr': TextEditingController(text: 'السيرة الذاتية'), // BUG-34
          'type': 'PDF',
          'required': true,
        },
        {
          'name': TextEditingController(text: 'Cover Letter'),
          'nameAr': TextEditingController(text: 'خطاب التغطية'), // BUG-34
          // BUG-207: Figma Apply form — Cover Letter is a link field.
          'type': 'Link',
          'required': true,
        },
      ]);
    }
    // BUG-08: the first "Required Skills" row used to be a throw-away
    // TextEditingController created inside build(), so whatever was typed
    // there was never read (and the first skill was silently lost). The
    // first row is now a real entry of _skills.
    if (_skills.isEmpty) {
      _skills.add({
        'en': TextEditingController(),
        'ar': TextEditingController(),
      });
    }
    // Baseline for the "nothing changed yet" check.
    _initialSignature = _formSignature();
  }

  void _seedFromExisting() {
    final cubit = context.read<JobListingCubit>();
    final job = cubit.allJobs.firstWhere(
          (j) => j.id == _editingJobId,
      orElse: () => JobPostModel.empty(),
    );

    _titleEn.text = job.title.en;
    _titleAr.text = job.title.ar;
    _department = job.department.isEmpty ? null : job.department;
    _jobLocation = job.location.isEmpty ? null : job.location;
    // BUG-10: fields the admin never picked stay empty instead of showing
    // the enum's default value.
    _workType = job.isUnset('workType') ? null : job.workType.label;
    _employmentType =
        job.isUnset('employmentType') ? null : job.employmentType.label;
    _durationText.text = job.employmentDurationText;
    _durationType = job.isUnset('employmentDurationType')
        ? null
        : job.employmentDurationType.label;
    _experienceLevel =
        job.isUnset('experienceLevel') ? null : job.experienceLevel.label;
    _salaryMin.text = job.salaryMin > 0 ? job.salaryMin.toInt().toString() : '';
    _salaryMax.text = job.salaryMax > 0 ? job.salaryMax.toInt().toString() : '';
    _currency = job.salaryCurrency;
    _qualificationEn.text = job.requiredQualification.en;
    _qualificationAr.text = job.requiredQualification.ar;

    for (final s in job.requiredSkills) {
      _skills.add({
        'en': TextEditingController(text: s.name.en),
        'ar': TextEditingController(text: s.name.ar),
      });
    }

    _aboutEn.text = job.aboutThisPosition.en;
    _aboutAr.text = job.aboutThisPosition.ar;
    _requirementsEn.text = job.requirements.en;
    _requirementsAr.text = job.requirements.ar;
    _prefSkillsEn.text = job.preferredSkills.en;
    _prefSkillsAr.text = job.preferredSkills.ar;

    for (final b in job.benefits) {
      _benefits.add({
        'titleEn': TextEditingController(text: b.title.en),
        'titleAr': TextEditingController(text: b.title.ar),
        'descEn': TextEditingController(text: b.shortDescription.en),
        'descAr': TextEditingController(text: b.shortDescription.ar),
      });
    }

    _hiringStart = job.hiringStartDate;
    _hiringEnd = job.hiringEndDate;
    _originalHiringStart = job.hiringStartDate;
    _originalHiringEnd = job.hiringEndDate;
    _maxApps.text = job.maxApplications > 0
        ? job.maxApplications.toString()
        : '';
    // ── Seed active/inactive toggle ─────────────────────────────
    // An ENDED job is still "on" — extending its end date (BUG-29) should
    // bring it back without also having to flip the switch.
    _isActive = job.status == JobStatus.active ||
        job.status == JobStatus.scheduled ||
        job.status == JobStatus.ended;
    _originalStatus = job.status;

    // BUG-29: only the START date is locked, and only once hiring has
    // actually started — the END date can always be extended / shortened.
    final start = job.hiringStartDate;
    _timelineLocked = job.publishStatus == 'published' &&
        start != null &&
        !DateTime.now().isBefore(DateTime(start.year, start.month, start.day));

    for (final d in job.requiredDocuments) {
      _requiredDocs.add({
        'name': TextEditingController(text: d.name),
        'nameAr': TextEditingController(text: d.nameAr),
        'type': d.docType.label,
        'required': d.isRequired,
      });
    }

    if (_requiredDocs.isEmpty) {
      _requiredDocs.addAll([
        {
          'name': TextEditingController(text: 'Resume'),
          'nameAr': TextEditingController(text: 'السيرة الذاتية'), // BUG-34
          'type': 'PDF',
          'required': true,
        },
        {
          'name': TextEditingController(text: 'Cover Letter'),
          'nameAr': TextEditingController(text: 'خطاب التغطية'), // BUG-34
          // BUG-207: Figma Apply form — Cover Letter is a link field.
          'type': 'Link',
          'required': true,
        },
      ]);
    }
  }

  @override
  void dispose() {
    _otherLocation.dispose();
    _titleEn.dispose();
    _titleAr.dispose();
    _durationText.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _qualificationEn.dispose();
    _qualificationAr.dispose();
    for (final s in _skills) {
      s['en']!.dispose();
      s['ar']!.dispose();
    }
    _aboutEn.dispose();
    _aboutAr.dispose();
    _requirementsEn.dispose();
    _requirementsAr.dispose();
    _prefSkillsEn.dispose();
    _prefSkillsAr.dispose();
    for (final b in _benefits) {
      b.values.forEach((c) => c.dispose());
    }
    _maxApps.dispose();
    for (final d in _requiredDocs) {
      (d['name'] as TextEditingController).dispose();
      (d['nameAr'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOGGLE ACTIVE / INACTIVE
  // ═══════════════════════════════════════════════════════════════════════════

  void _toggleStatus(bool active) {
    setState(() => _isActive = active);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REMOVE JOB
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _confirmRemove() async {
    // Shared dialog (core/custom/16-custom_dialog_manager.dart): it closes
    // itself and reports the choice, so nothing here pops it.
    final confirmed = await CustomDialogManager.showConfirm(
      context: context,
      title: 'REMOVE JOB POST',
      message:
          'This will mark the job as removed and hide it from applicants. '
          'You can still find it under the "Removed" filter.\n\nAre you sure?',
      confirmText: 'Remove',
      confirmColor: ColorPick.red,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    await context.read<JobListingCubit>().removeJob(_editingJobId!);
    if (!mounted) return;
    setState(() => _isSaving = false);
    showSuccessToast(context, 'Job post removed'); // BUG-293
    // Back past the edit page and the detail page.
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REMOVED JOBS — RESTORE / DELETE PERMANENTLY (BUG-45)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _restoreJob() async {
    final confirmed = await CustomDialogManager.showConfirm(
      context: context,
      title: 'RESTORE JOB POST',
      message: 'The job will be restored as INACTIVE so you can review it '
          'before making it visible to applicants again.\n\nContinue?',
      confirmText: 'Restore',
    );
    if (!confirmed || !mounted) return;
    setState(() => _isSaving = true);
    await context
        .read<JobListingCubit>()
        .updateJobStatus(_editingJobId!, JobStatus.inactive);
    if (!mounted) return;
    setState(() => _isSaving = false);
    showSuccessToast(context, 'Job restored (inactive)'); // BUG-293
    Navigator.of(context).pop();
  }

  Future<void> _deletePermanently() async {
    final confirmed = await CustomDialogManager.showConfirm(
      context: context,
      title: 'DELETE JOB POST PERMANENTLY',
      message: 'This permanently deletes the job post. This action cannot be '
          'undone.\n\nAre you sure?',
      confirmText: 'Delete',
      confirmColor: ColorPick.red,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isSaving = true);
    await context.read<JobListingCubit>().deleteJob(_editingJobId!);
    if (!mounted) return;
    setState(() => _isSaving = false);
    showSuccessToast(context, 'Job deleted'); // BUG-293
    // Back past the edit page and the (now deleted) job's detail page.
    final nav = Navigator.of(context);
    nav.pop();
    if (nav.canPop()) nav.pop();
  }

  JobPostModel _buildModel({String publishStatus = 'published'}) {
    final resolvedStatus = publishStatus == 'draft'
        ? JobStatus.drafted
        : (_isActive ? JobStatus.active : JobStatus.inactive);

    // BUG-10: remember which dropdowns were never picked so a draft doesn't
    // pretend to be "On Site / Junior / Full Time".
    final unset = <String>[
      if (_workType == null) 'workType',
      if (_employmentType == null) 'employmentType',
      if (_durationType == null) 'employmentDurationType',
      if (_experienceLevel == null) 'experienceLevel',
    ];

    return JobPostModel(
      id: _editingJobId ?? newJobItemId(),
      unsetFields: unset,
      title: BilingualTextJob(en: _titleEn.text.trim(), ar: _titleAr.text.trim()),
      department: _department ?? '',
      // Location only applies to On Site / Hybrid jobs
      location: _workType == 'Remotely' ? '' : (_jobLocation ?? ''),
      workType: WorkTypeExt.fromString(_workType ?? 'On Site'),
      employmentType: EmploymentTypeExt.fromString(
        _employmentType ?? 'Full Time',
      ),
      employmentDurationText:
          _durationType == 'Open' ? '' : _durationText.text, // BUG-216
      employmentDurationType: EmploymentDurationExt.fromString(
        _durationType ?? 'Open',
      ),
      experienceLevel: ExperienceLevelExt.fromString(
        _experienceLevel ?? 'Junior',
      ),
      salaryMin: double.tryParse(_salaryMin.text) ?? 0,
      salaryMax: double.tryParse(_salaryMax.text) ?? 0,
      salaryCurrency: _currency ?? 'SAR',
      requiredQualification: BilingualTextJob(
        en: _qualificationEn.text,
        ar: _qualificationAr.text,
      ),
      // BUG-08: every row is saved (including the first); rows left
      // completely empty are skipped.
      requiredSkills: _skills
          .where((s) =>
              s['en']!.text.trim().isNotEmpty ||
              s['ar']!.text.trim().isNotEmpty)
          .map(
            (s) => SkillItem(
          id: newJobItemId(), // BUG-240: unique per row
          name: BilingualTextJob(
              en: s['en']!.text.trim(), ar: s['ar']!.text.trim()),
        ),
      )
          .toList(),
      aboutThisPosition: BilingualTextJob(en: _aboutEn.text, ar: _aboutAr.text),
      requirements: BilingualTextJob(
        en: _requirementsEn.text,
        ar: _requirementsAr.text,
      ),
      preferredSkills: BilingualTextJob(
        en: _prefSkillsEn.text,
        ar: _prefSkillsAr.text,
      ),
      benefits: _benefits
          .map(
            (b) => BenefitItem(
          id: newJobItemId(), // BUG-240: unique per row
          title: BilingualTextJob(
            en: b['titleEn']!.text,
            ar: b['titleAr']!.text,
          ),
          shortDescription: BilingualTextJob(
            en: b['descEn']!.text,
            ar: b['descAr']!.text,
          ),
        ),
      )
          .toList(),
      hiringStartDate: _hiringStart,
      hiringEndDate: _hiringEnd,
      maxApplications: int.tryParse(_maxApps.text) ?? 0,
      requiredDocuments: _requiredDocs
          .map(
            (d) => RequiredDocument(
          id: newJobItemId(), // BUG-240: unique per row
          name: (d['name'] as TextEditingController).text,
          nameAr: (d['nameAr'] as TextEditingController).text,
          docType: DocTypeExt.fromString(d['type'] as String? ?? 'PDF'),
          isRequired: d['required'] as bool? ?? true,
        ),
      )
          .toList(),
      status: resolvedStatus,
      publishStatus: publishStatus,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PUBLISH
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  //  CROSS-FIELD RULES (BUG-28)
  // ═══════════════════════════════════════════════════════════════════════════

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Max salary must be ≥ min" — was accepted and shown as "20000 - 5000".
  String? get _salaryError {
    final min = double.tryParse(_salaryMin.text.trim());
    final max = double.tryParse(_salaryMax.text.trim());
    if (min != null && max != null && max < min) {
      return 'Max salary must be greater than or equal to min salary.';
    }
    return null;
  }

  /// "0" was accepted, then saved as blank and blocked every later edit.
  String? get _maxAppsError {
    final t = _maxApps.text.trim();
    if (t.isEmpty) return null; // the "required" check handles empty
    final n = int.tryParse(t);
    if (n == null || n < 1) return 'Must be at least 1.';
    return null;
  }

  /// Start date can't be in the past (unless hiring already started and the
  /// start date is locked).
  String? get _startDateError {
    if (_hiringStart == null || _timelineLocked) return null;
    if (_sameDay(_hiringStart, _originalHiringStart)) return null;
    if (_day(_hiringStart!).isBefore(_today)) {
      return "Start date can't be in the past.";
    }
    return null;
  }

  /// End date must be after the start date and not in the past.
  String? get _endDateError {
    if (_hiringEnd == null) return null;
    if (_hiringStart != null && !_day(_hiringEnd!).isAfter(_day(_hiringStart!))) {
      return 'End date must be after the start date.';
    }
    if (!_sameDay(_hiringEnd, _originalHiringEnd) &&
        _day(_hiringEnd!).isBefore(_today)) {
      return "End date can't be in the past.";
    }
    return null;
  }

  /// A skill row is fine when it is completely empty (ignored) or has both
  /// languages filled in.
  bool get _skillsOk => _skills.every((s) {
        final en = s['en']!.text.trim().isNotEmpty;
        final ar = s['ar']!.text.trim().isNotEmpty;
        return en == ar;
      });

  /// Key of the first accordion that still has a problem, or null.
  String? _firstInvalidSection() {
    bool filled(TextEditingController c) => c.text.trim().isNotEmpty;

    final jobInfoOk = filled(_titleEn) && filled(_titleAr) &&
        _department != null &&
        _workType != null &&
        (_workType == 'Remotely' || _jobLocation != null) &&
        _employmentType != null &&
        // BUG-216: "Open" has no number.
        (_durationType == 'Open' || filled(_durationText)) &&
        _durationType != null &&
        _experienceLevel != null &&
        filled(_salaryMin) && filled(_salaryMax) &&
        (_currency != null && _currency!.isNotEmpty) &&
        _salaryError == null &&
        filled(_qualificationEn) && filled(_qualificationAr) &&
        _skillsOk;
    if (!jobInfoOk) return 'jobInfo';

    final detailsOk = filled(_aboutEn) && filled(_aboutAr) &&
        filled(_requirementsEn) && filled(_requirementsAr) &&
        filled(_prefSkillsEn) && filled(_prefSkillsAr);
    if (!detailsOk) return 'jobDetails';

    final benefitsOk =
        _benefits.every((b) => b.values.every((c) => c.text.trim().isNotEmpty));
    if (!benefitsOk) return 'benefits';

    final appOk = _hiringStart != null && _hiringEnd != null &&
        _startDateError == null && _endDateError == null &&
        filled(_maxApps) && _maxAppsError == null &&
        _requiredDocs.every(
            (d) => (d['name'] as TextEditingController).text.trim().isNotEmpty);
    if (!appOk) return 'appDetails';

    return null;
  }

  /// BUG-27: Publish used to fail silently — the only feedback was a thin red
  /// border far up the page. Now: a message, the section is opened, and the
  /// page scrolls to it.
  void _revealProblem(String sectionKey, {String? message}) {
    setState(() => _open[sectionKey] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Please complete the highlighted fields.'),
        backgroundColor: ColorPick.red,
        duration: const Duration(seconds: 3),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[sectionKey]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  /// First cross-field message to show in the snackbar, if any.
  String? get _firstRuleMessage =>
      _salaryError ?? _startDateError ?? _endDateError ?? _maxAppsError;

  /// True when every field is filled and every dropdown/date is selected.
  bool get _isFormValid => _firstInvalidSection() == null;


  Future<void> _publish() async {
    if (_isSaving) return;

    // Marking _submitted makes every empty field / unselected dropdown render
    // its own red error; _revealProblem tells the user and scrolls there.
    setState(() => _submitted = true);
    final bad = _firstInvalidSection();
    if (bad != null) {
      _revealProblem(bad, message: _firstRuleMessage);
      return;
    }

    final bool isEdit = _editingJobId != null;
    // BUG-280: a job whose hiring starts later is SCHEDULED — don't promise
    // it will be visible "immediately".
    final bool scheduled =
        _hiringStart != null && _day(_hiringStart!).isAfter(_today);
    final String when = scheduled
        ? 'on ${DateFormat('d MMM yyyy').format(_hiringStart!)}'
        : 'immediately';
    final confirmed = await CustomDialogManager.showConfirm(
      context: context,
      title: isEdit ? 'SAVE JOB POST' : 'NEW JOB POSTING',
      message: isEdit
          ? 'Your changes will be applied to this job post and shown to '
              'applicants $when. Please ensure all details are accurate '
              'before confirming.'
          : 'You are about to publish a new job opportunity. This action will '
              'make the post visible to applicants $when. Please ensure all '
              'details are accurate before confirming.',
      confirmText: isEdit ? 'Save' : 'Submit',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    await context.read<JobListingCubit>().saveJob(
      _buildModel(publishStatus: 'published'),
      publishStatus: 'published',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SAVE AS DRAFT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveDraft() async {
    if (_isSaving) return;
    // BUG-10: a draft needs at least a job title — empty drafts used to be
    // saved as "Untitled" (and showed up on the dashboard as a raw id).
    if (_titleEn.text.trim().isEmpty && _titleAr.text.trim().isEmpty) {
      setState(() => _submitted = true);
      _revealProblem('jobInfo',
          message: 'Please enter at least the job title to save a draft.');
      return;
    }
    // Numbers that ARE entered must still make sense.
    final rule = _salaryError ?? _maxAppsError ?? _endDateError;
    if (rule != null) {
      setState(() => _submitted = true);
      _revealProblem(_salaryError != null ? 'jobInfo' : 'appDetails',
          message: rule);
      return;
    }
    // BUG-90: "Save For Later" now also exists while editing — it moves a
    // live / scheduled job back to Draft (hidden from applicants).
    final bool isEdit = _editingJobId != null;
    final confirmed = await CustomDialogManager.showConfirm(
      context: context,
      title: 'SAVE JOB POST FOR LATER',
      message: isEdit && _originalStatus != JobStatus.drafted
          ? 'This job post will be moved back to Draft and hidden from '
              'applicants until you publish it again.\nDo you want to continue?'
          : 'Your job post will be saved as a draft. It will not be visible '
              'to applicants until you publish it.\nDo you want to continue?',
      confirmText: 'Draft',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    await context.read<JobListingCubit>().saveJob(
      _buildModel(publishStatus: 'draft'),
      publishStatus: 'draft',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DATE PICKER HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickDate({
    required DateTime? currentDate,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
  }) async {
    final result = await DatePicker().showDatePicker(
      context,
      currentDate != null ? [currentDate] : [],
      currentDate ?? DateTime.now(),
      CalendarDatePicker2Type.single,
      firstDate:
      firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
    );
    if (result != null && result.isNotEmpty && result.first != null) {
      onPicked(result.first!);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HIRE DATE SETTERS — with cross-validation guards
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sets the hiring start date.
  /// If the new start date is after the current end date, clears the end date.
  void _setHiringStart(DateTime picked) {
    setState(() {
      _hiringStart = picked;
      // ── Guard: if end date is now before the new start, reset it ──
      if (_hiringEnd != null && _hiringEnd!.isBefore(picked)) {
        _hiringEnd = null;
      }
    });
  }

  /// Sets the hiring end date.
  /// The date picker already restricts selection to dates >= start date,
  /// but we add an extra programmatic guard just in case.
  void _setHiringEnd(DateTime picked) {
    if (_hiringStart != null && picked.isBefore(_hiringStart!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End date cannot be before start date'),
          backgroundColor: ColorPick.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _hiringEnd = picked;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isEdit = _editingJobId != null;

    return BlocListener<JobListingCubit, JobListingState>(
      listener: (context, state) {
        if (state is JobListingError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: ColorPick.red),
          );
        }
        if (state is JobListingSaved && _isSaving) {
          setState(() => _isSaving = false);
          // BUG-46: confirm every successful save (root-overlay toast — it
          // stays visible after this page closes).
          showSuccessToast(
            context,
            state.job.publishStatus == 'draft'
                ? 'Draft saved'
                : (_editingJobId != null ? 'Job post saved' : 'Job post published'),
          );
          // BUG-10 (white screen): close THIS page only, and only if it is
          // still the top route. The list page used to pop whatever route
          // was on top, which could empty the navigator.
          final route = ModalRoute.of(context);
          if (route != null && route.isCurrent && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: ColorPick.background,
        body: Stack(
          children: [
            AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  children: [
                    // BUG-286: no spacer ABOVE the header (it sat 24 px lower
                    // than on every other page).
                    AppAdminNavbar(
                      activeLabel: 'Job Listing',
                      homePage: CareersMainPageDashboard(),
                      webPage: MainMainPage(),
                      jobListingPage: JobListingMainPage(),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: 1000.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BUG-298: same back link as About Company.
                          const AdminBackLink(parentLabel: 'Job Listing', parentRoute: '/jobs'),
                          Text(
                            isEdit
                                ? 'Editing Job Post Details'
                                : 'Create New Job Post',
                            // BUG-286: same title size as every admin page
                            // (was ≈30 % smaller).
                            style: StyleText.fontSize28Weight600.copyWith(
                              color: ColorPick.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // BUG-45: a REMOVED job gets explicit Restore and
                          // Delete-permanently actions instead of the
                          // ambiguous Remove button + status switch.
                          if (isEdit && _originalStatus == JobStatus.removed) ...[
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _deletePermanently,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: ColorPick.red,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'Delete permanently',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _restoreJob,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF008037),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'Restore',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                          ] else if (isEdit) ...[
                            Row(
                              children: [
                                // Same Remove button as the Department edit
                                // page (features/departments/.../department_edit.dart).
                                GestureDetector(
                                  onTap: () => _confirmRemove(),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorPick.red,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Job Status',
                                  style: StyleText.fontSize13Weight600.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Transform.scale(
                                  scale: 0.85,
                                  child: FlutterSwitch(
                                    value: _isActive,
                                    activeColor: ColorPick.primary,
                                    activeToggleColor: Colors.white,
                                    inactiveColor: Colors.grey.shade400,
                                    inactiveToggleColor: Colors.white,
                                    width: 46.0,
                                    height: 27.0,
                                    toggleSize: 21.0,
                                    borderRadius: 13.5,
                                    padding: 3.0,
                                    onToggle: (val) => _toggleStatus(val),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                          ],

                          KeyedSubtree(
                            key: _sectionKeys['jobInfo'],
                            child: _accordion(
                              key: 'jobInfo',
                              title: 'Job Information',
                              children: [_jobInfoSection()],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          KeyedSubtree(
                            key: _sectionKeys['jobDetails'],
                            child: _accordion(
                              key: 'jobDetails',
                              title: 'Job Details',
                              children: [_jobDetailsSection()],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          KeyedSubtree(
                            key: _sectionKeys['benefits'],
                            child: _accordion(
                              key: 'benefits',
                              title: 'Benefits',
                              children: [_benefitsSection()],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          KeyedSubtree(
                            key: _sectionKeys['appDetails'],
                            child: _accordion(
                              key: 'appDetails',
                              title: 'Application Details',
                              children: [_applicationDetailsSection()],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          _bottomButtons(),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ],
),

            if (_isSaving)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircleProgress(),
                ),
              ),
          ],
        ),
      ),
    );
  }

}