// ******************* FILE INFO *******************
// File Name: job_listing_model.dart
// Created by: Amr Mesbah
// Purpose: Model for Job Listing CMS — full job post data

// ── Bilingual text ────────────────────────────────────────────────────────────

class BilingualTextJob {
  final String en;
  final String ar;

  const BilingualTextJob({this.en = '', this.ar = ''});

  factory BilingualTextJob.fromMap(Map<String, dynamic> map) =>
      BilingualTextJob(
        en: map['en'] as String? ?? '',
        ar: map['ar'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'en': en, 'ar': ar};

  BilingualTextJob copyWith({String? en, String? ar}) =>
      BilingualTextJob(en: en ?? this.en, ar: ar ?? this.ar);

  bool get isEmpty => en.isEmpty && ar.isEmpty;
}

// ── Enums ─────────────────────────────────────────────────────────────────────

enum JobStatus { active, inactive, ended, scheduled, drafted, removed }

extension JobStatusExt on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.active:    return 'Active';
      case JobStatus.inactive:  return 'Inactive';
      case JobStatus.ended:     return 'Ended';
      case JobStatus.scheduled: return 'Scheduled';
      case JobStatus.drafted:   return 'Drafted';
      case JobStatus.removed:   return 'Removed';
    }
  }

  static JobStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'active':    return JobStatus.active;
      case 'inactive':  return JobStatus.inactive;
      case 'ended':     return JobStatus.ended;
      case 'scheduled': return JobStatus.scheduled;
      case 'drafted':   return JobStatus.drafted;
      case 'removed':   return JobStatus.removed;
      default:          return JobStatus.drafted;
    }
  }
}

enum WorkType { onSite, remote, hybrid }

extension WorkTypeExt on WorkType {
  String get label {
    switch (this) {
      case WorkType.onSite: return 'On Site';
      case WorkType.remote: return 'Remotely';
      case WorkType.hybrid: return 'Hybrid';
    }
  }

  static WorkType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'on site':  return WorkType.onSite;
      case 'onsite':   return WorkType.onSite;
      case 'remotely': return WorkType.remote;
      case 'remote':   return WorkType.remote;
      case 'hybrid':   return WorkType.hybrid;
      default:         return WorkType.onSite;
    }
  }
}

enum EmploymentType { fullTime, partTime }

extension EmploymentTypeExt on EmploymentType {
  String get label {
    switch (this) {
      case EmploymentType.fullTime: return 'Full Time';
      case EmploymentType.partTime: return 'Part Time';
    }
  }

  static EmploymentType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'full time': return EmploymentType.fullTime;
      case 'fulltime':  return EmploymentType.fullTime;
      case 'part time': return EmploymentType.partTime;
      case 'parttime':  return EmploymentType.partTime;
      default:          return EmploymentType.fullTime;
    }
  }
}

enum ExperienceLevel { intern, junior, senior, leadership }

extension ExperienceLevelExt on ExperienceLevel {
  String get label {
    switch (this) {
      case ExperienceLevel.intern:     return 'Intern';
      case ExperienceLevel.junior:     return 'Junior';
      case ExperienceLevel.senior:     return 'Senior';
      case ExperienceLevel.leadership: return 'Leadership';
    }
  }

  static ExperienceLevel fromString(String s) {
    switch (s.toLowerCase()) {
      case 'intern':     return ExperienceLevel.intern;
      case 'junior':     return ExperienceLevel.junior;
      case 'senior':     return ExperienceLevel.senior;
      case 'leadership': return ExperienceLevel.leadership;
      default:           return ExperienceLevel.junior;
    }
  }
}

enum EmploymentDuration { open, month, week, year }

extension EmploymentDurationExt on EmploymentDuration {
  String get label {
    switch (this) {
      case EmploymentDuration.open:  return 'Open';
      case EmploymentDuration.month: return 'Month';
      case EmploymentDuration.week:  return 'Week';
      case EmploymentDuration.year:  return 'Year'; // BUG-47
    }
  }

  static EmploymentDuration fromString(String s) {
    switch (s.toLowerCase()) {
      case 'open':  return EmploymentDuration.open;
      case 'month': return EmploymentDuration.month;
      case 'week':  return EmploymentDuration.week;
      case 'year':  return EmploymentDuration.year;
      default:      return EmploymentDuration.open;
    }
  }
}

enum DocType { pdf, link }

extension DocTypeExt on DocType {
  String get label {
    switch (this) {
      case DocType.pdf:  return 'PDF';
      case DocType.link: return 'Link';
    }
  }

  static DocType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'pdf':  return DocType.pdf;
      case 'link': return DocType.link;
      default:     return DocType.pdf;
    }
  }
}

// ── Benefit Item ──────────────────────────────────────────────────────────────

class BenefitItem {
  final String id;
  final BilingualTextJob title;
  final BilingualTextJob shortDescription;

  const BenefitItem({
    required this.id,
    required this.title,
    required this.shortDescription,
  });

  factory BenefitItem.empty() => BenefitItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: const BilingualTextJob(),
    shortDescription: const BilingualTextJob(),
  );

  factory BenefitItem.fromMap(Map<String, dynamic> map) => BenefitItem(
    id: map['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: BilingualTextJob.fromMap(
        (map['title'] as Map<String, dynamic>?) ?? {}),
    shortDescription: BilingualTextJob.fromMap(
        (map['shortDescription'] as Map<String, dynamic>?) ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title.toMap(),
    'shortDescription': shortDescription.toMap(),
  };

  BenefitItem copyWith({
    String? id,
    BilingualTextJob? title,
    BilingualTextJob? shortDescription,
  }) =>
      BenefitItem(
        id: id ?? this.id,
        title: title ?? this.title,
        shortDescription: shortDescription ?? this.shortDescription,
      );
}

// ── Required Document ─────────────────────────────────────────────────────────

class RequiredDocument {
  final String id;
  final String name;    // English document name
  final String nameAr;  // Arabic document name
  final DocType docType;
  final bool isRequired; // true = required, false = optional

  const RequiredDocument({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.docType,
    this.isRequired = true,
  });

  factory RequiredDocument.empty({String name = 'Resume'}) => RequiredDocument(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    nameAr: '',
    docType: DocType.pdf,
    isRequired: true,
  );

  factory RequiredDocument.fromMap(Map<String, dynamic> map) =>
      RequiredDocument(
        id: map['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'] as String? ?? '',
        nameAr: map['nameAr'] as String? ?? '',
        docType: DocTypeExt.fromString(map['docType'] as String? ?? 'pdf'),
        // Older docs without the flag default to required.
        isRequired: map['isRequired'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'docType': docType.label,
    'isRequired': isRequired,
  };

  RequiredDocument copyWith({
    String? id,
    String? name,
    String? nameAr,
    DocType? docType,
    bool? isRequired,
  }) =>
      RequiredDocument(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        docType: docType ?? this.docType,
        isRequired: isRequired ?? this.isRequired,
      );
}

// ── Skill Item ────────────────────────────────────────────────────────────────

class SkillItem {
  final String id;
  final BilingualTextJob name;

  const SkillItem({required this.id, required this.name});

  factory SkillItem.empty() => SkillItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: const BilingualTextJob(),
  );

  factory SkillItem.fromMap(Map<String, dynamic> map) => SkillItem(
    id: map['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    name: BilingualTextJob.fromMap(
        (map['name'] as Map<String, dynamic>?) ?? {}),
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name.toMap()};

  SkillItem copyWith({String? id, BilingualTextJob? name}) =>
      SkillItem(id: id ?? this.id, name: name ?? this.name);
}

// ── Job Post Model ────────────────────────────────────────────────────────────

class JobPostModel {
  // ── Firestore field keys ──────────────────────────────────────────────────
  static const String ABOUT_THIS_POSITION = 'aboutThisPosition';
  static const String ACTIVE = 'active';
  static const String AR = 'ar';
  static const String BENEFITS = 'benefits';
  static const String DEPARTMENT = 'department';
  static const String DOC_TYPE = 'docType';
  static const String DRAFTED = 'drafted';
  static const String EMPLOYMENT_DURATION_TEXT = 'employmentDurationText';
  static const String EMPLOYMENT_DURATION_TYPE = 'employmentDurationType';
  static const String EMPLOYMENT_TYPE = 'employmentType';
  static const String EN = 'en';
  static const String ENDED = 'ended';
  static const String ENDED_DATE = 'endedDate';
  static const String EXPERIENCE_LEVEL = 'experienceLevel';
  static const String FULLTIME = 'fulltime';
  static const String HIRING_END_DATE = 'hiringEndDate';
  static const String HIRING_START_DATE = 'hiringStartDate';
  static const String HYBRID = 'hybrid';
  static const String ID = 'id';
  static const String INACTIVE = 'inactive';
  static const String INTERN = 'intern';
  static const String JUNIOR = 'junior';
  static const String LEADERSHIP = 'leadership';
  static const String LINK = 'link';
  static const String MAX_APPLICATIONS = 'maxApplications';
  static const String MONTH = 'month';
  static const String NAME = 'name';
  static const String ONSITE = 'onsite';
  static const String OPEN = 'open';
  static const String PARTTIME = 'parttime';
  static const String PDF = 'pdf';
  static const String POSTED_DATE = 'postedDate';
  static const String PREFERRED_SKILLS = 'preferredSkills';
  static const String PUBLISH_STATUS = 'publishStatus';
  static const String REMOTE = 'remote';
  static const String REMOTELY = 'remotely';
  static const String REMOVED = 'removed';
  static const String REQUIRED_DOCUMENTS = 'requiredDocuments';
  static const String REQUIRED_QUALIFICATION = 'requiredQualification';
  static const String REQUIRED_SKILLS = 'requiredSkills';
  static const String REQUIREMENTS = 'requirements';
  static const String SALARY_CURRENCY = 'salaryCurrency';
  static const String SALARY_MAX = 'salaryMax';
  static const String SALARY_MIN = 'salaryMin';
  static const String SCHEDULED = 'scheduled';
  static const String SENIOR = 'senior';
  static const String SHORT_DESCRIPTION = 'shortDescription';
  static const String STATUS = 'status';
  static const String TITLE = 'title';
  static const String TOTAL_APPLICATIONS = 'totalApplications';
  static const String WEEK = 'week';
  static const String WORK_TYPE = 'workType';

  final String id;

  // Job Information
  final BilingualTextJob title;
  final String department;

  /// Office location (from Contact Us office locations).
  /// Only meaningful when [workType] is onSite or hybrid.
  final String location;
  final WorkType workType;
  final EmploymentType employmentType;
  final String employmentDurationText; // e.g. "3 Weeks"
  final EmploymentDuration employmentDurationType;
  final ExperienceLevel experienceLevel;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;
  final BilingualTextJob requiredQualification;
  final List<SkillItem> requiredSkills;

  // Job Details
  final BilingualTextJob aboutThisPosition;
  final BilingualTextJob requirements;
  final BilingualTextJob preferredSkills;

  // Benefits
  final List<BenefitItem> benefits;

  // Application Details
  final DateTime? hiringStartDate;
  final DateTime? hiringEndDate;
  final int maxApplications;
  final List<RequiredDocument> requiredDocuments;

  // Meta
  final JobStatus status;
  final DateTime? postedDate;
  final DateTime? endedDate;
  final int totalApplications;
  final String publishStatus; // 'published', 'draft'

  /// BUG-10: dropdown fields the admin never picked (a draft saved early).
  /// The enums below always hold SOME value, so without this list a blank
  /// draft looked like "On Site / Junior / Full Time". Keys used:
  /// 'workType', 'employmentType', 'employmentDurationType', 'experienceLevel'.
  final List<String> unsetFields;

  bool isUnset(String field) => unsetFields.contains(field);

  /// Title for display: never a raw id, never empty (BUG-19).
  String get displayTitle =>
      title.en.trim().isNotEmpty
          ? title.en.trim()
          : (title.ar.trim().isNotEmpty ? title.ar.trim() : 'Untitled job');

  // ── BUG-11: status derived from the hiring window ─────────────────────────
  /// A published job whose hiring start date is still in the future is
  /// SCHEDULED; one whose end date has passed is ENDED. The stored status was
  /// never updated by anything, so both used to show as "Active" forever.
  /// Only the "live" statuses are derived — inactive / drafted / removed are
  /// explicit admin choices and are left alone.
  static JobStatus deriveStatus(
    JobStatus stored,
    DateTime? start,
    DateTime? end, {
    DateTime? now,
  }) {
    if (stored != JobStatus.active &&
        stored != JobStatus.scheduled &&
        stored != JobStatus.ended) {
      return stored;
    }
    final n = now ?? DateTime.now();
    if (end != null) {
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      if (n.isAfter(endOfDay)) return JobStatus.ended;
    }
    if (start != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      if (n.isBefore(startOfDay)) return JobStatus.scheduled;
    }
    return JobStatus.active;
  }

  /// This job with [status] re-derived from its hiring dates.
  JobPostModel withDerivedStatus() {
    final s = deriveStatus(status, hiringStartDate, hiringEndDate);
    if (s == status) return this;
    return copyWith(
      status: s,
      endedDate: s == JobStatus.ended ? (endedDate ?? hiringEndDate) : endedDate,
    );
  }

  const JobPostModel({
    required this.id,
    required this.title,
    this.department = '',
    this.location = '',
    this.workType = WorkType.onSite,
    this.employmentType = EmploymentType.fullTime,
    this.employmentDurationText = '',
    this.employmentDurationType = EmploymentDuration.open,
    this.experienceLevel = ExperienceLevel.junior,
    this.salaryMin = 0,
    this.salaryMax = 0,
    this.salaryCurrency = 'SAR',
    this.requiredQualification = const BilingualTextJob(),
    this.requiredSkills = const [],
    this.aboutThisPosition = const BilingualTextJob(),
    this.requirements = const BilingualTextJob(),
    this.preferredSkills = const BilingualTextJob(),
    this.benefits = const [],
    this.hiringStartDate,
    this.hiringEndDate,
    this.maxApplications = 0,
    this.requiredDocuments = const [],
    this.status = JobStatus.drafted,
    this.postedDate,
    this.endedDate,
    this.totalApplications = 0,
    this.publishStatus = 'draft',
    this.unsetFields = const [],
  });

  factory JobPostModel.empty() => JobPostModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: const BilingualTextJob(),
    requiredDocuments: [
      RequiredDocument.empty(name: 'Resume'),
      RequiredDocument.empty(name: 'Cover Letter'),
    ],
  );

  factory JobPostModel.fromMap(String id, Map<String, dynamic> map) {
    return JobPostModel(
      id: id,
      title: BilingualTextJob.fromMap(
          (map[TITLE] as Map<String, dynamic>?) ?? {}),
      department: map[DEPARTMENT] as String? ?? '',
      location: map['location'] as String? ?? '',
      workType:
      WorkTypeExt.fromString(map[WORK_TYPE] as String? ?? 'On Site'),
      employmentType: EmploymentTypeExt.fromString(
          map[EMPLOYMENT_TYPE] as String? ?? 'Full Time'),
      employmentDurationText:
      map[EMPLOYMENT_DURATION_TEXT] as String? ?? '',
      employmentDurationType: EmploymentDurationExt.fromString(
          map[EMPLOYMENT_DURATION_TYPE] as String? ?? 'open'),
      experienceLevel: ExperienceLevelExt.fromString(
          map[EXPERIENCE_LEVEL] as String? ?? 'junior'),
      salaryMin: _asDouble(map[SALARY_MIN]), // BUG-13/28: blank-safe
      salaryMax: _asDouble(map[SALARY_MAX]),
      salaryCurrency: map[SALARY_CURRENCY] as String? ?? 'SAR',
      requiredQualification: BilingualTextJob.fromMap(
          (map[REQUIRED_QUALIFICATION] as Map<String, dynamic>?) ?? {}),
      requiredSkills: ((map[REQUIRED_SKILLS] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => SkillItem.fromMap(s))
          .toList(),
      aboutThisPosition: BilingualTextJob.fromMap(
          (map[ABOUT_THIS_POSITION] as Map<String, dynamic>?) ?? {}),
      requirements: BilingualTextJob.fromMap(
          (map[REQUIREMENTS] as Map<String, dynamic>?) ?? {}),
      preferredSkills: BilingualTextJob.fromMap(
          (map[PREFERRED_SKILLS] as Map<String, dynamic>?) ?? {}),
      benefits: ((map[BENEFITS] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map((b) => BenefitItem.fromMap(b))
          .toList(),
      hiringStartDate: map[HIRING_START_DATE] != null
          ? _asDate(map[HIRING_START_DATE])
          : null,
      hiringEndDate: map[HIRING_END_DATE] != null
          ? _asDate(map[HIRING_END_DATE])
          : null,
      // BUG-34: tolerate num/String — a strict `as int?` could lose the value.
      maxApplications: _asInt(map[MAX_APPLICATIONS]),
      requiredDocuments:
      ((map[REQUIRED_DOCUMENTS] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map((d) => RequiredDocument.fromMap(d))
          .toList(),
      status: JobStatusExt.fromString(
          map[STATUS] as String? ?? 'drafted'),
      postedDate: map[POSTED_DATE] != null
          ? _asDate(map[POSTED_DATE])
          : null,
      endedDate: map[ENDED_DATE] != null
          ? _asDate(map[ENDED_DATE])
          : null,
      totalApplications: _asInt(map[TOTAL_APPLICATIONS]),
      publishStatus: map[PUBLISH_STATUS] as String? ?? 'draft',
      unsetFields: ((map['unsetFields'] as String?) ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    ).withDerivedStatus(); // BUG-11
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return v.trim().isEmpty ? null : DateTime.tryParse(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    try {
      return (v as dynamic).toDate() as DateTime; // Firestore Timestamp
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
    TITLE: title.toMap(),
    DEPARTMENT: department,
    'location': location,
    WORK_TYPE: workType.label,
    EMPLOYMENT_TYPE: employmentType.label,
    EMPLOYMENT_DURATION_TEXT: employmentDurationText,
    EMPLOYMENT_DURATION_TYPE: employmentDurationType.label,
    EXPERIENCE_LEVEL: experienceLevel.label,
    SALARY_MIN: salaryMin,
    SALARY_MAX: salaryMax,
    SALARY_CURRENCY: salaryCurrency,
    REQUIRED_QUALIFICATION: requiredQualification.toMap(),
    REQUIRED_SKILLS: requiredSkills.map((s) => s.toMap()).toList(),
    ABOUT_THIS_POSITION: aboutThisPosition.toMap(),
    REQUIREMENTS: requirements.toMap(),
    PREFERRED_SKILLS: preferredSkills.toMap(),
    BENEFITS: benefits.map((b) => b.toMap()).toList(),
    HIRING_START_DATE: hiringStartDate?.toIso8601String(),
    HIRING_END_DATE: hiringEndDate?.toIso8601String(),
    MAX_APPLICATIONS: maxApplications,
    REQUIRED_DOCUMENTS:
    requiredDocuments.map((d) => d.toMap()).toList(),
    STATUS: status.label,
    POSTED_DATE: postedDate?.toIso8601String(),
    ENDED_DATE: endedDate?.toIso8601String(),
    TOTAL_APPLICATIONS: totalApplications,
    PUBLISH_STATUS: publishStatus,
    'unsetFields': unsetFields.join(','),
  };

  /// Nested template for [FlatCodec.decode] (one populated sample per list).
  static Map<String, dynamic> get flatTemplate => {
        'title': {'en': '', 'ar': ''},
        'department': '',
        'location': '',
        'workType': '',
        'employmentType': '',
        'employmentDurationText': '',
        'employmentDurationType': '',
        'experienceLevel': '',
        'salaryMin': 0,
        'salaryMax': 0,
        'salaryCurrency': '',
        'requiredQualification': {'en': '', 'ar': ''},
        'requiredSkills': [
          {
            'id': '',
            'name': {'en': '', 'ar': ''}
          }
        ],
        'aboutThisPosition': {'en': '', 'ar': ''},
        'requirements': {'en': '', 'ar': ''},
        'preferredSkills': {'en': '', 'ar': ''},
        'benefits': [
          {
            'id': '',
            'title': {'en': '', 'ar': ''},
            'shortDescription': {'en': '', 'ar': ''},
          }
        ],
        'hiringStartDate': '',
        'hiringEndDate': '',
        'maxApplications': 0,
        'requiredDocuments': [
          {'id': '', 'name': '', 'nameAr': '', 'docType': '', 'isRequired': true}
        ],
        'status': '',
        'postedDate': '',
        'endedDate': '',
        'totalApplications': 0,
        'publishStatus': '',
        'unsetFields': '',
      };

  JobPostModel copyWith({
    String? id,
    BilingualTextJob? title,
    String? department,
    String? location,
    WorkType? workType,
    EmploymentType? employmentType,
    String? employmentDurationText,
    EmploymentDuration? employmentDurationType,
    ExperienceLevel? experienceLevel,
    double? salaryMin,
    double? salaryMax,
    String? salaryCurrency,
    BilingualTextJob? requiredQualification,
    List<SkillItem>? requiredSkills,
    BilingualTextJob? aboutThisPosition,
    BilingualTextJob? requirements,
    BilingualTextJob? preferredSkills,
    List<BenefitItem>? benefits,
    DateTime? hiringStartDate,
    DateTime? hiringEndDate,
    int? maxApplications,
    List<RequiredDocument>? requiredDocuments,
    JobStatus? status,
    DateTime? postedDate,
    DateTime? endedDate,
    int? totalApplications,
    String? publishStatus,
    List<String>? unsetFields,
  }) =>
      JobPostModel(
        id: id ?? this.id,
        title: title ?? this.title,
        department: department ?? this.department,
        location: location ?? this.location,
        workType: workType ?? this.workType,
        employmentType: employmentType ?? this.employmentType,
        employmentDurationText:
        employmentDurationText ?? this.employmentDurationText,
        employmentDurationType:
        employmentDurationType ?? this.employmentDurationType,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        salaryMin: salaryMin ?? this.salaryMin,
        salaryMax: salaryMax ?? this.salaryMax,
        salaryCurrency: salaryCurrency ?? this.salaryCurrency,
        requiredQualification:
        requiredQualification ?? this.requiredQualification,
        requiredSkills: requiredSkills ?? this.requiredSkills,
        aboutThisPosition: aboutThisPosition ?? this.aboutThisPosition,
        requirements: requirements ?? this.requirements,
        preferredSkills: preferredSkills ?? this.preferredSkills,
        benefits: benefits ?? this.benefits,
        hiringStartDate: hiringStartDate ?? this.hiringStartDate,
        hiringEndDate: hiringEndDate ?? this.hiringEndDate,
        maxApplications: maxApplications ?? this.maxApplications,
        requiredDocuments: requiredDocuments ?? this.requiredDocuments,
        status: status ?? this.status,
        postedDate: postedDate ?? this.postedDate,
        endedDate: endedDate ?? this.endedDate,
        totalApplications: totalApplications ?? this.totalApplications,
        publishStatus: publishStatus ?? this.publishStatus,
        unsetFields: unsetFields ?? this.unsetFields,
      );

  /// Generate demo jobs matching the Figma grid
  static List<JobPostModel> demoJobs() => [
    JobPostModel(
      id: '1',
      title: const BilingualTextJob(en: 'Sr. UX Designer', ar: 'مصمم UX أول'),
      department: 'Design',
      workType: WorkType.onSite,
      employmentType: EmploymentType.fullTime,
      employmentDurationText: '3 Years Exp',
      experienceLevel: ExperienceLevel.senior,
      salaryMin: 10000, salaryMax: 50000, salaryCurrency: 'SAR',
      requiredQualification: const BilingualTextJob(en: 'Have a degree related with Design'),
      requiredSkills: [SkillItem(id: '1', name: const BilingualTextJob(en: 'Compensation'))],
      aboutThisPosition: const BilingualTextJob(en: 'Collaborate with the Marketing Director and Lead Product Designer to define Pawlicy\'s brand identity and build comprehensive brand guidelines'),
      requirements: const BilingualTextJob(en: '3+ years of experience in marketing, brand, or graphic design'),
      preferredSkills: const BilingualTextJob(en: '3+ years of experience in marketing, brand, or graphic design'),
      benefits: [
        BenefitItem(id: '1', title: const BilingualTextJob(en: 'Competitive Compensation'), shortDescription: const BilingualTextJob(en: 'We offer competitive salary packages to reward your skills, experience, and dedication to the company.')),
        BenefitItem(id: '2', title: const BilingualTextJob(en: 'Paid Time Off'), shortDescription: const BilingualTextJob(en: 'Vacation Leave: Generous vacation days to relax and recharge.')),
        BenefitItem(id: '3', title: const BilingualTextJob(en: 'Professional Development'), shortDescription: const BilingualTextJob(en: 'Training Opportunities: Access to workshops, courses, and resources.')),
        BenefitItem(id: '4', title: const BilingualTextJob(en: 'Flexible Work Arrangements'), shortDescription: const BilingualTextJob(en: 'Remote Work: We support flexible work arrangements.')),
      ],
      hiringStartDate: DateTime(2026, 8, 28),
      hiringEndDate: DateTime(2026, 8, 28),
      maxApplications: 100,
      requiredDocuments: [RequiredDocument(id: '1', name: 'Resume', docType: DocType.pdf), RequiredDocument(id: '2', name: 'Cover Letter', docType: DocType.pdf)],
      status: JobStatus.active,
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
      totalApplications: 100,
      publishStatus: 'published',
    ),
    JobPostModel(
      id: '2',
      title: const BilingualTextJob(en: 'Sr. UX Designer', ar: 'مصمم UX أول'),
      department: 'Design', workType: WorkType.remote,
      employmentType: EmploymentType.fullTime,
      employmentDurationText: '3 Years Exp',
      experienceLevel: ExperienceLevel.senior,
      salaryMin: 10000, salaryMax: 50000, salaryCurrency: 'SAR',
      status: JobStatus.ended,
      endedDate: DateTime(2026, 7, 12),
      totalApplications: 100,
      publishStatus: 'published',
    ),
    JobPostModel(
      id: '3',
      title: const BilingualTextJob(en: 'Sr. UX Designer', ar: 'مصمم UX أول'),
      department: 'Design', workType: WorkType.onSite,
      employmentType: EmploymentType.fullTime,
      employmentDurationText: '3 Years Exp',
      experienceLevel: ExperienceLevel.senior,
      salaryMin: 10000, salaryMax: 50000, salaryCurrency: 'SAR',
      status: JobStatus.removed,
      endedDate: DateTime(2026, 7, 12),
      totalApplications: 0,
      publishStatus: 'published',
    ),
    JobPostModel(
      id: '4',
      title: const BilingualTextJob(en: 'Sr. UX Designer'),
      department: 'Design', workType: WorkType.onSite,
      employmentType: EmploymentType.fullTime,
      employmentDurationText: '3 Years Exp',
      experienceLevel: ExperienceLevel.senior,
      salaryMin: 10000, salaryMax: 50000, salaryCurrency: 'SAR',
      status: JobStatus.scheduled,
      postedDate: DateTime(2026, 7, 12),
      publishStatus: 'published',
    ),
    JobPostModel(
      id: '5',
      title: const BilingualTextJob(en: 'Sr. UX Designer'),
      department: 'Design', workType: WorkType.onSite,
      employmentType: EmploymentType.fullTime,
      employmentDurationText: '3 Years Exp',
      experienceLevel: ExperienceLevel.senior,
      salaryMin: 10000, salaryMax: 50000, salaryCurrency: 'SAR',
      status: JobStatus.drafted,
      publishStatus: 'draft',
    ),
    JobPostModel(
      id: '6',
      title: const BilingualTextJob(en: 'Sr. UX Designer'),
      department: 'Design', workType: WorkType.onSite,
      employmentType: EmploymentType.fullTime,
      employmentDurationText: '3 Years Exp',
      experienceLevel: ExperienceLevel.senior,
      salaryMin: 10000, salaryMax: 50000, salaryCurrency: 'SAR',
      status: JobStatus.inactive,
      endedDate: DateTime(2026, 7, 12),
      publishStatus: 'published',
    ),
  ];
}