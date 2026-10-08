part of '../../pages/about_us_preview.dart';

class _PreviewContent extends StatefulWidget {
  final double fakeWidth, fakeHeight;
  final AboutPageModel model;
  final bool isAr, isMobile;
  const _PreviewContent({
    required this.fakeWidth,
    required this.fakeHeight,
    required this.model,
    required this.isAr,
    this.isMobile = false,
  });
  @override
  State<_PreviewContent> createState() => _PreviewContentState();
}

class _PreviewContentState extends State<_PreviewContent> {
  int _topTab         = 0; // 0=About Us  1=Strategy  2=Terms  3=Privacy
  int _subTab         = 0; // Vision / Mission / Values
  int _mobileExpanded = 0; // accordion open index (-1=none)

  bool get _isDesktop  => widget.fakeWidth >= _kDesktopW;
  bool get _isTablet   => widget.fakeWidth >= 600 && !_isDesktop;
  bool get _isMobView  => widget.isMobile || widget.fakeWidth < 600;

  double get _hPad => _isDesktop ? 0 : (_isMobView ? 16 : 24);

  // branding stand-in
  Color get _primary   => _kDefaultGreen;
  Color get _secondary => _kGreenLight;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: Size(widget.fakeWidth, widget.fakeHeight),
        padding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
      ),
      child: Directionality(
        textDirection:
        widget.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          color: AppColors.background,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page heading ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: _hPad,
                      vertical: _isDesktop ? 36 : 20),
                  child: Text(
                    _ab(widget.model.title, widget.isAr).isNotEmpty
                        ? _ab(widget.model.title, widget.isAr)
                        : (widget.isAr ? 'من نحن' : 'About Us'),
                    style: StyleText.fontSize45Weight600.copyWith(
                      fontSize: _isDesktop ? 48 : 28,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),

                // // ── Top tab bar ────────────────────────────────────────
                // Padding(
                //   padding:
                //   EdgeInsets.symmetric(horizontal: _hPad),
                //   child: _isMobView
                //       ? SingleChildScrollView(
                //       scrollDirection: Axis.horizontal,
                //       child: Row(children: _buildTopTabs()))
                //       : Row(
                //       mainAxisAlignment:
                //       MainAxisAlignment.spaceEvenly,
                //       children: _buildTopTabs()),
                // ),
                // const SizedBox(height: 16),

                // ── Content ────────────────────────────────────────────
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: _hPad),
                  child: _buildContent(),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP TABS  (mirrors _DesktopTopTabItem / _MobileTopTabItem)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildTopTabs() {
    final labels = widget.isAr
        ? ['من نحن', 'استراتيجيتنا', 'الشروط والأحكام', 'سياسة الخصوصية']
        : ['About Us', 'Our Strategy', 'Terms and Conditions', 'Privacy Policy'];

    final icons = [
      Icons.people_outline,
      Icons.account_tree_outlined,
      Icons.description_outlined,
      Icons.lock_outline,
    ];

    return List.generate(4, (i) {
      final bool sel = _topTab == i;
      return GestureDetector(
        onTap: () => setState(
                () { _topTab = i; _subTab = 0; _mobileExpanded = 0; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: _isMobView ? 8 : 0),
          padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 12 : 10,
              vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isDesktop ? 48 : 38,
                height: _isDesktop ? 48 : 38,
                decoration: BoxDecoration(
                  color: sel ? _primary : _secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icons[i],
                      size: _isDesktop ? 24 : 20,
                      color: sel ? Colors.white : _primary),
                ),
              ),
              SizedBox(width: _isDesktop ? 10 : 6),
              Text(
                labels[i],
                style: StyleText.fontSize13Weight500.copyWith(
                  fontSize: _isDesktop ? 13 : 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _primary : AppColors.secondaryBlack,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTENT SWITCHER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContent() {
    switch (_topTab) {
      case 0:
        if (_isDesktop) return _buildDesktopAboutUs();
        if (_isMobView) return _buildMobileAboutUs();
        return _buildTabletAboutUs();
      case 1:
        return _buildPlaceholder(widget.isAr
            ? 'محتوى الاستراتيجية متاح في التطبيق'
            : 'Strategy content is available in the live app');
      case 2:
        return _buildPlaceholder(widget.isAr
            ? 'محتوى الشروط والأحكام متاح في التطبيق'
            : 'Terms and Conditions content is available in the live app');
      case 3:
        return _buildPlaceholder(widget.isAr
            ? 'محتوى سياسة الخصوصية متاح في التطبيق'
            : 'Privacy Policy content is available in the live app');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholder(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12)),
    child: Center(
      child: Text(msg,
          textAlign: TextAlign.center,
          style: StyleText.fontSize14Weight400.copyWith(
              fontSize: _isDesktop ? 14 : 12,
              color: Colors.grey[500])),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // ABOUT US — DESKTOP (two-column: left sub-tabs + right panel)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopAboutUs() {
    const double leftW = 280, gap = 16;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) => Padding(
                padding: EdgeInsets.only(bottom: i == 2 ? 0 : 8),
                child: _DesktopSubTab(
                  label:       _subTabLabel(i),
                  iconUrl:     _subTabIconUrl(i),
                  description: _subTab == i ? _subTabDesc(i) : '',
                  isSelected:  _subTab == i,
                  primary:     _primary,
                  secondary:   _secondary,
                  onTap: () => setState(() => _subTab = i),
                ),
              )),
            ),
          ),
          const SizedBox(width: gap),
          Expanded(child: _buildDesktopRightPanel()),
        ],
      ),
    );
  }

  Widget _buildDesktopRightPanel() {
    if (_subTab == 2) {
      final others = widget.model.values.length > 1
          ? widget.model.values.sublist(1) : <AboutValueItem>[];
      return _ValuesGrid(
          values: others, isRtl: widget.isAr,
          primary: _primary, secondary: _secondary, compact: false);
    }
    final s = _subTab == 0 ? widget.model.vision : widget.model.mission;
    return Container(
      width: double.infinity, height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _kSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(_ab(s.description, widget.isAr),
                style: StyleText.fontSize13Weight400.copyWith(
                    fontSize: 13,
                    height: 1.75,
                    color: const Color(0xFF444444))),
          ),
          if (s.svgUrl.isNotEmpty) ...[
            const SizedBox(width: 16),
            _netImg(url: s.svgUrl, width: 180, height: 180,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(10)),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABOUT US — TABLET (row of 3 tabs + content below)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabletAboutUs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
              child: _TabletSubTab(
                label: _subTabLabel(i), iconUrl: _subTabIconUrl(i),
                isSelected: _subTab == i,
                primary: _primary, secondary: _secondary,
                onTap: () => setState(() => _subTab = i),
              ),
            ),
          )),
        ),
        const SizedBox(height: 14),
        _buildTabletPanel(),
      ],
    );
  }

  Widget _buildTabletPanel() {
    if (_subTab == 2) {
      final others = widget.model.values.length > 1
          ? widget.model.values.sublist(1) : <AboutValueItem>[];
      return _ValuesGrid(
          values: others, isRtl: widget.isAr,
          primary: _primary, secondary: _secondary, compact: true);
    }
    final s = _subTab == 0 ? widget.model.vision : widget.model.mission;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s.svgUrl.isNotEmpty) ...[
          Center(child: _netImg(url: s.svgUrl, width: 160, height: 160,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),
        ],
        Text(_ab(s.description, widget.isAr),
            style: StyleText.fontSize11Weight400
                .copyWith(fontSize: 11, height: 1.75)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABOUT US — MOBILE (accordion)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileAboutUs() {
    return Column(
      children: List.generate(3, (i) {
        final bool open = _mobileExpanded == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MobileAccordion(
            label: _subTabLabel(i), iconUrl: _subTabIconUrl(i),
            isExpanded: open, primary: _primary, secondary: _secondary,
            onTap: () =>
                setState(() => _mobileExpanded = open ? -1 : i),
            child: _buildMobilePanel(i),
          ),
        );
      }),
    );
  }

  Widget _buildMobilePanel(int i) {
    if (i == 2) {
      final others = widget.model.values.length > 1
          ? widget.model.values.sublist(1) : <AboutValueItem>[];
      return _ValuesGrid(
          values: others, isRtl: widget.isAr,
          primary: _primary, secondary: _secondary, compact: true);
    }
    final s = i == 0 ? widget.model.vision : widget.model.mission;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (s.svgUrl.isNotEmpty) ...[
        Center(
          child: _netImg(
            url: s.svgUrl,
            width: 280,   // ✅ fixed mobile content width — no more Infinity
            height: 150,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
      ],
      Text(_ab(s.description, widget.isAr),
          style: StyleText.fontSize10Weight400
              .copyWith(fontSize: 10, height: 1.7)),
    ]);
  }

  // ── Sub-tab helpers ────────────────────────────────────────────────────────
  String _subTabLabel(int i) => switch (i) {
    0 => widget.isAr ? 'الرؤية'  : 'Vision',
    1 => widget.isAr ? 'الرسالة' : 'Mission',
    _ => widget.isAr ? 'القيم'   : 'Values',
  };
  String _subTabIconUrl(int i) => switch (i) {
    0 => widget.model.vision.iconUrl,
    1 => widget.model.mission.iconUrl,
    _ => widget.model.values.isNotEmpty
        ? widget.model.values.first.iconUrl : '',
  };
  String _subTabDesc(int i) {
    final raw = switch (i) {
      0 => _ab(widget.model.vision.subDescription, widget.isAr),
      1 => _ab(widget.model.mission.subDescription, widget.isAr),
      _ => widget.model.values.isNotEmpty
          ? _ab(widget.model.values.first.shortDescription, widget.isAr) : '',
    };
    return raw.length > 160 ? '${raw.substring(0, 157)}…' : raw;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP SUB-TAB ITEM  (mirrors _DesktopTabItem in about_page.dart)
// ═══════════════════════════════════════════════════════════════════════════════
