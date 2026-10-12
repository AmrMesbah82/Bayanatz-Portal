// ═══════════════════════════════════════════════════════════════════
// FILE 3: application_repo_impl.dart
// Path: lib/features/job/data/repository/application_repo_impl.dart
// ═══════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';


import '../../domain/base_repository/application_repo.dart';
import '../models/application_model.dart';

class ApplicationRepoImp implements ApplicationRepo {
  final FirebaseFirestore _firestore;

  ApplicationRepoImp({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _appCollection(String jobId) =>
      _firestore.collection('jobListings').doc(jobId).collection('applications');

  @override
  Future<List<ApplicationModel>> fetchAllApplications() async {
    try {

      // Get all jobListings first, then their applications subcollections
      final jobsSnapshot = await _firestore
          .collection('jobListings')
          .get(const GetOptions(source: Source.server));

      // BUG-261: applications of REMOVED jobs are not counted (the Home
      // dashboard already excluded them — 12 here vs 7 there).
      bool isRemoved(Map<String, dynamic> d) {
        final raw = d['Status'] ?? d['status'];
        final v = raw is List ? (raw.isEmpty ? null : raw.last) : raw;
        return (v?.toString().toLowerCase() ?? '') == 'removed';
      }

      final liveJobs =
          jobsSnapshot.docs.where((j) => !isRemoved(j.data())).toList();

      // BUG-281: the sub-collections were read ONE AFTER ANOTHER (5–9 s on
      // a blank page). They are now fetched in parallel.
      final perJob = await Future.wait(liveJobs.map((jobDoc) async {
        final appsSnapshot = await jobDoc.reference
            .collection('applications')
            .orderBy('applicationDate', descending: true)
            .get(const GetOptions(source: Source.server));
        return [
          for (final appDoc in appsSnapshot.docs)
            ApplicationModel.fromMap(appDoc.id, {
              ...appDoc.data(),
              'jobId': jobDoc.id,
            }),
        ];
      }));

      final List<ApplicationModel> allApps = [
        for (final list in perJob) ...list,
      ];
      allApps.sort((a, b) => (b.applicationDate ?? DateTime(0))
          .compareTo(a.applicationDate ?? DateTime(0)));

      return allApps;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ApplicationModel?> fetchApplicationById(String jobId, String appId) async {
    try {
      final doc = await _appCollection(jobId).doc(appId).get(
          const GetOptions(source: Source.server));

      if (!doc.exists || doc.data() == null) return null;

      return ApplicationModel.fromMap(doc.id, {
        ...doc.data()!,
        'jobId': jobId,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateApplication(ApplicationModel app) async {
    try {
      await _appCollection(app.jobId).doc(app.id).update(app.toMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateStatus(String jobId, String appId, ApplicationStatus status) async {
    try {
      await _appCollection(jobId).doc(appId).update({'status': status.label});
    } catch (e) {
      rethrow;
    }
  }
}