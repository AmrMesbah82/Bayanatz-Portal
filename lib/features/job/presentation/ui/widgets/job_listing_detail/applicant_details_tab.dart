part of '../../pages/job_listing_detail.dart';

class _ApplicantDetailsTab extends StatefulWidget {
  final JobPostModel job;
  final List<ApplicationModel> applications;
  final bool loading;
  final VoidCallback onRefresh;
  const _ApplicantDetailsTab({
    required this.job,
    required this.applications,
    required this.loading,
    required this.onRefresh,
  });

  @override
  State<_ApplicantDetailsTab> createState() => _ApplicantDetailsTabState();
}

class _ApplicantDetailsTabState extends State<_ApplicantDetailsTab> {
  String? _stageFilter;
  String? _statusFilter;

  // ── Calendar filter state — stores selected date for month/year filtering ──
  DateTime? _selectedCalendarDate;

  late Map<String, bool> _columnVisibility;

  @override
  void initState() {
    super.initState();
    _columnVisibility = ColumnKey.defaultVisibility();
  }

  bool _isVisible(String key) => _columnVisibility[key] ?? true;
  // Applied Date is always shown first, before the other visible columns.
  List<String> get _visibleColumnKeys {
    final keys = ColumnKey.all.where((k) => _isVisible(k)).toList();
    if (keys.remove(ColumnKey.appliedDate)) {
      keys.insert(0, ColumnKey.appliedDate);
    }
    return keys;
  }

  static final List<Map<String, String>> _stageItems = [
    {'key': 'Applied', 'value': 'Applied'},
    {'key': 'Interview', 'value': 'Interview'},
    {'key': 'Offer', 'value': 'Offer'},
    {'key': 'Hired', 'value': 'Hired'},
  ];

  static final List<Map<String, String>> _statusItems = [
    {'key': 'Applied', 'value': 'Applied'},
    {'key': 'Qualified', 'value': 'Qualified'},
    {'key': 'Unqualified', 'value': 'Unqualified'},
    {'key': 'Interview: Passed', 'value': 'Passed'},
    {'key': 'Interview: Failed', 'value': 'Failed'},
    {'key': 'Interview: Withdrew', 'value': 'Withdrew'},
    {'key': 'Offer: Approved', 'value': 'Approved'},
    {'key': 'Offer: Pending', 'value': 'Pending'},
    {'key': 'Offer: Rejected', 'value': 'Rejected'},
    {'key': 'Hired: Completed', 'value': 'Completed'},
  ];

  static final Map<String, Color> _stageColors = {
    'Applied': const Color(0xFF2196F3),
    'Interview': const Color(0xFFFF9800),
    'Offer': const Color(0xFF9C27B0),
    'Hired': const Color(0xFF2E7D32),
  };

  static final Map<String, Color> _statusColors = {
    'Applied': const Color(0xFF2196F3),
    'Qualified': const Color(0xFF2E7D32),
    'Unqualified': const Color(0xFFD32F2F),
    'Interview: Passed': const Color(0xFF2E7D32),
    'Interview: Failed': const Color(0xFFD32F2F),
    'Interview: Withdrew': const Color(0xFF757575),
    'Offer: Approved': const Color(0xFF2E7D32),
    'Offer: Pending': const Color(0xFFFF9800),
    'Offer: Rejected': const Color(0xFFD32F2F),
    'Hired: Completed': const Color(0xFF2E7D32),
  };

  List<ApplicationModel> get _filtered {
    var result = widget.applications;
    if (_stageFilter != null)
      result = result.where((a) => a.status.stage == _stageFilter).toList();
    if (_statusFilter != null)
      result = result.where((a) => a.status.label == _statusFilter).toList();
    // ── Calendar date filter — filters by month & year of selected date ──
    if (_selectedCalendarDate != null) {
      final filterYear = _selectedCalendarDate!.year;
      final filterMonth = _selectedCalendarDate!.month;
      result = result.where((a) {
        if (a.applicationDate == null) return false;
        return a.applicationDate!.year == filterYear &&
            a.applicationDate!.month == filterMonth;
      }).toList();
    }
    return result;
  }

  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // ── Open DatePicker for calendar filter ──
  Future<void> _openCalendarPicker() async {
    final datePicker = DatePicker();
    final result = await datePicker.showDatePicker(
      context,
      _selectedCalendarDate != null ? [_selectedCalendarDate] : [],
      _selectedCalendarDate ?? DateTime.now(),
      CalendarDatePicker2Type.single,
    );
    if (result != null && result.isNotEmpty && result.first != null && mounted) {
      setState(() {
        _selectedCalendarDate = result.first;
      });
    }
  }

  // ── Format selected calendar date for display ──
  String get _calendarDisplayText {
    if (_selectedCalendarDate == null) return 'Calendar';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_selectedCalendarDate!.month - 1]} ${_selectedCalendarDate!.year}';
  }

  // ── Open table setting dialog — uses top-level showTableSettingDialog ──
  Future<void> _openTableSettingDialog() async {
    final result = await showTableSettingDialog(context, _columnVisibility);
    if (result != null && mounted) {
      setState(() => _columnVisibility = result);
    }
  }

  // ── Styles ──
  TextStyle get _headerStyle => StyleText.fontSize12Weight600.copyWith(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  TextStyle get _cellStyle =>
      StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: const Color(0xFF333333));

  Widget _cell(Widget child, {EdgeInsets? padding}) {
    return Container(
      padding:
      padding ?? EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp),
      child: DefaultTextStyle.merge(style: _cellStyle, child: child),
    );
  }

  Widget _textCell(String text, {int maxLines = 1}) {
    return _cell(
      Text(
        text.isEmpty ? '—' : text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: _cellStyle.copyWith(
          color: text.isEmpty
              ? const Color(0xFFAAAAAA)
              : const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _rowTapWrapper(Widget child, VoidCallback onTap) => child;
  Widget _statusBadgeCell(String status) {
    return _textCell(status);
  }

  Widget _stageCell(String stage) {
    Color color;
    switch (stage) {
      case 'Hired':
        color = const Color(0xFF2E7D32);
        break;
      case 'Interview':
        color = const Color(0xFFFF9800);
        break;
      case 'Offer':
        color = const Color(0xFF9C27B0);
        break;
      default:
        color = const Color(0xFF333333);
    }
    return _cell(
      Text(
        stage.isEmpty ? '—' : stage,
        style: _cellStyle.copyWith(color: color, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tagCell(String tag) {
    if (tag.isEmpty) return _textCell('');
    Color bg, fg;
    switch (tag.toLowerCase()) {
      case 'strong':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'adequate':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        break;
      case 'weak':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF757575);
    }
    return _cell(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          FormatHelper.capitalize(tag),
          style: StyleText.fontSize11Weight600.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// BUG-112: shows "View CV" / "View Cover Letter" instead of the raw
  /// https://firebasestorage… address.
  Widget _linkCell(String url, {String label = 'View file'}) {
    if (url.isEmpty) return _textCell('');
    return _cell(
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => html.window.open(url, '_blank'),
          child: Text(
            label,
            // Figma (Applicant Details table, 7126:76470): the Resume /
            // Cover Letter cells are plain cell text, not blue links.
            style: _cellStyle.copyWith(color: const Color(0xFF333333)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  double _calcWidth(
      List<ApplicationModel> apps,
      String Function(ApplicationModel) getter, {
        double minW = 100,
        double maxW = 280,
      }) {
    double maxLen = 0;
    for (var a in apps) {
      final val = getter(a);
      if (val.isNotEmpty) maxLen = math.max(maxLen, val.length.toDouble());
    }
    if (maxLen == 0) return minW.sp;
    return math.max(math.min((maxLen * 8.sp) + 20.sp, maxW.sp), minW.sp);
  }

  String _headerLabel(String key) => ColumnKey.labels[key] ?? key;

  Widget _cellForKey(String key, ApplicationModel a) {
    // Total of the five 1–5 degrees (max 25) shown as a percentage of 100.
    final totalScore =
    (a.technicalSkills +
        a.communicationSkills +
        a.experienceBackground +
        a.cultureFit +
        a.leadershipPotential);
    final scoreText =
        totalScore > 0 ? '${(totalScore / 25 * 100).round()}%' : '';
    switch (key) {
      case ColumnKey.firstName:
        return _textCell(FormatHelper.capitalize(a.firstName));
      case ColumnKey.lastName:
        return _textCell(FormatHelper.capitalize(a.lastName));
      case ColumnKey.email:
        return _textCell(a.email);
      case ColumnKey.code:
        return _textCell(a.countryCode);
      case ColumnKey.phone:
        return _textCell(a.phone);
      case ColumnKey.source:
        return _textCell(FormatHelper.capitalize(a.source));
      case ColumnKey.location:
        return _textCell(FormatHelper.capitalize(a.jobLocation));
      case ColumnKey.resume:
        return _linkCell(a.resumeUrl, label: 'View CV');
      case ColumnKey.coverLetter:
        return _linkCell(a.coverLetterUrl, label: 'View Cover Letter');
      case ColumnKey.status:
        return _statusBadgeCell(FormatHelper.capitalize(a.status.label));
      case ColumnKey.stage:
        return _stageCell(FormatHelper.capitalize(a.status.stage));
      case ColumnKey.score:
        return _textCell(scoreText);
      case ColumnKey.tags:
        return _tagCell(a.tag);
      case ColumnKey.appliedDate:
        return _textCell(_fmtDate(a.applicationDate));
      case ColumnKey.interviewDate:
        return _textCell(_fmtDate(a.interviewDate));
      case ColumnKey.lastUpdate:
        return _textCell(_fmtDate(a.lastUpdate));
      case ColumnKey.yearOfGraduation:
        return _textCell(a.yearOfGraduation);
      case ColumnKey.comment:
        return _textCell(a.comments, maxLines: 2);
      default:
        return _textCell('');
    }
  }

  double _widthForKey(String key, List<ApplicationModel> rows) {
    switch (key) {
      case ColumnKey.firstName:
        return _calcWidth(rows, (a) => a.firstName, minW: 100, maxW: 180);
      case ColumnKey.lastName:
        return _calcWidth(rows, (a) => a.lastName, minW: 100, maxW: 180);
      case ColumnKey.email:
        return _calcWidth(rows, (a) => a.email, minW: 160, maxW: 280);
      case ColumnKey.code:
        return 70.sp;
      case ColumnKey.phone:
        return _calcWidth(rows, (a) => a.phone, minW: 110, maxW: 180);
      case ColumnKey.source:
        return 110.sp;
      case ColumnKey.location:
        return _calcWidth(rows, (a) => a.jobLocation, minW: 110, maxW: 200);
      case ColumnKey.resume:
        return 140.sp;
      case ColumnKey.coverLetter:
        return 140.sp;
      case ColumnKey.status:
        return 120.sp;
      case ColumnKey.stage:
        return 100.sp;
      case ColumnKey.score:
        return 70.sp;
      case ColumnKey.tags:
        return 80.sp;
      case ColumnKey.appliedDate:
        return 120.sp;
      case ColumnKey.interviewDate:
        return 130.sp;
      case ColumnKey.lastUpdate:
        return 120.sp;
      case ColumnKey.yearOfGraduation:
        return 130.sp;
      case ColumnKey.comment:
        return _calcWidth(rows, (a) => a.comments, minW: 140, maxW: 280);
      default:
        return 100.sp;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading)
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.sp),
          child: const CircleProgress(),
        ),
      );

    final rows = _filtered;
    final visibleKeys = _visibleColumnKeys;

    final columnWidths = <int, TableColumnWidth>{0: FixedColumnWidth(50.sp)};
    for (int i = 0; i < visibleKeys.length; i++) {
      columnWidths[i + 1] = FixedColumnWidth(
        _widthForKey(visibleKeys[i], rows),
      );
    }
    // Total table width — used so the empty-state panel spans the full table.
    final double tableWidth = 50.sp +
        visibleKeys.fold<double>(0, (sum, k) => sum + _widthForKey(k, rows));
    final headerLabels = <String>[
      'No',
      ...visibleKeys.map((k) => _headerLabel(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filter row ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 160.w,
              child: CustomDropdownFormFieldInvMaster(
                selectedValue: _statusFilter,
                items: _statusItems,
                widthIcon: 18,
                dropdownColor: Colors.white,
                heightIcon: 18,
                height: 36,
                hint: Text(
                  'Status',
                  style: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
                ),
                itemColors: _statusColors,
                showColorDots: true,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ),
            SizedBox(width: 12.w),
            SizedBox(
              width: 160.w,
              child: CustomDropdownFormFieldInvMaster(
                selectedValue: _stageFilter,
                items: _stageItems,
                widthIcon: 18,
                heightIcon: 18,
                dropdownColor: Colors.white,
                height: 36,
                hint: Text(
                  'Stage',
                  style: StyleText.fontSize12Weight400.copyWith(fontSize: 12.sp, color: AppColors.secondaryText),
                ),
                itemColors: _stageColors,
                showColorDots: true,
                onChanged: (v) => setState(() => _stageFilter = v),
              ),
            ),
            const Spacer(),
            // ── CALENDAR BUTTON — opens DatePicker dialog ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openCalendarPicker,
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  height: 36.h,
                  width: 160.w,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),

                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _calendarDisplayText,
                          style: StyleText.fontSize12Weight400.copyWith(
                            fontSize: 12.sp,
                            color: _selectedCalendarDate != null
                                ? AppColors.text
                                : AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      if (_selectedCalendarDate != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCalendarDate = null;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      if (_selectedCalendarDate == null)
                        CustomSvg(assetPath: "assets/images/calender.svg",width: 16.w,height: 16.h,fit: BoxFit.fill,)
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // ── TABLE SETTING BUTTON — uses Material InkWell for reliable tap on Web ──
            Material(
              color: ColorPick.primary,
              borderRadius: BorderRadius.circular(6.r),
              child: InkWell(
                onTap: _openTableSettingDialog,
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  width: 200.w,
                  height: 36.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Center(
                    child: Text(
                      'Table Setting',
                      style: StyleText.fontSize12Weight600.copyWith(
                        fontSize: 12.sp,
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
        SizedBox(height: 10.h),

        Align(
          alignment: Alignment.centerRight,
          child: customButtonWithImage(
            title: 'Export',
            function: () => showJobListingExportDialog(
              context,
              job: widget.job,
              applications: _filtered,
            ),
            textStyle: StyleText.fontSize12Weight600.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            height: 36.h,
            width: 135.w,
            space: 6.w,
            radius: 6.r,
            color: ColorPick.primary,
            image: 'assets/images/export.svg',
            widthImage: 16.sp,
            heightImage: 16.sp,
            colorBorder: Colors.transparent,
            svgColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
        ),
        SizedBox(height: 16.h),

        // ── TABLE — BUG-112: columns after "Resume" were cut off and the
        // scrollbar was hidden; it is now always visible.
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Table(
                  border: TableBorder.all(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: columnWidths,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: ColorPick.primary),
                      children: headerLabels
                          .map(
                            (name) => Padding(
                          padding: EdgeInsets.all(10.sp),
                          child: Text(
                            name,
                            style: _headerStyle,
                            maxLines: 1,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      )
                          .toList(),
                    ),

                    ...List.generate(rows.length, (index) {
                      final a = rows[index];
                      final rowColor = index.isEven
                          ? const Color(0xFFF7F8FA)
                          : Colors.white;

                      VoidCallback goDetails = () {};

                      final cells = <Widget>[
                        _textCell('${index + 1}'),
                        ...visibleKeys.map((key) => _cellForKey(key, a)),
                      ];

                      return TableRow(
                        decoration: BoxDecoration(color: rowColor),
                        children: cells
                            .map((cell) => _rowTapWrapper(cell, goDetails))
                            .toList(),
                      );
                    }),
                  ],
                ),

                    // ── Empty state — full-width panel under the header ──
                    if (rows.isEmpty)
                      Container(
                        width: tableWidth,
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 30.sp),
                        alignment: Alignment.center,
                        child: Text(
                          'No applicants match the selected filters.',
                          style: StyleText.fontSize13Weight400.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED — Section card (for Tab 1)
// ═════════════════════════════════════════════════════════════════════════════
