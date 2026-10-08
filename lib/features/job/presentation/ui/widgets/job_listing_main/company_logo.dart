part of '../../pages/job_listing_main.dart';

class _CompanyLogo extends StatelessWidget {
  final String logoUrl;
  const _CompanyLogo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final double sz = 36.sp; // readable size (was 30)
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: logoUrl.isNotEmpty
            ? NetworkImageView(
          url: logoUrl,
          width: sz,
          height: sz,
          fit: BoxFit.scaleDown,
          placeholder: _fallbackIcon(sz),
        )
            : _fallbackIcon(sz),
      ),
    );
  }

  // No department image → the admin header logo.
  Widget _fallbackIcon(double sz) {
    return Image.asset(
      'assets/images/login/logo.png',
      width: sz,
      height: sz,
      fit: BoxFit.contain,
    );
  }
}
