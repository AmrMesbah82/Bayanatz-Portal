// ******************* FILE INFO *******************
// Part of: main_edit.dart
// Contains: _removeBtn, _addLabelBtn, _sectionLabel, _imgBox,
//           _placeholderCircle, _ord

part of '../../pages/main_edit.dart';

extension _HomeEditHelpers on _MainEditPageState {
  Widget _removeBtn({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: ColorPick.red,
              borderRadius: BorderRadius.circular(4.r)),
          child: Text(label,
              style: StyleText.fontSize12Weight500
                  .copyWith(color: Colors.white)),
        ),
      );

  Widget _addLabelBtn({required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: const Color(0xFF797979),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFF797979))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add, size: 14.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text('Label',
                style: StyleText.fontSize12Weight500
                    .copyWith(color: Colors.white)),
          ]),
        ),
      );

  Widget _sectionLabel(String text) => Text(text,
      style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text));

  Widget _imgBox({
    required _PickedImage picked,
    String placeholderAsset = 'assets/home_control/image.svg',
    String pickIconAsset    = 'assets/control/camera.svg',
    VoidCallback? onPick,
  }) {
    // Delegates to the single shared image-upload circle (core/custom).
    return imageUploadCircleBare(
      bytes: picked.bytes,
      url: picked.url ?? '',
      onTap: onPick ?? () {},
    );
  }

  Widget _placeholderCircle(String assetPath) => Container(
        width: 70.w, height: 70.h,
        decoration: const BoxDecoration(
            color: Color(0xFFD9D9D9), shape: BoxShape.circle),
        child: Center(
            child: CustomSvg(
                assetPath: assetPath,
                width: 30.w, height: 30.h,
                fit: BoxFit.fill)),
      );

  String _ord(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}
