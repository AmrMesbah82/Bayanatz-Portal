part of '../../pages/main_preview.dart';

class _MobilePhoneShell extends StatelessWidget {
  final double containerWidth;
  final bool   isRtl;

  const _MobilePhoneShell({
    required this.containerWidth,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final double scale  = _safeScale(_kPhoneShellW / _kFakeMobileW);
    final double shellH = _kFakeMobileH * scale;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:        ColorPick.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: SizedBox(
          width:  _kPhoneShellW,
          height: shellH,
          child: Container(
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ColorPick.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth:  _kFakeMobileW,
              maxHeight: _kFakeMobileH,
              child: Transform.scale(
                scale:     scale,
                alignment: Alignment.topLeft,
                child: SiteShellPreview(
                  fakeWidth:  _kFakeMobileW,
                  fakeHeight: _kFakeMobileH,
                  isRtl:      isRtl,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
