// ******************* FILE INFO *******************
// Part of: main_edit.dart
// Contains: _seedFromModel, _save
// SPLIT: Main data (branding/footer/social) comes from MainCmsCubit
//        (MainPageModel / mainPage collection). Nav buttons belong to HOME
//        and are read/written through HomeCmsCubit.

part of '../../pages/main_edit.dart';

// ── The 5 fixed navigation items (identity/routes NOT editable) ──────────────
const List<Map<String, String>> _kCanonicalNavItems = [
  {'route': '/',         'en': 'Home',       'ar': 'الرئيسية'},
  {'route': '/services', 'en': 'Services',   'ar': 'الخدمات'},
  {'route': '/about',    'en': 'About Us',   'ar': 'من نحن'},
  {'route': '/contact',  'en': 'Contact Us', 'ar': 'اتصل بنا'},
  {'route': '/careers',  'en': 'Careers',    'ar': 'الوظائف'},
];

extension _HomeEditSave on _MainEditPageState {
  // ─────────────────────────────────────────────────────────────────────────
  //  SEED FROM MODEL — main data (branding/footer/social) + home nav buttons
  // ─────────────────────────────────────────────────────────────────────────
  void _seedFromModel(MainPageModel d, HomePageModel h) {
    // Main navbar items live ONLY in mainPage/main. They are a separate feature
    // from the Home page nav cards (homePage/home_page) — never read the home
    // doc here. (The [h] parameter is kept for signature compatibility.)
    final List<NavButtonModel> savedNav = d.navButtons;

    final modelHash = Object.hashAll([
      ...savedNav.map((b) => b.id + b.name.en + b.route),
      ...d.socialLinks.map((s) => s.iconUrl),
      d.branding.logoUrl,
    ]);

    if (_seededModelHash == modelHash) return;
    _seededModelHash = modelHash;

    // Remove all listeners before seeding
    for (final m in _navBtns) {
      m['nameEn']!.removeListener(_onFieldChanged);
      m['nameAr']!.removeListener(_onFieldChanged);
    }
    for (final col in _footerColumns) {
      (col['titleEn'] as TextEditingController).removeListener(_onFieldChanged);
      (col['titleAr'] as TextEditingController).removeListener(_onFieldChanged);
      for (final label in col['labels'] as List<Map<String, dynamic>>) {
        (label['en'] as TextEditingController).removeListener(_onFieldChanged);
        (label['ar'] as TextEditingController).removeListener(_onFieldChanged);
      }
    }
    for (final link in _links) {
      link.text.removeListener(_onFieldChanged);
    }

    // ── Nav buttons (HOME data) — FIXED 5 canonical items ───────────────────
    // Home, Services, About Us, Contact Us, Careers. The item set and its
    // routes are fixed; the admin can only edit the DISPLAY name (EN/AR),
    // status and order. Saved buttons keep their saved names/order; any
    // canonical item missing from the saved data (e.g. Home) is appended
    // with its default labels.
    final ordered = <NavButtonModel>[];
    for (final b in savedNav) {
      if (_kCanonicalNavItems.any((c) => c['route'] == b.route) &&
          !ordered.any((o) => o.route == b.route)) {
        ordered.add(b);
      }
    }
    for (final c in _kCanonicalNavItems) {
      if (!ordered.any((b) => b.route == c['route'])) {
        ordered.add(NavButtonModel(
          id:    '',
          name:  BiText(en: c['en']!, ar: c['ar']!),
          route: c['route']!,
        ));
      }
    }

    while (_navBtns.length > ordered.length) {
      final removed = _navBtns.removeLast();
      removed['nameEn']!.dispose();
      removed['nameAr']!.dispose();
      _navRoutes.removeLast();
      _navStatus.removeLast();
    }
    while (_navBtns.length < ordered.length) {
      _navBtns.add({
        'nameEn': TextEditingController(),
        'nameAr': TextEditingController(),
      });
      _navRoutes.add(null);
      _navStatus.add(true);
    }
    for (var i = 0; i < ordered.length; i++) {
      _navBtns[i]['nameEn']!.text = ordered[i].name.en;
      _navBtns[i]['nameAr']!.text = ordered[i].name.ar;
      _navRoutes[i] = ordered[i].route;
      _navStatus[i] = ordered[i].status;
    }

    // ── Footer columns (MAIN data) ──────────────────────────────────────────
    while (_footerColumns.length > d.footerColumns.length) {
      final removed = _footerColumns.removeLast();
      _disposeColumn(removed);
    }
    while (_footerColumns.length < d.footerColumns.length) {
      _footerColumns.add(_newFooterColumn());
    }
    for (var i = 0; i < d.footerColumns.length; i++) {
      (_footerColumns[i]['titleEn'] as TextEditingController).text =
          d.footerColumns[i].title.en;
      (_footerColumns[i]['titleAr'] as TextEditingController).text =
          d.footerColumns[i].title.ar;
      _footerColumns[i]['route'] =
          d.footerColumns[i].route.isEmpty ? null : d.footerColumns[i].route;

      final labels = _footerColumns[i]['labels'] as List<Map<String, dynamic>>;
      while (labels.length > d.footerColumns[i].labels.length) {
        _disposeLabel(labels.removeLast());
      }
      while (labels.length < d.footerColumns[i].labels.length) {
        labels.add(_newLabelRow());
      }
      for (var li = 0; li < d.footerColumns[i].labels.length; li++) {
        (labels[li]['en'] as TextEditingController).text =
            d.footerColumns[i].labels[li].label.en;
        (labels[li]['ar'] as TextEditingController).text =
            d.footerColumns[i].labels[li].label.ar;
        // BUG-59: '' is the "None" choice (label without a link) and is a
        // valid saved value — keep it, don't turn it back into "unset".
        labels[li]['route'] = d.footerColumns[i].labels[li].route;
      }
    }

    // ── Social links (MAIN data) ────────────────────────────────────────────
    while (_links.length > d.socialLinks.length) _links.removeLast().dispose();
    while (_links.length < d.socialLinks.length) _links.add(_LinkItem());
    for (var i = 0; i < d.socialLinks.length; i++) {
      _links[i].text.text = d.socialLinks[i].url;
      _links[i].icon = d.socialLinks[i].iconUrl.isNotEmpty
          ? _PickedImage(url: d.socialLinks[i].iconUrl)
          : const _PickedImage();
      _links[i].visibility = d.socialLinks[i].visibility;
    }

    // ── Branding (MAIN data) ────────────────────────────────────────────────
    _primaryColor.text = d.branding.primaryColor;
    _secondaryColor.text = d.branding.secondaryColor;
    _bgColor.text = d.branding.backgroundColor.isNotEmpty
        ? d.branding.backgroundColor
        : '#D9D9D9';
    _headerFooterColor.text = d.branding.headerFooterColor.isNotEmpty
        ? d.branding.headerFooterColor
        : '#D9D9D9';
    _mainWidgetColor.text = d.branding.mainWidgetColor.isNotEmpty
        ? d.branding.mainWidgetColor
        : '#D9D9D9';
    _engFont = d.branding.englishFont.isEmpty ? 'Cairo' : d.branding.englishFont;
    // BUG-78: a Latin-only font saved earlier falls back to Cairo.
    _arFont = _kArabicFonts.any((m) => m['key'] == d.branding.arabicFont)
        ? d.branding.arabicFont
        : 'Cairo';
    _logoPicked = d.branding.logoUrl.isNotEmpty
        ? _PickedImage(url: d.branding.logoUrl)
        : const _PickedImage();

    // Re-attach listeners
    for (final m in _navBtns) {
      m['nameEn']!.addListener(_onFieldChanged);
      m['nameAr']!.addListener(_onFieldChanged);
    }
    for (final col in _footerColumns) {
      (col['titleEn'] as TextEditingController).addListener(_onFieldChanged);
      (col['titleAr'] as TextEditingController).addListener(_onFieldChanged);
      for (final label in col['labels'] as List<Map<String, dynamic>>) {
        (label['en'] as TextEditingController).addListener(_onFieldChanged);
        (label['ar'] as TextEditingController).addListener(_onFieldChanged);
      }
    }
    for (final link in _links) {
      link.text.addListener(_onFieldChanged);
    }

    _syncFooterTitlesFromNav(); // BUG-67

    // Remember the form exactly as it was loaded. Publish stays disabled until
    // the current signature differs from this one — see _isDirty in
    // main_edit.dart.
    _seedSignature = _formSignature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SAVE / PUBLISH
  //  Everything on this page — branding, footer, social AND the main navbar
  //  items — is saved to the MAIN doc (mainPage/main) via MainCmsCubit only.
  //  The Home page nav cards are a separate feature and are NOT touched here.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _save(MainCmsCubit cubit,
      {String publishStatus = 'published'}) async {
    try {
      // NOTE: Main navbar items are persisted ONLY to mainPage/main below (via
      // cubit.setNavButtons + cubit.save). This editor no longer touches the
      // HOME doc — the Home page nav cards are an independent feature edited on
      // the Home page and stored in homePage/home_page.

      _syncFooterTitlesFromNav(); // BUG-67

      // ── Footer columns — MAIN ─────────────────────────────────────────────
      while (cubit.current.footerColumns.length < _footerColumns.length) {
        cubit.addFooterColumn();
      }
      while (cubit.current.footerColumns.length > _footerColumns.length) {
        cubit.removeFooterColumn(cubit.current.footerColumns.last.id);
      }
      for (var i = 0; i < _footerColumns.length; i++) {
        final colId = cubit.current.footerColumns[i].id;
        cubit.updateFooterColumnTitle(colId,
            en: (_footerColumns[i]['titleEn'] as TextEditingController).text,
            ar: (_footerColumns[i]['titleAr'] as TextEditingController).text);
        cubit.updateFooterColumnRoute(
            colId, _footerColumns[i]['route'] as String? ?? '');

        final labels = _footerColumns[i]['labels'] as List<Map<String, dynamic>>;
        while (cubit.current.footerColumns[i].labels.length < labels.length) {
          cubit.addFooterLabel(colId);
        }
        while (cubit.current.footerColumns[i].labels.length > labels.length) {
          cubit.removeFooterLabel(
              colId, cubit.current.footerColumns[i].labels.last.id);
        }
        for (var li = 0; li < labels.length; li++) {
          final lblId = cubit.current.footerColumns[i].labels[li].id;
          final lblRoute = (labels[li]['route'] as String?) ?? '';
          cubit.updateFooterLabel(colId, lblId,
              en: (labels[li]['en'] as TextEditingController).text,
              ar: (labels[li]['ar'] as TextEditingController).text);
          cubit.updateFooterLabelRoute(colId, lblId, lblRoute);
        }
      }

      // ── Social links — MAIN ───────────────────────────────────────────────
      while (cubit.current.socialLinks.length < _links.length) {
        cubit.addSocialLink();
      }
      while (cubit.current.socialLinks.length > _links.length) {
        cubit.removeSocialLink(cubit.current.socialLinks.last.id);
      }
      for (var i = 0; i < _links.length; i++) {
        final id = cubit.current.socialLinks[i].id;
        cubit.updateSocialLink(id,
            url: _links[i].text.text, visibility: _links[i].visibility);
        if (_links[i].icon.bytes != null) {
          await cubit.uploadSocialLinkIcon(id, _links[i].icon.bytes!);
        }
      }

      // ── Main navbar items — saved to MAIN (mainPage/main) ONLY ────────────
      // The website navbar reads them from this doc. The Home page nav cards
      // are separate (homePage/home_page) and are not written here.
      cubit.setNavButtons([
        for (var i = 0; i < _navBtns.length; i++)
          if ((_navRoutes[i] ?? '').isNotEmpty)
            NavButtonModel(
              id:     'nb_${i + 1}',
              name:   BiText(
                en: _navBtns[i]['nameEn']!.text.trim(),
                ar: _navBtns[i]['nameAr']!.text.trim(),
              ),
              route:  _navRoutes[i]!,
              status: _navStatus[i],
            ),
      ]);

      // ── Branding / Logo — MAIN ────────────────────────────────────────────
      if (_logoPicked.bytes != null) {
        await cubit.uploadLogo(_logoPicked.bytes!);
      }
      cubit.updatePrimaryColor(_primaryColor.text);
      cubit.updateSecondaryColor(_secondaryColor.text);
      cubit.updateBackgroundColor(_bgColor.text);
      cubit.updateHeaderFooterColor(_headerFooterColor.text);
      cubit.updateMainWidgetColor(_mainWidgetColor.text);
      cubit.updateEnglishFont(_engFont ?? 'Cairo');
      cubit.updateArabicFont(_arFont ?? 'Cairo');

      // Save main data (incl. main navbar items) to the MAIN doc ONLY.
      await cubit.save(publishStatus: publishStatus);
    } catch (e) {
      // Errors surface via MainCmsError state
    }
  }
}
