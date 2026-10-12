// ******************* FILE INFO *******************
// File Name: blog_model.dart
// Created by: Amr Mesbah

class BlogBilingualText {
  final String en;
  final String ar;
  const BlogBilingualText({this.en = '', this.ar = ''});

  factory BlogBilingualText.fromMap(Map<String, dynamic> m) =>
      BlogBilingualText(en: (m['en'] as String?) ?? '', ar: (m['ar'] as String?) ?? '');

  Map<String, dynamic> toMap() => {'en': en, 'ar': ar};

  BlogBilingualText copyWith({String? en, String? ar}) =>
      BlogBilingualText(en: en ?? this.en, ar: ar ?? this.ar);
}

enum BlogBlockType { paragraph, numbering, bulletPoint }

class BlogDescriptionBlock {
  final String           id;
  final BlogBlockType    type;
  final BlogBilingualText content;

  const BlogDescriptionBlock({required this.id, required this.type, required this.content});

  factory BlogDescriptionBlock.fromMap(Map<String, dynamic> m) => BlogDescriptionBlock(
    id:      (m['id'] as String?) ?? '',
    type:    BlogBlockType.values.firstWhere(
            (e) => e.name == (m['type'] as String? ?? 'paragraph'),
        orElse: () => BlogBlockType.paragraph),
    content: BlogBilingualText.fromMap((m['content'] as Map<String, dynamic>?) ?? {}),
  );

  Map<String, dynamic> toMap() => {'id': id, 'type': type.name, 'content': content.toMap()};

  BlogDescriptionBlock copyWith({String? id, BlogBlockType? type, BlogBilingualText? content}) =>
      BlogDescriptionBlock(id: id ?? this.id, type: type ?? this.type, content: content ?? this.content);
}

class BlogPostModel {
  // ── Firestore field keys ──────────────────────────────────────────────────
  static const String AR = 'ar';
  static const String BLOCKS = 'blocks';
  static const String BUTTON_LABEL = 'buttonLabel';
  static const String CONTENT = 'content';
  static const String DESCRIPTION_TITLE = 'descriptionTitle';
  static const String EN = 'en';
  static const String ID = 'id';
  static const String IMAGE_URL = 'imageUrl';
  static const String QUESTION = 'question';
  static const String SHORT_DESCRIPTION = 'shortDescription';
  static const String STATUS = 'status';
  static const String TYPE = 'type';

  final String             id;
  final String             status;       // 'published' | 'draft'
  final String             imageUrl;
  final BlogBilingualText  question;
  final BlogBilingualText  shortDescription;
  final BlogBilingualText  buttonLabel;
  final BlogBilingualText  descriptionTitle;
  final List<BlogDescriptionBlock> blocks;
  final DateTime?          createdAt;

  /// BUG-196: when the post last changed status (Inactive / Draft / Removed
  /// since …). Stored by the repo as a flat `Status_Changed_At` string.
  final DateTime?          statusChangedAt;

  const BlogPostModel({
    required this.id,
    this.status           = 'draft',
    this.imageUrl         = '',
    required this.question,
    required this.shortDescription,
    required this.buttonLabel,
    required this.descriptionTitle,
    this.blocks           = const [],
    this.createdAt,
    this.statusChangedAt,
  });

  factory BlogPostModel.empty() => BlogPostModel(
      id: '', question: const BlogBilingualText(),
      shortDescription: const BlogBilingualText(),
      buttonLabel: const BlogBilingualText(),
      descriptionTitle: const BlogBilingualText());

  factory BlogPostModel.fromMap(String docId, Map<String, dynamic> m) {
    DateTime? createdAt;
    try {
      final raw = m['createdAt'];
      if (raw != null) createdAt = DateTime.fromMillisecondsSinceEpoch(raw.millisecondsSinceEpoch as int);
    } catch (_) {}
    return BlogPostModel(
      id: docId, status: (m['status'] as String?) ?? 'draft',
      imageUrl: (m['imageUrl'] as String?) ?? '',
      question: BlogBilingualText.fromMap((m['question'] as Map<String, dynamic>?) ?? {}),
      shortDescription: BlogBilingualText.fromMap((m['shortDescription'] as Map<String, dynamic>?) ?? {}),
      buttonLabel: BlogBilingualText.fromMap((m['buttonLabel'] as Map<String, dynamic>?) ?? {}),
      descriptionTitle: BlogBilingualText.fromMap((m['descriptionTitle'] as Map<String, dynamic>?) ?? {}),
      blocks: ((m['blocks'] as List?) ?? [])
          .map((b) => BlogDescriptionBlock.fromMap(b as Map<String, dynamic>)).toList(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    STATUS: status, IMAGE_URL: imageUrl,
    QUESTION: question.toMap(), SHORT_DESCRIPTION: shortDescription.toMap(),
    BUTTON_LABEL: buttonLabel.toMap(), DESCRIPTION_TITLE: descriptionTitle.toMap(),
    BLOCKS: blocks.map((b) => b.toMap()).toList(),
  };

  /// Nested template for [FlatCodec.decode] (one populated sample block).
  /// `createdAt` is intentionally excluded — the repo stores/reads it as a
  /// separate flat `Created_At` string.
  static Map<String, dynamic> get flatTemplate => {
        'status': '',
        'imageUrl': '',
        'question': {'en': '', 'ar': ''},
        'shortDescription': {'en': '', 'ar': ''},
        'buttonLabel': {'en': '', 'ar': ''},
        'descriptionTitle': {'en': '', 'ar': ''},
        'blocks': [
          {
            'id': '',
            'type': '',
            'content': {'en': '', 'ar': ''}
          }
        ],
      };

  BlogPostModel copyWith({
    String? id, String? status, String? imageUrl,
    BlogBilingualText? question, BlogBilingualText? shortDescription,
    BlogBilingualText? buttonLabel, BlogBilingualText? descriptionTitle,
    List<BlogDescriptionBlock>? blocks, DateTime? createdAt,
    DateTime? statusChangedAt,
  }) => BlogPostModel(
      id: id ?? this.id, status: status ?? this.status, imageUrl: imageUrl ?? this.imageUrl,
      question: question ?? this.question, shortDescription: shortDescription ?? this.shortDescription,
      buttonLabel: buttonLabel ?? this.buttonLabel, descriptionTitle: descriptionTitle ?? this.descriptionTitle,
      blocks: blocks ?? this.blocks, createdAt: createdAt ?? this.createdAt,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt);
}