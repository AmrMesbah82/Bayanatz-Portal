part of '../../pages/our_teams_preview.dart';

class _PreviewContent extends StatefulWidget {
  final double fakeWidth, fakeHeight;
  final OurTeamsModel? data;
  final bool isAr, isMobile;

  const _PreviewContent({
    required this.fakeWidth,
    required this.fakeHeight,
    required this.data,
    required this.isAr,
    this.isMobile = false,
  });

  @override
  State<_PreviewContent> createState() => _PreviewContentState();
}

class _PreviewContentState extends State<_PreviewContent> {
  bool _accordionOpen = true;

  bool get _isDesktop => widget.fakeWidth >= _kDesktopW;
  bool get _isMob     => widget.isMobile || widget.fakeWidth < 600;

  static const Color _primary   = Color(0xFF008037);
  static const Color _sectionBg = Color(0xFFF1F2ED);
  static const Color _hintText  = Color(0xFFAAAAAA);
  static const Color _labelText = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final items = widget.data?.items ?? [];
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size:       Size(widget.fakeWidth, widget.fakeHeight),
        padding:    EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      child: Directionality(
        textDirection:
        widget.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          color: _sectionBg,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Green accordion header ──────────────────────────────
                GestureDetector(
                  onTap: () =>
                      setState(() => _accordionOpen = !_accordionOpen),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    color: _primary,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'View',
                            style: StyleText.fontSize14Weight600.copyWith(
                              fontSize: 14,
                              color:    Colors.white,
                            ),
                          ),
                        ),
                        Icon(
                          _accordionOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size:  20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_accordionOpen) ...[
                  const SizedBox(height: 20),

                  // ── "Meet Our Teams" heading ───────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: widget.isAr ? 'تعرف على ' : 'Meet ',
                            style: StyleText.fontSize28Weight600.copyWith(
                              fontSize: _isDesktop ? 28 : (_isMob ? 18 : 22),
                              color:    Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: widget.isAr ? 'فريقنا' : 'Our Team',
                            style: StyleText.fontSize28Weight600.copyWith(
                              fontSize:  _isDesktop ? 28 : (_isMob ? 18 : 22),
                              color:     _primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Team rows ──────────────────────────────────────────
                  if (items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          widget.isAr
                              ? 'لا توجد فرق بعد.'
                              : 'No teams added yet.',
                          style: StyleText.fontSize14Weight400.copyWith(
                              fontSize: 14, color: _hintText),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: _isDesktop ? 20 : (_isMob ? 12 : 16)),
                      child: Column(
                        children: _buildRows(items),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Chunk items into rows of 3 ──────────────────────────────────────────────
  List<Widget> _buildRows(List<OurTeamItem> items) {
    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i += _kPerRow) {
      final rowIndex = i ~/ _kPerRow;
      final chunk =
      items.sublist(i, (i + _kPerRow).clamp(0, items.length));

      widgets.add(_RowSection(
        rowIndex:   rowIndex,
        items:      chunk,
        totalPerRow: _kPerRow,
        isAr:       widget.isAr,
        isMobile:   _isMob,
      ));
      if (i + _kPerRow < items.length)
        widgets.add(const SizedBox(height: 14));
    }
    return widgets;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROW SECTION  — labeled row with cards
// ═══════════════════════════════════════════════════════════════════════════════
