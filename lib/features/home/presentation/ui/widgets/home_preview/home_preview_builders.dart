part of '../../pages/home_preview.dart';

extension _HomePreviewBuilders on _HomePreviewPageMasterState {
  Widget _buildDeviceTabBar() {
    final tabs = [_Device.desktop, _Device.tablet, _Device.mobile];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tabs.length, (i) {
        final d = tabs[i];
        final isActive = _device == d;
        final label = d.name[0].toUpperCase() + d.name.substring(1);
        return Padding(
          padding: EdgeInsets.only(right: 24.w),
          child: GestureDetector(
            onTap: () => setState(() => _device = d),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Text(label, style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? ColorPick.primary : AppColors.secondaryText,
                    )),
                  ),
                  Container(height: 2, color: isActive ? ColorPick.primary : Colors.transparent),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _langChip(String label, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? ColorPick.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(label,
          style: StyleText.fontSize12Weight500.copyWith(
            color: active ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _homeViewAccordion(HomePageModel? data, bool isAr) {
    return Container(
      decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(6.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _homeViewOpen = !_homeViewOpen),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
              child: Row(children: [
                Expanded(child: Text('Home View',
                    style: StyleText.fontSize14Weight600.copyWith(color: Colors.white))),
                Icon(
                  _homeViewOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 20.sp,
                ),
              ]),
            ),
          ),
          if (_homeViewOpen) _previewFrame(data, isAr),
        ],
      ),
    );
  }

  Widget _previewFrame(HomePageModel? data, bool isAr) {
    final double fakeW = switch (_device) {
      _Device.desktop => 1366,
      _Device.tablet  => 1024,
      _Device.mobile  => 375,
    };
    final double fakeH = switch (_device) {
      _Device.desktop => 768,
      _Device.tablet  => 768,
      _Device.mobile  => 812,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availW = constraints.maxWidth;
        final double scale = availW / fakeW;
        final double scaledH = fakeH * scale;

        return ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.r)),
            child: SizedBox(
              width: availW,
              height: scaledH,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: fakeW, maxWidth: fakeW,
                minHeight: fakeH, maxHeight: fakeH,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  // BUG-15: was a nested ScreenUtilInit that re-scaled the
                  // whole admin app; PreviewViewport leaves ScreenUtil alone.
                  child: _PreviewViewport(
                    width: fakeW,
                    height: fakeH,
                    child: Directionality(
                        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                        child: SizedBox.expand(
                          child: Container(
                            color: AppColors.background,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildActualHomeContent(data ?? _emptyHomePageModel(), isAr),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  HomePageModel _emptyHomePageModel() {
    return HomePageModel(
      title: BiText(en: '', ar: ''),
      shortDescription: BiText(en: '', ar: ''),
      sections: [],
      navButtons: [],
    );
  }

  Widget _buildActualHomeContent(HomePageModel data, bool isAr) {
    return Builder(
      builder: (context) {
        final double w = MediaQuery.of(context).size.width;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(data, w, isAr),
            _buildHeroCardsSection(data, w, isAr),
            SizedBox(height: 32.h),
          ],
        );
      },
    );
  }

  Widget _buildHeroSection(HomePageModel data, double w, bool isAr) {
    final Color primary = context.primaryBrandColor;
    final bool isMobile = w < 600.w;
    final String titleText = isAr
        ? (data.title.ar.isNotEmpty ? data.title.ar : data.title.en)
        : data.title.en;
    final String descText = isAr
        ? (data.shortDescription.ar.isNotEmpty ? data.shortDescription.ar : data.shortDescription.en)
        : data.shortDescription.en;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20.w : 36.w, vertical: isMobile ? 20.h : 44.h),
      child: Column(
        children: [
          Text(titleText, style: TextStyle(
            fontSize: isMobile ? 28.sp : 48.sp,
            fontWeight: FontWeight.bold, color: primary, height: 1.1,
          )),
          SizedBox(height: 8.h),
          Text(descText, textAlign: TextAlign.center, style: TextStyle(
            fontSize: isMobile ? 12.sp : 20.sp,
            fontWeight: FontWeight.w400, color: primary,
          )),
        ],
      ),
    );
  }

  Widget _buildHeroCardsSection(HomePageModel data, double w, bool isAr) {
    if (w >= 1024.w) return _buildDesktopCards(data, isAr);
    if (w >= 600.w) return _buildTabletCards(data, isAr);
    return _buildMobileCards(data, isAr);
  }

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return const Color(0xFF2D8C4E);
  }

  Widget _buildDesktopCards(HomePageModel data, bool isAr) {
    const Color sectionBg = Color(0xFFF2F6EF);
    final Color primary = context.primaryBrandColor;
    final double innerOffset = 36.h + 10.h + 90.h;
    final double btnOffset = innerOffset + 36.h + 10.h;
    final sec = data.sections;

    String secDesc(int i) => i < sec.length
        ? (isAr ? (sec[i].description.ar.isNotEmpty ? sec[i].description.ar : sec[i].description.en) : sec[i].description.en)
        : '';

    return Container(
      color: sectionBg,
      padding: EdgeInsets.symmetric(horizontal: 36.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOuterCard(iconUrl: sec.isNotEmpty ? sec[0].iconUrl : '', imageUrl: sec.isNotEmpty ? sec[0].imageUrl : '',
              text: secDesc(0), cardColor: primary, iconOnRight: !isAr),
          SizedBox(width: 10.w),
          SizedBox(width: 160.w, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: innerOffset),
            _buildCircleIcon(sec.length > 1 ? sec[1].iconUrl : ''),
            SizedBox(height: 10.h),
            _buildSectionImage(sec.length > 1 ? sec[1].imageUrl : '', 160.w, 180.h),
            SizedBox(height: 10.h),
            _buildGreenCard(width: 160.w, height: 120.h, text: secDesc(1), color: primary, isRtl: isAr),
          ])),
          SizedBox(width: 10.w),
          SizedBox(width: 240.w, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(height: btnOffset),
            ...data.navButtons.asMap().entries.map((entry) {
              final index = entry.key;
              final btn = entry.value;
              final label = isAr ? (btn.name.ar.isNotEmpty ? btn.name.ar : btn.name.en) : btn.name.en;
              final double btnWidth = index == 0 ? 240.w : index == 1 ? 196.w : index == 2 ? 172.w : 160.w;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  width: btnWidth, height: 48.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r)),
                  child: Center(child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: primary))),
                ),
              );
            }),
          ])),
          SizedBox(width: 10.w),
          SizedBox(width: 160.w, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(height: innerOffset),
            _buildCircleIcon(sec.length > 2 ? sec[2].iconUrl : ''),
            SizedBox(height: 10.h),
            _buildSectionImage(sec.length > 2 ? sec[2].imageUrl : '', 160.w, 180.h),
            SizedBox(height: 10.h),
            _buildGreenCard(width: 160.w, height: 120.h, text: secDesc(2), color: primary, isRtl: isAr),
          ])),
          SizedBox(width: 10.w),
          _buildOuterCard(iconUrl: sec.length > 3 ? sec[3].iconUrl : '', imageUrl: sec.length > 3 ? sec[3].imageUrl : '',
              text: secDesc(3), cardColor: primary, iconOnRight: isAr),
        ],
      ),
    );
  }

  Widget _buildOuterCard({
    required String iconUrl, required String imageUrl, required String text,
    required Color cardColor, bool iconOnRight = false,
  }) {
    final double totalW = 212.w;
    final double iconSz = 36.w;
    final double imgW = 160.w;
    final double gap = 12.w;
    final Widget img = _buildSectionImage(imageUrl, imgW, 180.h, radius: 16.r);
    final Widget icn = Container(
      width: iconSz, height: iconSz,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: ClipOval(child: _smartImage(url: iconUrl, width: 18.w, height: 18.w, fit: BoxFit.scaleDown)),
    );
    return SizedBox(
      width: totalW,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children:
            iconOnRight ? [img, SizedBox(width: gap), icn] : [icn, SizedBox(width: gap), img]),
        SizedBox(height: 10.h),
        _buildGreenCard(width: totalW, height: 120.h, text: text, color: cardColor, isRtl: false),
      ]),
    );
  }

  Widget _buildCircleIcon(String iconUrl) {
    return Container(
      width: 36.w, height: 36.w,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: ClipOval(child: _smartImage(url: iconUrl, width: 18.w, height: 18.w, fit: BoxFit.contain)),
    );
  }

  Widget _buildSectionImage(String imageUrl, double width, double height, {double? radius}) {
    final r = radius ?? 12.r;
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Container(
          width: width, height: height, color: AppColors.card, alignment: Alignment.center,
          child: NetworkImageView(url: imageUrl, width: width * 0.75, height: height * 0.75, fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r)),
    );
  }

  Widget _buildGreenCard({
    double? width, required double height, required String text, required Color color,
    double? fontSize, bool isRtl = false,
  }) {
    final double fSize = fontSize ?? 12.sp;
    const double lineHeight = 1.2;
    final double padding = 10.r * 2;
    final int maxLines = ((height - padding) / (fSize * lineHeight)).floor().clamp(1, 99);
    return Container(
      width: width, height: height,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10.r)),
      child: Text(text,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        maxLines: maxLines, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fSize, fontWeight: FontWeight.w400, color: Colors.white, height: lineHeight),
      ),
    );
  }

  Widget _smartImage({required String url, required double width, required double height, BoxFit fit = BoxFit.contain}) {
    if (url.isEmpty) return Icon(Icons.image_outlined, size: 16.sp, color: Colors.grey);
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImageView(url: url, width: width, height: height, fit: fit);
    }
    return Icon(Icons.image_outlined, size: 16.sp, color: Colors.grey);
  }
}
