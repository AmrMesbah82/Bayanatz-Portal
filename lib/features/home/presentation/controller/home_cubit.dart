// ******************* FILE INFO *******************
// File Name: home_cubit.dart
// Description: BLoC Cubit for Home CMS.
//              THREE-document architecture — published, scheduled and draft
//              each live in their own document, so saving one never overwrites
//              another and a queued release can coexist with a draft:
//
//              - load()  reads all three at once and keeps them in memory, so
//                        the overview can show every version side by side.
//                        The editor buffer is seeded draft → scheduled →
//                        published, i.e. the most recent unfinished work.
//              - save('published') → writes the live doc, clears the draft
//              - save('draft')     → writes the draft doc ONLY
//              - save('scheduled') → writes the scheduled doc ONLY
//              - removeDraft() / removeScheduled() → delete that slot
//
//              Only one draft and one scheduled release may exist at a time.
//              Saving into an occupied slot you are not already editing is
//              refused with HomeCmsSlotBusy rather than silently overwriting.
// Created by: Amr Mesbah
// UPDATED: Scheduled split out of the draft document into its own slot ✅

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/home_model.dart';
import '../../domain/base_repository/home_repo.dart';
import 'home_state.dart';



class HomeCmsCubit extends Cubit<HomeCmsState> {
  HomeCmsCubit({required HomeRepository repository})
      : _repo = repository,
        super(HomeCmsInitial());

  final HomeRepository _repo;

  /// The editor buffer — what the edit screen reads and mutates.
  HomePageModel _model = HomePageModel.defaultModel;
  HomePageModel get current => _model;

  // ── The three stored versions, cached from the last load() ────────────────
  // The overview screen renders all three at once, so it needs them together
  // rather than one at a time.

  HomePageModel? _published;
  HomePageModel? _scheduled;
  HomePageModel? _draft;

  /// The live version. Null only before the first successful load.
  HomePageModel? get publishedModel => _published;

  /// The queued release, or null when nothing is scheduled.
  HomePageModel? get scheduledModel => _scheduled;

  /// The open draft, or null when there isn't one.
  HomePageModel? get draftModel => _draft;

  bool get hasScheduled => _scheduled != null;
  bool get hasDraft     => _draft != null;

  /// Which stored version the editor buffer came from.
  HomeVersionSlot _slot = HomeVersionSlot.published;
  HomeVersionSlot get slot => _slot;

  /// Kept for existing call sites.
  bool get isFromDraft => _slot == HomeVersionSlot.draft;

  /// A new draft can only be started when the draft slot is free. If you are
  /// already editing the draft, saving again just updates it.
  bool get canSaveDraft => !hasDraft || _slot == HomeVersionSlot.draft;

  /// Same rule for the scheduled slot.
  bool get canSaveScheduled =>
      !hasScheduled || _slot == HomeVersionSlot.scheduled;

  /// True once a scheduled release is due — its date is today or in the past.
  bool get isScheduledDue {
    final date = _scheduled?.scheduledPublishDate;
    if (date == null) return false;
    final startOfDay = DateTime(date.year, date.month, date.day);
    return !DateTime.now().isBefore(startOfDay);
  }

  /// Load one specific version into the editor buffer. Used by the overview
  /// when the user opens the editor from a particular tab.
  void editSlot(HomeVersionSlot slot) {
    final model = switch (slot) {
      HomeVersionSlot.published => _published,
      HomeVersionSlot.scheduled => _scheduled,
      HomeVersionSlot.draft     => _draft,
    };
    if (model == null) return;
    _model = model;
    _slot  = slot;
    emit(HomeCmsLoaded(_model, slot: slot));
  }

  static final _rng = Random();
  static String _uid() {
    final ts   = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = _rng.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    return '${ts}_$rand';
  }

  // ── Merge defaults ────────────────────────────────────────────────────────
  // Dedupe the saved nav buttons by id. Default nav buttons are used ONLY as a
  // fallback when none are saved — we never re-inject a default by route,
  // otherwise changing a saved button's route (e.g. moving Careers to another
  // page) makes the old route look "missing" and adds a duplicate button.
  HomePageModel _mergeDefaults(HomePageModel loaded) {
    final seen = <String>{};
    final deduped = loaded.navButtons.where((b) {
      if (seen.contains(b.id)) return false;
      seen.add(b.id);
      return true;
    }).toList();

    if (deduped.isEmpty) {
      return loaded.copyWith(navButtons: HomePageModel.defaultModel.navButtons);
    }

    return loaded.copyWith(navButtons: deduped);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOAD — reads all three slots
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> load() async {
    emit(HomeCmsLoading());
    try {
      // Fetch all three concurrently — the overview shows them together, and
      // three sequential round-trips is three times the wait.
      final results = await Future.wait([
        _repo.fetchHomePageFresh(),
        _repo.fetchScheduled(),
        _repo.fetchDraft(),
      ]);

      _published = _mergeDefaults(results[0] as HomePageModel);
      final scheduled = results[1] as HomePageModel?;
      final draft     = results[2] as HomePageModel?;
      _scheduled = scheduled == null ? null : _mergeDefaults(scheduled);
      _draft     = draft == null ? null : _mergeDefaults(draft);

      // Seed the editor with the most recent unfinished work: a draft first,
      // then a queued release, otherwise what is live.
      if (_draft != null) {
        _model = _draft!;
        _slot  = HomeVersionSlot.draft;
      } else if (_scheduled != null) {
        _model = _scheduled!;
        _slot  = HomeVersionSlot.scheduled;
      } else {
        _model = _published!;
        _slot  = HomeVersionSlot.published;
      }

      emit(HomeCmsLoaded(_model, slot: _slot));
    } catch (e) {
      emit(HomeCmsError('Failed to load home page: $e'));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SAVE — routes to published or draft based on publishStatus
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> save({
    String publishStatus = 'published',
    DateTime? scheduledPublishDate,
  }) async {


    // ── Slot guards ───────────────────────────────────────────────────────
    // Refuse to clobber work that is already sitting in a slot. You can always
    // keep updating the version you are currently editing.
    if (publishStatus == 'draft' && !canSaveDraft) {
      emit(HomeCmsSlotBusy(
        'A draft already exists. Publish it or remove it before starting '
        'another one.',
        HomeVersionSlot.draft,
        _model,
      ));
      return;
    }
    if (publishStatus == 'scheduled' && !canSaveScheduled) {
      emit(HomeCmsSlotBusy(
        'A scheduled release already exists. Publish it or remove it before '
        'scheduling another one.',
        HomeVersionSlot.scheduled,
        _model,
      ));
      return;
    }

    emit(HomeCmsSaving(_model));

    try {
      switch (publishStatus) {
      // ── PUBLISH: write the live doc and close the draft ─────────────
        case 'published':
          final saving = _model.copyWith(
            publishStatus: 'published',
            clearScheduledPublishDate: true,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveHomePage(saving);

          // Publishing finishes the draft you were working on. A scheduled
          // release is a separate, deliberate queue entry, so it is left
          // alone — remove it explicitly if you no longer want it.
          await _repo.deleteDraft();
          _draft = null;

          // Re-fetch to pick up the server timestamp.
          final persisted = await _repo.fetchHomePageFresh();
          _published = _mergeDefaults(persisted);
          _model     = _published!;
          _slot      = HomeVersionSlot.published;
          emit(HomeCmsSaved(_model));
          break;

      // ── DRAFT: draft doc only, published stays live ─────────────────
        case 'draft':
          final saving = _model.copyWith(
            publishStatus: 'draft',
            clearScheduledPublishDate: true,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveDraft(saving);
          _draft = saving;
          _model = saving;
          _slot  = HomeVersionSlot.draft;
          emit(HomeCmsDraftSaved(_model));
          break;

      // ── SCHEDULED: its own doc, published stays live until the date ─
        case 'scheduled':
          final saving = _model.copyWith(
            publishStatus: 'scheduled',
            scheduledPublishDate: scheduledPublishDate,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveScheduled(saving);
          _scheduled = saving;
          _model     = saving;
          _slot      = HomeVersionSlot.scheduled;
          emit(HomeCmsScheduledSaved(_model));
          break;

        default:
          emit(HomeCmsError('Unknown publish status: $publishStatus', _model));
      }
    } catch (e) {
      emit(HomeCmsError('Failed to save: $e', _model));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REMOVE A SLOT — the published version is never touched
  // ══════════════════════════════════════════════════════════════════════════

  /// Delete the draft. The live page is unaffected.
  Future<void> removeDraft() async {
    try {
      await _repo.deleteDraft();
      _draft = null;
      if (_slot == HomeVersionSlot.draft) {
        _model = _scheduled ?? _published ?? HomePageModel.defaultModel;
        _slot  = _scheduled != null
            ? HomeVersionSlot.scheduled
            : HomeVersionSlot.published;
      }
      emit(HomeCmsDraftDeleted());
    } catch (e) {
      emit(HomeCmsError('Failed to remove draft: $e', _model));
    }
  }

  /// Cancel the scheduled release. The live page is unaffected.
  Future<void> removeScheduled() async {
    try {
      await _repo.deleteScheduled();
      _scheduled = null;
      if (_slot == HomeVersionSlot.scheduled) {
        _model = _draft ?? _published ?? HomePageModel.defaultModel;
        _slot  = _draft != null
            ? HomeVersionSlot.draft
            : HomeVersionSlot.published;
      }
      emit(HomeCmsScheduledDeleted());
    } catch (e) {
      emit(HomeCmsError('Failed to remove scheduled version: $e', _model));
    }
  }

  /// Kept as an alias so existing "Discard draft" call sites keep working.
  Future<void> discardDraft() => removeDraft();

  /// Copy a due scheduled release into the published document and clear the
  /// scheduled slot. Safe to call at any time — it does nothing unless a
  /// scheduled version exists and its date has arrived.
  Future<void> publishDueScheduled() async {
    if (!isScheduledDue) return;
    try {
      await _repo.promoteScheduled();
      _scheduled = null;
      await load();
    } catch (e) {
      emit(HomeCmsError('Failed to publish scheduled version: $e', _model));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FIELD UPDATE METHODS (unchanged API)
  // ══════════════════════════════════════════════════════════════════════════

  void updateScheduledPublishDate(DateTime? date) {
    if (date == null) {
      _model = _model.copyWith(clearScheduledPublishDate: true);
    } else {
      _model = _model.copyWith(scheduledPublishDate: date);
    }
  }

  void updateTitle({required String en, required String ar}) {
    _model = _model.copyWith(title: BiText(en: en, ar: ar));
  }

  void updateShortDescription({required String en, required String ar}) {
    _model = _model.copyWith(shortDescription: BiText(en: en, ar: ar));
  }

  // ── Nav Buttons ───────────────────────────────────────────────────────────
  void addNavButton() {
    final updated = List<NavButtonModel>.from(_model.navButtons)
      ..add(NavButtonModel(id: _uid()));
    _model = _model.copyWith(navButtons: updated);
  }

  void removeNavButton(String id) {
    _model = _model.copyWith(
      navButtons: _model.navButtons.where((b) => b.id != id).toList(),
    );
  }

  void reorderNavButtons(int oldIndex, int newIndex) {
    final list = List<NavButtonModel>.from(_model.navButtons);
    if (newIndex > oldIndex) newIndex--;
    list.insert(newIndex, list.removeAt(oldIndex));
    _model = _model.copyWith(navButtons: list);
    emit(HomeCmsLoaded(_model, slot: _slot));
  }

  void reorderNavButtonsSilent(int oldIndex, int newIndex) {
    final list = List<NavButtonModel>.from(_model.navButtons);
    if (newIndex > oldIndex) newIndex--;
    list.insert(newIndex, list.removeAt(oldIndex));
    _model = _model.copyWith(navButtons: list);
  }

  void updateNavButtonName(String id,
      {required String en, required String ar}) {
    _model = _model.copyWith(
      navButtons: _model.navButtons
          .map((b) => b.id == id ? b.copyWith(name: BiText(en: en, ar: ar)) : b)
          .toList(),
    );
  }

  void updateNavButtonRoute(String id, String route) {
    _model = _model.copyWith(
      navButtons: _model.navButtons
          .map((b) => b.id == id ? b.copyWith(route: route) : b)
          .toList(),
    );
  }

  void toggleNavButtonStatus(String id) {
    _model = _model.copyWith(
      navButtons: _model.navButtons
          .map((b) => b.id == id ? b.copyWith(status: !b.status) : b)
          .toList(),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────
  void updateSectionTextBoxColor(int index, String color) {
    _updateSection(index, (s) => s.copyWith(textBoxColor: color));
  }

  void updateSectionDescription(int index,
      {required String en, required String ar}) {
    _updateSection(index, (s) => s.copyWith(description: BiText(en: en, ar: ar)));
  }

  void updateSectionVisibility(int index, bool visibility) {
    _updateSection(index, (s) => s.copyWith(visibility: visibility));
  }

  Future<void> uploadSectionImage(int index, Uint8List bytes) async {
    final path = 'home_cms/sections/$index/image_${_uid()}.jpg';
    try {
      final url = await _repo.uploadImage(bytes: bytes, storagePath: path);
      _updateSection(index, (s) => s.copyWith(imageUrl: url));
    } catch (e, st) {
      emit(HomeCmsError('Section image upload failed: $e', _model));
    }
  }

  Future<void> uploadSectionIcon(int index, Uint8List bytes) async {
    final path = 'home_cms/sections/$index/icon_${_uid()}.png';
    try {
      final url = await _repo.uploadImage(bytes: bytes, storagePath: path);
      _updateSection(index, (s) => s.copyWith(iconUrl: url));
    } catch (e, st) {
      emit(HomeCmsError('Section icon upload failed: $e', _model));
    }
  }

  void _updateSection(int index, SectionCardModel Function(SectionCardModel) updater) {
    final sections = List<SectionCardModel>.from(_model.sections);
    while (sections.length <= index) {
      // ✅ Assign the fixed slot position when padding new section cards.
      final slot = sections.length;
      sections.add(SectionCardModel(
        position: slot < kSectionPositions.length ? kSectionPositions[slot] : 'left',
      ));
    }
    sections[index] = updater(sections[index]);
    _model = _model.copyWith(sections: sections);
  }

  // ── Header Items ──────────────────────────────────────────────────────────
  // REMOVED: header items are STATIC (HomePageModel.staticHeaderItems).
  // They are not part of the CMS model and are never uploaded to Firebase.

  // ── Footer / Social / Branding ────────────────────────────────────────────
  // REMOVED: footer columns, social links and branding/logo belong to the
  // MAIN page CMS (MainCmsCubit / MainPageModel / mainPage collection).
}