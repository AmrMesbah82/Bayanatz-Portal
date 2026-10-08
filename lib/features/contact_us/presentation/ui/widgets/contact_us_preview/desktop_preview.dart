part of '../../pages/contact_us_preview.dart';

class _DesktopPreview extends StatelessWidget {
  final ContactUsCmsModel data;

  const _DesktopPreview({required this.data});

  @override
  Widget build(BuildContext context) {
    final double contentW = (339.w * 4) + (12.w * 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40.h),

        // Title
        Center(
          child: SizedBox(
            width: contentW,
            child: Text(
              'Contact Us', // BUG-107: same heading as the live page
              style: StyleText.fontSize45Weight600.copyWith(
                fontSize: 48.sp,
                color: ColorPick.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        SizedBox(height: 32.h),

        // Info Card + Form Placeholder
        Center(
          child: SizedBox(
            width: contentW,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _InfoCard(data: data),
                  ),
                  SizedBox(width: 28.w),
                  Expanded(
                    flex: 3,
                    child: _FormPlaceholder(),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Office Locations
        Center(
          child: SizedBox(
            width: contentW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Office Locations',
                  style: StyleText.fontSize45Weight600.copyWith(
                    fontSize: 32.sp,
                    color: ColorPick.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: data.officeLocations.asMap().entries.map((e) {
                    final bool isLast = e.key == data.officeLocations.length - 1;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 16.w),
                        child: _OfficeCard(location: e.value),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 64.h),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE PREVIEW
// ═══════════════════════════════════════════════════════════════════════════════
