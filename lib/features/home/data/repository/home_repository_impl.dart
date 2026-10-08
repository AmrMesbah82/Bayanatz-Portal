// ******************* FILE INFO *******************
// File Name: home_repository_impl.dart
// Description: Firebase implementation of HomeRepository.
//              Dual-document architecture:
//              - Published → `cms/home_page`
//              - Draft     → `cms/home_page_draft`
//
//              "Save For Later" writes to the _draft doc only.
//              "Publish" writes to the published doc and deletes the draft.
//              "Schedule" writes to the _draft doc with publishStatus = 'scheduled'.
// Created by: Amr Mesbah
// Last Update: 20/04/2026
// UPDATED: Dual-document draft system ✅

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


import '../../../../core/utils/flat_codec.dart';
import '../../domain/base_repository/home_repo.dart';
import '../models/home_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    String collection    = 'homePage',
    String publishedDoc  = 'home_page',
    String draftDoc      = 'home_page_draft',
    String scheduledDoc  = 'home_page_scheduled',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _collection = collection,
        _publishedDoc = publishedDoc,
        _draftDoc = draftDoc,
        _scheduledDoc = scheduledDoc;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  final String _collection;
  final String _publishedDoc;
  final String _draftDoc;
  final String _scheduledDoc;

  DocumentReference<Map<String, dynamic>> get _publishedRef =>
      _firestore.collection(_collection).doc(_publishedDoc);

  DocumentReference<Map<String, dynamic>> get _draftRef =>
      _firestore.collection(_collection).doc(_draftDoc);

  DocumentReference<Map<String, dynamic>> get _scheduledRef =>
      _firestore.collection(_collection).doc(_scheduledDoc);

  // ═════════════════════════════════════════════════════════════════════════
  //  PUBLISHED DOCUMENT
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<HomePageModel> fetchHomePage() async {
    try {
      final snapshot = await _publishedRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return HomePageModel.defaultModel;
      }
      final data = _sanitize(snapshot.data()!);
      final model = HomePageModel.fromMap(
        FlatCodec.decode(data, HomePageModel.flatTemplate),
      );
      return model;
    } catch (e, st) {
      return HomePageModel.defaultModel;
    }
  }

  @override
  Future<HomePageModel> fetchHomePageFresh() async {
    try {
      final snapshot = await _publishedRef.get(const GetOptions(source: Source.server));
      if (!snapshot.exists || snapshot.data() == null) {
        return HomePageModel.defaultModel;
      }
      final data = _sanitize(snapshot.data()!);
      final model = HomePageModel.fromMap(
        FlatCodec.decode(data, HomePageModel.flatTemplate),
      );
      return model;
    } catch (e, st) {
      return HomePageModel.defaultModel;
    }
  }

  @override
  Future<void> saveHomePage(HomePageModel model) async {
    try {
      final nested = {
        ...model.toMap(),
        'scheduledPublishDate': model.scheduledPublishDate?.toIso8601String(),
      };
      await FlatCodec.writeVersioned(_publishedRef, nested);
      await _removeLegacyHeaderItemKeys(_publishedRef);
    } catch (e, st) {
      rethrow;
    }
  }

  @override
  Future<void> saveNavButtons(List<NavButtonModel> navButtons) async {
    // Partial write — ONLY Nav_Buttons_* keys, no stamp, no publish status,
    // no title/sections. Publishing Main must never upload home content.
    //
    // GUARD: if the home document does not exist yet (Home was never
    // published), do NOTHING — publishing Main must not create the home doc.
    final snap = await _publishedRef.get();
    if (!snap.exists) return;

    final nested = {
      HomePageModel.NAV_BUTTONS: navButtons.map((e) => e.toMap()).toList(),
    };
    await FlatCodec.writeVersioned(_publishedRef, nested, stampKey: null);
    await _removeLegacyHeaderItemKeys(_publishedRef);
  }

  /// Cleanup: these keys no longer belong to the HOME CMS document —
  /// • Header_Items_*   → header items are STATIC (never stored)
  /// • Branding_*       → branding/theme/logo belongs to MAIN (mainPage)
  /// • Footer_Columns_* → footer belongs to MAIN (mainPage)
  /// • Social_Links_*   → social links belong to MAIN (mainPage)
  /// Delete any legacy keys that older versions of the app uploaded here.
  static const List<String> _legacyMainPrefixes = [
    'Header_Items',
    'Branding_',
    'Footer_Columns_',
    'Social_Links_',
  ];

  Future<void> _removeLegacyHeaderItemKeys(
      DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) return;
      final stale = data.keys
          .where((k) => _legacyMainPrefixes.any((p) => k.startsWith(p)))
          .toList();
      if (stale.isEmpty) return;
      await ref.update({for (final k in stale) k: FieldValue.delete()});
    } catch (_) {
      // best-effort cleanup — never block a save
    }
  }

  @override
  Stream<HomePageModel> watchHomePage() {
    return _publishedRef.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return HomePageModel.defaultModel;
      try {
        return HomePageModel.fromMap(
          FlatCodec.decode(_sanitize(snap.data()!), HomePageModel.flatTemplate),
        );
      } catch (e) {
        return HomePageModel.defaultModel;
      }
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  DRAFT DOCUMENT
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<HomePageModel?> fetchDraft() async {
    try {
      final snapshot = await _draftRef.get(const GetOptions(source: Source.server));
      if (snapshot.exists && snapshot.data() != null) {
        final data = _sanitize(snapshot.data()!);
        return HomePageModel.fromMap(
          FlatCodec.decode(data, HomePageModel.flatTemplate),
        );
      }
      return null;
    } catch (e, st) {
      rethrow;
    }
  }

  @override
  Future<void> saveDraft(HomePageModel model) async {
    try {
      final nested = {
        ...model.toMap(),
        'scheduledPublishDate': model.scheduledPublishDate?.toIso8601String(),
      };
      await FlatCodec.writeVersioned(_draftRef, nested);
      await _removeLegacyHeaderItemKeys(_draftRef);
    } catch (e, st) {
      rethrow;
    }
  }

  @override
  Future<void> deleteDraft() async {
    try {
      final snap = await _draftRef.get();
      if (snap.exists) {
        await _draftRef.delete();
      } else {
      }
    } catch (e, st) {
      rethrow;
    }
  }

  @override
  Future<void> promoteDraft() async {
    try {
      final draft = await fetchDraft();
      if (draft == null) {
        return;
      }
      final publishedModel = draft.copyWith(
        publishStatus: 'published',
        clearScheduledPublishDate: true,
      );
      await saveHomePage(publishedModel);
      await deleteDraft();
    } catch (e, st) {
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  SCHEDULED DOCUMENT
  // ═════════════════════════════════════════════════════════════════════════
  //
  // A scheduled release lives in its OWN document, not in the draft. That is
  // what lets a queued release and a work-in-progress draft coexist, and what
  // keeps the currently published page untouched until the date arrives.

  @override
  Future<HomePageModel?> fetchScheduled() async {
    try {
      final snapshot =
          await _scheduledRef.get(const GetOptions(source: Source.server));
      if (snapshot.exists && snapshot.data() != null) {
        final data = _sanitize(snapshot.data()!);
        return HomePageModel.fromMap(
          FlatCodec.decode(data, HomePageModel.flatTemplate),
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveScheduled(HomePageModel model) async {
    try {
      final nested = {
        ...model.toMap(),
        'scheduledPublishDate': model.scheduledPublishDate?.toIso8601String(),
      };
      await FlatCodec.writeVersioned(_scheduledRef, nested);
      await _removeLegacyHeaderItemKeys(_scheduledRef);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteScheduled() async {
    try {
      final snap = await _scheduledRef.get();
      if (snap.exists) await _scheduledRef.delete();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> promoteScheduled() async {
    try {
      final scheduled = await fetchScheduled();
      if (scheduled == null) return;
      final publishedModel = scheduled.copyWith(
        publishStatus: 'published',
        clearScheduledPublishDate: true,
        lastUpdatedAt: DateTime.now(),
      );
      await saveHomePage(publishedModel);
      await deleteScheduled();
    } catch (e) {
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  ASSETS
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String storagePath,
  }) async {
    try {
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
      final url  = await task.ref.getDownloadURL();
      return url;
    } catch (e, st) {
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _sanitize(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data);
  }

  String _detectMime(Uint8List b) {
    if (b.length < 4) return 'application/octet-stream';
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
    if (b[0] == 0xFF && b[1] == 0xD8)                                   return 'image/jpeg';
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return 'image/gif';
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b.length >= 12 && b[8] == 0x57 && b[9] == 0x45 &&
        b[10] == 0x42 && b[11] == 0x50)                                  return 'image/webp';
    if (b[0] == 0x3C)                                                    return 'image/svg+xml';
    return 'image/jpeg';
  }
}