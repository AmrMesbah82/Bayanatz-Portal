part of '../../pages/job_listing_main.dart';

class _JobCard extends StatelessWidget {
  final JobPostModel job;
  final String logoUrl;
  final VoidCallback? onTap;

  const _JobCard({required this.job, required this.logoUrl, this.onTap});

  // BUG-295: shared status colours (Inactive and Scheduled were the same
  // orange here).
  Color get _statusTextColor => JobStatusStyle.color(job.status);

  Color get _bottomBarColor {
    switch (job.status) {
      case JobStatus.active:    return const Color(0xFF008037);
      case JobStatus.ended:     return const Color(0xFFD32F2F);
      case JobStatus.removed:   return const Color(0xFFD32F2F);
      case JobStatus.scheduled: return const Color(0xFF008037);
      case JobStatus.drafted:   return const Color(0xFF008037);
      case JobStatus.inactive:  return const Color(0xFF008037);
    }
  }

  String get _bottomSvg {
    switch (job.status) {
      case JobStatus.active:    return _Svg.posted;
      case JobStatus.ended:     return _Svg.endedOn;
      case JobStatus.removed:   return _Svg.removed;
      case JobStatus.scheduled: return _Svg.scheduled;
      case JobStatus.drafted:   return _Svg.started;
      case JobStatus.inactive:  return _Svg.inactive;
    }
  }

  String get _bottomText {
    switch (job.status) {
      case JobStatus.active:
        // BUG-44: "Posted 0 Days ago" → "Posted Today".
        final days = DateTime.now().difference(job.postedDate ?? DateTime.now()).inDays;
        if (days <= 0) return 'Posted Today';
        if (days == 1) return 'Posted 1 Day ago';
        return 'Posted $days Days ago';
      case JobStatus.ended:
        return 'Ended On ${_formatDate(job.endedDate ?? job.hiringEndDate)}';
      case JobStatus.removed:
        return 'Removed Since ${_formatDate(job.endedDate)}';
      case JobStatus.scheduled:
        // Scheduled jobs open on their hiring start date (BUG-11).
        return 'Scheduled At ${_formatDate(job.hiringStartDate ?? job.postedDate)}';
      case JobStatus.drafted:
        return 'Draft — not published yet';
      case JobStatus.inactive:
        // BUG-44: the date is now stamped when a job is deactivated.
        final d = _formatDate(job.endedDate);
        return d.isEmpty ? 'Inactive' : 'Inactive Since $d';
    }
  }

  String get _bottomRightText {
    if (job.totalApplications > 0) return 'Total Applications: ${job.totalApplications}'; // BUG-41
    return '';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Real requirements text from the job data (falls back to the required
  /// qualification, then a placeholder) — replaces the old hardcoded string.
  String get _requirementsPreview {
    final r = job.requirements.en.trim();
    if (r.isNotEmpty) return r;
    final q = job.requiredQualification.en.trim();
    return q.isNotEmpty ? q : 'No requirements added';
  }

  String _workTypeSvg() {
    switch (job.workType) {
      case WorkType.remote: return _Svg.remote;
      case WorkType.onSite: return _Svg.office;
      case WorkType.hybrid: return _Svg.office;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Logo + Title ──────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CompanyLogo(logoUrl: logoUrl),
                      SizedBox(width: 10.w),
                      Expanded(
                        // BUG-44: user text is shown exactly as typed (no
                        // auto Title-Case), and it truncates BEFORE the status
                        // badge instead of running underneath it.
                        // BUG-303: long titles wrap to 2 lines and the full
                        // title shows on hover (was cut at ≈190 px).
                        child: Tooltip(
                          message: job.displayTitle,
                          waitDuration: const Duration(milliseconds: 400),
                          child: Text(
                            job.displayTitle,
                            style: StyleText.fontSize15Weight600.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _statusBadge(),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // ── Tags with SVG icons ───────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      // BUG-10 / BUG-47: the location used to be a hard-coded
                      // "Egypt" on every card (even remote jobs), and unset
                      // dropdowns showed invented defaults.
                      if (job.location.trim().isNotEmpty &&
                          job.workType != WorkType.remote)
                        _svgTag(_Svg.calendar, job.location.trim()),
                      if (!job.isUnset('workType'))
                        _svgTag(_workTypeSvg(), job.workType.displayLabel), // BUG-157
                      if (!job.isUnset('experienceLevel'))
                        _svgTag(_Svg.yearsExp, job.experienceLevel.label),
                      if (job.salaryMax > 0)
                        _svgTag(
                          _Svg.calendar,
                          // BUG-44: salary with its currency.
                          job.salaryDisplay, // BUG-304
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Requirements (real data) + View ───────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.sp),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _requirementsPreview, // BUG-44: as typed
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.text),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'View',
                        style: StyleText.fontSize12Weight500.copyWith(
                          fontSize: 12.sp,
                          color: ColorPick.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: ColorPick.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Bottom bar with SVG icon ──────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: ColorPick.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.r),
                      bottomRight: Radius.circular(10.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        _bottomSvg,
                        width: 18.sp,
                        height: 18.sp,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _bottomText,
                          style: StyleText.fontSize12Weight600.copyWith(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_bottomRightText.isNotEmpty)
                        Text(
                          _bottomRightText,
                          style: StyleText.fontSize11Weight400.copyWith(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  // ── Status badge — now part of the header row (BUG-44) ──────────────────
  Widget _statusBadge() => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        child: Text(
          job.status.displayLabel, // BUG-279: "Draft", not "Drafted"
          style: StyleText.fontSize13Weight600.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _statusTextColor,
          ),
        ),
      );

  Widget _svgTag(String svgAsset, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorPick.primary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 14.sp,
            height: 14.sp,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          SizedBox(width: 5.w),
          Text(
            text, // BUG-44: shown as typed
            style: StyleText.fontSize11Weight600.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  COMPANY LOGO — from Firebase via HomeCmsCubit
// ═════════════════════════════════════════════════════════════════════════════
