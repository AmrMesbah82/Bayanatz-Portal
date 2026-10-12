// ═══════════════════════════════════════════════════════════════════
// FILE 4: application_state.dart
// Path: lib/controller/application/application_state.dart
// ═══════════════════════════════════════════════════════════════════


import '../../../../core/main_widgets/application_filter_dialog.dart';
import '../../data/models/application_model.dart';

abstract class ApplicationState {}

class ApplicationInitial extends ApplicationState {}

class ApplicationLoading extends ApplicationState {}

class ApplicationLoaded extends ApplicationState {
  final List<ApplicationModel> applications;
  final String activeJobTitleFilter;   // ← was activeDeptFilter
  final String searchQuery;
  final ApplicationFilterData? filterData;

  ApplicationLoaded({
    required this.applications,
    this.activeJobTitleFilter = 'All',  // ← was activeDeptFilter
    this.searchQuery = '',
    this.filterData,
  });

  List<ApplicationModel> get filteredApps {
    var result = List<ApplicationModel>.from(applications);

    // ── 1. Job Title filter (was Department) ──────────────────────────────
    if (activeJobTitleFilter != 'All') {
      result = result
          .where((a) => a.jobTitle.toLowerCase() == activeJobTitleFilter.toLowerCase())
          .toList();
    }

    // ── 2. Search query ───────────────────────────────────────────────────
    // BUG-273: ignore leading / trailing spaces (" " used to match nothing).
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((a) {
        return a.fullName.toLowerCase().contains(q) ||
            a.email.toLowerCase().contains(q) ||
            a.jobTitle.toLowerCase().contains(q) ||
            a.department.toLowerCase().contains(q);
      }).toList();
    }

    // ── 3. Dialog filter ──────────────────────────────────────────────────
    if (filterData != null && !filterData!.isEmpty) {

      // Employment Type
      if (filterData!.employmentType != null) {
        result = result
            .where((a) => a.employmentType.toLowerCase() ==
            filterData!.employmentType!.toLowerCase())
            .toList();
      }

      // Years of Experience
      if (filterData!.yearsOfExperience != null) {
        result = result
            .where((a) => a.experienceLevel.toLowerCase() ==
            filterData!.yearsOfExperience!.toLowerCase())
            .toList();
      }

      // Status (matches enum label e.g. "Offer: Approved")
      if (filterData!.status != null) {
        result = result
            .where((a) => a.status.label == filterData!.status)
            .toList();
      }

      // Stage (matches enum stage e.g. "Interview")
      if (filterData!.stage != null) {
        result = result
            .where((a) => a.status.stage == filterData!.stage)
            .toList();
      }

      // Score / Tag (e.g. "Strong", "Adequate", "Weak")
      if (filterData!.score != null) {
        result = result
            .where((a) =>
        a.tag.toLowerCase() == filterData!.score!.toLowerCase())
            .toList();
      }

      // Sort By
      if (filterData!.sortBy != null) {
        switch (filterData!.sortBy) {
          case 'date_desc':
            result.sort((a, b) =>
                (b.applicationDate ?? DateTime(0))
                    .compareTo(a.applicationDate ?? DateTime(0)));
            break;
          case 'date_asc':
            result.sort((a, b) =>
                (a.applicationDate ?? DateTime(0))
                    .compareTo(b.applicationDate ?? DateTime(0)));
            break;
          case 'name_asc':
            result.sort((a, b) => a.fullName.compareTo(b.fullName));
            break;
          case 'name_desc':
            result.sort((a, b) => b.fullName.compareTo(a.fullName));
            break;
        }
      }
    }

    return result;
  }

  // ── Summary counts ────────────────────────────────────────────────────────
  int get totalCount => filteredApps.length;

  /// BUG-170: "Applied" applications nobody has reviewed yet — they were in
  /// no counter, so the stage cards did not add up to the total.
  int get appliedPending =>
      filteredApps.where((a) => a.status == ApplicationStatus.applied).length;
  int get appliedQualified =>
      filteredApps.where((a) => a.status == ApplicationStatus.qualified).length;
  int get appliedUnqualified =>
      filteredApps.where((a) => a.status == ApplicationStatus.unqualified).length;

  int get interviewPassed =>
      filteredApps.where((a) => a.status == ApplicationStatus.interviewPassed).length;
  int get interviewWithdrew =>
      filteredApps.where((a) => a.status == ApplicationStatus.interviewWithdrew).length;
  int get interviewFailed =>
      filteredApps.where((a) => a.status == ApplicationStatus.interviewFailed).length;

  int get offerApproved =>
      filteredApps.where((a) => a.status == ApplicationStatus.offerApproved).length;
  int get offerPending =>
      filteredApps.where((a) => a.status == ApplicationStatus.offerPending).length;
  int get offerRejected =>
      filteredApps.where((a) => a.status == ApplicationStatus.offerRejected).length;

  int get hiredCompleted =>
      filteredApps.where((a) => a.status == ApplicationStatus.hired).length;

  // ── Job Title counts for filter tabs (was departmentCounts) ──────────────
  Map<String, int> get jobTitleCounts {
    final map = <String, int>{};
    for (final a in applications) {
      if (a.jobTitle.isNotEmpty) {
        map[a.jobTitle] = (map[a.jobTitle] ?? 0) + 1;
      }
    }
    return map;
  }
}

class ApplicationDetailLoaded extends ApplicationState {
  final ApplicationModel application;
  ApplicationDetailLoaded(this.application);
}

class ApplicationUpdated extends ApplicationState {
  final ApplicationModel application;
  ApplicationUpdated(this.application);
}

class ApplicationError extends ApplicationState {
  final String message;
  final List<ApplicationModel>? lastApps;
  ApplicationError(this.message, {this.lastApps});
}