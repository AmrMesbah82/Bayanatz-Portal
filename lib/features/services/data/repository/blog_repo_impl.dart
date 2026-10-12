// ******************* FILE INFO *******************
// File Name: blog_repo_impl.dart
// Description: Firebase implementation of BlogRepository.
//              Dual-document architecture per post:
//              - Published → `blog_posts/{id}`
//              - Draft     → `blog_posts/{id}_draft`
// Created by: Amr Mesbah
// Last Update: 20/04/2026
// UPDATED: Per-post dual-document draft system ✅

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/utils/flat_codec.dart';
import '../../domain/base_repository/blog_repo.dart';
import '../models/blog_model.dart';

class BlogRepositoryImpl implements BlogRepository {
  BlogRepositoryImpl({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage   = storage   ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage   _storage;

  static const String _collection = 'blogPosts';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  // ═════════════════════════════════════════════════════════════════════════
  //  PUBLISHED DOCUMENTS
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<List<BlogPostModel>> fetchAllPosts() async {
    try {
      final snap = await _col.orderBy('Last_Updated_At', descending: true).get();
      // Filter out draft documents (those ending with _draft)
      final posts = snap.docs
          .where((d) => !d.id.endsWith('_draft'))
          .map((d) => _decodeBlog(d.id, _sanitize(d.data())))
          .toList();
      return posts;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<BlogPostModel> fetchPost(String id) async {
    try {
      final snap = await _col.doc(id).get();
      if (!snap.exists || snap.data() == null) return BlogPostModel.empty();
      return _decodeBlog(snap.id, _sanitize(snap.data()!));
    } catch (e) {
      return BlogPostModel.empty();
    }
  }

  @override
  Future<BlogPostModel?> fetchPostById(String id) async {
    try {
      final snap = await _col.doc(id).get();
      if (!snap.exists || snap.data() == null) return null;
      return _decodeBlog(snap.id, _sanitize(snap.data()!));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> createPost(BlogPostModel post) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final ref = await _col.add(FlatCodec.encodeNew({
        ...post.toMap(),
        'createdAt': now,
        'statusChangedAt': now, // BUG-196
      }));
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePost(BlogPostModel post) async {
    try {
      // BUG-196: remember WHEN the status changed (cards said "Inactive
      // Since <posting date>").
      final before = await fetchPostById(post.id);
      final statusChanged = before == null || before.status != post.status;
      // Versioned append write (append-on-change history per field).
      await FlatCodec.writeVersioned(_col.doc(post.id), {
        ...post.toMap(),
        if (post.createdAt != null)
          'createdAt': post.createdAt!.toIso8601String(),
        if (statusChanged)
          'statusChangedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// BUG-92: "Remove" is a SOFT delete — the post moves to the "Removed"
  /// tab (status 'removed', hidden from the public site) and can be restored
  /// or deleted for good from there. It used to delete the document.
  @override
  Future<void> removePost(String id) async {
    try {
      await FlatCodec.writeVersioned(_col.doc(id), {
        'status': 'removed',
        'statusChangedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await deleteDraft(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deletePost(String id) async {
    try {
      await _col.doc(id).delete();
      // Also delete any draft for this post
      final draftRef = _col.doc('${id}_draft');
      final draftSnap = await draftRef.get();
      if (draftSnap.exists) {
        await draftRef.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<BlogPostModel>> watchAllPosts() {
    return _col.orderBy('Last_Updated_At', descending: true).snapshots().map((snap) =>
        snap.docs
            .where((d) => !d.id.endsWith('_draft'))
            .map((d) => _decodeBlog(d.id, _sanitize(d.data())))
            .toList());
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PER-POST DRAFT DOCUMENTS
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<BlogPostModel?> fetchDraft(String postId) async {
    try {
      final snap = await _col.doc('${postId}_draft').get();
      if (snap.exists && snap.data() != null) {
        return _decodeBlog(postId, _sanitize(snap.data()!));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveDraft(BlogPostModel post) async {
    final draftId = '${post.id}_draft';
    try {
      await FlatCodec.writeVersioned(_col.doc(draftId), {
        ...post.toMap(),
        'originalPostId': post.id,
        'createdAt': (post.createdAt ?? DateTime.now()).toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteDraft(String postId) async {
    try {
      final ref = _col.doc('${postId}_draft');
      final snap = await ref.get();
      if (snap.exists) {
        await ref.delete();
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> promoteDraft(String postId) async {
    try {
      final draft = await fetchDraft(postId);
      if (draft == null) {
        return;
      }
      final publishedModel = draft.copyWith(status: 'published');
      await updatePost(publishedModel);
      await deleteDraft(postId);
    } catch (e) {
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  ASSETS
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<String> uploadImage({required Uint8List bytes, required String storagePath}) async {
    try {
      final ref  = _storage.ref().child(storagePath);
      final mime = _detectMime(bytes);
      final task = await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url  = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _sanitize(Map<String, dynamic> d) {
    final copy = Map<String, dynamic>.from(d);
    copy.remove('updatedAt');
    return copy;
  }

  /// Decode a FLAT Firestore blog document into a model, restoring the
  /// separately-stored `Created_At` ISO string into the model's createdAt.
  BlogPostModel _decodeBlog(String id, Map<String, dynamic> data) {
    final model = BlogPostModel.fromMap(
      id,
      FlatCodec.decode(data, BlogPostModel.flatTemplate),
    );
    final rawCreated = data['Created_At'];
    final createdStr = (rawCreated is List && rawCreated.isNotEmpty)
        ? rawCreated.last
        : rawCreated;
    final created = (createdStr is String && createdStr.isNotEmpty)
        ? DateTime.tryParse(createdStr)
        : null;
    // BUG-196: date of the last status change.
    final rawChanged = data['Status_Changed_At'];
    final changedStr = (rawChanged is List && rawChanged.isNotEmpty)
        ? rawChanged.last
        : rawChanged;
    final changed = (changedStr is String && changedStr.isNotEmpty)
        ? DateTime.tryParse(changedStr)?.toLocal()
        : null;
    return model.copyWith(createdAt: created?.toLocal(), statusChangedAt: changed);
  }

  String _detectMime(Uint8List b) {
    if (b.length < 4) return 'application/octet-stream';
    if (b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b[0] == 0x47 && b[1] == 0x49) return 'image/gif';
    if (b[0] == 0x52 && b[1] == 0x49 && b.length >= 12 &&
        b[8] == 0x57 && b[9] == 0x45) return 'image/webp';
    if (b[0] == 0x3C) return 'image/svg+xml';
    return 'image/jpeg';
  }
}