part of '../../pages/department_main.dart';

class _DepartmentCard extends StatefulWidget {
  final DepartmentModel    department;
  final List<JobPostModel> allJobs;
  final VoidCallback       onTap;

  const _DepartmentCard({
    required this.department,
    required this.allJobs,
    required this.onTap,
  });

  @override
  State<_DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<_DepartmentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final deptJobs = widget.allJobs
        .where((j) => widget.department.matchesJob(j.department))
        .toList();

    final totalCount    = deptJobs.length;
    final activeCount   =
        deptJobs.where((j) => j.status == JobStatus.active).length;
    final inactiveCount =
        deptJobs.where((j) => j.status == JobStatus.inactive).length;

    final createdText = widget.department.createdAt != null
        ? 'Created At: ${widget.department.createdAt!.day} '
        '${_monthName(widget.department.createdAt!.month)} '
        '${widget.department.createdAt!.year}'
        : 'Created At: —';

    return MouseRegion(
      cursor:   SystemMouseCursors.click,
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: _hovered
                ? [
              BoxShadow(
                color:      ColorPick.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset:     const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: Row(
                  children: [
                    // ── Company logo ──
                    BlocBuilder<MainCmsCubit, MainCmsState>(
                      builder: (context, state) {
                        // BUG-86: the department's own image first.
                        // No department image → the admin header logo.
                        final String logoUrl = widget.department.iconUrl;
                        final double sz = 36.sp;
                        return SizedBox(
                          width: sz,
                          height: sz,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: logoUrl.isNotEmpty
                                ? NetworkImageView(
                              url:    logoUrl,
                              width:  sz,
                              height: sz,
                              fit:    BoxFit.cover,
                            )
                                : Image.asset('assets/images/login/logo.png',
                                width: sz, height: sz, fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        widget.department.nameEn.isEmpty
                            ? 'Department Name'
                            : FormatHelper.capitalize(widget.department.nameEn),
                        style: TextStyle(
                          fontSize:   15.sp,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.text,
                        ),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ),

                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // ── Stats ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow('Total Job Post:', totalCount,
                        'assets/images/job_list/totoal_job.svg'),
                    SizedBox(height: 6.h),
                    _statRow('Active Job:', activeCount,
                        'assets/images/job_list/active_job.svg'),
                    SizedBox(height: 6.h),
                    _statRow('Inactive Job:', inactiveCount,
                        'assets/images/job_list/inactive_job.svg'),
                  ],
                ),
              ),

              SizedBox(height: 10.sp),
              const Spacer(),

              // ── Bottom bar ──
              Container(
                width:   double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: ColorPick.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(10.r),
                    bottomRight: Radius.circular(10.r),
                  ),
                ),
                child: Text(
                  createdText,
                  style: TextStyle(
                    fontSize:   12.sp,
                    color:      Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, int count, String svgPath) {
    return Row(
      children: [
        CustomSvg(
            assetPath: svgPath,
            width:     14.sp,
            height:    14.sp,
            fit:       BoxFit.contain),
        SizedBox(width: 8.w),
        Text('$label ',
            style: StyleText.fontSize12Weight500
                .copyWith(color: AppColors.text)),
        Text('$count',
            style: StyleText.fontSize12Weight500
                .copyWith(color: AppColors.secondaryText)),
      ],
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
