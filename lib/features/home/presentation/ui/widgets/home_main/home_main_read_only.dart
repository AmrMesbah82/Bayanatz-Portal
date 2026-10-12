part of '../../pages/home_main.dart';

extension _HomeMainReadOnly on _HomeMainPageMasterState {
  Widget _headingsReadOnly(HomePageModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _readField('Title', data.title.en.isNotEmpty ? data.title.en : 'Text Here')),
          SizedBox(width: 16.w),
          Expanded(child: _readFieldRtl('العنوان', data.title.ar)),
        ]),
        SizedBox(height: 16.h),
        _readField('Short Description',
            data.shortDescription.en.isNotEmpty ? data.shortDescription.en : 'Text Here',
            height: 80),
        SizedBox(height: 16.h),
        _readFieldRtl('وصف مختصر', data.shortDescription.ar, height: 80),

      ],
    );
  }

  Widget _navButtonsReadOnly(HomePageModel data) {
    if (data.navButtons.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(child: Text('No navigation buttons configured',
            style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(data.navButtons.length, (i) {
          final btn = data.navButtons[i];
          final routeLabel = _kRouteLabelMap[btn.route] ?? btn.route;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${_ordinal(i + 1)} Button',
                    style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
              ]),
              SizedBox(height: 8.h),
              Row(children: [
                Expanded(child: _readField('Button Name', btn.name.en.isNotEmpty ? btn.name.en : 'Text Here')),
                SizedBox(width: 16.w),
                Expanded(child: _readFieldRtl('عنوان الزر', btn.name.ar)),
              ]),
              SizedBox(height: 10.h),
              Row(children: [
                Expanded(child: _readField('Navigate To', routeLabel.isNotEmpty ? routeLabel : 'Not set')),
                SizedBox(width: 16.w),
                const Expanded(child: SizedBox()),
              ]),
              if (i < data.navButtons.length - 1) ...[
                SizedBox(height: 14.h),
                Divider(color: ColorPick.white, thickness: 1),
                SizedBox(height: 10.h),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _sectionView(HomePageModel data, int index) {
    final sec = index < data.sections.length ? data.sections[index] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Image', style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
            SizedBox(height: 6.h),
            _imgCircle(sec?.imageUrl ?? ''),
          ]),
          SizedBox(width: 24.w),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Icon', style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
            SizedBox(height: 6.h),
            _imgCircle(sec?.iconUrl ?? '', isAdd: true),
          ]),
          const Spacer(),
          if (sec != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(height: 6.h),
              // Visibility shown as an on/off switch, matching main_main.dart.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Visibility ',
                      style: StyleText.fontSize14Weight500
                          .copyWith(color: AppColors.text)),
                  Container(
                    width: 32.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: sec.visibility
                          ? ColorPick.primary
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Align(
                      alignment: sec.visibility
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 14.w,
                        height: 14.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
        ]),
        SizedBox(height: 14.h),
        _readField('Description', sec?.description.en ?? 'Text Here', height: 80),
        SizedBox(height: 10.h),
        _readFieldRtl('الوصف', sec?.description.ar ?? '', height: 80),
      ],
    );
  }

  Widget _imgCircle(String url, {bool isAdd = false}) {
    return NetworkImageView.circle(url: url, diameter: 60.w);
  }

  Widget _accordion({required String key, required String title, required List<Widget> children}) {
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

  Widget _readField(String label, String value, {double height = 36}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
      SizedBox(height: 4.h),
      Container(
        width: double.infinity, height: height.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
        alignment: height > 36 ? Alignment.topLeft : Alignment.centerLeft,
        child: Text(value,
            style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
            maxLines: height > 36 ? 4 : 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );

  Widget _readFieldRtl(String label, String value, {double height = 36}) => Directionality(
    textDirection: ui.TextDirection.rtl,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity, height: height.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
          alignment: height > 36 ? Alignment.topRight : Alignment.centerRight,
          child: Text(value.isEmpty ? 'أكتب هنا' : value,
              style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
              textDirection: ui.TextDirection.rtl,
              maxLines: height > 36 ? 4 : 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );

  String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}
