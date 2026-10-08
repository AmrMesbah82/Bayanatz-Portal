part of '../../pages/contact_us_preview.dart';

class _FormPlaceholder extends StatelessWidget {
  final bool isMobile;

  const _FormPlaceholder({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final double pad = isMobile ? 20 : 25.r;
    final double rad = isMobile ? 14 : 15.r;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rad),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BUG-107: same form as the live /contact page (it showed Full
          // Name / Email / Phone / Subject / Message only).
          Text(
            'Get in Touch',
            style: StyleText.fontSize22Weight700.copyWith(
              fontSize: isMobile ? 18 : 16.sp,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 12.h),

          Text('This is a preview. Form inputs are not functional.',
              style: StyleText.fontSize13Weight400.copyWith(color: Colors.black54)),
          SizedBox(height: isMobile ? 12.0 : 12.h),

          _label('Preferred Language *'),
          const SizedBox(height: 6),
          Row(children: [
            _radio('Arabic', false),
            const SizedBox(width: 16),
            _radio('English', true),
            const SizedBox(width: 16),
            _radio('Other', false),
          ]),
          const SizedBox(height: 10),
          _pair(_placeholderField('First Name *'), _placeholderField('Last Name *')),
          _pair(_placeholderField('Email *'), _phoneField()),
          _pair(_placeholderField('Location *', dropdown: true),
              _placeholderField("Entity's Name (Optional)")),
          _pair(_placeholderField("Entity's Type *", dropdown: true),
              _placeholderField("Entity's Size *", dropdown: true)),
          _placeholderField('Subject *'),
          _placeholderFieldLarge('Message *'),

          SizedBox(height: 8.h),

          SizedBox(
            width: double.infinity,
            height: isMobile ? 52.0 : 48.h,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPick.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 8.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Send',
                style: StyleText.fontSize16Weight600.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text));

  Widget _radio(String label, bool selected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16, color: selected ? ColorPick.primary : Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: StyleText.fontSize13Weight400.copyWith(color: Colors.black87)),
        ],
      );

  /// Two fields side by side (stacked on a phone), like the live form.
  Widget _pair(Widget a, Widget b) => isMobile
      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [a, b])
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
        );

  Widget _box({bool dropdown = false, String? text}) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2ED),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          if (text != null)
            Text(text, style: StyleText.fontSize12Weight400.copyWith(color: AppColors.text)),
          const Spacer(),
          if (dropdown) const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ]),
      );

  Widget _phoneField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Phone Number *'),
          const SizedBox(height: 6),
          Row(children: [
            SizedBox(width: 90, child: _box(dropdown: true, text: '🇪🇬 +20')),
            const SizedBox(width: 6),
            Expanded(child: _box()),
          ]),
          const SizedBox(height: 8),
        ],
      );

  Widget _placeholderField(String label, {bool dropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        _box(dropdown: dropdown),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _placeholderFieldLarge(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text)),
        const SizedBox(height: 6),
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2ED),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Office Card (Desktop) ────────────────────────────────────────────────────
