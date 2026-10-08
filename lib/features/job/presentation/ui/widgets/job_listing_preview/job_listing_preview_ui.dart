part of '../../pages/job_listing_preview.dart';

extension _JobListingPreviewUi on _JobListingPreviewPageState {
  Widget _viewModeTab(String mode) {
    final isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Padding(
        padding: EdgeInsets.only(right: 28.w),
        child: Text(mode,
          style: isActive
              ? StyleText.fontSize16Weight600.copyWith(color: ColorPick.primary,
                  decoration: TextDecoration.underline, decorationColor: ColorPick.primary)
              : StyleText.fontSize16Weight400.copyWith(color: AppColors.secondaryText),
        ),
      ),
    );
  }

  Widget _langToggle(String lang) {
    final isActive = _lang == lang;
    return GestureDetector(
      onTap: () => setState(() => _lang = lang),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? ColorPick.primary : ColorPick.white,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: isActive ? ColorPick.primary : AppColors.secondaryText),
        ),
        child: Text(lang, style: StyleText.fontSize12Weight600.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.secondaryText)),
      ),
    );
  }

  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        if (label1.isNotEmpty)
          Expanded(child: RichText(text: TextSpan(children: [
            TextSpan(text: '$label1 ', style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.secondaryText, height: 1.6)),
            TextSpan(text: value1, style: StyleText.fontSize13Weight600.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: ColorPick.primary, height: 1.6)),
          ]))),
        if (label2.isNotEmpty)
          Expanded(child: RichText(text: TextSpan(children: [
            TextSpan(text: '$label2 ', style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.secondaryText, height: 1.6)),
            TextSpan(text: value2, style: StyleText.fontSize13Weight600.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: ColorPick.primary, height: 1.6)),
          ]))),
      ],
    );
  }

  Widget _singleInfo(String label, String value) {
    return RichText(text: TextSpan(children: [
      TextSpan(text: '$label ', style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.secondaryText, height: 1.6)),
      TextSpan(text: value, style: StyleText.fontSize13Weight600.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: ColorPick.primary, decorationColor: ColorPick.primary, height: 1.6)),
    ]));
  }

  Widget _sectionCard({required String title, required String text}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(10.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: StyleText.fontSize16Weight700.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700, color: ColorPick.primary)),
        SizedBox(height: 14.h),
        _bulletList(text),
      ]),
    );
  }

  Widget _benefitsCard(JobPostModel job, bool isAr) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(10.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Benefits', style: StyleText.fontSize16Weight700.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700, color: ColorPick.primary)),
        SizedBox(height: 16.h),
        ...job.benefits.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          final title = isAr ? b.title.ar : b.title.en;
          final desc = isAr ? b.shortDescription.ar : b.shortDescription.en;
          return Column(children: [
            if (i > 0) SizedBox(height: 20.h),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 350.w, child: Text(title.isEmpty ? 'Benefit' : title,
                  style: StyleText.fontSize14Weight600.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.text))),
              SizedBox(width: 20.w),
              Expanded(child: desc.isNotEmpty ? _richBulletList(desc)
                  : Text('-', style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.secondaryText))),
            ]),
          ]);
        }).toList(),
      ]),
    );
  }

  Widget _bulletList(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines.map((line) {
      return Padding(padding: EdgeInsets.only(bottom: 6.h), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(top: 10.h), child: Container(
          width: 5.sp, height: 5.sp,
          decoration: BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
        )),
        SizedBox(width: 10.w),
        Expanded(child: Text(line.trim(), style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.text, height: 1.6))),
      ]));
    }).toList());
  }

  Widget _richBulletList(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines.map((line) {
      final trimmed = line.trim();
      final colonIndex = trimmed.indexOf(':');
      Widget textWidget;
      if (colonIndex > 0 && colonIndex < trimmed.length - 1) {
        final key = trimmed.substring(0, colonIndex + 1);
        final value = trimmed.substring(colonIndex + 1).trim();
        textWidget = RichText(text: TextSpan(children: [
          TextSpan(text: '$key ', style: StyleText.fontSize13Weight600.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.text, height: 1.6)),
          TextSpan(text: value, style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.text, height: 1.6)),
        ]));
      } else {
        textWidget = Text(trimmed, style: StyleText.fontSize13Weight400.copyWith(fontSize: 13.sp, color: AppColors.text, height: 1.6));
      }
      return Padding(padding: EdgeInsets.only(bottom: 6.h), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(top: 6.h), child: Container(
          width: 5.sp, height: 5.sp,
          decoration: BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
        )),
        SizedBox(width: 10.w),
        Expanded(child: textWidget),
      ]));
    }).toList());
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
