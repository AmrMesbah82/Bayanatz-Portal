// ******************* FILE INFO *******************
// File Name: contact_us_cms_cubit.dart
// Created by: Claude Assistant

import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/contact_us_model_location.dart';
import '../../data/repository/contact_us_location_repo_impl.dart';
import '../../domain/base_repository/contact_us_location.dart';
import 'contact_us_location_state.dart';



class ContactUsCmsCubit extends Cubit<ContactUsCmsState> {
  final ContactUsCmsRepo _repo;

  ContactUsCmsCubit({ContactUsCmsRepo? repo})
      : _repo = repo ?? ContactUsCmsRepoImpl(),
        super(ContactUsCmsInitial());

  // ── Load contact us CMS data ──────────────────────────────────────────────

  Future<void> load() async {
    try {
      emit(ContactUsCmsLoading());
      final data = await _repo.load();
      emit(ContactUsCmsLoaded(data));
    } catch (e) {
      emit(ContactUsCmsError('Failed to load contact us data: ${e.toString()}'));
    }
  }

  /// BUG-53: preview the admin's UNSAVED edits (no Firestore read).
  void showDraft(ContactUsCmsModel draft) => emit(ContactUsCmsLoaded(draft));

  // ── Save contact us CMS data ──────────────────────────────────────────────

  Future<void> save({
    required ContactUsCmsModel model,
    Map<String, Uint8List>? imageUploads,
  }) async {
    try {
      await _repo.save(model: model, imageUploads: imageUploads);


      // ✅ Reload to get updated URLs and emit with data
      final updatedData = await _repo.load();
      emit(ContactUsCmsSaved(updatedData));
    } catch (e) {
      emit(ContactUsCmsError('Failed to save contact us data: ${e.toString()}'));
    }
  }
}