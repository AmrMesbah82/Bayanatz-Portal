// ═══════════════════════════════════════════════════════════════════
// FILE: inquiry_cubit.dart
// Path: lib/controller/inquiry/inquiry_cubit.dart
// UPDATED: Added filter methods for status, entity type, location, month
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/inquiry_model.dart';
import '../../domain/base_repository/inquiry_repo.dart';
import 'inquiry_state.dart';

class InquiryCubit extends Cubit<InquiryState> {
  final InquiryRepo _repo;

  InquiryCubit({required InquiryRepo repo})
      : _repo = repo,
        super(InquiryInitial());

  List<InquiryModel> _allInquiries = [];
  String _searchQuery = '';
  String? _statusFilter;
  String? _entityTypeFilter;
  String? _locationFilter;
  int? _monthFilter;
  // BUG-36: the "Calendar" filter is a real date range now.
  DateTime? _fromDate;
  DateTime? _toDate;

  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    _emitLoaded();
  }

  List<InquiryModel> get allInquiries => _allInquiries;

  Future<void> loadInquiries() async {
    try {
      emit(InquiryLoading());
      _allInquiries = await _repo.fetchAllInquiries();
      _emitLoaded();
    } catch (e) {
      emit(InquiryError('Failed to load: $e', lastInquiries: _allInquiries));
    }
  }

  // ── Filter setters ──────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    _emitLoaded();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    _emitLoaded();
  }

  void setEntityTypeFilter(String? entityType) {
    _entityTypeFilter = entityType;
    _emitLoaded();
  }

  void setLocationFilter(String? location) {
    _locationFilter = location;
    _emitLoaded();
  }

  void setMonthFilter(int? month) {
    _monthFilter = month;
    _emitLoaded();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _entityTypeFilter = null;
    _locationFilter = null;
    _monthFilter = null;
    _fromDate = null;
    _toDate = null;
    _emitLoaded();
  }

  // ── Detail / Update ─────────────────────────────────────────────────────

  Future<void> loadDetail(String id) async {
    try {
      final local = _allInquiries.where((i) => i.id == id).toList();
      if (local.isNotEmpty) {
        emit(InquiryDetailLoaded(local.first));
        return;
      }
      final inquiry = await _repo.fetchInquiryById(id);
      if (inquiry != null) {
        emit(InquiryDetailLoaded(inquiry));
      } else {
        emit(InquiryError('Inquiry not found', lastInquiries: _allInquiries));
      }
    } catch (e) {
      emit(InquiryError('Failed to load: $e', lastInquiries: _allInquiries));
    }
  }

  Future<void> updateStatus(String id, InquiryStatus newStatus) async {
    try {
      await _repo.updateStatus(id, newStatus);
      _allInquiries = _allInquiries.map((i) {
        if (i.id == id) return i.copyWith(status: newStatus);
        return i;
      }).toList();
      final updated = _allInquiries.firstWhere((i) => i.id == id);
      emit(InquiryUpdated(updated));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) _emitLoaded();
      });
    } catch (e) {
      emit(InquiryError('Failed to update: $e', lastInquiries: _allInquiries));
    }
  }

  Future<void> updateNote(String id, String note) async {
    try {
      final inquiry = _allInquiries.firstWhere((i) => i.id == id);
      final updated = inquiry.copyWith(note: note);
      await _repo.updateInquiry(updated);
      _allInquiries = _allInquiries.map((i) => i.id == id ? updated : i).toList();
      emit(InquiryUpdated(updated));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) _emitLoaded();
      });
    } catch (e) {
      emit(InquiryError('Failed to save: $e', lastInquiries: _allInquiries));
    }
  }

  void backToList() => _emitLoaded();

  void _emitLoaded() {
    emit(InquiryLoaded(
      inquiries: _allInquiries,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      entityTypeFilter: _entityTypeFilter,
      locationFilter: _locationFilter,
      monthFilter: _monthFilter,
      fromDate: _fromDate,
      toDate: _toDate,
    ));
  }
}