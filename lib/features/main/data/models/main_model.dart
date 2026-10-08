// ******************* FILE INFO *******************
// File Name: main_model.dart
// Description: Pure data model for the MAIN page CMS (site shell):
//              branding/theme + logo, footer columns, social links.
//              These fields belong to MAIN — they are NOT part of the
//              Home CMS document. Nav buttons belong to HOME.
//              Reuses the component classes (BrandingModel,
//              FooterColumnModel, SocialLinkModel, BiText) from home_model.
// Created by: Amr Mesbah

import '../../../home/data/models/home_model.dart'
    show
        BiText,
        BrandingModel,
        FooterColumnModel,
        FooterLabelModel,
        NavButtonModel,
        SocialLinkModel;

export '../../../home/data/models/home_model.dart'
    show
        BiText,
        BrandingModel,
        FooterColumnModel,
        FooterLabelModel,
        NavButtonModel,
        SocialLinkModel;

// ─────────────────────────────────────────────────────────────────────────────
// ROOT — MainPageModel
// ─────────────────────────────────────────────────────────────────────────────

class MainPageModel {
  // ── Firestore field keys ──────────────────────────────────────────────────
  static const String BRANDING = 'branding';
  static const String FOOTER_COLUMNS = 'footerColumns';
  static const String SOCIAL_LINKS = 'socialLinks';
  static const String NAV_BUTTONS = 'navButtons';
  static const String PUBLISH_STATUS = 'publishStatus';

  final BrandingModel           branding;
  final List<FooterColumnModel> footerColumns;
  final List<SocialLinkModel>   socialLinks;
  final List<NavButtonModel>    navButtons;
  final String                  publishStatus; // 'published' | 'scheduled' | 'draft'
  final DateTime?               lastUpdatedAt;
  final DateTime?               scheduledPublishDate;

  const MainPageModel({
    this.branding      = const BrandingModel(),
    this.footerColumns = const [],
    this.socialLinks   = const [],
    this.navButtons    = const [],
    this.publishStatus = 'draft',
    this.lastUpdatedAt,
    this.scheduledPublishDate,
  });

  MainPageModel copyWith({
    BrandingModel?           branding,
    List<FooterColumnModel>? footerColumns,
    List<SocialLinkModel>?   socialLinks,
    List<NavButtonModel>?    navButtons,
    String?                  publishStatus,
    DateTime?                lastUpdatedAt,
    DateTime?                scheduledPublishDate,
    // Use this sentinel to explicitly clear the scheduled date
    bool                     clearScheduledPublishDate = false,
  }) =>
      MainPageModel(
        branding:             branding             ?? this.branding,
        footerColumns:        footerColumns        ?? this.footerColumns,
        socialLinks:          socialLinks          ?? this.socialLinks,
        navButtons:           navButtons           ?? this.navButtons,
        publishStatus:        publishStatus        ?? this.publishStatus,
        lastUpdatedAt:        lastUpdatedAt        ?? this.lastUpdatedAt,
        scheduledPublishDate: clearScheduledPublishDate
            ? null
            : (scheduledPublishDate ?? this.scheduledPublishDate),
      );

  Map<String, dynamic> toMap() => {
    BRANDING:       branding.toMap(),
    FOOTER_COLUMNS: footerColumns.map((e) => e.toMap()).toList(),
    SOCIAL_LINKS:   socialLinks.map((e) => e.toMap()).toList(),
    NAV_BUTTONS:    navButtons.map((e) => e.toMap()).toList(),
    PUBLISH_STATUS: publishStatus,
  };

  /// Nested template used by FlatCodec.decode to rebuild this model from the
  /// FLAT string-key Firestore document.
  static Map<String, dynamic> get flatTemplate => {
    ...defaultModel.toMap(),
    'lastUpdatedAt': '',
    'scheduledPublishDate': '',
  };

  factory MainPageModel.fromMap(Map<String, dynamic> map) => MainPageModel(
    branding: BrandingModel.fromMap(map[BRANDING] ?? {}),
    footerColumns: (map[FOOTER_COLUMNS] as List<dynamic>? ?? [])
        .map((e) => FooterColumnModel.fromMap(e as Map<String, dynamic>))
        .toList(),
    socialLinks: (map[SOCIAL_LINKS] as List<dynamic>? ?? [])
        .map((e) => SocialLinkModel.fromMap(e as Map<String, dynamic>))
        .toList(),
    navButtons: (map[NAV_BUTTONS] as List<dynamic>? ?? [])
        .map((e) => NavButtonModel.fromMap(e as Map<String, dynamic>))
        .toList(),
    publishStatus:        map[PUBLISH_STATUS] ?? 'draft',
    lastUpdatedAt:        _parseDateTime(map['lastUpdatedAt']),
    scheduledPublishDate: _parseDateTime(map['scheduledPublishDate']),
  );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) return value;
      // BUG-25: runtimeType.toString() is MINIFIED in release web builds, so
      // checking for the name 'Timestamp' never matched in production and
      // every date came back null ("Last Updated On —"). Duck-type the
      // Firestore Timestamp instead.
      if (value is! String && value is! num) {
        try { return (value as dynamic).toDate() as DateTime; } catch (_) {}
      }
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {}
    return null;
  }

  static MainPageModel get defaultModel => const MainPageModel(
    branding: BrandingModel(),
    footerColumns: [
      FooterColumnModel(
        id: 'fc_1',
        title: BiText(en: 'Services', ar: 'الخدمات'),
        route: '/services',
        labels: [
          FooterLabelModel(id: 'fl_1a', label: BiText(en: 'Digital Strategy', ar: 'الاستراتيجية الرقمية')),
          FooterLabelModel(id: 'fl_1b', label: BiText(en: 'Data Analytics',   ar: 'تحليل البيانات')),
        ],
      ),
      FooterColumnModel(
        id: 'fc_2',
        title: BiText(en: 'About Us', ar: 'من نحن'),
        route: '/about',
        labels: [
          FooterLabelModel(id: 'fl_2a', label: BiText(en: 'Mission', ar: 'الرسالة')),
          FooterLabelModel(id: 'fl_2b', label: BiText(en: 'Vision',  ar: 'الرؤية')),
        ],
      ),
      FooterColumnModel(
        id: 'fc_3',
        title: BiText(en: 'Contact Us', ar: 'اتصل بنا'),
        route: '/contact',
        labels: [
          FooterLabelModel(id: 'fl_3a', label: BiText(en: 'Contact Form', ar: 'نموذج التواصل')),
        ],
      ),
    ],
    socialLinks: [
      SocialLinkModel(id: 'sl_0', iconUrl: '', url: '', visibility: true),
      SocialLinkModel(id: 'sl_1', iconUrl: '', url: '', visibility: true),
      SocialLinkModel(id: 'sl_2', iconUrl: '', url: '', visibility: true),
      SocialLinkModel(id: 'sl_3', iconUrl: '', url: '', visibility: true),
    ],
    navButtons: [
      NavButtonModel(id: 'nb_1', name: BiText(en: 'Home',       ar: 'الرئيسية'), route: '/',         status: true),
      NavButtonModel(id: 'nb_2', name: BiText(en: 'Services',   ar: 'الخدمات'),  route: '/services', status: true),
      NavButtonModel(id: 'nb_3', name: BiText(en: 'About Us',   ar: 'من نحن'),   route: '/about',    status: true),
      NavButtonModel(id: 'nb_4', name: BiText(en: 'Contact Us', ar: 'اتصل بنا'), route: '/contact',  status: true),
      NavButtonModel(id: 'nb_5', name: BiText(en: 'Careers',    ar: 'الوظائف'),  route: '/careers',  status: true),
    ],
    publishStatus: 'draft',
    lastUpdatedAt: null,
    scheduledPublishDate: null,
  );
}
