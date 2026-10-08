// ******************* FILE INFO *******************
// Part of: application_main.dart
// Contains: _buildGrid, _buildTable

part of '../../pages/application_main.dart';

extension _ApplicationMainTable on _ApplicationMainPageState {
  // ── Card Grid (3 columns) ─────────────────────────────────────────────────
  Widget _buildGrid(List<ApplicationModel> apps) {
    // BUG-16: one card per row on a phone.
    final int cols = AdminLayout.isPhone(context) ? 1 : 3;
    final rows = (apps.length / cols).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final start = rowIndex * cols;
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          // BUG-148: gaps are separate boxes (they were padding inside the
          // first two cells, so the 3rd card was 13 px wider).
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int colIndex = 0; colIndex < cols; colIndex++) ...[
                  if (colIndex > 0) SizedBox(width: 12.w),
                  if (start + colIndex >= apps.length)
                    const Expanded(child: SizedBox())
                  else
                    Expanded(
                      child: _AppCard(
                        app: apps[start + colIndex],
                        onTap: () => navigateTo(
                            context,
                            ApplicationDetailPage(
                                jobId: apps[start + colIndex].jobId,
                                appId: apps[start + colIndex].id)),
                        onDownload: () => _downloadPdf(apps[start + colIndex]),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  /// BUG-120: location of the job an (older) application belongs to.
  String _jobLocationOf(String jobId) {
    try {
      for (final j in context.read<JobListingCubit>().allJobs) {
        if (j.id == jobId) {
          if (j.workType == WorkType.remote) return 'Remote';
          return j.location;
        }
      }
    } catch (_) {}
    return '';
  }

  // ── Table View ─────────────────────────────────────────────────────────────
  Widget _buildTable(List<ApplicationModel> apps) {
    final headers = [
      'No', 'Candidate', 'Email', 'Phone', 'Department',
      'Job Title', 'Work Type', 'Location', 'Employment Type',
      'Experience Level', 'Salary Range', 'Currency', 'Application Date',
      'Status', 'Download',
    ];

    final columnWidths = <int, TableColumnWidth>{
      0:  FixedColumnWidth(50.sp),
      1:  FixedColumnWidth(140.sp),
      2:  FixedColumnWidth(200.sp),
      3:  FixedColumnWidth(150.sp),
      4:  FixedColumnWidth(120.sp),
      5:  FixedColumnWidth(150.sp),
      6:  FixedColumnWidth(100.sp),
      7:  FixedColumnWidth(120.sp),
      8:  FixedColumnWidth(130.sp),
      9:  FixedColumnWidth(120.sp),
      10: FixedColumnWidth(120.sp),
      11: FixedColumnWidth(90.sp),   // Currency
      12: FixedColumnWidth(110.sp),
      13: FixedColumnWidth(110.sp),
      14: FixedColumnWidth(90.sp),
    };

    TextStyle cellStyle = StyleText.fontSize11Weight400.copyWith(fontSize: 11.sp, color: AppColors.text);

    Widget cell(Widget child) => Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp),
      child: DefaultTextStyle.merge(style: cellStyle, child: child),
    );

    Widget textCell(String text) => cell(
      Text(text.isEmpty ? '-' : text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );

    Color statusColor(ApplicationStatus status) {
      switch (status) {
        case ApplicationStatus.hired:
          return Colors.green.shade600;
        case ApplicationStatus.unqualified:
        case ApplicationStatus.interviewFailed:
        case ApplicationStatus.offerRejected:
          return Colors.red.shade600;
        case ApplicationStatus.interviewPassed:
        case ApplicationStatus.interviewWithdrew:
          return Colors.blue.shade600;
        case ApplicationStatus.offerApproved:
        case ApplicationStatus.offerPending:
          return Colors.orange.shade600;
        case ApplicationStatus.qualified:
          return Colors.teal.shade600;
        case ApplicationStatus.applied:
        default:
          return ColorPick.primary;
      }
    }

    // BUG-115: the table (≈1,900 px) could not be scrolled to Status / PDF
    // and had no scrollbar. It now scrolls inside a box of exactly the
    // available width, with an always-visible horizontal scrollbar.
    return _HScrollBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: Table(
          border: TableBorder.all(color: Colors.transparent),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: columnWidths,
          children: [
            // ── Header Row ──
            TableRow(
              decoration: const BoxDecoration(color: ColorPick.primary),
              children: headers.map((h) => Padding(
                padding: EdgeInsets.all(10.sp),
                child: Text(
                  h,
                  maxLines: 1,
                  style: StyleText.fontSize11Weight600.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )).toList(),
            ),

            // ── Data Rows ──
            ...List.generate(apps.length, (index) {
              final a = apps[index];
              final isEven = index.isEven;
              final rowColor = isEven ? const Color(0xFFF7F8FA) : Colors.white;

              // BUG-145: one date format ("4 Oct 2026") everywhere.
              final dateStr = a.applicationDate != null
                  ? DateFormat('d MMM yyyy').format(a.applicationDate!)
                  : '-';

              final cells = [
                textCell('${index + 1}'),
                textCell(a.fullName),
                textCell(a.email),
                textCell('${a.countryCode} ${a.phone}'.trim()), // BUG-114
                textCell(a.department),
                textCell(a.jobTitle),
                textCell(a.workType),
                // BUG-120: older applications were saved with an empty
                // location — fall back to the job's own location.
                textCell(a.jobLocation.isNotEmpty
                    ? a.jobLocation
                    : _jobLocationOf(a.jobId)),
                textCell(a.employmentType),
                textCell(a.experienceLevel),
                textCell(a.salaryRange),
                textCell(a.currency),
                textCell(dateStr),
                cell(
                  Text(
                    a.status.label,
                    style: StyleText.fontSize11Weight600.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor(a.status),
                    ),
                  ),
                ),
                cell(
                  InkWell(
                    onTap: () => _downloadPdf(a),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ColorPick.primary,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, size: 12.sp, color: Colors.white),
                          SizedBox(width: 2.w),
                          Text('PDF',
                              style: StyleText.fontSize10Weight700.copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ];

              return TableRow(
                decoration: BoxDecoration(color: rowColor),
                children: List.generate(cells.length, (ci) {
                  if (ci < cells.length - 1) {
                    return InkWell(
                      onTap: () => navigateTo(context,
                          ApplicationDetailPage(jobId: a.jobId, appId: a.id)),
                      child: cells[ci],
                    );
                  }
                  return cells[ci];
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// BUG-115: horizontal scroller that always gets a FINITE width (the
/// available one) and shows its scrollbar, so every column is reachable.
class _HScrollBox extends StatefulWidget {
  const _HScrollBox({required this.child});
  final Widget child;

  @override
  State<_HScrollBox> createState() => _HScrollBoxState();
}

class _HScrollBoxState extends State<_HScrollBox> {
  final ScrollController _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth.isFinite
          ? c.maxWidth
          : MediaQuery.sizeOf(context).width - 32;
      return SizedBox(
        width: w,
        child: Scrollbar(
          controller: _ctrl,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: widget.child,
          ),
        ),
      );
    });
  }
}
