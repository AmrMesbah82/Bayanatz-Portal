part of '../../pages/terms_page/terms_preview.dart';

class _TermsPreviewContent extends StatefulWidget {
  final double fakeWidth, fakeHeight;
  final TermsOfServiceModel    model;
  final Map<String, Uint8List> imageUploads;
  final bool isAr, isMobile;

  const _TermsPreviewContent({
    required this.fakeWidth,
    required this.fakeHeight,
    required this.model,
    required this.imageUploads,
    required this.isAr,
    this.isMobile = false,
  });

  @override
  State<_TermsPreviewContent> createState() => _TermsPreviewContentState();
}

class _TermsPreviewContentState extends State<_TermsPreviewContent> {
  bool _termsOpen   = true;
  bool _privacyOpen = true;

  bool get _isDesktop => widget.fakeWidth >= _kDesktopW;
  bool get _isMobView => widget.isMobile || widget.fakeWidth < 600;

  double get _hPad => _isDesktop ? 0 : (_isMobView ? 16 : 24);

  static const Color _primary = Color(0xFF2D8C4E);

  // ── SVG resolver — bytes win over URL ─────────────────────────────────────
  Uint8List? _bytes(String key) => widget.imageUploads[key];

  Widget _svgWidget({
    required String     storageKey,
    required String     fallbackUrl,
    required double     width,
    required double     height,
  }) {
    final bytes = _bytes(storageKey);
    if (bytes != null && bytes.isNotEmpty) {
      return SvgPicture.memory(bytes,
          width: width, height: height, fit: BoxFit.contain);
    }
    if (fallbackUrl.isNotEmpty) {
      return NetworkImageView(
        url: fallbackUrl,
        width: width, height: height, fit: BoxFit.contain,
      );
    }
    return SizedBox(
      width: width, height: height,
      child: Icon(Icons.image_outlined,
          color: Colors.grey[400], size: width * 0.4),
    );
  }

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
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: _hPad, vertical: _isDesktop ? 36 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page title ───────────────────────────────────────
                  Text(
                    widget.isAr ? 'الشروط والسياسات' : 'Terms & Policies',
                    style: StyleText.fontSize45Weight600.copyWith(
                      fontSize: _isDesktop ? 38 : (_isMobView ? 22 : 28),
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  SizedBox(height: _isDesktop ? 32 : 20),

                  // ── Terms and Conditions accordion ───────────────────
                  _accordion(
                    title: widget.isAr
                        ? 'الشروط والأحكام'
                        : 'Terms and Conditions',
                    isOpen: _termsOpen,
                    onToggle: () =>
                        setState(() => _termsOpen = !_termsOpen),
                    child: _sectionContent(
                      section: widget.model.termsAndConditions,
                      svgKey: 'terms_cms/terms/svg',
                    ),
                  ),
                  SizedBox(height: _isDesktop ? 16 : 12),

                  // ── Privacy Policy accordion ─────────────────────────
                  _accordion(
                    title: widget.isAr
                        ? 'سياسة الخصوصية'
                        : 'Privacy Policy',
                    isOpen: _privacyOpen,
                    onToggle: () =>
                        setState(() => _privacyOpen = !_privacyOpen),
                    child: _sectionContent(
                      section: widget.model.privacyPolicy,
                      svgKey: 'terms_cms/privacy/svg',
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Accordion ──────────────────────────────────────────────────────────────
  Widget _accordion({
    required String       title,
    required bool         isOpen,
    required VoidCallback onToggle,
    required Widget       child,
  }) {
    // This renders a PREVIEW of the public site, so it keeps the site's green
    // branding and its own responsive header sizing rather than the admin style.
    return CustomAccordion(
      title:       title,
      isOpen:      isOpen,
      onToggle:    onToggle,
      headerColor: _primary,
      headerRadius: 8,
      headerPadding: EdgeInsets.symmetric(
          horizontal: _isDesktop ? 24 : 16,
          vertical: _isDesktop ? 18 : 14),
      titleStyle: StyleText.fontSize16Weight600.copyWith(
        fontSize: _isDesktop ? 16 : (_isMobView ? 13 : 14),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: _isDesktop ? 0 : 16, vertical: 16.h),
        child: child,
      ),
    );
  }

  // ── Section content — Desktop: row, Tablet/Mobile: column ─────────────────
  Widget _sectionContent({
    required TermsSection section,
    required String       svgKey,
  }) {
    final desc    = widget.isAr
        ? section.description.ar
        : section.description.en;
    final svgUrl  = section.svgUrl;
    final hasSvg  = _bytes(svgKey) != null || svgUrl.isNotEmpty;

    final double svgSize = _isDesktop ? 180 : (_isMobView ? 100 : 130);
    final double fontSize = _isDesktop ? 14 : (_isMobView ? 11 : 12);

    final Widget svgW = hasSvg
        ? _svgWidget(
      storageKey:  svgKey,
      fallbackUrl: svgUrl,
      width:       svgSize,
      height:      svgSize,
    )
        : const SizedBox.shrink();

    final Widget textW = Text(
      desc.isEmpty
          ? (widget.isAr ? 'وصف القسم…' : 'Section description…')
          : desc,
      style: StyleText.fontSize13Weight400.copyWith(
        fontSize: fontSize,
        height: 1.75,
        color: const Color(0xFF444444),
      ),
    );

    if (_isDesktop) {
      // Desktop: text left, SVG right (or reversed for RTL)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: textW),
          if (hasSvg) ...[
            const SizedBox(width: 32),
            svgW,
          ],
        ],
      );
    } else {
      // Tablet / Mobile: SVG top, text below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSvg) ...[
            Center(child: svgW),
            SizedBox(height: _isMobView ? 12 : 16),
          ],
          textW,
        ],
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BROWSER CHROME BAR
// ═══════════════════════════════════════════════════════════════════════════════
