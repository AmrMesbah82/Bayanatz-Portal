part of '../../pages/application_main.dart';

class _AppCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  const _AppCard({required this.app, this.onTap, this.onDownload});

  /// Same stage icons as the summary cards row on ApplicationMainPage.
  String get _statusSvg {
    switch (app.status) {
      case ApplicationStatus.applied:
      case ApplicationStatus.qualified:
      case ApplicationStatus.unqualified:
        return 'assets/images/job_list/applied.svg';
      case ApplicationStatus.interviewPassed:
      case ApplicationStatus.interviewFailed:
      case ApplicationStatus.interviewWithdrew:
        return 'assets/images/job_list/interview.svg';
      case ApplicationStatus.offerApproved:
      case ApplicationStatus.offerPending:
      case ApplicationStatus.offerRejected:
        return 'assets/images/job_list/offer.svg';
      case ApplicationStatus.hired:
        return 'assets/images/job_list/hired.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = app.applicationDate != null
        ? '${app.applicationDate!.day} ${_month(app.applicationDate!.month)} ${app.applicationDate!.year}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 10.sp),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tags row ──
            Row(
              children: [
                if (app.tag.isNotEmpty)
                  _tag(app.tag, ColorPick.primary, icon: Icons.local_offer_outlined),
                SizedBox(width: 6.w),
                _tag(app.status.label, ColorPick.primary, svgAsset: _statusSvg),
                const Spacer(),
                GestureDetector(
                  onTap: onDownload,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorPick.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text('Download Summary' /* BUG-241: it builds a summary PDF */, style: StyleText.fontSize10Weight700.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // ── Job Title (was Department) ──
            Row(
              children: [
                // Same logo as the admin header (assets/images/login/logo.png),
                // at a readable size — Figma Applications card, 50 × 50.
                Image.asset(
                  'assets/images/login/logo.png',
                  width: 36.sp,
                  height: 36.sp,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BUG-159: the heading is the JOB applied for (two
                      // applications to different jobs of one department
                      // looked identical); the department is the sub-line.
                      Text(
                        app.jobTitle.trim().isNotEmpty
                            ? app.jobTitle.trim()
                            : (app.department.isEmpty ? '—' : app.department),
                        style: StyleText.fontSize13Weight600.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        app.department.isEmpty
                            ? 'Department'
                            : FormatHelper.capitalize(app.department),
                        style: StyleText.fontSize10Weight400.copyWith(fontSize: 10.sp, color: AppColors.secondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // ── Info rows ──
            _infoRow('Candidate:', FormatHelper.capitalize(app.fullName)),
            SizedBox(height: 4.h),
            _infoRow('Email:', app.email),
            SizedBox(height: 4.h),
            // BUG-114: "+20 0000000000" like the detail page (was "+200000000000").
            _infoRow('Phone Number:', '${app.countryCode} ${app.phone}'.trim()),
            SizedBox(height: 4.h),
            _infoRow('Application Date:', dateStr),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, {IconData? icon, String? svgAsset}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null) ...[
            SvgPicture.asset(
              svgAsset,
              width: 11.sp,
              height: 11.sp,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(width: 3.w),
          ] else if (icon != null) ...[
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Text(FormatHelper.capitalize(text), style: StyleText.fontSize10Weight700.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: StyleText.fontSize11Weight600.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w600, color: ColorPick.primary)),
        SizedBox(width: 4.w),
        Expanded(child: Text(value, style: StyleText.fontSize11Weight400.copyWith(fontSize: 11.sp, color: AppColors.text), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
