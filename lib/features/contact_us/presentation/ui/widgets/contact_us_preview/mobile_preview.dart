part of '../../pages/contact_us_preview.dart';

class _MobilePreview extends StatelessWidget {
  final ContactUsCmsModel data;

  const _MobilePreview({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            'Contact Us', // BUG-107: same heading as the live page
            style: StyleText.fontSize45Weight600.copyWith(
              fontSize: 34,
              color: ColorPick.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          _MobileInfoCard(data: data),
          const SizedBox(height: 20),

          _FormPlaceholder(isMobile: true),
          const SizedBox(height: 32),

          Text(
            'Office Locations',
            style: StyleText.fontSize22Weight700.copyWith(color: ColorPick.primary),
          ),
          const SizedBox(height: 16),

          ...data.officeLocations.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OfficeCardMobile(location: o),
          )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Info Card (Desktop) ──────────────────────────────────────────────────────
