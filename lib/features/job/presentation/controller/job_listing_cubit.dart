// ******************* FILE INFO *******************
// File Name: job_listing_cubit.dart
// Created by: Amr Mesbah
// Purpose: Cubit for Job Listing — Firebase Firestore via repository pattern
// FIXED: saveJob() no longer forces JobStatus.active on every publish —
//        it now respects the status passed in the model (active OR inactive)
// FIXED: Added applyAdvancedFilter() + clearAdvancedFilter() for filter dialog

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/main_widgets/job_listing_filter_dialog.dart';
import '../../data/models/job_listing_model.dart';
import '../../domain/base_repository/job_listing_repo.dart';
import 'job_listing_state.dart';


class JobListingCubit extends Cubit<JobListingState> {
  final JobListingRepo _repo;

  JobListingCubit({required JobListingRepo repo})
      : _repo = repo,
        super(JobListingInitial());

  List<JobPostModel> _allJobs = [];
  String _activeFilter = 'All';
  String _searchQuery = '';
  StreamSubscription? _streamSub;

  // ── Advanced filter from dialog ────────────────────────────────────────────
  JobListingFilterData? _advancedFilter;

  List<JobPostModel> get allJobs => _allJobs;

  // ══════════════════════════════════════════════════════════════════════════
  //  LOAD ALL JOBS (one-time fetch)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> loadJobs() async {
    try {
      emit(JobListingLoading());
      _allJobs = await _repo.fetchAllJobs();
      _emitLoaded();
    } catch (e) {
      emit(JobListingError('Failed to load jobs: $e', lastJobs: _allJobs));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STREAM ALL JOBS (real-time)
  // ══════════════════════════════════════════════════════════════════════════

  void streamJobs() {
    emit(JobListingLoading());
    _streamSub?.cancel();
    _streamSub = _repo.streamAllJobs().listen(
          (jobs) {
        _allJobs = jobs;
        _emitLoaded();
      },
      onError: (e) {
        emit(JobListingError('Stream error: $e', lastJobs: _allJobs));
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FILTER & SEARCH
  // ══════════════════════════════════════════════════════════════════════════

  void setFilter(String filter) {
    _activeFilter = filter;
    _emitLoaded();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _emitLoaded();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ADVANCED FILTER (from dialog)
  // ══════════════════════════════════════════════════════════════════════════

  void applyAdvancedFilter(JobListingFilterData filter) {


    _advancedFilter = filter;
    _emitLoaded();
  }

  void clearAdvancedFilter() {
    _advancedFilter = null;
    _emitLoaded();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> addJob(JobPostModel job) async {
    try {
      final created = await _repo.createJob(job);
      _allJobs = [created, ..._allJobs];
      _emitLoaded();
    } catch (e) {
      emit(JobListingError('Failed to add job: $e', lastJobs: _allJobs));
    }
  }

  Future<void> updateJob(JobPostModel updated) async {
    try {
      await _repo.updateJob(updated);
      _allJobs = _allJobs.map((j) => j.id == updated.id ? updated : j).toList();
      _emitLoaded();
    } catch (e) {
      emit(JobListingError('Failed to update job: $e', lastJobs: _allJobs));
    }
  }

  Future<void> removeJob(String id) async {
    try {
      await _repo.removeJob(id);
      _allJobs = _allJobs.map((j) {
        if (j.id == id) {
          return j.copyWith(status: JobStatus.removed, endedDate: DateTime.now());
        }
        return j;
      }).toList();
      _emitLoaded();
    } catch (e) {
      emit(JobListingError('Failed to remove job: $e', lastJobs: _allJobs));
    }
  }

  Future<void> deleteJob(String id) async {
    try {
      await _repo.deleteJob(id);
      _allJobs = _allJobs.where((j) => j.id != id).toList();
      _emitLoaded();
    } catch (e) {
      emit(JobListingError('Failed to delete job: $e', lastJobs: _allJobs));
    }
  }

  Future<void> updateJobStatus(String id, JobStatus status) async {
    try {
      await _repo.updateJobStatus(id, status);
      _allJobs = _allJobs.map((j) {
        if (j.id == id) {
          return j.copyWith(
            status: status,
            endedDate: (status == JobStatus.ended ||
                status == JobStatus.removed ||
                status == JobStatus.inactive)
                ? DateTime.now()
                : j.endedDate,
            postedDate: status == JobStatus.active ? DateTime.now() : j.postedDate,
          );
        }
        return j;
      }).toList();
      _emitLoaded();
    } catch (e) {
      emit(JobListingError('Failed to update status: $e', lastJobs: _allJobs));
    }
  }

  /// Load a single job for editing/preview
  Future<void> loadJobDetail(String id) async {
    try {
      final local = _allJobs.where((j) => j.id == id).toList();
      if (local.isNotEmpty) {
        emit(JobListingDetailLoaded(local.first));
        return;
      }
      final job = await _repo.fetchJobById(id);
      if (job != null) {
        emit(JobListingDetailLoaded(job));
      } else {
        emit(JobListingError('Job not found', lastJobs: _allJobs));
      }
    } catch (e) {
      emit(JobListingError('Failed to load job: $e', lastJobs: _allJobs));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SAVE JOB (create or update)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveJob(JobPostModel job, {String? publishStatus}) async {
    try {
      final ps = publishStatus ?? job.publishStatus;

      final resolvedStatus = ps == 'draft' ? JobStatus.drafted : job.status;

      final existing = _allJobs.where((j) => j.id == job.id).toList();
      final JobPostModel? before = existing.isEmpty ? null : existing.first;
      final bool wasLive = before != null &&
          (before.status == JobStatus.active ||
              before.status == JobStatus.scheduled ||
              before.status == JobStatus.ended);

      final updated = job.copyWith(
        publishStatus: ps,
        status: resolvedStatus,
        // Keep the original posting date when an already-live job is edited;
        // only a job going live for the first time gets "now".
        postedDate: (ps == 'published' && resolvedStatus == JobStatus.active)
            ? (wasLive ? (before.postedDate ?? DateTime.now()) : DateTime.now())
            : (before?.postedDate ?? job.postedDate),
        // BUG-44: "Inactive Since" had no date — stamp it when deactivated.
        endedDate: resolvedStatus == JobStatus.inactive
            ? (before?.status == JobStatus.inactive
                ? (before?.endedDate ?? DateTime.now())
                : DateTime.now())
            : (resolvedStatus == JobStatus.active ? null : job.endedDate),
        totalApplications: before?.totalApplications ?? job.totalApplications,
      ).withDerivedStatus(); // BUG-11: scheduled / ended from the dates


      final existIndex = _allJobs.indexWhere((j) => j.id == updated.id);
      if (existIndex >= 0) {
        await _repo.updateJob(updated);
        _allJobs[existIndex] = updated;
      } else {
        final created = await _repo.createJob(updated);
        _allJobs = [created, ..._allJobs];
      }

      emit(JobListingSaved(updated));

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) _emitLoaded();
      });
    } catch (e) {
      emit(JobListingError('Failed to save job: $e', lastJobs: _allJobs));
    }
  }

  /// Back to list from detail
  void backToList() {
    _emitLoaded();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPER
  // ══════════════════════════════════════════════════════════════════════════


  void _emitLoaded() {
    emit(JobListingLoaded(
      jobs: _allJobs,
      activeFilter: _activeFilter,
      searchQuery: _searchQuery,
      advancedFilter: _advancedFilter,
    ));
  }

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}