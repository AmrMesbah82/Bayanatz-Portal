// ******************* FILE INFO *******************
// File Name: main_cubit.dart
// Description: BLoC Cubit for the MAIN page CMS — branding/theme + logo,
//              footer columns and social links. Bound to its OWN Firestore
//              collection ('mainPage') and its OWN model (MainPageModel),
//              fully separated from the Home CMS document.
//              Dual-document architecture:
//              - load() checks for draft first, falls back to published
//              - save(publishStatus: 'published') → published doc, deletes draft
//              - save(publishStatus: 'draft')     → draft doc only
//              - save(publishStatus: 'scheduled') → draft doc with schedule date
// Created by: Amr Mesbah

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/main_model.dart';
import '../../domain/base_repository/main_repo.dart';
import 'main_state.dart';

class MainCmsCubit extends Cubit<MainCmsState> {
  MainCmsCubit({required MainRepository repository})
      : _repo = repository,
        super(MainCmsInitial());

  final MainRepository _repo;
  final _storage = GetStorage();

  MainPageModel _model = MainPageModel.defaultModel;
  MainPageModel get current => _model;

  /// Whether the currently loaded data came from a draft document.
  bool _isFromDraft = false;
  bool get isFromDraft => _isFromDraft;

  static final _rng = Random();
  static String _uid() {
    final ts   = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = _rng.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    return '${ts}_$rand';
  }

  void _applyFontsToStorage(BrandingModel branding) {
    final engFont = branding.englishFont.isEmpty ? 'Cairo' : branding.englishFont;
    final arFont  = branding.arabicFont.isEmpty  ? 'Cairo' : branding.arabicFont;
    _storage.write('font',        engFont);
    _storage.write('font_arabic', arFont);
    // Rebuild the whole tree so AppTextStyles re-reads the new families.
    Get.forceAppUpdate();
  }

  // ── Merge defaults ────────────────────────────────────────────────────────
  MainPageModel _mergeDefaults(MainPageModel loaded) {
    return loaded.copyWith(
      footerColumns: _normalizeFooterIds(loaded.footerColumns),
    );
  }

  /// Ensures every footer column and label has a unique, non-empty id.
  List<FooterColumnModel> _normalizeFooterIds(List<FooterColumnModel> columns) {
    final colIds = <String>{};
    return columns.map((c) {
      var colId = c.id;
      if (colId.isEmpty || colIds.contains(colId)) colId = 'fc_${_uid()}';
      colIds.add(colId);

      final lblIds = <String>{};
      final labels = c.labels.map((l) {
        var lblId = l.id;
        if (lblId.isEmpty || lblIds.contains(lblId)) lblId = 'fl_${_uid()}';
        lblIds.add(lblId);
        return lblId == l.id ? l : l.copyWith(id: lblId);
      }).toList();

      return c.copyWith(id: colId, labels: labels);
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOAD — draft-first strategy
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> load() async {
    emit(MainCmsLoading());
    try {
      final draft = await _repo.fetchDraft();
      if (draft != null) {
        _model       = _mergeDefaults(draft);
        _isFromDraft = true;
        _applyFontsToStorage(_model.branding);
        emit(MainCmsLoaded(_model, isFromDraft: true));
        return;
      }

      final fetched = await _repo.fetchMainPageFresh();
      _model       = _mergeDefaults(fetched);
      _isFromDraft = false;
      _applyFontsToStorage(_model.branding);
      emit(MainCmsLoaded(_model, isFromDraft: false));
    } catch (e) {
      emit(MainCmsError('Failed to load main page: $e'));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SAVE — routes to published or draft based on publishStatus
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> save({
    String publishStatus = 'published',
    DateTime? scheduledPublishDate,
  }) async {
    emit(MainCmsSaving(_model));

    try {
      switch (publishStatus) {
        case 'published':
          final saving = _model.copyWith(
            publishStatus: 'published',
            clearScheduledPublishDate: true,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveMainPage(saving);
          await _repo.deleteDraft();
          _isFromDraft = false;

          final persisted = await _repo.fetchMainPageFresh();
          _model = _mergeDefaults(persisted);
          _applyFontsToStorage(_model.branding);
          emit(MainCmsSaved(_model));
          break;

        case 'draft':
          final saving = _model.copyWith(
            publishStatus: 'draft',
            clearScheduledPublishDate: true,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveDraft(saving);
          _isFromDraft = true;
          _model = saving;
          emit(MainCmsDraftSaved(_model));
          break;

        case 'scheduled':
          final saving = _model.copyWith(
            publishStatus: 'scheduled',
            scheduledPublishDate: scheduledPublishDate,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveDraft(saving);
          _isFromDraft = true;
          _model = saving;
          emit(MainCmsDraftSaved(_model));
          break;

        default:
          final saving = _model.copyWith(
            publishStatus: publishStatus,
            lastUpdatedAt: DateTime.now(),
          );
          await _repo.saveDraft(saving);
          _isFromDraft = true;
          _model = saving;
          emit(MainCmsDraftSaved(_model));
      }
    } catch (e) {
      emit(MainCmsError('Failed to save: $e', _model));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DISCARD DRAFT
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> discardDraft() async {
    try {
      await _repo.deleteDraft();
      _isFromDraft = false;
      emit(MainCmsDraftDeleted());
    } catch (e) {
      emit(MainCmsError('Failed to discard draft: $e', _model));
    }
  }

  void updateScheduledPublishDate(DateTime? date) {
    if (date == null) {
      _model = _model.copyWith(clearScheduledPublishDate: true);
    } else {
      _model = _model.copyWith(scheduledPublishDate: date);
    }
  }

  // ── Footer Columns ────────────────────────────────────────────────────────
  void addFooterColumn() {
    final updated = List<FooterColumnModel>.from(_model.footerColumns)
      ..add(FooterColumnModel(id: _uid()));
    _model = _model.copyWith(footerColumns: updated);
  }

  void removeFooterColumn(String id) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns.where((c) => c.id != id).toList(),
    );
  }

  void updateFooterColumnTitle(String colId, {required String en, required String ar}) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns
          .map((c) => c.id == colId ? c.copyWith(title: BiText(en: en, ar: ar)) : c)
          .toList(),
    );
  }

  void updateFooterColumnRoute(String colId, String route) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns
          .map((c) => c.id == colId ? c.copyWith(route: route) : c)
          .toList(),
    );
  }

  void addFooterLabel(String colId) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns.map((c) {
        if (c.id != colId) return c;
        return c.copyWith(labels: [...c.labels, FooterLabelModel(id: _uid())]);
      }).toList(),
    );
  }

  void removeFooterLabel(String colId, String labelId) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns.map((c) {
        if (c.id != colId) return c;
        return c.copyWith(labels: c.labels.where((l) => l.id != labelId).toList());
      }).toList(),
    );
  }

  void updateFooterLabel(String colId, String labelId,
      {required String en, required String ar}) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns.map((c) {
        if (c.id != colId) return c;
        return c.copyWith(
          labels: c.labels
              .map((l) => l.id == labelId ? l.copyWith(label: BiText(en: en, ar: ar)) : l)
              .toList(),
        );
      }).toList(),
    );
  }

  void updateFooterLabelRoute(String colId, String labelId, String route) {
    _model = _model.copyWith(
      footerColumns: _model.footerColumns.map((c) {
        if (c.id != colId) return c;
        return c.copyWith(
          labels: c.labels
              .map((l) => l.id == labelId ? l.copyWith(route: route) : l)
              .toList(),
        );
      }).toList(),
    );
  }

  // ── Social Links ──────────────────────────────────────────────────────────
  void addSocialLink() {
    _model = _model.copyWith(
      socialLinks: [..._model.socialLinks, SocialLinkModel(id: 'sl_${_uid()}')],
    );
  }

  void removeSocialLink(String id) {
    _model = _model.copyWith(
      socialLinks: _model.socialLinks.where((s) => s.id != id).toList(),
    );
  }

  void updateSocialLink(String id, {required String url, bool? visibility}) {
    _model = _model.copyWith(
      socialLinks: _model.socialLinks
          .map((s) => s.id == id
              ? s.copyWith(url: url, visibility: visibility ?? s.visibility)
              : s)
          .toList(),
    );
  }

  Future<void> uploadSocialLinkIcon(String id, Uint8List bytes) async {
    final path = 'main_cms/social_icons/${id}_${_uid()}.png';
    try {
      final url = await _repo.uploadImage(bytes: bytes, storagePath: path);
      _model = _model.copyWith(
        socialLinks: _model.socialLinks
            .map((s) => s.id == id ? s.copyWith(iconUrl: url) : s)
            .toList(),
      );
    } catch (e) {
      emit(MainCmsError('Social icon upload failed: $e', _model));
    }
  }

  // ── Branding / Logo ───────────────────────────────────────────────────────
  Future<void> uploadLogo(Uint8List bytes) async {
    final path = 'main_cms/branding/logo_${_uid()}.png';
    try {
      final url = await _repo.uploadImage(bytes: bytes, storagePath: path);
      _model = _model.copyWith(branding: _model.branding.copyWith(logoUrl: url));
    } catch (e) {
      emit(MainCmsError('Logo upload failed: $e', _model));
    }
  }

  /// Navigation labels edited on the Main page are stored in mainPage/main —
  /// the website reads them from here.
  void setNavButtons(List<NavButtonModel> navButtons) {
    _model = _model.copyWith(navButtons: navButtons);
  }

  void updatePrimaryColor(String hex) {
    _model = _model.copyWith(branding: _model.branding.copyWith(primaryColor: hex));
  }

  void updateSecondaryColor(String hex) {
    _model = _model.copyWith(branding: _model.branding.copyWith(secondaryColor: hex));
  }

  void updateBackgroundColor(String hex) {
    _model = _model.copyWith(branding: _model.branding.copyWith(backgroundColor: hex));
  }

  void updateHeaderFooterColor(String hex) {
    _model = _model.copyWith(branding: _model.branding.copyWith(headerFooterColor: hex));
  }

  void updateMainWidgetColor(String hex) {
    _model = _model.copyWith(branding: _model.branding.copyWith(mainWidgetColor: hex));
  }

  void updateEnglishFont(String font) {
    _model = _model.copyWith(branding: _model.branding.copyWith(englishFont: font));
  }

  void updateArabicFont(String font) {
    _model = _model.copyWith(branding: _model.branding.copyWith(arabicFont: font));
  }
}
