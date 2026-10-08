// ******************* FILE INFO *******************
// File Name: intern_model.dart

class InternModel {
  final String id;
  final String photoUrl;
  final String firstName;
  final String lastName;
  final String position;
  final String degrees;
  final DateTime? joinedDate;
  final String whatHaveILearned;

  // BUG-74: Arabic versions (the Arabic site had no way to show interns in
  // Arabic). Empty = fall back to the English value.
  final String firstNameAr;
  final String lastNameAr;
  final String positionAr;
  final String degreesAr;
  final String whatHaveILearnedAr;
  // final List<String> tags;

  const InternModel({
    required this.id,
    this.photoUrl = '',
    required this.firstName,
    required this.lastName,
    this.position = '',
    this.degrees = '',
    this.joinedDate,
    required this.whatHaveILearned,
    this.firstNameAr        = '',
    this.lastNameAr         = '',
    this.positionAr         = '',
    this.degreesAr          = '',
    this.whatHaveILearnedAr = '',
    // this.tags = const [],
  });

  String get fullName => '$firstName $lastName'.trim();

  // BUG-74: language-aware getters (Arabic falls back to English when empty).
  String _pick(bool ar, String arValue, String enValue) =>
      ar && arValue.trim().isNotEmpty ? arValue : enValue;
  String fullNameFor(bool ar) {
    final f = _pick(ar, firstNameAr, firstName);
    final l = _pick(ar, lastNameAr, lastName);
    return '$f $l'.trim();
  }
  String positionFor(bool ar)         => _pick(ar, positionAr, position);
  String degreesFor(bool ar)          => _pick(ar, degreesAr, degrees);
  String whatHaveILearnedFor(bool ar) =>
      _pick(ar, whatHaveILearnedAr, whatHaveILearned);

  String get joinDateLabel {
    if (joinedDate == null) return '';
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Joined as Intern: ${joinedDate!.day} ${months[joinedDate!.month]} ${joinedDate!.year}';
  }

  InternModel copyWith({
    String? id,
    String? photoUrl,
    String? firstName,
    String? lastName,
    String? position,
    String? degrees,
    DateTime? joinedDate,
    String? whatHaveILearned,
    String? firstNameAr,
    String? lastNameAr,
    String? positionAr,
    String? degreesAr,
    String? whatHaveILearnedAr,
    // List<String>? tags,
  }) {
    return InternModel(
      id:               id               ?? this.id,
      photoUrl:         photoUrl         ?? this.photoUrl,
      firstName:        firstName        ?? this.firstName,
      lastName:         lastName         ?? this.lastName,
      position:         position         ?? this.position,
      degrees:          degrees          ?? this.degrees,
      joinedDate:       joinedDate       ?? this.joinedDate,
      whatHaveILearned: whatHaveILearned ?? this.whatHaveILearned,
      firstNameAr:        firstNameAr        ?? this.firstNameAr,
      lastNameAr:         lastNameAr         ?? this.lastNameAr,
      positionAr:         positionAr         ?? this.positionAr,
      degreesAr:          degreesAr          ?? this.degreesAr,
      whatHaveILearnedAr: whatHaveILearnedAr ?? this.whatHaveILearnedAr,
      // tags:             tags             ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':               id,
    'photoUrl':         photoUrl,
    'firstName':        firstName,
    'lastName':         lastName,
    'position':         position,
    'degrees':          degrees,
    'joinedDate':       joinedDate?.toIso8601String(),
    'whatHaveILearned': whatHaveILearned,
    'firstNameAr':        firstNameAr,
    'lastNameAr':         lastNameAr,
    'positionAr':         positionAr,
    'degreesAr':          degreesAr,
    'whatHaveILearnedAr': whatHaveILearnedAr,
    // 'tags':             tags,
  };

  /// Nested template for [FlatCodec.decode]. `tags` is a string list, so it
  /// flattens to Tags_Count + Tags_0, Tags_1, …
  static Map<String, dynamic> get flatTemplate => {
        'id': '',
        'photoUrl': '',
        'firstName': '',
        'lastName': '',
        'position': '',
        'degrees': '',
        'joinedDate': '',
        'whatHaveILearned': '',
        'firstNameAr': '',
        'lastNameAr': '',
        'positionAr': '',
        'degreesAr': '',
        'whatHaveILearnedAr': '',
        // 'tags': [''],
      };

  factory InternModel.fromMap(Map<String, dynamic> map) => InternModel(
    id:               map['id']               as String? ?? '',
    photoUrl:         map['photoUrl']         as String? ?? '',
    firstName:        map['firstName']        as String? ?? '',
    lastName:         map['lastName']         as String? ?? '',
    position:         map['position']         as String? ?? '',
    degrees:          map['degrees']          as String? ?? '',
    joinedDate:       map['joinedDate'] != null
        ? DateTime.tryParse(map['joinedDate'] as String)
        : null,
    whatHaveILearned: map['whatHaveILearned'] as String? ?? '',
    firstNameAr:        map['firstNameAr']        as String? ?? '',
    lastNameAr:         map['lastNameAr']         as String? ?? '',
    positionAr:         map['positionAr']         as String? ?? '',
    degreesAr:          map['degreesAr']          as String? ?? '',
    whatHaveILearnedAr: map['whatHaveILearnedAr'] as String? ?? '',
    // tags:             (map['tags'] as List<dynamic>?)
    //     ?.map((e) => e as String)
    //     .toList() ?? [],
  );

  factory InternModel.empty() => InternModel(
    id:               '',
    firstName:        '',
    lastName:         '',
    whatHaveILearned: '',
  );
}