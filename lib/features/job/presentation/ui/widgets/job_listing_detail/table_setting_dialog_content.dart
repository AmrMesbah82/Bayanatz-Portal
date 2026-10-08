part of '../../pages/job_listing_detail.dart';

class _TableSettingDialogContent extends StatefulWidget {
  final Map<String, bool> columnVisibility;
  const _TableSettingDialogContent({required this.columnVisibility});

  @override
  State<_TableSettingDialogContent> createState() =>
      _TableSettingDialogContentState();
}

class _TableSettingDialogContentState
    extends State<_TableSettingDialogContent> {
  late Map<String, bool> _tempVisibility;

  static const _leftKeysTop = [
    ColumnKey.firstName,
    ColumnKey.lastName,
    ColumnKey.email,
    ColumnKey.code,
    ColumnKey.phone,
  ];

  static const _rightKeysTop = [
    ColumnKey.status,
    ColumnKey.stage,
    ColumnKey.score,
    ColumnKey.tags,
  ];

  static const _leftKeysBottom = [
    ColumnKey.source,
    ColumnKey.location,
    ColumnKey.resume,
    ColumnKey.coverLetter,
  ];

  static const _rightKeysBottom = [
    ColumnKey.appliedDate,
    ColumnKey.interviewDate,
    ColumnKey.lastUpdate,
    ColumnKey.yearOfGraduation,
  ];

  @override
  void initState() {
    super.initState();
    _tempVisibility = Map.from(widget.columnVisibility);


  }

  void _reset() {
    setState(() {
      _tempVisibility = ColumnKey.defaultVisibility();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520.w,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 32.sp,
                    height: 32.sp,
                    decoration: BoxDecoration(
                      color: ColorPick.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: CustomSvg(
                      assetPath: "assets/images/table_icon.svg",
                      width: 20.w,
                      height: 20.h,
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Table Setting',
                    style: StyleText.fontSize16Weight700.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _reset,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Reset',
                        style: StyleText.fontSize12Weight600.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // ── Top group — two columns ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: _leftKeysTop
                          .map((key) => _buildSwitchRow(key))
                          .toList(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      children: _rightKeysTop
                          .map((key) => _buildSwitchRow(key))
                          .toList(),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 8.h),

              // ── Bottom group — two columns ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: _leftKeysBottom
                          .map((key) => _buildSwitchRow(key))
                          .toList(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      children: _rightKeysBottom
                          .map((key) => _buildSwitchRow(key))
                          .toList(),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // ── Bottom buttons — Back + Save ──
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(null);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            'Back',
                            style: StyleText.fontSize14Weight600.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: InkWell(
                      onTap: () {

                        Navigator.of(context).pop(_tempVisibility);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: ColorPick.primary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            'Save',
                            style: StyleText.fontSize14Weight600.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String key) {
    final label = ColumnKey.labels[key] ?? key;
    final value = _tempVisibility[key] ?? true;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: StyleText.fontSize13Weight500.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          FlutterSwitch(
            width: 38.sp,
            height: 22.sp,
            padding: 3.sp,
            borderRadius: 20.sp,
            toggleSize: 16.sp,
            activeColor: ColorPick.primary,
            inactiveColor: Colors.grey.withValues(alpha: .16),
            value: value,
            onToggle: (v) {
              setState(() {
                _tempVisibility[key] = v;
              });
            },
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PAGE
// ═════════════════════════════════════════════════════════════════════════════
