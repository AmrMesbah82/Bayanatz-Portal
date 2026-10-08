// ******************* FILE INFO *******************
// File Name: careers_cubit.dart
// Created by: Amr Mesbah
// FIXED: loadRealData() now fetches live jobs + applications from Firestore
//        and builds the dashboard via CareersDashboardData.fromRealData()

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../job/data/models/application_model.dart';
import '../../../job/data/models/job_listing_model.dart';
import '../../../job/domain/base_repository/application_repo.dart';
import '../../../job/domain/base_repository/job_listing_repo.dart';
import '../../data/models/careers_model.dart';
import '../../data/repository/careers_repo_impl.dart';
import '../../domain/base_repository/careers_repo.dart';
import 'careers_state.dart';


// ── Dashboard time filter ────────────────────────────────────────────────────

enum DashboardTimeRange {
  allTime,
  last7Days,
  last30Days,
  last3Months,
  last6Months,
  thisYear,
}

extension DashboardTimeRangeX on DashboardTimeRange {
  String get label {
    switch (this) {
      case DashboardTimeRange.allTime:     return 'All Time';
      case DashboardTimeRange.last7Days:   return 'Last 7 Days';
      case DashboardTimeRange.last30Days:  return 'Last 30 Days';
      case DashboardTimeRange.last3Months: return 'Last 3 Months';
      case DashboardTimeRange.last6Months: return 'Last 6 Months';
      case DashboardTimeRange.thisYear:    return 'This Year';
    }
  }

  /// Inclusive start of the range — `null` means "no lower bound".
  DateTime? startDate(DateTime now) {
    switch (this) {
      case DashboardTimeRange.allTime:     return null;
      case DashboardTimeRange.last7Days:   return now.subtract(const Duration(days: 7));
      case DashboardTimeRange.last30Days:  return now.subtract(const Duration(days: 30));
      case DashboardTimeRange.last3Months: return DateTime(now.year, now.month - 3, now.day);
      case DashboardTimeRange.last6Months: return DateTime(now.year, now.month - 6, now.day);
      case DashboardTimeRange.thisYear:    return DateTime(now.year, 1, 1);
    }
  }
}

class CareersCmsCubit extends Cubit<CareersCmsState> {
  final CareersCmsRepo _repo;
  final JobListingRepo _jobRepo;
  final ApplicationRepo _appRepo;

  CareersCmsCubit({
    CareersCmsRepo? repo,
    required JobListingRepo jobRepo,
    required ApplicationRepo appRepo,
  })  : _repo = repo ?? CareersCmsRepoImpl(),
        _jobRepo = jobRepo,
        _appRepo = appRepo,
        super(CareersCmsInitial());

  // ── Raw data + dashboard filters ──────────────────────────────────────────
  // The unfiltered lists are kept so the dashboard can be recomputed locally
  // whenever the Time / Department filter changes (no extra Firestore reads).

  List<JobPostModel>     _rawJobs = [];
  List<ApplicationModel> _rawApps = [];

  DashboardTimeRange _timeRange = DashboardTimeRange.allTime;
  String? _department; // null = All Departments

  DashboardTimeRange get timeRange   => _timeRange;
  String?            get department  => _department;
  bool get hasDashboardFilters =>
      _timeRange != DashboardTimeRange.allTime || _department != null;

  /// Departments that actually appear in the data (sorted, de-duplicated).
  List<String> get availableDepartments {
    final seen = <String, String>{}; // lowercase → original casing
    for (final j in _rawJobs) {
      // Removed jobs are left out of the dashboard (BUG-31) — and so are
      // departments that only they still reference.
      if (j.status == JobStatus.removed) continue;
      final d = j.department.trim();
      if (d.isNotEmpty) seen.putIfAbsent(d.toLowerCase(), () => d);
    }
    for (final a in _appsOfLiveJobs(_rawApps, _rawJobs)) {
      final d = a.department.trim();
      if (d.isNotEmpty) seen.putIfAbsent(d.toLowerCase(), () => d);
    }
    final list = seen.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void setDashboardTimeRange(DashboardTimeRange range) {
    if (_timeRange == range) return;
    _timeRange = range;
    _rebuildDashboard();
  }

  /// `null` or empty → All Departments.
  void setDashboardDepartment(String? dept) {
    final normalized = (dept == null || dept.trim().isEmpty) ? null : dept.trim();
    if (_department == normalized) return;
    _department = normalized;
    _rebuildDashboard();
  }

  void clearDashboardFilters() {
    _timeRange  = DashboardTimeRange.allTime;
    _department = null;
    _rebuildDashboard();
  }

  /// BUG-121: applications of REMOVED jobs were still counted (Applications
  /// Received 4, Hiring Stage 4 …) while every job KPI said 0. Both now use
  /// the same job set: applications only count when their job is not removed.
  List<ApplicationModel> _appsOfLiveJobs(
      List<ApplicationModel> apps, List<JobPostModel> jobs) {
    if (jobs.isEmpty) return apps; // jobs failed to load — don't hide all
    final removed = {
      for (final j in jobs)
        if (j.status == JobStatus.removed) j.id,
    };
    return apps.where((a) => !removed.contains(a.jobId)).toList();
  }

  /// Recomputes the dashboard from the raw lists using the active filters.
  void _rebuildDashboard() {
    final from = _timeRange.startDate(DateTime.now());

    bool matchesDept(String value) =>
        _department == null ||
        value.trim().toLowerCase() == _department!.toLowerCase();

    // With no time filter everything passes; with one, records that carry no
    // date at all can't be placed on the timeline and are left out.
    bool inRange(DateTime? date) {
      if (from == null) return true;
      if (date == null) return false;
      return !date.isBefore(from);
    }

    final jobs = _rawJobs
        .where((j) => matchesDept(j.department) && inRange(j.postedDate ?? j.endedDate))
        .toList();

    final apps = _appsOfLiveJobs(_rawApps, _rawJobs)
        .where((a) => matchesDept(a.department) && inRange(a.applicationDate))
        .toList();

    final dashboard = CareersDashboardData.fromRealData(jobs: jobs, apps: apps);
    emit(CareersCmsLoaded(current.copyWith(dashboard: dashboard)));
  }

  // ── Convenience getter for the current model (never null) ──────────────────

  CareersCmsModel get current {
    final s = state;
    if (s is CareersCmsLoaded) return s.data;
    if (s is CareersCmsSaved) return s.data;
    if (s is CareersCmsError && s.lastData != null) return s.lastData!;
    return CareersCmsModel.empty();
  }

  // ── Load CMS content from Firestore ───────────────────────────────────────

  Future<void> load() async {
    emit(CareersCmsLoading());
    try {
      final model = await _repo.fetch();
      emit(CareersCmsLoaded(model));
    } catch (e) {
      emit(CareersCmsError(e.toString()));
    }
  }

  // ── Load REAL dashboard data from Firestore jobs + applications ────────────

  /// BUG-02: set when part of the dashboard data could not be loaded, so the
  /// page can say so instead of silently showing 0 (an admin couldn't tell
  /// "still loading / failed" from "really empty").
  String? dashboardLoadWarning;

  Future<void> loadRealData() async {
    emit(CareersCmsLoading());
    dashboardLoadWarning = null;
    final failed = <String>[];
    try {
      // Fetch CMS content (overview, statistics) + real-time data in parallel
      // BUG-22 / BUG-31: each source is loaded independently. Before, ONE
      // failing read (e.g. applications) threw the whole dashboard into the
      // empty fallback, so some loads showed all-zero KPIs and others didn't.
      Future<T> safe<T>(Future<T> f, T fallback, String what) async {
        try {
          return await f;
        } catch (_) {
          failed.add(what);
          return fallback;
        }
      }

      final results = await Future.wait<Object>([
        safe<CareersCmsModel>(_repo.fetch(), CareersCmsModel.empty(), 'page content'),
        safe<List<JobPostModel>>(
            _jobRepo.fetchAllJobs(), const <JobPostModel>[], 'jobs'),
        safe<List<ApplicationModel>>(_appRepo.fetchAllApplications(),
            const <ApplicationModel>[], 'applications'),
      ]);
      if (failed.isNotEmpty) {
        dashboardLoadWarning =
            'Some dashboard data could not be loaded (${failed.join(', ')}). '
            'The numbers below may be incomplete.';
      }

      final cmsModel        = results[0] as CareersCmsModel;
      final jobs            = results[1] as List<JobPostModel>;
      final apps            = results[2] as List<ApplicationModel>;

      // Keep the unfiltered data so the Time / Department filters can
      // recompute the dashboard without hitting Firestore again.
      _rawJobs = jobs;
      _rawApps = apps;

      // Build dashboard from real Firebase data
      final dashboard = CareersDashboardData.fromRealData(
        jobs: jobs,
        apps: _appsOfLiveJobs(apps, jobs), // BUG-121
      );

      // Merge: keep CMS overview/statistics, replace dashboard with live data
      final merged = cmsModel.copyWith(dashboard: dashboard);

      emit(CareersCmsLoaded(merged));

      // Re-apply any filter the user had picked before the reload.
      if (hasDashboardFilters) _rebuildDashboard();
    } catch (e) {
      // BUG-02: say it failed instead of showing an all-zero dashboard.
      dashboardLoadWarning =
          'The dashboard could not be loaded. The numbers below are not real.';
      emit(CareersCmsLoaded(CareersCmsModel.empty()));
    }
  }

  /// Fallback demo (no Firestore needed) — keep for offline testing
  void loadDemo() {
    emit(CareersCmsLoaded(CareersCmsModel.empty()));
  }

  // ── Save to Firestore ──────────────────────────────────────────────────────

  Future<void> save(CareersCmsModel model) async {
    final previous = current;
    emit(CareersCmsLoading());
    try {
      await _repo.save(model);
      // Stamp locally so the main page shows the new date without a reload
      // (the server timestamp is read back on the next fetch).
      emit(CareersCmsSaved(model.copyWith(lastUpdated: DateTime.now())));
    } catch (e) {
      emit(CareersCmsError(e.toString(), lastData: previous));
    }
  }

  // ── Local draft mutations (edit page uses these before final save) ─────────

  void updateOverviewDescription(BilingualText value) {
    final updated = current.copyWith(
      overview: current.overview.copyWith(description: value),
    );
    emit(CareersCmsLoaded(updated));
  }

  void updateOverviewActionButton(BilingualText value) {
    final updated = current.copyWith(
      overview: current.overview.copyWith(actionButtonLabel: value),
    );
    emit(CareersCmsLoaded(updated));
  }

  void addStatistic() {
    final stats = List<CareerStatItem>.from(current.statistics)
      ..add(CareerStatItem.empty());
    emit(CareersCmsLoaded(current.copyWith(statistics: stats)));
  }

  void removeStatistic(String id) {
    final stats = current.statistics.where((s) => s.id != id).toList();
    emit(CareersCmsLoaded(current.copyWith(statistics: stats)));
  }

  void updateStatistic(CareerStatItem updated) {
    final stats = current.statistics
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    emit(CareersCmsLoaded(current.copyWith(statistics: stats)));
  }
}