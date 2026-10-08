// ═══════════════════════════════════════════════════════════════════
// FILE 1: department_model.dart
// Path: lib/features/departments/data/models/department_model.dart
// ═══════════════════════════════════════════════════════════════════

class DepartmentModel {
  // ── Firestore field keys ──────────────────────────────────────────────────
  static const String CREATED_AT = 'createdAt';
  static const String ICON_URL = 'iconUrl';
  static const String NAME_AR = 'nameAr';
  static const String NAME_EN = 'nameEn';

  final String id;
  final String nameEn;
  final String nameAr;
  final String iconUrl;
  final DateTime? createdAt;

  const DepartmentModel({
    required this.id,
    this.nameEn = '',
    this.nameAr = '',
    this.iconUrl = '',
    this.createdAt,
  });

  factory DepartmentModel.empty() => DepartmentModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
  );

  factory DepartmentModel.fromMap(String id, Map<String, dynamic> map) {
    return DepartmentModel(
      id: id,
      nameEn: map[NAME_EN] as String? ?? '',
      nameAr: map[NAME_AR] as String? ?? '',
      iconUrl: map[ICON_URL] as String? ?? '',
      createdAt: map[CREATED_AT] != null
          ? DateTime.tryParse(map[CREATED_AT] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    NAME_EN: nameEn,
    NAME_AR: nameAr,
    ICON_URL: iconUrl,
    CREATED_AT: (createdAt ?? DateTime.now()).toIso8601String(),
  };

  /// Nested template for [FlatCodec.decode].
  static Map<String, dynamic> get flatTemplate => {
        NAME_EN: '',
        NAME_AR: '',
        ICON_URL: '',
        CREATED_AT: '',
      };

  /// Whether a job's stored `department` value belongs to this department.
  ///
  /// Jobs save the department as its English name, but older records may hold
  /// the Arabic name or the document id — accept all three, ignoring case and
  /// surrounding whitespace.
  bool matchesJob(String jobDepartment) {
    final v = jobDepartment.trim().toLowerCase();
    if (v.isEmpty) return false;
    return v == nameEn.trim().toLowerCase() ||
        (nameAr.isNotEmpty && v == nameAr.trim().toLowerCase()) ||
        v == id.trim().toLowerCase();
  }

  DepartmentModel copyWith({
    String? id,
    String? nameEn,
    String? nameAr,
    String? iconUrl,
    DateTime? createdAt,
  }) =>
      DepartmentModel(
        id: id ?? this.id,
        nameEn: nameEn ?? this.nameEn,
        nameAr: nameAr ?? this.nameAr,
        iconUrl: iconUrl ?? this.iconUrl,
        createdAt: createdAt ?? this.createdAt,
      );
}