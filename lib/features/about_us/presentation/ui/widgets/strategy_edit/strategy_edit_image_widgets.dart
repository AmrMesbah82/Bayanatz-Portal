// ******************* FILE INFO *******************
// File Name: strategy_edit_image_widgets.dart
// Description: Nav icon upload + Strategic house display widgets for Strategy edit
// Ported from beauty_admin (nav_icon_upload_widget.dart + strategic_house_display_widget.dart)

part of '../../pages/strategy_page/strategy_edit.dart';

class _NavIconUploadWidget extends StatelessWidget {
  final Uint8List? bytes;
  final String url;
  final bool isSvg;
  final String? errorText;
  final Future<Uint8List> Function(String) loadSvgBytes;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _NavIconUploadWidget({
    super.key,
    required this.bytes,
    required this.url,
    required this.isSvg,
    this.errorText,
    required this.loadSvgBytes,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null || url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon',
            style: StyleText.fontSize16Weight500.copyWith(
                color: AppColors.text
            )
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: errorText != null
                          ? Border.all(color: const Color(0xFFD32F2F), width: 2)
                          : null,
                    ),
                    child: hasImage
                        ? ClipOval(
                      child: Builder(
                        builder: (context) {
                          if (bytes != null) {
                            final b = bytes!;
                            final isPng = b.length >= 4 &&
                                b[0] == 0x89 && b[1] == 0x50 &&
                                b[2] == 0x4E && b[3] == 0x47;
                            return isPng
                                ? Image.memory(b, fit: BoxFit.cover)
                                : SvgPicture.memory(
                                    b,
                                    fit: BoxFit.scaleDown,
                                    placeholderBuilder: (context) => const Center(
                                      child: CircleProgress(),
                                    ),
                                  );
                          }
                          if (url.isNotEmpty && isSvg) {
                            return FutureBuilder<Uint8List>(
                              key: ValueKey(url),
                              future: loadSvgBytes(url),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircleProgress(),
                                  );
                                }
                                if (snapshot.hasData) {
                                  return SvgPicture.memory(
                                    snapshot.data!,
                                    fit: BoxFit.scaleDown,
                                  );
                                }
                                return Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 28.sp,
                                );
                              },
                            );
                          }
                          if (url.isNotEmpty) {
                            return Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                                size: 28.sp,
                              ),
                            );
                          }
                          return Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 28.sp,
                          );
                        },
                      ),
                    )
                        : Icon(Icons.add,
                        color: errorText != null ? const Color(0xFFD32F2F) : Colors.grey[600],
                        size: 28.sp),
                  ),
                  if (hasImage && onRemove != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFD32F2F),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  // ✅ Camera badge always shown bottom-right, matching the
                  // standard image-upload circle used across the app.
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 25.w,
                      height: 25.h,
                      decoration: BoxDecoration(
                        color: ColorPick.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: CustomSvg(
                          assetPath: "assets/control/camera.svg",
                          width: 10.w,
                          height: 10.h,
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              color: const Color(0xFFD32F2F),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget for displaying the selected device preview
class _StrategicHouseDisplayWidget extends StatelessWidget {
  final DisplayDeviceTab displayTab;
  final Uint8List? desktopBytes;
  final String desktopUrl;
  final bool desktopIsSvg;
  final Uint8List? tabletBytes;
  final String tabletUrl;
  final bool tabletIsSvg;
  final Uint8List? mobileBytes;
  final String mobileUrl;
  final bool mobileIsSvg;
  final Future<Uint8List> Function(String) loadSvgBytes;

  const _StrategicHouseDisplayWidget({
    required this.displayTab,
    required this.desktopBytes,
    required this.desktopUrl,
    required this.desktopIsSvg,
    required this.tabletBytes,
    required this.tabletUrl,
    required this.tabletIsSvg,
    required this.mobileBytes,
    required this.mobileUrl,
    required this.mobileIsSvg,
    required this.loadSvgBytes,
  });

  double _getPreviewWidth() {
    switch (displayTab) {
      case DisplayDeviceTab.largeScreen:
        return double.infinity;
      case DisplayDeviceTab.tablet:
        return 600;
      case DisplayDeviceTab.mobile:
        return 320;
    }
  }

  Uint8List? _getCurrentBytes() {
    switch (displayTab) {
      case DisplayDeviceTab.largeScreen:
        return desktopBytes;
      case DisplayDeviceTab.tablet:
        return tabletBytes;
      case DisplayDeviceTab.mobile:
        return mobileBytes;
    }
  }

  String _getCurrentUrl() {
    switch (displayTab) {
      case DisplayDeviceTab.largeScreen:
        return desktopUrl;
      case DisplayDeviceTab.tablet:
        return tabletUrl;
      case DisplayDeviceTab.mobile:
        return mobileUrl;
    }
  }

  bool _getCurrentIsSvg() {
    switch (displayTab) {
      case DisplayDeviceTab.largeScreen:
        return desktopIsSvg;
      case DisplayDeviceTab.tablet:
        return tabletIsSvg;
      case DisplayDeviceTab.mobile:
        return mobileIsSvg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _getCurrentBytes();
    final url = _getCurrentUrl();
    final isSvg = _getCurrentIsSvg();
    final hasImage = bytes != null || url.isNotEmpty;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _getPreviewWidth(),
        height: 220.h,

        child: hasImage
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Builder(
            builder: (context) {
              if (bytes != null) {
                final isPng = bytes.length >= 4 &&
                    bytes[0] == 0x89 && bytes[1] == 0x50 &&
                    bytes[2] == 0x4E && bytes[3] == 0x47;
                return isPng
                    ? Image.memory(bytes,
                        width: _getPreviewWidth(),
                        height: 220.h,
                        fit: BoxFit.contain)
                    : SvgPicture.memory(
                        bytes,
                        width: _getPreviewWidth(),
                        height: 220.h,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const Center(
                          child: CircleProgress(),
                        ),
                      );
              }
              if (url.isNotEmpty && isSvg) {
                return FutureBuilder<Uint8List>(
                  key: ValueKey(url),
                  future: loadSvgBytes(url),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircleProgress()
                      );
                    }
                    if (snapshot.hasData) {
                      return SvgPicture.memory(
                        snapshot.data!,
                        width: _getPreviewWidth(),
                        height: 220.h,
                        fit: BoxFit.contain,
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 48.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Failed to load SVG',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              if (url.isNotEmpty) {
                return Image.network(
                  url,
                  width: _getPreviewWidth(),
                  height: 220.h,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 48.sp,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomSvg(
              assetPath: "assets/images/upload-image.svg",
              width: 100.w,
              height: 100.h,
              fit: BoxFit.fill,
            ),
            SizedBox(height: 8.h),
            Text(
              'No image uploaded for ${displayTab == DisplayDeviceTab.largeScreen ? "Desktop" : displayTab == DisplayDeviceTab.tablet ? "Tablet" : "Mobile"}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
