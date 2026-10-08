// ═══════════════════════════════════════════════════════════════════
// FILE 1: application_model.dart
// Path: lib/features/job/data/models/application_model.dart
// ═══════════════════════════════════════════════════════════════════

class ApplicationModel {
  // ── Firestore field keys ──────────────────────────────────────────────────
  static const String APPLICATION_DATE = 'applicationDate';
  static const String APPLIED = 'applied';
  static const String COMMENTS = 'comments';
  static const String COMMUNICATION_SKILLS = 'communicationSkills';
  static const String COUNTRY_CODE = 'countryCode';
  static const String COVER_LETTER_NAME = 'coverLetterName';
  static const String COVER_LETTER_URL = 'coverLetterUrl';
  static const String CULTURE_FIT = 'cultureFit';
  static const String CURRENCY = 'currency';
  static const String DEPARTMENT = 'department';
  static const String DOCUMENTS = 'documents';
  static const String EMAIL = 'email';
  static const String EMPLOYMENT_DURATION = 'employmentDuration';
  static const String EMPLOYMENT_TYPE = 'employmentType';
  static const String EXPERIENCE_BACKGROUND = 'experienceBackground';
  static const String EXPERIENCE_LEVEL = 'experienceLevel';
  static const String FIRST_NAME = 'firstName';
  static const String INTERVIEW_DATE = 'interviewDate';
  static const String JOB_ID = 'jobId';
  static const String JOB_LOCATION = 'jobLocation';
  static const String JOB_TITLE = 'jobTitle';
  static const String LAST_NAME = 'lastName';
  static const String LAST_UPDATE = 'lastUpdate';
  static const String LEADERSHIP_POTENTIAL = 'leadershipPotential';
  static const String PHONE = 'phone';
  static const String QUALIFIED = 'qualified';
  static const String REQUIRED_QUALIFICATION = 'requiredQualification';
  static const String REQUIRED_SKILLS = 'requiredSkills';
  static const String RESUME_NAME = 'resumeName';
  static const String RESUME_URL = 'resumeUrl';
  static const String SALARY_RANGE = 'salaryRange';
  static const String SOURCE = 'source';
  static const String STATUS = 'status';
  static const String TAG = 'tag';
  static const String TECHNICAL_SKILLS = 'technicalSkills';
  static const String UNQUALIFIED = 'unqualified';
  static const String WORK_TYPE = 'workType';
  static const String YEAR_OF_GRADUATION = 'yearOfGraduation';
  static const String GENDER = 'gender'; // BUG-85

  final String id;
  final String jobId;
  final String jobTitle;
  final String department;

  // Personal Info
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String countryCode;
  final String yearOfGraduation;
  /// BUG-85: 'Male' / 'Female' / '' (not answered) — from the Apply form.
  final String gender;

  // Profile / Documents
  final String resumeUrl;
  final String resumeName;
  final String coverLetterUrl;
  final String coverLetterName;

  /// Dynamic documents array written by the apply form:
  /// [{name, docType (PDF|Link), url, fileName}]
  final List<ApplicationDocument> documents;

  // Status
  final ApplicationStatus status;
  final String tag; // 'Weak', 'Adequate', 'Strong'

  // Scoring Interview
  final int technicalSkills;
  final int communicationSkills;
  final int experienceBackground;
  final int cultureFit;
  final int leadershipPotential;
  final String comments;

  // Meta
  final DateTime? applicationDate;
  final DateTime? interviewDate;
  final DateTime? lastUpdate;
  final String source;
  final String workType;
  final String employmentType;
  final String experienceLevel;
  final String salaryRange;
  final String currency;
  final String jobLocation;
  final String employmentDuration;
  final String requiredQualification;
  final String requiredSkills;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    this.jobTitle = '',
    this.department = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.countryCode = '+234',
    this.yearOfGraduation = '',
    this.gender = '',
    this.resumeUrl = '',
    this.resumeName = '',
    this.coverLetterUrl = '',
    this.coverLetterName = '',
    this.documents = const [],
    this.status = ApplicationStatus.applied,
    this.tag = '',
    this.technicalSkills = 0,
    this.communicationSkills = 0,
    this.experienceBackground = 0,
    this.cultureFit = 0,
    this.leadershipPotential = 0,
    this.comments = '',
    this.applicationDate,
    this.interviewDate,
    this.lastUpdate,
    this.source = '',
    this.workType = '',
    this.employmentType = '',
    this.experienceLevel = '',
    this.salaryRange = '',
    this.currency = '',
    this.jobLocation = '',
    this.employmentDuration = '',
    this.requiredQualification = '',
    this.requiredSkills = '',
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return ApplicationModel(
      id: id,
      jobId: map[JOB_ID] as String? ?? '',
      jobTitle: map[JOB_TITLE] as String? ?? '',
      department: map[DEPARTMENT] as String? ?? '',
      firstName: map[FIRST_NAME] as String? ?? '',
      lastName: map[LAST_NAME] as String? ?? '',
      email: map[EMAIL] as String? ?? '',
      phone: map[PHONE] as String? ?? '',
      countryCode: map[COUNTRY_CODE] as String? ?? '+234',
      yearOfGraduation: map[YEAR_OF_GRADUATION] as String? ?? '',
      gender: map[GENDER] as String? ?? '',
      resumeUrl: map[RESUME_URL] as String? ?? '',
      resumeName: map[RESUME_NAME] as String? ?? '',
      coverLetterUrl: map[COVER_LETTER_URL] as String? ?? '',
      coverLetterName: map[COVER_LETTER_NAME] as String? ?? '',
      documents: ((map[DOCUMENTS] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map((d) => ApplicationDocument.fromMap(d))
          .toList(),
      status: ApplicationStatusExt.fromString(map[STATUS] as String? ?? 'Applied'),
      tag: map[TAG] as String? ?? '',
      technicalSkills: map[TECHNICAL_SKILLS] as int? ?? 0,
      communicationSkills: map[COMMUNICATION_SKILLS] as int? ?? 0,
      experienceBackground: map[EXPERIENCE_BACKGROUND] as int? ?? 0,
      cultureFit: map[CULTURE_FIT] as int? ?? 0,
      leadershipPotential: map[LEADERSHIP_POTENTIAL] as int? ?? 0,
      comments: map[COMMENTS] as String? ?? '',
      applicationDate: map[APPLICATION_DATE] != null
          ? DateTime.tryParse(map[APPLICATION_DATE] as String)
          : null,
      interviewDate: map[INTERVIEW_DATE] != null
          ? DateTime.tryParse(map[INTERVIEW_DATE] as String)
          : null,
      lastUpdate: map[LAST_UPDATE] != null
          ? DateTime.tryParse(map[LAST_UPDATE] as String)
          : null,
      source: map[SOURCE] as String? ?? '',
      workType: map[WORK_TYPE] as String? ?? '',
      employmentType: map[EMPLOYMENT_TYPE] as String? ?? '',
      experienceLevel: map[EXPERIENCE_LEVEL] as String? ?? '',
      salaryRange: map[SALARY_RANGE] as String? ?? '',
      currency: map[CURRENCY] as String? ?? '',
      jobLocation: map[JOB_LOCATION] as String? ?? '',
      employmentDuration: map[EMPLOYMENT_DURATION] as String? ?? '',
      requiredQualification: map[REQUIRED_QUALIFICATION] as String? ?? '',
      requiredSkills: map[REQUIRED_SKILLS] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    JOB_ID: jobId,
    JOB_TITLE: jobTitle,
    DEPARTMENT: department,
    FIRST_NAME: firstName,
    LAST_NAME: lastName,
    EMAIL: email,
    PHONE: phone,
    COUNTRY_CODE: countryCode,
    YEAR_OF_GRADUATION: yearOfGraduation,
    GENDER: gender,
    RESUME_URL: resumeUrl,
    RESUME_NAME: resumeName,
    COVER_LETTER_URL: coverLetterUrl,
    COVER_LETTER_NAME: coverLetterName,
    DOCUMENTS: documents.map((d) => d.toMap()).toList(),
    STATUS: status.label,
    TAG: tag,
    TECHNICAL_SKILLS: technicalSkills,
    COMMUNICATION_SKILLS: communicationSkills,
    EXPERIENCE_BACKGROUND: experienceBackground,
    CULTURE_FIT: cultureFit,
    LEADERSHIP_POTENTIAL: leadershipPotential,
    COMMENTS: comments,
    APPLICATION_DATE: (applicationDate ?? DateTime.now()).toIso8601String(),
    INTERVIEW_DATE: interviewDate?.toIso8601String(),
    LAST_UPDATE: lastUpdate?.toIso8601String(),
    SOURCE: source,
    WORK_TYPE: workType,
    EMPLOYMENT_TYPE: employmentType,
    EXPERIENCE_LEVEL: experienceLevel,
    SALARY_RANGE: salaryRange,
    CURRENCY: currency,
    JOB_LOCATION: jobLocation,
    EMPLOYMENT_DURATION: employmentDuration,
    REQUIRED_QUALIFICATION: requiredQualification,
    REQUIRED_SKILLS: requiredSkills,
  };

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? department,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? countryCode,
    String? yearOfGraduation,
    String? gender,
    String? resumeUrl,
    String? resumeName,
    String? coverLetterUrl,
    String? coverLetterName,
    List<ApplicationDocument>? documents,
    ApplicationStatus? status,
    String? tag,
    int? technicalSkills,
    int? communicationSkills,
    int? experienceBackground,
    int? cultureFit,
    int? leadershipPotential,
    String? comments,
    DateTime? applicationDate,
    DateTime? interviewDate,
    DateTime? lastUpdate,
    String? source,
    String? workType,
    String? employmentType,
    String? experienceLevel,
    String? salaryRange,
    String? currency,
    String? jobLocation,
    String? employmentDuration,
    String? requiredQualification,
    String? requiredSkills,
  }) =>
      ApplicationModel(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        jobTitle: jobTitle ?? this.jobTitle,
        department: department ?? this.department,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        countryCode: countryCode ?? this.countryCode,
        yearOfGraduation: yearOfGraduation ?? this.yearOfGraduation,
        gender: gender ?? this.gender,
        resumeUrl: resumeUrl ?? this.resumeUrl,
        resumeName: resumeName ?? this.resumeName,
        coverLetterUrl: coverLetterUrl ?? this.coverLetterUrl,
        coverLetterName: coverLetterName ?? this.coverLetterName,
        documents: documents ?? this.documents,
        status: status ?? this.status,
        tag: tag ?? this.tag,
        technicalSkills: technicalSkills ?? this.technicalSkills,
        communicationSkills: communicationSkills ?? this.communicationSkills,
        experienceBackground: experienceBackground ?? this.experienceBackground,
        cultureFit: cultureFit ?? this.cultureFit,
        leadershipPotential: leadershipPotential ?? this.leadershipPotential,
        comments: comments ?? this.comments,
        applicationDate: applicationDate ?? this.applicationDate,
        interviewDate: interviewDate ?? this.interviewDate,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        source: source ?? this.source,
        workType: workType ?? this.workType,
        employmentType: employmentType ?? this.employmentType,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        salaryRange: salaryRange ?? this.salaryRange,
        currency: currency ?? this.currency,
        jobLocation: jobLocation ?? this.jobLocation,
        employmentDuration: employmentDuration ?? this.employmentDuration,
        requiredQualification: requiredQualification ?? this.requiredQualification,
        requiredSkills: requiredSkills ?? this.requiredSkills,
      );
}

// ── Application Document (from the dynamic apply form) ───────────────────────

class ApplicationDocument {
  final String name;     // e.g. "Resume", "Portfolio"
  final String docType;  // "PDF" or "Link"
  final String url;
  final String fileName;

  const ApplicationDocument({
    this.name = '',
    this.docType = 'PDF',
    this.url = '',
    this.fileName = '',
  });

  factory ApplicationDocument.fromMap(Map<String, dynamic> map) =>
      ApplicationDocument(
        name: map['name'] as String? ?? '',
        docType: map['docType'] as String? ?? 'PDF',
        url: map['url'] as String? ?? '',
        fileName: map['fileName'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'docType': docType,
        'url': url,
        'fileName': fileName,
      };
}

// ── Status Enum ──────────────────────────────────────────────────────────────

enum ApplicationStatus {
  applied,
  qualified,
  unqualified,
  interviewPassed,
  interviewFailed,
  interviewWithdrew,
  offerApproved,
  offerPending,
  offerRejected,
  hired,
}

extension ApplicationStatusExt on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.applied:           return 'Applied';
      case ApplicationStatus.qualified:         return 'Qualified';
      case ApplicationStatus.unqualified:       return 'Unqualified';
      case ApplicationStatus.interviewPassed:   return 'Interview: Passed';
      case ApplicationStatus.interviewFailed:   return 'Interview: Failed';
      case ApplicationStatus.interviewWithdrew: return 'Interview: Withdrew';
      case ApplicationStatus.offerApproved:     return 'Offer: Approved';
      case ApplicationStatus.offerPending:      return 'Offer: Pending';
      case ApplicationStatus.offerRejected:     return 'Offer: Rejected';
      case ApplicationStatus.hired:             return 'Hired: Completed';
    }
  }

  /// Which pipeline stage this status belongs to
  String get stage {
    switch (this) {
      case ApplicationStatus.applied:
      case ApplicationStatus.qualified:
      case ApplicationStatus.unqualified:
        return 'Applied';
      case ApplicationStatus.interviewPassed:
      case ApplicationStatus.interviewFailed:
      case ApplicationStatus.interviewWithdrew:
        return 'Interview';
      case ApplicationStatus.offerApproved:
      case ApplicationStatus.offerPending:
      case ApplicationStatus.offerRejected:
        return 'Offer';
      case ApplicationStatus.hired:
        return 'Hired';
    }
  }

  static ApplicationStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'applied':           return ApplicationStatus.applied;
      case 'qualified':         return ApplicationStatus.qualified;
      case 'unqualified':       return ApplicationStatus.unqualified;
      case 'interview: passed':   return ApplicationStatus.interviewPassed;
      case 'interview: failed':   return ApplicationStatus.interviewFailed;
      case 'interview: withdrew': return ApplicationStatus.interviewWithdrew;
      case 'offer: approved':     return ApplicationStatus.offerApproved;
      case 'offer: pending':      return ApplicationStatus.offerPending;
      case 'offer: rejected':     return ApplicationStatus.offerRejected;
      case 'hired: completed':    return ApplicationStatus.hired;
      default:                    return ApplicationStatus.applied;
    }
  }
}