part of '../../pages/about_us_main.dart';

// ── Date formatter ─────────────────────────────────────────────────────────
String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month]} ${d.year}';
}

// ── Read-only LTR field ────────────────────────────────────────────────────
Widget _readField(String label, String value, {double height = 36}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          height: height.h,
          padding: EdgeInsets.symmetric(
              horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4.r)),
          alignment: height > 36 ? Alignment.topLeft : Alignment.centerLeft,
          child: Text(value,
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
              maxLines: height > 36 ? 5 : 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );

// ── Read-only RTL field ────────────────────────────────────────────────────
Widget _readFieldRtl(String label, String value, {double height = 36}) =>
    Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: StyleText.fontSize12Weight500
                  .copyWith(color: AppColors.text)),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            height: height.h,
            padding: EdgeInsets.symmetric(
                horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4.r)),
            alignment:
            height > 36 ? Alignment.topRight : Alignment.centerRight,
            child: Text(
                value.isEmpty ? 'أكتب هنا' : value,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
                textDirection: TextDirection.rtl,
                maxLines: height > 36 ? 5 : 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

// ── Helpers extension on state ─────────────────────────────────────────────
extension _AboutMainHelpers on _AboutMainPageMasterDashboardState {

  // ── Tab bar ────────────────────────────────────────────────────────────
  // BUG-155: shared sub-tab row (same look on every CMS tab).
  Widget _buildTabBar() {
    return CmsSubTabs(
      labels: _tabLabels,
      activeIndex: _tabIndex,
      onTap: (i) => setState(() => _tabIndex = i),
    );
  }

  // ── Last Updated row ───────────────────────────────────────────────────
  Widget _lastUpdatedRow({
    required VoidCallback onEdit,
    DateTime? lastUpdated,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
              color: ColorPick.white,
              borderRadius: BorderRadius.circular(4.r)),
          child: Text(
            'Last Updated On ${_fmtDate(lastUpdated)}',
            style: StyleText.fontSize13Weight500
                .copyWith(color: ColorPick.primary),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            width: 130.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Edit Details',
                    style: StyleText.fontSize14Weight500
                        .copyWith(color: Colors.black)),
                SizedBox(width: 6.w),
                CustomSvg(
                    assetPath: "assets/control/edit_icon_pick.svg",
                    width: 20.w,
                    height: 20.h,
                    fit: BoxFit.scaleDown,
                    color: ColorPick.primary),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Accordion ──────────────────────────────────────────────────────────
  Widget _accordion({
    required String key,
    required String title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
