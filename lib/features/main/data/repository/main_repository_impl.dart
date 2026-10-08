// ******************* FILE INFO *******************
// File Name: main_repository_impl.dart
// Description: Firebase implementation of MainRepository.
//              Dual-document architecture:
//              - Published → `mainPage/main`
//              - Draft     → `mainPage/main_draft`
//              Stores ONLY main data: branding/theme + logo, footer columns,
//              social links. Home content (title, short description, nav
//              buttons, sections) lives in the homePage collection.
// Created by: Amr Mesbah

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/utils/flat_codec.dart';
import '../../domain/base_repository/main_repo.dart';
import '../models/main_model.dart';

class MainRepositoryImpl implements MainRepository {
  MainRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    String collection   = 'mainPage',
    String publishedDoc = 'main',
    String draftDoc     = 'main_draft',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _collection = collection,
        _publishedDoc = publishedDoc,
        _draftDoc = draftDoc;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  final String _collection;
  final String _publishedDoc;
  final String _draftDoc;

  DocumentReference<Map<String, dynamic>> get _publishedRef =>
      _firestore.collection(_collection).doc(_publishedDoc);

  DocumentReference<Map<String, dynamic>> get _draftRef =>
      _firestore.collection(_collection).doc(_draftDoc);

  // ═════════════════════════════════════════════════════════════════════════
  //  PUBLISHED DOCUMENT
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<MainPageModel> fetchMainPage() async {
    try {
      final snapshot = await _publishedRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return MainPageModel.defaultModel;
      }
      return MainPageModel.fromMap(
        FlatCodec.decode(snapshot.data()!, MainPageModel.flatTemplate),
      );
    } catch (e) {
      return MainPageModel.defaultModel;
    }
  }

  @override
  Future<MainPageModel> fetchMainPageFresh() async {
    try {
      final snapshot =
          await _publishedRef.get(const GetOptions(source: Source.server));
      if (!snapshot.exists || snapshot.data() == null) {
        return MainPageModel.defaultModel;
      }
      return MainPageModel.fromMap(
        FlatCodec.decode(snapshot.data()!, MainPageModel.flatTemplate),
      );
    } catch (e) {
      return MainPageModel.defaultModel;
    }
  }

  @override
  Future<void> saveMainPage(MainPageModel model) async {
    final nested = {
      ...model.toMap(),
      'scheduledPublishDate': model.scheduledPublishDate?.toIso8601String(),
    };
    await FlatCodec.writeVersioned(_publishedRef, nested);
    await _removeLegacyHomeKeys(_publishedRef);
  }

  @override
  Stream<MainPageModel> watchMainPage() {
    return _publishedRef.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return MainPageModel.defaultModel;
      try {
        return MainPageModel.fromMap(
          FlatCodec.decode(snap.data()!, MainPageModel.flatTemplate),
        );
      } catch (e) {
        return MainPageModel.defaultModel;
      }
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  DRAFT DOCUMENT
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<MainPageModel?> fetchDraft() async {
    try {
      final snapshot =
          await _draftRef.get(const GetOptions(source: Source.server));
      if (snapshot.exists && snapshot.data() != null) {
        return MainPageModel.fromMap(
          FlatCodec.decode(snapshot.data()!, MainPageModel.flatTemplate),
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveDraft(MainPageModel model) async {
    final nested = {
      ...model.toMap(),
      'scheduledPublishDate': model.scheduledPublishDate?.toIso8601String(),
    };
    await FlatCodec.writeVersioned(_draftRef, nested);
    await _removeLegacyHomeKeys(_draftRef);
  }

  @override
  Future<void> deleteDraft() async {
    final snap = await _draftRef.get();
    if (snap.exists) {
      await _draftRef.delete();
    }
  }

  @override
  Future<void> promoteDraft() async {
    final draft = await fetchDraft();
    if (draft == null) return;
    final publishedModel = draft.copyWith(
      publishStatus: 'published',
      clearScheduledPublishDate: true,
    );
    await saveMainPage(publishedModel);
    await deleteDraft();
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  ASSETS
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String storagePath,
  }) async {
    // BUG-68: images can now be PNG/JPG/WebP as well as SVG. Give the file
    // the extension of what it really is, so the public site can tell an SVG
    // from a bitmap by its URL.
    final ext = switch (_detectMime(bytes)) {
      'image/svg+xml' => 'svg',
      'image/png'     => 'png',
      'image/gif'     => 'gif',
      'image/webp'    => 'webp',
      _               => 'jpg',
    };
    storagePath = storagePath.contains('.')
        ? storagePath.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '.$ext')
        : '$storagePath.$ext';
    final ref  = _storage.ref().child(storagePath);
    final mime = _detectMime(bytes);
    final task = await ref.putData(bytes, SettableMetadata(contentType: mime));
    return task.ref.getDownloadURL();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Cleanup: HOME content does not belong in the main document — delete any
  /// legacy Title_*, Short_Description_*, Sections_* and Header_Items_* keys
  /// that older versions of the app uploaded here.
  /// NOTE: Nav_Buttons_* DO belong here now — the navbar labels edited on the
  /// Main page are saved in mainPage/main and read by the website from here.
  static const List<String> _legacyHomePrefixes = [
    'Title_',
    'Short_Description_',
    'Sections_',
    'Header_Items',
  ];

  Future<void> _removeLegacyHomeKeys(
      DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) return;
      final stale = data.keys
          .where((k) => _legacyHomePrefixes.any((p) => k.startsWith(p)))
          .toList();
      if (stale.isEmpty) return;
      await ref.update({for (final k in stale) k: FieldValue.delete()});
    } catch (_) {
      // best-effort cleanup — never block a save
    }
  }

  String _detectMime(Uint8List b) {
    if (b.length < 4) return 'application/octet-stream';
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
    if (b[0] == 0xFF && b[1] == 0xD8)                                 return 'image/jpeg';
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return 'image/gif';
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b.length >= 12 && b[8] == 0x57 && b[9] == 0x45 &&
        b[10] == 0x42 && b[11] == 0x50)                               return 'image/webp';
    if (b[0] == 0x3C)                                                 return 'image/svg+xml';
    return 'image/jpeg';
  }
}
