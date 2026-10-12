// ******************* FILE INFO *******************
// File Name: job_listing_repo_impl.dart
// Created by: Amr Mesbah
// Purpose: Firebase Firestore implementation of JobListingRepo

import 'package:cloud_firestore/cloud_firestore.dart';


import '../../../../core/utils/flat_codec.dart';
import '../../domain/base_repository/job_listing_repo.dart';
import '../models/job_listing_model.dart';

class JobListingRepoImp implements JobListingRepo {
  final FirebaseFirestore _firestore;

  JobListingRepoImp({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ── Collection reference ──────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobListings');

  // ── BUG-01 / BUG-99 / BUG-103: public visibility flag ─────────────────────
  /// Scalar field the Firestore rules check: visitors may only read jobs with
  /// `Public_Listed == true` (Active or Scheduled). Drafts, inactive, ended
  /// and removed jobs are admin-only — also when opened by a direct link.
  static const String publicFlag = 'Public_Listed';

  static bool isPublic(JobStatus status) =>
      status == JobStatus.active || status == JobStatus.scheduled;

  /// Older documents have no flag yet → write it once (admin only).
  void _backfillPublicFlag(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      List<JobPostModel> jobs) {
    final batch = _firestore.batch();
    var n = 0;
    for (var i = 0; i < docs.length && i < jobs.length; i++) {
      final want = isPublic(jobs[i].status);
      if (docs[i].data()[publicFlag] != want) {
        batch.update(docs[i].reference, {publicFlag: want});
        n++;
      }
    }
    if (n > 0) batch.commit().catchError((_) {});
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH ALL
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<JobPostModel>> fetchAllJobs() async {
    try {
      final snapshot = await _collection
          .orderBy('Last_Updated_At', descending: true)
          .get(const GetOptions(source: Source.server));

      final jobs = snapshot.docs.map((doc) {
        return JobPostModel.fromMap(
          doc.id,
          FlatCodec.decode(doc.data(), JobPostModel.flatTemplate),
        );
      }).toList();

      _backfillPublicFlag(snapshot.docs, jobs);
      return jobs;
    } catch (e) {
      // Fallback to cache if server fails
      try {
        final snapshot = await _collection
            .orderBy('Last_Updated_At', descending: true)
            .get(const GetOptions(source: Source.cache));
        final jobs = snapshot.docs.map((doc) {
          return JobPostModel.fromMap(
          doc.id,
          FlatCodec.decode(doc.data(), JobPostModel.flatTemplate),
        );
        }).toList();
        return jobs;
      } catch (cacheError) {
        rethrow;
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH BY ID
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<JobPostModel?> fetchJobById(String id) async {
    try {
      final doc = await _collection.doc(id).get(const GetOptions(source: Source.server));
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      final job = JobPostModel.fromMap(
        doc.id,
        FlatCodec.decode(doc.data()!, JobPostModel.flatTemplate),
      );
      return job;
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CREATE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<JobPostModel> createJob(JobPostModel job) async {
    try {
      final docRef = await _collection.add({
        ...FlatCodec.encodeNew(job.toMap()),
        publicFlag: isPublic(job.status),
      });
      final created = job.copyWith(id: docRef.id);
      return created;
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPDATE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> updateJob(JobPostModel job) async {
    try {
      await FlatCodec.writeVersioned(_collection.doc(job.id), job.toMap(),
          scalars: {publicFlag: isPublic(job.status)});
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DELETE (hard)
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> deleteJob(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REMOVE (soft — sets status to Removed)
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> removeJob(String id) async {
    try {
      // Partial update — writeVersioned appends only these changed fields.
      await FlatCodec.writeVersioned(_collection.doc(id), {
        'status': JobStatus.removed.label,
        'endedDate': jobDateToStore(DateTime.now()), // BUG-277: UTC
      }, scalars: {publicFlag: false});
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPDATE STATUS
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> updateJobStatus(String id, JobStatus status) async {
    try {
      final Map<String, dynamic> data = {'status': status.label};
      if (status == JobStatus.ended || status == JobStatus.removed || status == JobStatus.inactive) {
        data['endedDate'] = jobDateToStore(DateTime.now()); // BUG-277: UTC
      }
      if (status == JobStatus.active) {
        data['postedDate'] = jobDateToStore(DateTime.now()); // BUG-277: UTC
      }
      // Partial update — writeVersioned appends only these changed fields.
      await FlatCodec.writeVersioned(_collection.doc(id), data,
          scalars: {publicFlag: isPublic(status)});
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STREAM ALL (real-time)
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Stream<List<JobPostModel>> streamAllJobs() {
    return _collection
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final jobs = snapshot.docs.map((doc) {
        return JobPostModel.fromMap(
          doc.id,
          FlatCodec.decode(doc.data(), JobPostModel.flatTemplate),
        );
      }).toList();
      return jobs;
    });
  }
}