// ******************* FILE INFO *******************
// File Name: home_state.dart
// Description: States for HomeCmsCubit.
//              THREE-document architecture (published + scheduled + draft).
// Created by: Amr Mesbah
// UPDATED: Added editingSlot to HomeCmsLoaded, plus scheduled save/delete
//          states, so the UI can tell which version it is looking at ✅

import '../../data/models/home_model.dart';

/// Which stored version the editor is working on.
enum HomeVersionSlot { published, scheduled, draft }

abstract class HomeCmsState {}

class HomeCmsInitial extends HomeCmsState {}

class HomeCmsLoading extends HomeCmsState {}

/// Loaded state — carries the data being edited AND which slot it came from.
class HomeCmsLoaded extends HomeCmsState {
  final HomePageModel data;

  /// Which document the editor buffer was seeded from.
  final HomeVersionSlot slot;

  HomeCmsLoaded(this.data, {this.slot = HomeVersionSlot.published});

  /// Kept so existing call sites reading `state.isFromDraft` keep working.
  bool get isFromDraft => slot == HomeVersionSlot.draft;

  /// True when the editor is working on a queued scheduled release.
  bool get isFromScheduled => slot == HomeVersionSlot.scheduled;
}

class HomeCmsSaving extends HomeCmsState {
  final HomePageModel data;
  HomeCmsSaving(this.data);
}

/// Published successfully — the live document was written.
class HomeCmsSaved extends HomeCmsState {
  final HomePageModel data;
  HomeCmsSaved(this.data);
}

/// Draft saved successfully — published doc was NOT touched.
class HomeCmsDraftSaved extends HomeCmsState {
  final HomePageModel data;
  HomeCmsDraftSaved(this.data);
}

/// Scheduled release saved successfully — published doc was NOT touched and
/// stays live until the scheduled date arrives.
class HomeCmsScheduledSaved extends HomeCmsState {
  final HomePageModel data;
  HomeCmsScheduledSaved(this.data);
}

/// Draft deleted (discarded from the editor, or removed from the overview).
class HomeCmsDraftDeleted extends HomeCmsState {}

/// Scheduled release cancelled and removed.
class HomeCmsScheduledDeleted extends HomeCmsState {}

/// A save was refused because that slot is already occupied — e.g. trying to
/// start a second draft while one is still open. Carries the current data so
/// the screen never goes blank.
class HomeCmsSlotBusy extends HomeCmsState {
  final String message;
  final HomeVersionSlot slot;
  final HomePageModel data;
  HomeCmsSlotBusy(this.message, this.slot, this.data);
}

class HomeCmsError extends HomeCmsState {
  final String message;
  final HomePageModel? lastData;
  HomeCmsError(this.message, [this.lastData]);
}
