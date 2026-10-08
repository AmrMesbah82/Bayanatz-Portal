// ******************* FILE INFO *******************
// File Name: service_repository_impl.dart
// Description: Firebase implementation of ServiceRepository.
//   • Firestore  → document: cms/service_page
//   • Storage    → bucket path: service_cms/...
// Created by: Amr Mesbah
// FIXED: _sanitize() now converts lastUpdatedAt Timestamp → ISO string
//        instead of removing it, so ServicePageModel.fromMap() can parse it

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/base_repository/services_repo.dart';
import '../../../../core/utils/flat_codec.dart';
import '../models/services_model.dart';


class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage?   storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage   = storage   ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage   _storage;

  static const String _collection = 'services';
  static const String _document   = 'service_page';

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _firestore.collection(_collection).doc(_document);

  // ── Fetch (cache-first) ───────────────────────────────────────────────────

  @override
  Future<ServicePageModel> fetchServicePage() async {
    try {
      final snapshot = await _docRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return ServicePageModel.empty();
      }
      final data  = _sanitize(snapshot.data()!);
      final model = ServicePageModel.fromMap(
        FlatCodec.decode(data, ServicePageModel.flatTemplate),
      );
      return model;
    } catch (e, st) {
      return ServicePageModel.empty();
    }
  }

  // ── Fetch FRESH (server only, bypasses cache) ─────────────────────────────

  @override
  Future<ServicePageModel> fetchServicePageFresh() async {
    try {
      final snapshot = await _docRef.get(const GetOptions(source: Source.server));
      if (!snapshot.exists || snapshot.data() == null) {
        return ServicePageModel.empty();
      }
      final data  = _sanitize(snapshot.data()!);
      final model = ServicePageModel.fromMap(
        FlatCodec.decode(data, ServicePageModel.flatTemplate),
      );
      if (model.journeyItems.isNotEmpty) {
      }
      return model;
    } catch (e, st) {
      return ServicePageModel.empty();
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  @override
  Future<void> saveServicePage(ServicePageModel model) async {
    try {
      // Versioned append write; scalar Last_Updated_At added by the codec.
      final nested = model.toMap()..remove('lastUpdatedAt');
      await FlatCodec.writeVersioned(_docRef, nested);
    } catch (e, st) {
      rethrow;
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String    storagePath,
  }) async {
    try {
      final ref  = _storage.ref().child(storagePath);
      final mime = _detectMime(bytes);
      final task = await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url  = await task.ref.getDownloadURL();
      return url;
    } catch (e, st) {
      rethrow;
    }
  }

  // ── Watch (realtime stream) ───────────────────────────────────────────────

  @override
  Stream<ServicePageModel> watchServicePage() {
    return _docRef.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return ServicePageModel.empty();
      try {
        final data = _sanitize(snap.data()!);
        return ServicePageModel.fromMap(data);
      } catch (e) {
        return ServicePageModel.empty();
      }
    });
  }

  // ── ✅ FIXED: Sanitize raw Firestore map ──────────────────────────────────
  // Previously this removed lastUpdatedAt entirely, so the model never got it.
  // Now it converts Firestore Timestamp → ISO string so fromMap() can parse it.

  Map<String, dynamic> _sanitize(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);

    // ✅ Convert Firestore Timestamp to ISO string instead of removing it
    final rawTs = copy['lastUpdatedAt'];
    // BUG-25: runtimeType names are minified on web release — duck-type instead.
    if (rawTs != null && rawTs is! String && rawTs is! num) {
      try {
        final dt = (rawTs as dynamic).toDate() as DateTime;
        copy['lastUpdatedAt'] = dt.toIso8601String();
      } catch (e) {
        copy.remove('lastUpdatedAt');
      }
    }

    return copy;
  }

  // ── MIME sniff ────────────────────────────────────────────────────────────

  String _detectMime(Uint8List b) {
    if (b.length < 4) return 'application/octet-stream';
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
    if (b[0] == 0xFF && b[1] == 0xD8)                                   return 'image/jpeg';
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return 'image/gif';
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b.length >= 12 && b[8] == 0x57 && b[9] == 0x45 &&
        b[10] == 0x42 && b[11] == 0x50)                                 return 'image/webp';
    if (b[0] == 0x3C)                                                   return 'image/svg+xml';
    return 'image/jpeg';
  }
}