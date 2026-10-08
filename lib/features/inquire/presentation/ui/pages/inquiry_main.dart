// ═══════════════════════════════════════════════════════════════════
// FILE: inquiry_main.dart (View Page)
// Path: lib/features/inquire/presentation/ui/pages/inquiry_main.dart
// UPDATED: Charts enhanced to match Figma design exactly
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/widget/auto_close_dialog.dart';
import 'package:web_app_admin/core/widget/date_pic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_app_admin/core/widget/custom_dropdwon.dart';
import 'package:web_app_admin/core/widget/button.dart';
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/search.dart';
import 'package:web_app_admin/core/custom_svg.dart';
import 'package:web_app_admin/core/widget/textfield.dart';

import '../../../../../core/constant/color.dart';
import 'package:web_app_admin/core/main_widgets/admin_layout.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/main_widgets/csv_export_dialog.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/inquiry_model.dart';
import '../../controller/inquiry_cubit.dart';
import '../../controller/inquiry_state.dart';
import '../widgets/inquiry_status_colors.dart';
import 'inquiry_details.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/inquiry_main/pie_chart_painter.dart';

// class _C {
//   static const Color primary      = Color(0xFF008037);
//   static const Color primaryLight = Color(0xFF4CAF7D);
//   static const Color back         = Color(0xFFF1F2ED);
//   static const Color cardBg       = Color(0xFFFFFFFF);
//   static const Color labelText    = Color(0xFF333333);
//   static const Color hintText     = Color(0xFFAAAAAA);
//   static const Color border       = Color(0xFFE0E0E0);
//   static const Color barLight     = Color(0xFFB2DFCC);   // light green bg for location bars
//   static const Color barLighter   = Color(0xFFDCEFE5);   // even lighter for entity size
// }

// ── Month name helper ────────────────────────────────────────────────────────
const List<String> _kMonthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class InquiryMainPage extends StatefulWidget {
  const InquiryMainPage({super.key});

  @override
  State<InquiryMainPage> createState() => _InquiryMainPageState();
}

class _InquiryMainPageState extends State<InquiryMainPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InquiryCubit>().loadInquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CSV EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  String _escapeCsvValue(String value) {
    if (value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatDateForExport(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // BUG-32: shared export dialog — always downloads (header-only when empty),
  // validates the file name inside the dialog, and confirms the download.
  void _showExportDialog(List<InquiryModel> inquiries) {
    showCsvExportDialog(
      context,
      defaultFileName: 'inquiries',
      itemLabel: 'inquiries',
      header: const ['No', 'Submission Date', 'Preferred Language', 'First Name',
        'Last Name', 'Email', 'Country Code', 'Phone Number', 'Location',
        'Entity Name', 'Entity Type', 'Entity Size', 'Subject', 'Message',
        'Note', 'Status'],
      rows: [
        for (int i = 0; i < inquiries.length; i++)
          [
            '${i + 1}',
            _formatDateForExport(inquiries[i].submissionDate),
            inquiries[i].preferredLanguage,
            inquiries[i].firstName,
            inquiries[i].lastName,
            inquiries[i].email,
            inquiries[i].countryCode,
            inquiries[i].phone,
            inquiries[i].location,
            inquiries[i].entityName,
            inquiries[i].entityType,
            inquiries[i].entitySize,
            inquiries[i].subject,
            inquiries[i].message,
            inquiries[i].note,
            inquiries[i].status.label,
          ],
      ],
    );
  }

  void _performExport(List<InquiryModel> inquiries, String fileName) {
    try {
      final csvBuffer = StringBuffer();
      csvBuffer.writeln(['No', 'Submission Date', 'Preferred Language', 'First Name', 'Last Name', 'Email', 'Country Code', 'Phone Number', 'Location', 'Entity Name', 'Entity Type', 'Entity Size', 'Subject', 'Message', 'Note', 'Status'].map(_escapeCsvValue).join(','));
      for (int i = 0; i < inquiries.length; i++) {
        final inq = inquiries[i];
        csvBuffer.writeln(['${i + 1}', _formatDateForExport(inq.submissionDate), inq.preferredLanguage, inq.firstName, inq.lastName, inq.email, inq.countryCode, inq.phone, inq.location, inq.entityName, inq.entityType, inq.entitySize, inq.subject, inq.message, inq.note, inq.status.label].map(_escapeCsvValue).join(','));
      }
      final bytes = utf8.encode(csvBuffer.toString());
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final finalFileName = fileName.toLowerCase().endsWith('.csv') ? fileName : '$fileName.csv';
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)..setAttribute('download', finalFileName)..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red));
    }
  }

  void _showExportSuccessDialog(String fileName) {
    // Closes itself after 3 s (AutoCloseDialog) — no OK button.
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AutoCloseDialog(child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 320.w,
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.sp, height: 64.sp,
                decoration: BoxDecoration(color: ColorPick.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle, color: ColorPick.primary, size: 40.sp),
              ),
              SizedBox(height: 16.h),
              Text('Export Successful', textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
              SizedBox(height: 8.h),
              Text('$fileName\ndownloaded successfully', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText, height: 1.4)),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      )),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocListener<InquiryCubit, InquiryState>(
      listener: (context, state) {
        if (state is InquiryUpdated) context.read<InquiryCubit>().loadInquiries();
      },
      child: BlocBuilder<InquiryCubit, InquiryState>(
        builder: (context, state) {
          if (state is InquiryInitial || state is InquiryLoading) {
            return const Scaffold(backgroundColor: ColorPick.background, body: Center(child: CircleProgress()));
          }

          final cubit = context.read<InquiryCubit>();
          List<InquiryModel> inquiries = [];
          int totalCount = 0, newCount = 0, repliedCount = 0, closedCount = 0;
          Map<String, int> entityTypeCounts  = {};
          Map<String, int> entitySizeCounts  = {};
          Map<String, int> locationCounts    = {};
          Map<int, int>    monthlySubmissions = {};
          List<String> uniqueStatuses    = [];
          List<String> uniqueEntityTypes = [];
          List<String> uniqueLocations   = [];
          List<int>    uniqueMonths      = [];
          String? activeStatusFilter;
          String? activeEntityTypeFilter;
          String? activeLocationFilter;
          int?    activeMonthFilter;

          if (state is InquiryLoaded) {
            inquiries           = state.filtered;
            totalCount          = state.totalCount;
            newCount            = state.newCount;
            repliedCount        = state.repliedCount;
            closedCount         = state.closedCount;
            entityTypeCounts    = state.entityTypeCounts;
            entitySizeCounts    = state.entitySizeCounts;
            locationCounts      = state.locationCounts;
            monthlySubmissions  = state.monthlySubmissions;
            uniqueStatuses      = state.uniqueStatuses;
            uniqueEntityTypes   = state.uniqueEntityTypes;
            uniqueLocations     = state.uniqueLocations;
            uniqueMonths        = state.uniqueMonths;
            activeStatusFilter     = state.statusFilter;
            activeEntityTypeFilter = state.entityTypeFilter;
            activeLocationFilter   = state.locationFilter;
            activeMonthFilter      = state.monthFilter;
          }
          if (state is InquiryError && state.lastInquiries != null) inquiries = state.lastInquiries!;

          final statusItems     = uniqueStatuses.map((s)    => {'key': s, 'value': s}).toList();
          final entityTypeItems = uniqueEntityTypes.map((s) => {'key': s, 'value': s}).toList();
          final locationItems   = uniqueLocations.map((s)   => {'key': s, 'value': s}).toList();

          final DateTime? fromDate = cubit.fromDate;
          final DateTime? toDate = cubit.toDate;
          final bool hasActiveFilters = activeStatusFilter != null || activeEntityTypeFilter != null || activeLocationFilter != null || activeMonthFilter != null || fromDate != null || toDate != null;

          return Scaffold(
            backgroundColor: ColorPick.background,
            body: AdminStickyBody(
                reflowOnPhone: true, // BUG-16
  children: [
                    AppAdminNavbar(
                      activeLabel: 'Inquiries',
                      homePage: CareersMainPageDashboard(),
                      webPage: MainMainPage(),
                      jobListingPage: JobListingMainPage(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AdminLayout.sidePadding(context), vertical: 20.h),
                      child: SizedBox(
                        width: AdminLayout.contentWidth(context), // BUG-16
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inquiries', style: StyleText.fontSize45Weight600.copyWith(color: ColorPick.primary, fontWeight: FontWeight.w700)),
                            SizedBox(height: 16.h),
                            Row(children: [AppSearchTextField(controller: _searchController, onChanged: (v) => cubit.setSearch(v), hintText: 'Search')]),
                            SizedBox(height: 16.h),

                            // ── Summary cards ──
                            // BUG-16: 2 × 2 counters on a phone (labels were cut).
                            AdminCardsRow(phoneColumns: 2, children: [
                              // Figma: "Total Submission". BUG-152: New and
                              // Closed were the same red → Figma colours
                              // (Inquires, nodes 7126:65493/65498/65503):
                              // New green, Replied orange, Closed red.
                              _summaryCard('Total Submission', totalCount, Colors.grey),
                              _summaryCard('New', newCount, InquiryStatus.newInquiry.color),
                              _summaryCard('Replied', repliedCount, InquiryStatus.replied.color),
                              _summaryCard('Closed', closedCount, InquiryStatus.closed.color),
                            ]),
                            SizedBox(height: 16.h),

                            // ── Filters ── (BUG-16: wrap onto several lines on a phone)
                            _filtersLayout(context, [
                              SizedBox(width: 130.w, child: CustomDropdownFormFieldInvMaster(selectedValue: activeStatusFilter, items: statusItems, widthIcon: 14, heightIcon: 14, height: 32, dropdownColor: ColorPick.white, primaryColor: ColorPick.primary, hint: Text('Status', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText)), onChanged: (v) => cubit.setStatusFilter(v))),
                              SizedBox(width: 8.w),
                              SizedBox(width: 150.w, child: CustomDropdownFormFieldInvMaster(selectedValue: activeEntityTypeFilter, items: entityTypeItems, widthIcon: 14, heightIcon: 14, height: 32, dropdownColor: ColorPick.white, primaryColor: ColorPick.primary, hint: Text('Entity Type', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText)), onChanged: (v) => cubit.setEntityTypeFilter(v))),
                              SizedBox(width: 8.w),
                              SizedBox(width: 140.w, child: CustomDropdownFormFieldInvMaster(selectedValue: activeLocationFilter, items: locationItems, widthIcon: 14, heightIcon: 14, height: 32, dropdownColor: ColorPick.white, primaryColor: ColorPick.primary, hint: Text('Location', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText)), onChanged: (v) => cubit.setLocationFilter(v))),
                              SizedBox(width: 8.w),
                              // BUG-36: "Calendar" opens a real date-range picker
                              // (it was a dropdown of months).
                              _calendarButton(cubit, fromDate, toDate),
                              SizedBox(width: 8.w),
                              if (hasActiveFilters)
                                GestureDetector(
                                  onTap: () { cubit.clearAllFilters(); _searchController.clear(); },
                                  child: Container(
                                    height: 32.h, padding: EdgeInsets.symmetric(horizontal: 10.w),
                                    decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(4.r), border: Border.all(color: ColorPick.white)),
                                    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.clear, size: 12.sp, color: AppColors.secondaryText), SizedBox(width: 4.w), Text('Clear', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText))])),
                                  ),
                                ),
                            ], customButtonWithImage(title: 'Export', function: () => _showExportDialog(inquiries), textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white), height: 32.h, space: 4.w, radius: 6, color: ColorPick.primary, image: 'assets/images/export.svg', widthImage: 14.sp, heightImage: 14.sp, colorBorder: ColorPick.primary, svgColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 10.w))),
                            SizedBox(height: 16.h),

                            // ── Table ──
                            _buildTable(inquiries),
                            SizedBox(height: 40.h),

                            // ── Charts title ──
                            Text('Dashboard', style: StyleText.fontSize24Weight600.copyWith(color: ColorPick.primary, fontWeight: FontWeight.w700)),
                            SizedBox(height: 16.h),

                            // Row 1 — Bar chart + Entity Types
                            AdminCardsRow(stretch: true, gap: 16.w, children: [ // BUG-16
                              _chartCard('Submission Received', 'Total: $totalCount', _buildBarChart(monthlySubmissions)),
                              _chartCard('Entity Types', '', _buildEntityTypeChart(entityTypeCounts)),
                            ]),
                            SizedBox(height: 16.h),

                            // Row 2 — Entity Size + Location
                            AdminCardsRow(stretch: true, gap: 16.w, children: [ // BUG-16
                              _chartCard('Entity Size Distribution', '', _buildSizeStackedBar(entitySizeCounts)),
                              _chartCard('Location Distribution', '', _buildLocationChart(locationCounts)),
                            ]),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ],
),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CALENDAR (date range) — BUG-36
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _calendarButton(InquiryCubit cubit, DateTime? from, DateTime? to) {
    String f(DateTime d) => '${d.day}/${d.month}/${d.year}';
    final bool active = from != null || to != null;
    return GestureDetector(
      onTap: () async {
        // BUG-153: same dialog-size picker and rules as Applications.
        final picked = await showAdminDateRangePicker(
          context,
          initial: (from != null && to != null)
              ? DateTimeRange(start: from, end: to)
              : null,
        );
        if (picked != null) cubit.setDateRange(picked.start, picked.end);
      },
      child: Container(
        // Same height as the Status / Entity Type / Location dropdowns next
        // to it: their box is 12.h padding top + bottom around the 20.sp
        // arrow icon.
        height: 24.h + 20.sp,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: ColorPick.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active
                  ? '${from != null ? f(from) : '…'} – ${to != null ? f(to) : '…'}'
                  : 'Calendar',
              style: TextStyle(
                  fontSize: 11.sp,
                  color: active ? AppColors.text : AppColors.secondaryText),
            ),
            SizedBox(width: 12.w),
            // App calendar icon (same SVG as Applicant Details / filters).
            CustomSvg(
              assetPath: 'assets/images/calender.svg',
              width: 16.w,
              height: 16.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// BUG-16: the filter bar is one row on desktop; on a phone the dropdowns
  /// wrap onto several lines and Export sits on its own line.
  Widget _filtersLayout(BuildContext context, List<Widget> filters, Widget export) {
    if (!AdminLayout.isPhone(context)) {
      return Row(children: [...filters, const Spacer(), export]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: filters.where((w) => !(w is SizedBox && w.child == null)).toList(),
        ),
        const SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerEnd, child: export),
      ],
    );
  }

  Widget _summaryCard(String title, int count, Color topColor) {
    return Container(
      decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(8.r)),
      child: Column(children: [
        Container(height: 4.h, decoration: BoxDecoration(color: topColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(8.r), topRight: Radius.circular(8.r)))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.text)),
            Text('$count', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: const Color(0xFF3C3C43))), // Figma
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TABLE
  // ═══════════════════════════════════════════════════════════════════════════

  final _headers = const [
    'No', 'Submission Date', 'Preferred Language', 'First Name', 'Last Name',
    'Email', 'Country Code', 'Phone Number', 'Location', 'Entity Name',
    'Entity Type', 'Entity Size', 'Subject', 'Message', 'Note', 'Status',
  ];

  // BUG-24: flexible widths — each column fits its content (header or
  // values) between a minimum and a cap, instead of fixed widths that left a
  // big gap after short columns such as "Email".
  // [min, cap] per column, in logical pixels (scaled with .sp below).
  static const List<List<double>> _columnBounds = [
    [40, 60],   [100, 130], [110, 150], [80, 160],  [80, 160],  [120, 240],
    [80, 110],  [100, 150], [80, 160],  [100, 200], [90, 180],  [80, 120],
    [100, 220], [120, 260], [100, 220], [70, 110],
  ];

  Map<int, TableColumnWidth> get _flexColumnWidths => {
        for (int i = 0; i < _columnBounds.length; i++)
          i: MaxColumnWidth(
            FixedColumnWidth(_columnBounds[i][0].sp),
            MinColumnWidth(
              const IntrinsicColumnWidth(),
              FixedColumnWidth(_columnBounds[i][1].sp),
            ),
          ),
      };

  TextStyle get _cellStyle => TextStyle(fontSize: 11.sp, color: AppColors.text);
  Widget _cell(Widget child) => Container(padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp), child: DefaultTextStyle.merge(style: _cellStyle, child: child));
  Widget _textCell(String text, {int maxLines = 2}) => _cell(Text(text.isEmpty ? '-' : text, maxLines: maxLines, overflow: TextOverflow.ellipsis));

  Widget _buildTable(List<InquiryModel> inquiries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTableGrid(inquiries),
        // BUG-24: an empty table used to be just a header row.
        if (inquiries.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(4.r),
              ),
            ),
            alignment: Alignment.center,
            child: Text('No inquiries yet',
                style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText)),
          ),
      ],
    );
  }

  Widget _buildTableGrid(List<InquiryModel> inquiries) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: Table(
          border: TableBorder.all(color: Colors.transparent),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: _flexColumnWidths,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: ColorPick.primary),
              children: _headers.map((h) => Padding(padding: EdgeInsets.all(10.sp), child: Text(h, maxLines: 1, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.white)))).toList(),
            ),
            ...List.generate(inquiries.length, (index) {
              final i = inquiries[index];
              final rowColor = index.isEven ? const Color(0xFFF7F8FA) : Colors.white;
              final dateStr = i.submissionDate != null ? '${i.submissionDate!.day}/${i.submissionDate!.month}/${i.submissionDate!.year}' : '-';
              final cells = [
                _textCell('${index + 1}', maxLines: 1), _textCell(dateStr, maxLines: 1),
                _textCell(i.preferredLanguage, maxLines: 1), _textCell(i.firstName),
                _textCell(i.lastName), _textCell(i.email), _textCell(i.countryCode, maxLines: 1),
                _textCell(i.phone), _textCell(i.location), _textCell(i.entityName),
                _textCell(i.entityType), _textCell(i.entitySize, maxLines: 1),
                _textCell(i.subject), _textCell(i.message, maxLines: 1), _textCell(i.note, maxLines: 1),
                _cell(Text(i.status.label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: i.status.color))),
              ];
              return TableRow(
                decoration: BoxDecoration(color: rowColor),
                children: cells.map((cell) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<InquiryCubit>(), child: InquiryDetailPage(inquiryId: i.id)))), child: cell)).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CHART CARD WRAPPER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _chartCard(String title, String subtitle, Widget chart) {
    return Container(
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,        // ← shrink to content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: ColorPick.primary)),
          if (subtitle.isNotEmpty) ...[SizedBox(height: 4.h), Text(subtitle, style: TextStyle(fontSize: 11.sp, color: AppColors.text))],
          SizedBox(height: 12.h),
          chart,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BAR CHART — values rotated inside bars (Figma style)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBarChart(Map<int, int> monthly) {
    // BUG-151: bare axes with no inquiries → the shared empty state.
    if (monthly.values.every((v) => v <= 0)) return _emptyChart();
    final maxVal = monthly.values.fold(1, (a, b) => a > b ? a : b);
    const maxBarH = 130.0;
    const labelH  = 16.0; // reserved height above every bar for the label

    return SizedBox(
      height: 175.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final val  = monthly[i + 1] ?? 0;
          final barH = maxVal > 0 ? (val / maxVal) * maxBarH : 0.0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // value label always above bar (empty string when 0 so space is consistent)
                  SizedBox(
                    height: labelH.h,
                    child: val > 0
                        ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        '$val',
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        : const SizedBox(),
                  ),
                  // bar itself
                  Container(
                    height: barH.h,
                    decoration: BoxDecoration(
                      color: val > 0 ? ColorPick.primary : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft:  Radius.circular(3.r),
                        topRight: Radius.circular(3.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(_kMonthNames[i], style: TextStyle(fontSize: 8.sp, color: AppColors.secondaryText)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ENTITY TYPES — 2-col grid, label left + % right, green progress bar
  //  Matches Figma: name | pct% on one line, bar underneath, divider between rows
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEntityTypeChart(Map<String, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);
    // BUG-24: empty state instead of a blank white card.
    if (total == 0) return _emptyChart();
    final entries = counts.entries.toList();
    final half = (entries.length / 2).ceil();
    final left  = entries.take(half).toList();
    final right = entries.skip(half).toList();
    final rows  = max(left.length, right.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (idx) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (idx < left.length)  Expanded(child: _entityTypeItem(left[idx],  total))
              else                    const Expanded(child: SizedBox()),
              SizedBox(width: 16.w),
              if (idx < right.length) Expanded(child: _entityTypeItem(right[idx], total))
              else                    const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _entityTypeItem(MapEntry<String, int> e, int total) {
    final pct = total > 0 ? (e.value / total * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // label + percentage on same row (like Figma)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                e.key,
                style: TextStyle(fontSize: 10.sp, color: AppColors.text),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        // progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: Container(
            height: 7.h,
            color: Colors.white,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (pct / 100).clamp(0.0, 1.0),
              child: Container(color: ColorPick.primary),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ENTITY SIZE — legend row with dot + label + bold count, stacked bar
  //  Matches Figma: dots in a row, then one stacked horizontal bar below
  // ═══════════════════════════════════════════════════════════════════════════

  // All possible entity size categories in display order
  static const List<String> _kAllEntitySizes = [
    '1 to 50',
    '51 to 150',
    '151 to 500',
    '501 to 750',
    '+750',
  ];

  Widget _buildSizeStackedBar(Map<String, int> counts) {
    // Merge with all predefined sizes so zeros show up
    final allCounts = <String, int>{
      for (final size in _kAllEntitySizes) size: counts[size] ?? 0,
      // also keep any extra keys not in predefined list
      for (final e in counts.entries)
        if (!_kAllEntitySizes.contains(e.key)) e.key: e.value,
    };

    final keys   = allCounts.keys.toList();
    final colors = _sizeColors(keys.length);
    final total  = allCounts.values.fold(0, (a, b) => a + b);
    final bool noData = total == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend row
        Wrap(
          spacing: 20.w,
          runSpacing: 10.h,
          children: List.generate(keys.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 10.sp, height: 10.sp,
                  decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                ),
                SizedBox(width: 5.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(keys[i],                   style: TextStyle(fontSize: 9.sp,  color: AppColors.text, fontWeight: FontWeight.w400)),
                    Text('${allCounts[keys[i]]}',   style: TextStyle(fontSize: 12.sp, color: AppColors.text, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            );
          }),
        ),
        SizedBox(height: 16.h),
        // Stacked horizontal bar — an empty grey track when there is no data
        // (it used to draw five equal coloured parts).
        if (noData)
          Container(
            height: 24.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4.r),
            ),
            alignment: Alignment.center,
            child: Text('No data yet',
                style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText)),
          )
        else
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: SizedBox(
            height: 24.h,
            child: Row(
              children: List.generate(keys.length, (i) {
                // if all zeros give each equal flex so bar still renders
                final flex = total > 0 ? (allCounts[keys[i]] ?? 0) : 1;
                return Flexible(
                  flex: flex == 0 ? 0 : flex,
                  child: flex == 0
                      ? const SizedBox()
                      : Container(color: colors[i]),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _sizeColors(int count) {
    final palette = [
      ColorPick.primary,
      ColorPick.primary.withValues(alpha: 0.8),
      ColorPick.primary.withValues(alpha: 0.6),
      ColorPick.primary.withValues(alpha: 0.4),
      ColorPick.primary.withValues(alpha: 0.2),
    ];
    return List.generate(count, (i) => palette[i % palette.length]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOCATION DISTRIBUTION — dual-tone vertical bars (Figma style)
  //  Full-height light bg, dark green fills from bottom proportionally
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _emptyChart() => SizedBox(
        height: 160.h,
        width: double.infinity,
        child: Center(
          child: Text(
            'No inquiries yet', // BUG-151: same wording as the table
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText),
          ),
        ),
      );

  Widget _buildLocationChart(Map<String, int> counts) {
    if (counts.isEmpty) {
      // Keep the same footprint as the populated chart so the card
      // doesn't collapse when there's no data.
      return SizedBox(
        height: 160.h,
        width: double.infinity,
        child: Center(
          child: Text(
            'No data',
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText),
          ),
        ),
      );
    }
    final total    = counts.values.fold(0, (a, b) => a + b);
    const barH     = 120.0; // total bar height in logical pixels

    return SizedBox(
      height: 160.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: counts.entries.map((e) {
          final pct    = total > 0 ? (e.value / total * 100).round() : 0;
          final fillH  = (pct / 100) * barH;
          final emptyH = barH - fillH;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // full bar = light top + dark bottom
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // light (empty) portion on top
                        Container(height: emptyH.h, color: ColorPick.primary.withValues(alpha: .5)),
                        // dark (filled) portion on bottom
                        Container(height: fillH.h,  color: ColorPick.primary),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text('$pct%', style: TextStyle(fontSize: 8.sp, color: AppColors.text, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  Text(e.key, style: TextStyle(fontSize: 7.sp, color: AppColors.secondaryText), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PIE CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════════
