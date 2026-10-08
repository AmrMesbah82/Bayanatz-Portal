part of '../../pages/job_listing_detail.dart';

class _SectionCard extends StatefulWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _open = true;
  @override
  Widget build(BuildContext context) {
    // BUG-154: these bars were 54 px tall (own padding/title/icon) while every
    // other page uses the shared 44 px CustomAccordion — same widget now.
    return CustomAccordion(
      title: widget.title,
      isOpen: _open,
      onToggle: () => setState(() => _open = !_open),
      child: SizedBox(width: double.infinity, child: widget.child),
    );
  }
}
