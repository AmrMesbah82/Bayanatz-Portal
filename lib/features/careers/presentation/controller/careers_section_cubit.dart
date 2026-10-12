// ******************* FILE INFO *******************
// File Name: careers_section_cubit.dart
// Cubit for Why Join Our Team / Our Interns / Our Teams
// One cubit instance per section tab — pass sectionKey in constructor.

import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';


import '../../data/models/careers_section_model.dart';
import '../../data/repository/careers_section_repo_impl.dart';
import '../../domain/base_repository/careers_section_repo.dart';
import 'careers_section_state.dart';


class CareersSectionCubit extends Cubit<CareersSectionState> {
  final String sectionKey; // 'whyJoinOurTeam' | 'ourInterns' | 'ourTeams'
  final CareersSectionRepo _repo;
  late CareersSectionModel _model;

  CareersSectionCubit({
    required this.sectionKey,
    CareersSectionRepo? repo,
  })  : _repo = repo ?? CareersSectionRepoImp(),
        super(CareersSectionInitial()) {
    _model = CareersSectionModel.empty(sectionKey);
  }

  CareersSectionModel get current => _model;

  // ── Load ────────────────────────────────────────────────────────────────────
  Future<void> load() async {
    emit(CareersSectionLoading());
    try {
      _model = await _repo.load(sectionKey);
      emit(CareersSectionLoaded(_model));
    } catch (e) {
      emit(CareersSectionError(e.toString()));
    }
  }

  // ── Add Item ────────────────────────────────────────────────────────────────
  void addItem() {
    final newId = const Uuid().v4();
    final updated = List<CareersSectionItem>.from(_model.items)
      ..add(CareersSectionItem(id: newId));
    _model = _model.copyWith(items: updated);
    emit(CareersSectionLoaded(_model));
  }

  // ── Remove Item ─────────────────────────────────────────────────────────────
  void removeItem(String itemId) {
    final updated =
    _model.items.where((item) => item.id != itemId).toList();
    _model = _model.copyWith(items: updated);
    emit(CareersSectionLoaded(_model));

  }

  // ── Update Title ────────────────────────────────────────────────────────────
  void updateTitle(String itemId, {String? en, String? ar}) {
    final updated = _model.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(
        title: item.title.copyWith(en: en, ar: ar),
      );
    }).toList();
    _model = _model.copyWith(items: updated);
  }

  // ── Update Description ──────────────────────────────────────────────────────
  void updateDescription(String itemId, {String? en, String? ar}) {
    final updated = _model.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(
        description: item.description.copyWith(en: en, ar: ar),
      );
    }).toList();
    _model = _model.copyWith(items: updated);
  }

  // ── Upload Icon ─────────────────────────────────────────────────────────────
  Future<void> uploadIcon(String itemId, Uint8List bytes) async {
    final url = await _repo.uploadIcon(sectionKey, itemId, bytes);
    final updated = _model.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(iconUrl: url);
    }).toList();
    _model = _model.copyWith(items: updated);
  }

  // ── Upload SVG Image ────────────────────────────────────────────────────────
  Future<void> uploadSvg(String itemId, Uint8List bytes) async {
    final url = await _repo.uploadSvg(sectionKey, itemId, bytes);
    final updated = _model.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(svgUrl: url);
    }).toList();
    _model = _model.copyWith(items: updated);
  }

  // ── Clear SVG Image (BUG-211) ───────────────────────────────────────────────
  void clearSvg(String itemId) {
    final updated = _model.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(svgUrl: '');
    }).toList();
    _model = _model.copyWith(items: updated);
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> save() async {
    emit(CareersSectionLoading());
    try {
      _model = _model.copyWith(lastUpdated: DateTime.now());
      await _repo.save(_model);
      // Reload to get server timestamp
      _model = await _repo.load(sectionKey);
      emit(CareersSectionSaved(_model));
    } catch (e) {
      emit(CareersSectionError(e.toString()));
    }
  }
}