// ******************* FILE INFO *******************
// File Name: careers_model.dart
// Created by: Amr Mesbah
// Purpose: Model for Careers CMS — Overview + Statistics + Dashboard Charts

// ── Bilingual text ────────────────────────────────────────────────────────────



import '../../../job/data/models/application_model.dart';
import '../../../job/data/models/job_listing_model.dart';

class BilingualText {
  final String en;
  final String ar;

  const BilingualText({this.en = '', this.ar = ''});

  factory BilingualText.fromMap(Map<String, dynamic> map) => BilingualText(
    en: map['en'] as String? ?? '',
    ar: map['ar'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'en': en, 'ar': ar};

  BilingualText copyWith({String? en, String? ar}) =>
      BilingualText(en: en ?? this.en, ar: ar ?? this.ar);

  bool get isEmpty => en.isEmpty && ar.isEmpty;
}

// ── Career Statistic Item ─────────────────────────────────────────────────────

// PATCH — replace your CareerStatItem class in careers_model.dart with this version
// Added: iconUrl field (Firebase Storage download URL for the SVG icon)

class CareerStatItem {
  final String id;
  final BilingualText title;
  final BilingualText shortDescription;
  final String summaryValue;
  final String iconUrl; // ← NEW

  const CareerStatItem({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.summaryValue,
    this.iconUrl = '',
  });

  factory CareerStatItem.empty() => CareerStatItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: const BilingualText(),
    shortDescription: const BilingualText(),
    summaryValue: '',
    iconUrl: '',
  );

  factory CareerStatItem.fromMap(String id, Map<String, dynamic> map) =>
      CareerStatItem(
        id: id,
        title: BilingualText.fromMap(
            (map['title'] as Map<String, dynamic>?) ?? {}),
        shortDescription: BilingualText.fromMap(
            (map['shortDescription'] as Map<String, dynamic>?) ?? {}),
        summaryValue: map['summaryValue'] as String? ?? '',
        iconUrl: map['iconUrl'] as String? ?? '', // ← read from Firestore
      );

  Map<String, dynamic> toMap() => {
    'title': title.toMap(),
    'shortDescription': shortDescription.toMap(),
    'summaryValue': summaryValue,
    'iconUrl': iconUrl, // ← write to Firestore
  };

  CareerStatItem copyWith({
    String? id,
    BilingualText? title,
    BilingualText? shortDescription,
    String? summaryValue,
    String? iconUrl,
  }) =>
      CareerStatItem(
        id: id ?? this.id,
        title: title ?? this.title,
        shortDescription: shortDescription ?? this.shortDescription,
        summaryValue: summaryValue ?? this.summaryValue,
        iconUrl: iconUrl ?? this.iconUrl,
      );
}

// ── Careers Overview ─────────────────────────────────────────────────────────

class CareersOverview {
  final BilingualText description;
  final BilingualText actionButtonLabel;

  const CareersOverview({
    required this.description,
    required this.actionButtonLabel,
  });

  factory CareersOverview.empty() => const CareersOverview(
    description: BilingualText(),
    actionButtonLabel: BilingualText(),
  );

  factory CareersOverview.fromMap(Map<String, dynamic> map) => CareersOverview(
    description: BilingualText.fromMap(
        (map['description'] as Map<String, dynamic>?) ?? {}),
    actionButtonLabel: BilingualText.fromMap(
        (map['actionButtonLabel'] as Map<String, dynamic>?) ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'description': description.toMap(),
    'actionButtonLabel': actionButtonLabel.toMap(),
  };

  CareersOverview copyWith({
    BilingualText? description,
    BilingualText? actionButtonLabel,
  }) =>
      CareersOverview(
        description: description ?? this.description,
        actionButtonLabel: actionButtonLabel ?? this.actionButtonLabel,
      );
}

// ── Dashboard Stat Card ──────────────────────────────────────────────────────

class DashboardStatCard {
  final String label;
  final int value;
  final String iconAsset;

  const DashboardStatCard({
    required this.label,
    required this.value,
    this.iconAsset = '',
  });

  factory DashboardStatCard.fromMap(Map<String, dynamic> map) =>
      DashboardStatCard(
        label: map['label'] as String? ?? '',
        value: map['value'] as int? ?? 0,
        iconAsset: map['iconAsset'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'label': label,
    'value': value,
    'iconAsset': iconAsset,
  };
}

// ── Hiring Stage Item (for funnel chart) ─────────────────────────────────────

class HiringStageItem {
  final String label;
  final int value;

  const HiringStageItem({required this.label, required this.value});

  factory HiringStageItem.fromMap(Map<String, dynamic> map) => HiringStageItem(
    label: map['label'] as String? ?? '',
    value: map['value'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {'label': label, 'value': value};
}

// ── Score Distribution Item ──────────────────────────────────────────────────

class ScoreDistributionItem {
  final String label;
  final int value;
  final String colorHex;

  const ScoreDistributionItem({
    required this.label,
    required this.value,
    required this.colorHex,
  });

  factory ScoreDistributionItem.fromMap(Map<String, dynamic> map) =>
      ScoreDistributionItem(
        label: map['label'] as String? ?? '',
        value: map['value'] as int? ?? 0,
        colorHex: map['colorHex'] as String? ?? '#CCCCCC',
      );

  Map<String, dynamic> toMap() => {
    'label': label,
    'value': value,
    'colorHex': colorHex,
  };
}

// ── Careers Dashboard Data ───────────────────────────────────────────────────

class CareersDashboardData {
  // Stat cards
  final List<DashboardStatCard> statCards;

  // Applications Received — monthly bar chart
  final List<String> appReceivedLabels;
  final List<double> appReceivedValues;

  // Job Posting Status — grouped bar chart
  final List<String> jobPostingLabels;
  final List<double> jobPostingActive;
  final List<double> jobPostingClosed;
  final List<double> jobPostingScheduled;
  final List<double> jobPostingDraft;

  // Hiring Stage — funnel
  final List<HiringStageItem> hiringStages;

  // Job Status — pie chart
  final Map<String, double> jobStatus;
  final int jobStatusTotal;

  // Candidate Quality — pie chart
  final double qualifiedPercent;
  final double unqualifiedPercent;
  /// BUG-258: share of applicants still at "Applied" (not reviewed yet).
  final double notReviewedPercent;
  final int totalApplications;

  // Jobs Performance — grouped bar per role
  final List<String> performanceRoles;
  final List<double> performanceApplications;
  final List<double> performanceInterviews;
  final List<double> performanceHires;

  // Job Offer — pie chart
  final int jobOfferApproved;
  final int jobOfferPending;
  final int jobOfferRejected;

  // Candidate Score Distribution — segmented bar
  final List<ScoreDistributionItem> scoreDistribution;

  // Employment Types — horizontal bar + pie
  final Map<String, double> employmentTypes;

  // Candidate Gender — pie chart
  final double malePercent;
  final double femalePercent;

  /// BUG-85: real applicant counts per gender ('Male' / 'Female' /
  /// 'Not specified') for the "Candidate Gender" chart.
  final Map<String, double> genderCounts;

  const CareersDashboardData({
    required this.statCards,
    required this.appReceivedLabels,
    required this.appReceivedValues,
    required this.jobPostingLabels,
    required this.jobPostingActive,
    required this.jobPostingClosed,
    required this.jobPostingScheduled,
    required this.jobPostingDraft,
    required this.hiringStages,
    required this.jobStatus,
    required this.jobStatusTotal,
    required this.qualifiedPercent,
    required this.unqualifiedPercent,
    this.notReviewedPercent = 0,
    required this.totalApplications,
    required this.performanceRoles,
    required this.performanceApplications,
    required this.performanceInterviews,
    required this.performanceHires,
    required this.jobOfferApproved,
    required this.jobOfferPending,
    required this.jobOfferRejected,
    required this.scoreDistribution,
    required this.employmentTypes,
    required this.malePercent,
    required this.femalePercent,
    this.genderCounts = const {},
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  REAL DATA FACTORY — computed from Firestore jobs + applications
  // ═══════════════════════════════════════════════════════════════════════════

  factory CareersDashboardData.fromRealData({
    required List<JobPostModel> jobs,
    required List<ApplicationModel> apps,
  }) {
    // BUG-22 / BUG-31: every widget below is computed from this ONE list.
    // Removed jobs are deleted from the admin's point of view, so they are
    // left out everywhere (they used to keep deleted departments and junk
    // titles alive on the charts).
    jobs = jobs.where((j) => j.status != JobStatus.removed).toList();

    // ── Stat Cards ────────────────────────────────────────────────────────────
    final totalJobs     = jobs.length;
    // "Office" = any job that involves the office: On Site AND Hybrid (Hybrid
    // was counted nowhere, so Office + Remote never equalled All Jobs).
    // BUG-268: work-type cards add up to All Jobs (On Site + Hybrid +
    // Remote — Hybrid was hidden inside "Office"), and status cards add up
    // too (Active + Scheduled + Inactive/Ended + Draft).
    final onSiteJobs    = jobs.where((j) =>
        !j.isUnset('workType') && j.workType == WorkType.onSite).length;
    final hybridJobs    = jobs.where((j) =>
        !j.isUnset('workType') && j.workType == WorkType.hybrid).length;
    final remoteJobs    = jobs.where((j) =>
        !j.isUnset('workType') && j.workType == WorkType.remote).length;
    final activeJobs    = jobs.where((j) => j.status == JobStatus.active).length;
    final scheduledJobs = jobs.where((j) => j.status == JobStatus.scheduled).length;
    final closedJobs    = jobs.where((j) =>
        j.status == JobStatus.ended || j.status == JobStatus.inactive).length;
    final draftedJobs   = jobs.where((j) => j.status == JobStatus.drafted).length;

    final statCards = [
      DashboardStatCard(label: 'All Jobs',          value: totalJobs,   iconAsset: 'assets/images/job_list/all_job.svg'),
      DashboardStatCard(label: 'On Site Jobs',      value: onSiteJobs,  iconAsset: 'assets/images/job_list/office_job.svg'),
      DashboardStatCard(label: 'Hybrid Jobs',       value: hybridJobs,  iconAsset: 'assets/images/job_list/office_job.svg'),
      DashboardStatCard(label: 'Remote Jobs',       value: remoteJobs,  iconAsset: 'assets/images/job_list/remote_job.svg'),
      // BUG-41: plural, like "All Jobs" / "Office Jobs".
      DashboardStatCard(label: 'Active Jobs',       value: activeJobs,  iconAsset: 'assets/images/job_list/active_job.svg'),
      DashboardStatCard(label: 'Scheduled Jobs',    value: scheduledJobs, iconAsset: 'assets/images/job_list/active_job.svg'),
      // BUG-279: Job Listing names ("Inactive" / "Ended", "Draft").
      DashboardStatCard(label: 'Inactive / Ended',  value: closedJobs,  iconAsset: 'assets/images/job_list/requiement_end.svg'),
      DashboardStatCard(label: 'Draft Jobs',        value: draftedJobs, iconAsset: 'assets/images/job_list/dradt.svg'),
    ];

    // ── Applications Received — group by month of applicationDate ─────────────
    final monthLabels = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final monthCounts = List<double>.filled(12, 0);
    for (final app in apps) {
      if (app.applicationDate != null) {
        monthCounts[app.applicationDate!.month - 1]++;
      }
    }

    // ── Job Posting Status — BUG-21: grouped by STATUS (the chart's title and
    // legend), not by department. One bar per status, coloured per legend.
    // BUG-279: the same status names as the Job Listing tabs (one bar each):
    // Active · Scheduled · Inactive · Ended · Draft — "Closed" merged two.
    final deptLabels = <String>['Active', 'Scheduled', 'Inactive', 'Ended', 'Draft'];
    final nActive    = jobs.where((j) => j.status == JobStatus.active).length.toDouble();
    final nInactive  = jobs.where((j) => j.status == JobStatus.inactive).length.toDouble();
    final nEnded     = jobs.where((j) => j.status == JobStatus.ended).length.toDouble();
    final nScheduled = jobs.where((j) => j.status == JobStatus.scheduled).length.toDouble();
    final nDraft     = jobs.where((j) => j.status == JobStatus.drafted).length.toDouble();
    final qActive    = <double>[nActive, 0, 0, 0, 0];
    final qScheduled = <double>[0, nScheduled, 0, 0, 0];
    final qClosed    = <double>[0, 0, nInactive, nEnded, 0];
    final qDraft     = <double>[0, 0, 0, 0, nDraft];

    // ── Hiring Stage — funnel from application statuses ───────────────────────
    // An application carries only its CURRENT status, so a hired candidate is
    // no longer "Offer: Approved" and no longer "Interview: Passed". A funnel
    // must count everyone who REACHED a stage, not everyone parked on it —
    // otherwise Hired = 1 sits under Offer Sent = 0, which cannot happen.
    const interviewStatuses = {
      ApplicationStatus.interviewPassed,
      ApplicationStatus.interviewFailed,
      ApplicationStatus.interviewWithdrew,
    };
    const offerStatuses = {
      ApplicationStatus.offerApproved,
      ApplicationStatus.offerPending,
      ApplicationStatus.offerRejected,
    };

    bool isHired(ApplicationModel a) => a.status == ApplicationStatus.hired;
    bool reachedOffer(ApplicationModel a) =>
        offerStatuses.contains(a.status) || isHired(a);
    bool reachedInterview(ApplicationModel a) =>
        interviewStatuses.contains(a.status) || reachedOffer(a);

    final applied     = apps.length; // everyone who applied enters the funnel
    final interviewed = apps.where(reachedInterview).length;
    final offerSent   = apps.where(reachedOffer).length;
    final hired       = apps.where(isHired).length;

    final hiringStages = [
      HiringStageItem(label: 'Applied',  value: applied),
      HiringStageItem(label: 'Interview',  value: interviewed),
      // BUG-278: one stage list everywhere — Applied · Interview · Offer · Hired.
      HiringStageItem(label: 'Offer',      value: offerSent),
      HiringStageItem(label: 'Hired',      value: hired),
    ];

    // ── Job Status — pie chart ────────────────────────────────────────────────
    // Same buckets as Job Posting Status, so every job is in exactly one.
    final statusCounts = <String, double>{
      'Active':    nActive,
      'Scheduled': nScheduled,
      'Inactive':  nInactive, // BUG-279: was "Closed"
      'Ended':     nEnded,
      'Draft':     nDraft,
    }..removeWhere((_, v) => v == 0);

    // BUG-38: the centre of the donut counts JOBS (it said "Total Department").
    final totalForStatus = jobs.length;

    // ── Candidate Quality ─────────────────────────────────────────────────────
    // BUG-258: statuses are counted explicitly. Not-yet-reviewed "Applied"
    // applicants are their own "Not reviewed" slice — they used to be
    // counted as Unqualified (unqualified = total − qualified → 100 %).
    final totalApps      = apps.length;
    final notReviewedCount =
        apps.where((a) => a.status == ApplicationStatus.applied).length;
    final unqualifiedCount =
        apps.where((a) => a.status == ApplicationStatus.unqualified).length;
    final qualifiedCount = totalApps - notReviewedCount - unqualifiedCount;
    final qualifiedPct   = totalApps > 0 ? (qualifiedCount / totalApps * 100) : 0.0;
    final unqualifiedPct = totalApps > 0 ? (unqualifiedCount / totalApps * 100) : 0.0;
    final notReviewedPct = totalApps > 0 ? (notReviewedCount / totalApps * 100) : 0.0;

    // ── Jobs Performance — top 4 job titles by application count ─────────────
    // BUG-19: never show a raw Firestore id as a job name. Resolve the title
    // from the job itself, falling back to "Untitled job".
    final titleById = {for (final j in jobs) j.id: j.displayTitle};
    final jobAppMap = <String, List<ApplicationModel>>{};
    for (final app in apps) {
      final title = app.jobTitle.trim().isNotEmpty
          ? app.jobTitle.trim()
          : (titleById[app.jobId] ?? 'Untitled job');
      jobAppMap.putIfAbsent(title, () => []).add(app);
    }

    // Sort by app count, take top 4
    final sortedEntries = jobAppMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top4 = sortedEntries.take(4).toList();

    final perfRoles = top4.map((e) => e.key).toList();
    final perfApps  = top4.map((e) => e.value.length.toDouble()).toList();
    // Same "reached the stage" rule as the funnel: someone now Hired was
    // interviewed on the way there.
    final perfInterviews = top4
        .map((e) => e.value.where(reachedInterview).length.toDouble())
        .toList();
    final perfHires =
        top4.map((e) => e.value.where(isHired).length.toDouble()).toList();

    // ── Job Offer ─────────────────────────────────────────────────────────────
    // A hired candidate approved their offer — their status has simply moved
    // on to "Hired", so they must still count as Approved here.
    final offerApproved = apps
        .where((a) =>
            a.status == ApplicationStatus.offerApproved || isHired(a))
        .length;
    final offerPending  = apps.where((a) => a.status == ApplicationStatus.offerPending).length;
    final offerRejected = apps.where((a) => a.status == ApplicationStatus.offerRejected).length;

    // ── Score Distribution ────────────────────────────────────────────────────
    // Average score per applicant = mean of all 5 scoring fields (each 0–10 or 0–100)
    // Bucket: Poor(0–20), Weak(21–40), Good(41–60), Very Good(61–80), Excellent(81–100)
    // BUG-84: each criterion is scored 1–5 (the applicant page shows
    // 4/3/5/4/4 = 20/25 = 80 %), but this code compared the 1–5 AVERAGE with
    // 0–100 bands, so every scored applicant landed in "Poor". The score is
    // now the same percentage the applicant page shows.
    int poor = 0, weak = 0, good = 0, veryGood = 0, excellent = 0;
    for (final app in apps) {
      final scores = [
        app.technicalSkills,
        app.communicationSkills,
        app.experienceBackground,
        app.cultureFit,
        app.leadershipPotential,
      ];
      final totalScore = scores.fold<int>(0, (s, v) => s + v);
      // Not scored yet — don't count it in any bucket.
      if (totalScore == 0) continue;
      final maxPer = scores.reduce((a, b) => a > b ? a : b);
      // 1–5 stars (current), older 0–10 or 0–100 data still bucketed right.
      final double scale = maxPer <= 5 ? 5 : (maxPer <= 10 ? 10 : 100);
      final pct = totalScore / (scale * scores.length) * 100;
      if (pct <= 20)       poor++;
      else if (pct <= 40)  weak++;
      else if (pct <= 60)  good++;
      else if (pct <= 80)  veryGood++;
      else                  excellent++;
    }

    final scoreDistribution = [
      ScoreDistributionItem(label: 'Poor',      value: poor,      colorHex: '#D32F2F'),
      ScoreDistributionItem(label: 'Weak',      value: weak,      colorHex: '#F44336'),
      ScoreDistributionItem(label: 'Good',      value: good,      colorHex: '#FF9800'),
      ScoreDistributionItem(label: 'Very Good', value: veryGood,  colorHex: '#E91E63'),
      ScoreDistributionItem(label: 'Excellent', value: excellent, colorHex: '#2E7D32'),
    ];

    // ── Employment Types — BUG-31: from the JOBS' employment type (the chart
    // said "No Data" although the jobs were Full Time / Part Time; it was
    // reading the applicants' experience level instead).
    final fullTimeCount = jobs.where((j) =>
        !j.isUnset('employmentType') &&
        j.employmentType == EmploymentType.fullTime).length.toDouble();
    final partTimeCount = jobs.where((j) =>
        !j.isUnset('employmentType') &&
        j.employmentType == EmploymentType.partTime).length.toDouble();
    final unspecifiedEmp =
        jobs.where((j) => j.isUnset('employmentType')).length.toDouble();

    final employmentTypes = <String, double>{
      if (fullTimeCount  > 0) 'Full Time':   fullTimeCount,
      if (partTimeCount  > 0) 'Part Time':   partTimeCount,
      if (unspecifiedEmp > 0) 'Unspecified': unspecifiedEmp,
    };

    // ── Candidate Gender (BUG-85) — from the applicants' Gender answer on the
    // public Apply form. Older applications (no answer) = "Not specified".
    double male = 0, female = 0, unknown = 0;
    for (final a in apps) {
      switch (a.gender.trim().toLowerCase()) {
        case 'male':
          male++;
          break;
        case 'female':
          female++;
          break;
        default:
          unknown++;
      }
    }
    final genderTotal = male + female + unknown;
    final malePercent   = genderTotal > 0 ? male / genderTotal * 100 : 0.0;
    final femalePercent = genderTotal > 0 ? female / genderTotal * 100 : 0.0;
    final genderCounts = <String, double>{
      if (male > 0) 'Male': male,
      if (female > 0) 'Female': female,
      if (unknown > 0) 'Not specified': unknown,
    };

    return CareersDashboardData(
      statCards: statCards,
      appReceivedLabels: monthLabels,
      appReceivedValues: monthCounts,
      jobPostingLabels:    deptLabels,
      jobPostingActive:    qActive,
      jobPostingClosed:    qClosed,
      jobPostingScheduled: qScheduled,
      jobPostingDraft:     qDraft,
      hiringStages:        hiringStages,
      // BUG-38: no fake "No Data = 1" slice — the chart shows an empty state.
      jobStatus:           statusCounts,
      jobStatusTotal:      totalForStatus,
      qualifiedPercent:    qualifiedPct,
      unqualifiedPercent:  unqualifiedPct,
      notReviewedPercent:  notReviewedPct, // BUG-258
      totalApplications:   totalApps,
      performanceRoles:        perfRoles,
      performanceApplications: perfApps,
      performanceInterviews:   perfInterviews,
      performanceHires:        perfHires,
      jobOfferApproved: offerApproved,
      jobOfferPending:  offerPending,
      jobOfferRejected: offerRejected,
      scoreDistribution: scoreDistribution,
      employmentTypes:   employmentTypes, // empty → chart shows "No data yet"
      malePercent:   malePercent,
      femalePercent: femalePercent,
      genderCounts:  genderCounts,
    );
  }

  // ── Static hardcoded demo (kept as fallback) ──────────────────────────────
  factory CareersDashboardData.demo() => CareersDashboardData(
    statCards: const [
      DashboardStatCard(label: 'All Jobs',          value: 1000, iconAsset: 'assets/images/job_list/all_job.svg'),
      DashboardStatCard(label: 'Office Jobs',       value: 3,    iconAsset: 'assets/images/job_list/office_job.svg'),
      DashboardStatCard(label: 'Remote Jobs',       value: 3,    iconAsset: 'assets/images/job_list/remote_job.svg'),
      DashboardStatCard(label: 'Active Job',        value: 3,    iconAsset: 'assets/images/job_list/active_job.svg'),
      DashboardStatCard(label: 'Recruitment End', value: 3,    iconAsset: 'assets/images/job_list/requiement_end.svg'),
      DashboardStatCard(label: 'Drafted',           value: 3,    iconAsset: 'assets/images/job_list/dradt.svg'),
    ],
    appReceivedLabels: const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
    appReceivedValues: const [320,280,350,300,420,380,450,400,360,300,340,390],
    jobPostingLabels: const ['Active','Closed','Scheduled','Draft'],
    jobPostingActive:    const [400,100,200,50],
    jobPostingClosed:    const [300,80,150,30],
    jobPostingScheduled: const [200,60,100,20],
    jobPostingDraft:     const [100,40,50,10],
    hiringStages: const [
      HiringStageItem(label: 'Applied',  value: 500),
      HiringStageItem(label: 'Interview',  value: 350),
      HiringStageItem(label: 'Offer', value: 200),
      HiringStageItem(label: 'Hired',      value: 120),
    ],
    jobStatus: const {'Active': 35, 'Scheduled': 25, 'Closed': 20, 'Draft': 20},
    jobStatusTotal: 9,
    qualifiedPercent: 72,
    unqualifiedPercent: 28,
    totalApplications: 114765,
    performanceRoles: const ['Frontend Developer','Backend Developer','UI/UX Designer','Backend Developer'],
    performanceApplications: const [90,75,60,80],
    performanceInterviews:   const [50,40,35,45],
    performanceHires:        const [20,15,12,18],
    jobOfferApproved: 59091,
    jobOfferPending:  31760,
    jobOfferRejected: 23510,
    scoreDistribution: const [
      ScoreDistributionItem(label: 'Poor',      value: 18,   colorHex: '#D32F2F'),
      ScoreDistributionItem(label: 'Weak',      value: 45,   colorHex: '#F44336'),
      ScoreDistributionItem(label: 'Good',      value: 2113, colorHex: '#FF9800'),
      ScoreDistributionItem(label: 'Very Good', value: 2113, colorHex: '#E91E63'),
      ScoreDistributionItem(label: 'Excellent', value: 45,   colorHex: '#2E7D32'),
    ],
    employmentTypes: const {'Intern': 40, 'Junior': 30, 'Senior': 20, 'Leadership': 10},
    malePercent:   72,
    femalePercent: 28,
  );
}

// ── Root model ────────────────────────────────────────────────────────────────

class CareersCmsModel {
  final CareersOverview overview;
  final List<CareerStatItem> statistics;
  final CareersDashboardData dashboard;
  final DateTime? lastUpdated;

  const CareersCmsModel({
    required this.overview,
    required this.statistics,
    required this.dashboard,
    this.lastUpdated,
  });

  factory CareersCmsModel.empty() => CareersCmsModel(
    overview: CareersOverview.empty(),
    statistics: [],
    dashboard: CareersDashboardData.demo(),
  );

  factory CareersCmsModel.fromMap(Map<String, dynamic> map) {
    final rawStats = (map['statistics'] as List<dynamic>?) ?? <dynamic>[];
    final stats = rawStats
        .whereType<Map<String, dynamic>>()
        .map((s) => CareerStatItem.fromMap(
      s['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      s,
    ))
        .toList();

    DateTime? lastUpdated;
    if (map['lastUpdated'] != null) {
      try {
        lastUpdated = DateTime.parse(map['lastUpdated'] as String);
      } catch (_) {}
    }

    return CareersCmsModel(
      overview: CareersOverview.fromMap(
          (map['overview'] as Map<String, dynamic>?) ?? {}),
      statistics: stats,
      dashboard: CareersDashboardData.demo(), // replaced at runtime via fromRealData
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toMap() => {
    'overview': overview.toMap(),
    'statistics': statistics.map((s) => {'id': s.id, ...s.toMap()}).toList(),
    'lastUpdated': DateTime.now().toIso8601String(),
  };

  /// Nested template for [FlatCodec.decode] (one populated sample statistic).
  static Map<String, dynamic> get flatTemplate => {
        'overview': {
          'description': {'en': '', 'ar': ''},
          'actionButtonLabel': {'en': '', 'ar': ''},
        },
        'statistics': [
          {
            'id': '',
            'title': {'en': '', 'ar': ''},
            'shortDescription': {'en': '', 'ar': ''},
            'summaryValue': '',
            'iconUrl': '',
          }
        ],
        'lastUpdated': '',
      };

  CareersCmsModel copyWith({
    CareersOverview? overview,
    List<CareerStatItem>? statistics,
    CareersDashboardData? dashboard,
    DateTime? lastUpdated,
  }) =>
      CareersCmsModel(
        overview: overview ?? this.overview,
        statistics: statistics ?? this.statistics,
        dashboard: dashboard ?? this.dashboard,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}