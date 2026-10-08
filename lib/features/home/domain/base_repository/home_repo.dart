// ******************* FILE INFO *******************
// File Name: home_repo.dart
// Description: Abstract repository for Home CMS.
//              THREE-document architecture — each version is stored on its own
//              so none of them can overwrite another:
//              - Published doc  → `homePage/home_page`
//              - Scheduled doc  → `homePage/home_page_scheduled`
//              - Draft doc      → `homePage/home_page_draft`
//
//              A scheduled release and a draft can exist at the same time, and
//              saving either one never touches the published version that is
//              currently live.
// Created by: Amr Mesbah
// UPDATED: Scheduled split out of the draft document into its own slot ✅

import 'dart:typed_data';

import '../../data/models/home_model.dart';

abstract class HomeRepository {
  // ── Published document ───────────────────────────────────────────────────
  Future<HomePageModel> fetchHomePage();
  Future<HomePageModel> fetchHomePageFresh();
  Future<void> saveHomePage(HomePageModel model);
  Stream<HomePageModel> watchHomePage();

  /// Partial write: updates ONLY the Nav_Buttons_* keys of the published
  /// home document. Used by the MAIN page (which edits nav buttons) so that
  /// publishing Main never uploads the rest of the home content
  /// (title / sections / descriptions / publish status).
  Future<void> saveNavButtons(List<NavButtonModel> navButtons);

  // ── Draft document ───────────────────────────────────────────────────────
  /// Fetch the draft version. Returns null if no draft exists.
  Future<HomePageModel?> fetchDraft();

  /// Save form edits as a draft (does NOT touch the published doc).
  Future<void> saveDraft(HomePageModel model);

  /// Delete the draft document (e.g. after publish or discard).
  Future<void> deleteDraft();

  /// Promote draft → published: copies draft into the published doc,
  /// then deletes the draft.
  Future<void> promoteDraft();

  // ── Scheduled document ───────────────────────────────────────────────────
  /// Fetch the scheduled version. Returns null if nothing is scheduled.
  Future<HomePageModel?> fetchScheduled();

  /// Save form edits as a scheduled release, carrying its publish date.
  /// Does NOT touch the published doc — the live page stays as it is until
  /// the scheduled date arrives.
  Future<void> saveScheduled(HomePageModel model);

  /// Delete the scheduled document (cancel the scheduled release).
  Future<void> deleteScheduled();

  /// Promote scheduled → published: copies the scheduled version into the
  /// published doc, then clears the scheduled slot. Called once its date has
  /// passed.
  Future<void> promoteScheduled();

  // ── Assets ───────────────────────────────────────────────────────────────
  Future<String> uploadImage({
    required Uint8List bytes,
    required String storagePath,
  });
}
