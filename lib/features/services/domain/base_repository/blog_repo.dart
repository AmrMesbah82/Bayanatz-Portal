// ******************* FILE INFO *******************
// File Name: blog_repo.dart
// Description: Abstract repository for Blog CMS.
//              Supports dual-document architecture per post:
//              - Published doc  → `blog_posts/{id}`
//              - Draft doc      → `blog_posts/{id}_draft`
// Created by: Amr Mesbah
// Last Update: 20/04/2026
// UPDATED: Added per-post draft lifecycle methods ✅

import 'dart:typed_data';

import '../../data/models/blog_model.dart';

abstract class BlogRepository {
  // ── Published documents ──────────────────────────────────────────────────
  Future<List<BlogPostModel>> fetchAllPosts();
  Future<BlogPostModel>       fetchPost(String id);
  Future<BlogPostModel?>      fetchPostById(String id);
  Future<String>              createPost(BlogPostModel post);
  Future<void>                updatePost(BlogPostModel post);
  Future<void>                deletePost(String id);
  Future<void>                removePost(String id); // BUG-92: soft delete
  Stream<List<BlogPostModel>> watchAllPosts();

  // ── Per-post draft documents ─────────────────────────────────────────────
  /// Fetch the draft version of a post. Returns null if no draft exists.
  Future<BlogPostModel?> fetchDraft(String postId);

  /// Save edits as a draft for a specific post (does NOT touch the published doc).
  Future<void> saveDraft(BlogPostModel post);

  /// Delete the draft document for a specific post.
  Future<void> deleteDraft(String postId);

  /// Promote draft → published: copies draft into the published doc,
  /// then deletes the draft.
  Future<void> promoteDraft(String postId);

  // ── Assets ───────────────────────────────────────────────────────────────
  Future<String> uploadImage({required Uint8List bytes, required String storagePath});
}