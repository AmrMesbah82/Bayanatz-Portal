// ******************* FILE INFO *******************
// File Name: blog_cubit.dart
// Description: Cubit for Blog CMS.
//              Dual-document architecture per post:
//              - createPost/updatePost with status='published' → writes published doc, deletes draft
//              - createPost/updatePost with status='draft' → writes draft doc only
//              - discardDraft() → deletes draft doc
// Created by: Amr Mesbah
// Last Update: 20/04/2026
// UPDATED: Per-post dual-document draft system ✅

import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/blog_model.dart';
import '../../domain/base_repository/blog_repo.dart';
import 'blog_state.dart';

// Import repo — adjust path to match your project structure

class BlogCubit extends Cubit<BlogState> {
  final BlogRepository _repo;

  BlogCubit(this._repo) : super(BlogInitial());

  List<BlogPostModel> _posts = [];
  List<BlogPostModel> get posts => _posts;

  // ══════════════════════════════════════════════════════════════════════════
  //  LOAD
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> load() async {
    emit(BlogLoading());
    try {
      _posts = await _repo.fetchAllPosts();
      emit(BlogLoaded(_posts));
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CREATE POST — routes to published or draft
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> createPost({
    required BlogPostModel post,
    Uint8List? imageBytes,
  }) async {
    try {
      String imageUrl = post.imageUrl;

      // Upload image if provided
      if (imageBytes != null) {
        final path = 'blog_images/${DateTime.now().millisecondsSinceEpoch}.svg';
        imageUrl = await _repo.uploadImage(bytes: imageBytes, storagePath: path);
      }

      final postWithImage = post.copyWith(imageUrl: imageUrl);

      switch (post.status) {
      // ── PUBLISH: create the published doc directly ──────────────────
        case 'published':
          final newId = await _repo.createPost(postWithImage);
          final saved = postWithImage.copyWith(id: newId);
          emit(BlogSaved(saved));
          break;

      // ── DRAFT: create the published doc as draft ────────────────────
      // For new posts, we create the doc with status='draft' directly
      // (no separate _draft doc needed since there's no published version)
        case 'draft':
        default:
          final newId = await _repo.createPost(postWithImage);
          final saved = postWithImage.copyWith(id: newId);
          emit(BlogDraftSaved(saved));
          break;
      }
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPDATE POST — routes to published or draft
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updatePost({
    required BlogPostModel post,
    Uint8List? imageBytes,
  }) async {
    try {
      String imageUrl = post.imageUrl;

      // Upload image if provided
      if (imageBytes != null) {
        final path = 'blog_images/${post.id}_${DateTime.now().millisecondsSinceEpoch}.svg';
        imageUrl = await _repo.uploadImage(bytes: imageBytes, storagePath: path);
      }

      final postWithImage = post.copyWith(imageUrl: imageUrl);

      switch (post.status) {
      // ── PUBLISH: update the published doc, delete any draft ──────────
      // BUG-61: 'inactive' is a status of the LIVE post too. It used to fall
      // through to the draft branch, which wrote a hidden "<id>_draft" copy
      // and left the original Posted and public.
        case 'published':
        case 'inactive':
          await _repo.updatePost(postWithImage);
          // Clean up any existing draft for this post
          await _repo.deleteDraft(post.id);
          emit(BlogSaved(postWithImage));
          break;

      // ── DRAFT: save to draft doc only, do NOT touch published ────────
        case 'draft':
        default:
          // Check if this post already exists as published
          final existingPublished = await _repo.fetchPostById(post.id);
          if (existingPublished != null && existingPublished.status == 'published') {
            // Published version exists — save edits as a separate draft doc
            await _repo.saveDraft(postWithImage);
          } else {
            // No published version — just update the doc directly with draft status
            await _repo.updatePost(postWithImage);
          }
          emit(BlogDraftSaved(postWithImage));
          break;
      }
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DISCARD DRAFT — deletes the draft doc (published stays untouched)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> discardDraft(String postId) async {
    try {
      await _repo.deleteDraft(postId);
      emit(BlogDraftDeleted());
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH POST WITH DRAFT-FIRST STRATEGY
  // ══════════════════════════════════════════════════════════════════════════
  /// Loads a post for editing — checks for draft first, falls back to published.
  /// Returns the model and whether it came from a draft.
  Future<({BlogPostModel post, bool isFromDraft})> fetchForEdit(String postId) async {
    try {
      // 1️⃣ Check if a draft exists
      final draft = await _repo.fetchDraft(postId);
      if (draft != null) {
        return (post: draft, isFromDraft: true);
      }

      // 2️⃣ No draft — load published
      final published = await _repo.fetchPost(postId);
      return (post: published, isFromDraft: false);
    } catch (e) {
      rethrow;
    }
  }

  // ── Delete post ───────────────────────────────────────────────────────────
  Future<void> deletePost(String id) async {
    try {
      await _repo.deletePost(id);
      await load(); // Refresh list
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }
}