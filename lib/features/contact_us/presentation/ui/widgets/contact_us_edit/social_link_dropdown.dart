part of '../../pages/contact_us_edit.dart';

class _SocialLinkDropdown extends StatelessWidget {
  final List<SocialLinkModel> footerLinks;
  /// The currently selected index into [footerLinks], or null if nothing chosen.
  final int?                  selectedIndex;
  final ValueChanged<int?>    onChanged;
  final bool                  submitted;

  const _SocialLinkDropdown({
    required this.footerLinks,
    required this.selectedIndex,
    required this.onChanged,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasError =
        submitted && (selectedIndex == null);

    // ── Loading state ──────────────────────────────────────────────────────
    if (footerLinks.isEmpty) {
      return Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color:        const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14.w, height: 14.w,
              child: const CircleProgress(),
            ),
            SizedBox(width: 10.w),
            Text(
              'Loading footer social links...',
              style: StyleText.fontSize12Weight400.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // ── Build items — VALUE IS ALWAYS THE INDEX (unique by definition) ──────
    final items = footerLinks.asMap().entries.map((entry) {
      final index  = entry.key;
      final link   = entry.value;
      final hasUrl = link.url.isNotEmpty;

      return DropdownItem<int>(
        value:   index,        // ← always unique
        enabled: hasUrl,       // disabled when no URL
        label: hasUrl
            ? _truncateUrl(link.url)
            : 'Social ${index + 1} — no URL set',
        leading: Container(
          width:  36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: hasUrl
                ? const Color(0xFFE8F5EE)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Center(
            child: link.iconUrl.isNotEmpty
                ? NetworkImageView(
                    url: link.iconUrl,
                    width: 20.w, height: 20.w, fit: BoxFit.contain,
                  )
                : Icon(
                    Icons.link, size: 16.sp,
                    color: hasUrl ? ColorPick.primary : Colors.grey.shade400,
                  ),
          ),
        ),
        // "No URL" badge for disabled items
        trailing: !hasUrl
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color:        Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'No URL',
                  style: StyleText.fontSize10Weight400.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              )
            : null,
      );
    }).toList();

    return CustomDropdown<int>(
      value: selectedIndex,
      items: items,
      hint: 'Select a social link from footer',
      hintStyle: StyleText.fontSize12Weight400.copyWith(
        color: Colors.grey.shade400,
      ),
      prefixIcon: selectedIndex == null
          ? Icon(Icons.link, size: 16.sp, color: Colors.grey.shade400)
          : null,
      valueStyle: StyleText.fontSize12Weight400.copyWith(
        color: Colors.black87,
      ),
      itemStyle: StyleText.fontSize12Weight400,
      fillColor: Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      itemHeight: 48.h,
      triggerPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      suffixIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20.sp, color: Colors.grey.shade600,
      ),
      errorText: hasError ? 'Please select a social link' : null,
      errorStyle: StyleText.fontSize11Weight400.copyWith(
        color: ColorPick.red,
      ),
      onChanged: (idx) {
        // Extra guard: don't allow selecting a link with no URL
        if (footerLinks[idx].url.isEmpty) return;
        onChanged(idx);
      },
    );
  }

  String _truncateUrl(String url) {
    final clean = url
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('www.', '');
    return clean.length > 38 ? '${clean.substring(0, 38)}…' : clean;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════════
