part of '../../pages/job_listing_detail.dart';

class _DashboardTab extends StatelessWidget {
  final JobPostModel job;
  final List<ApplicationModel> applications;
  final bool loading;
  const _DashboardTab({
    required this.job,
    required this.applications,
    required this.loading,
  });

  int get _total => applications.length;
  int get _qualified =>
      applications.where((a) => a.status == ApplicationStatus.qualified).length;
  int get _unqualified => applications
      .where((a) => a.status == ApplicationStatus.unqualified)
      .length;
  /// Still sitting on "Applied" (not yet screened). Kept for readability —
  /// the funnel's Applied stage counts EVERY application, not just these.
  // ignore: unused_element
  int get _applied =>
      applications.where((a) => a.status == ApplicationStatus.applied).length;
  int get _interviewPassed => applications
      .where((a) => a.status == ApplicationStatus.interviewPassed)
      .length;
  int get _interviewFailed => applications
      .where((a) => a.status == ApplicationStatus.interviewFailed)
      .length;
  int get _interviewWithdrew => applications
      .where((a) => a.status == ApplicationStatus.interviewWithdrew)
      .length;
  int get _offerApproved => applications
      .where((a) => a.status == ApplicationStatus.offerApproved)
      .length;
  int get _offerPending => applications
      .where((a) => a.status == ApplicationStatus.offerPending)
      .length;
  int get _offerRejected => applications
      .where((a) => a.status == ApplicationStatus.offerRejected)
      .length;
  int get _hired =>
      applications.where((a) => a.status == ApplicationStatus.hired).length;
  // ── Funnel stages: "reached", not "currently sitting on" ──────────────────
  // An application stores ONE current status. Someone now `hired` is no longer
  // `offerApproved`, no longer `interviewPassed`, no longer `applied` — so
  // counting each stage by exact status makes every earlier stage read 0 while
  // Hired reads 1, which is impossible in a funnel. These helpers count who
  // reached a stage, including everyone who has since moved past it.
  static const Set<ApplicationStatus> _interviewStatuses = {
    ApplicationStatus.interviewPassed,
    ApplicationStatus.interviewFailed,
    ApplicationStatus.interviewWithdrew,
  };
  static const Set<ApplicationStatus> _offerStatuses = {
    ApplicationStatus.offerApproved,
    ApplicationStatus.offerPending,
    ApplicationStatus.offerRejected,
  };

  bool _isHired(ApplicationModel a) => a.status == ApplicationStatus.hired;

  /// Got an offer (or was hired, which requires one).
  bool _reachedOffer(ApplicationModel a) =>
      _offerStatuses.contains(a.status) || _isHired(a);

  /// Was interviewed (or got past the interview to an offer / hire).
  bool _reachedInterview(ApplicationModel a) =>
      _interviewStatuses.contains(a.status) || _reachedOffer(a);

  /// Passed the interview — explicitly, or implicitly by receiving an offer.
  bool _passedInterview(ApplicationModel a) =>
      a.status == ApplicationStatus.interviewPassed || _reachedOffer(a);

  /// Approved their offer — explicitly, or implicitly by being hired.
  bool _approvedOffer(ApplicationModel a) =>
      a.status == ApplicationStatus.offerApproved || _isHired(a);

  int get _appliedStage => applications.length; // everyone applied
  int get _interviewStage => applications.where(_reachedInterview).length;
  int get _offerStage => applications.where(_reachedOffer).length;

  Map<int, int> get _appsByMonth {
    final map = <int, int>{};
    for (final a in applications) {
      if (a.applicationDate != null) {
        final month = a.applicationDate!.month;
        map[month] = (map[month] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<String, int> get _scoreDistribution {
    int poor = 0, weak = 0, good = 0, veryGood = 0, excellent = 0;
    for (final a in applications) {
      final avg =
      (a.technicalSkills +
          a.communicationSkills +
          a.experienceBackground +
          a.cultureFit +
          a.leadershipPotential);
      if (avg == 0) continue;
      final score = avg / 5.0;
      if (score <= 1)
        poor++;
      else if (score <= 2)
        weak++;
      else if (score <= 3)
        good++;
      else if (score <= 4)
        veryGood++;
      else
        excellent++;
    }
    return {
      'Poor': poor,
      'Weak': weak,
      'Good': good,
      'Very Good': veryGood,
      'Excellent': excellent,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.sp),
          child: const CircleProgress(),
        ),
      );
    if (applications.isEmpty)
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.sp),
          child: Text(
            'No applications yet for this job.',
            style: StyleText.fontSize14Weight400.copyWith(fontSize: 14.sp, color: AppColors.secondaryText),
          ),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartRow(
          left: _buildApplicationsReceived(),
          right: _buildCandidateClassification(),
        ),
        SizedBox(height: 16.h),
        _chartRow(left: _buildHiringStage(), right: _buildInterviewStage()),
        SizedBox(height: 16.h),
        _chartRow(
          left: _buildJobOffer(),
          right: _buildScoreDistributionChart(),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _chartRow({required Widget left, required Widget right}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      SizedBox(width: 16.w),
      Expanded(child: right),
    ],
  );

  Widget _buildApplicationsReceived() {
    final labels = [
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
    final byMonth = _appsByMonth;
    final values = List.generate(12, (i) => (byMonth[i + 1] ?? 0).toDouble());
    // Same nice axis scale as careers_charts.dart — small steps (0, 2, 4…).
    final maxY = _niceMax(values);
    final interval = _niceInterval(maxY);
    return _card(
      title: 'Applications Received',
      subtitle: 'Total: ${_fmtNum(_total)}',
      height: 280,
      child: Expanded(
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: values
                .asMap()
                .entries
                .map(
                  (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    width: 14.sp,
                    color: _Ch.green,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ],
                showingTooltipIndicators: e.value > 0 ? [0] : [],
              ),
            )
                .toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35.sp,
                  interval: interval,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: StyleText.fontSize14Weight400.copyWith(fontSize: 9.sp, color: Colors.grey.shade800),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22.sp,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    return i >= 0 && i < 12
                        ? Text(
                      labels[i],
                      style: StyleText.fontSize8Weight400.copyWith(
                        fontSize: 8.sp,
                        color: Colors.grey.shade800,
                      ),
                    )
                        : const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEFF3F9), strokeWidth: 1),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipColor: (_) => Colors.transparent,
                tooltipBorder: BorderSide.none,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  rod.toY.toInt().toString(),
                  StyleText.fontSize14Weight400.copyWith(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: _Ch.darkGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateClassification() {
    final qualifiedCount =
        _qualified + _interviewPassed + _offerApproved + _offerPending + _hired;
    final unqualifiedCount =
        _unqualified + _interviewFailed + _interviewWithdrew + _offerRejected;
    final totalClassified = qualifiedCount + unqualifiedCount;
    final qPct = totalClassified > 0
        ? (qualifiedCount / totalClassified * 100).round()
        : 0;
    final uPct = totalClassified > 0 ? 100 - qPct : 0;
    return _card(
      title: 'Candidate Classification',
      height: 280,
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendRow(_Ch.green, '$qPct%', 'Qualified'),
                  SizedBox(height: 12.h),
                  _legendRow(_Ch.grey, '$uPct%', 'Unqualified'),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 44.sp,
                      sections: [
                        PieChartSectionData(
                          value: qualifiedCount.toDouble().clamp(
                            0.1,
                            double.infinity,
                          ),
                          color: _Ch.green,
                          radius: 30.sp,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: unqualifiedCount.toDouble().clamp(
                            0.1,
                            double.infinity,
                          ),
                          color: _Ch.grey,
                          radius: 30.sp,
                          title: '',
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total\nApplication',
                        textAlign: TextAlign.center,
                        style: StyleText.fontSize14Weight400.copyWith(fontSize: 9.sp, color: Colors.black87),
                      ),
                      Text(
                        _fmtNum(_total),
                        style: StyleText.fontSize16Weight700.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHiringStage() {
    // ── Rejected = unqualified + interview failed + offer rejected + interview withdrew
    final rejected = _unqualified + _interviewFailed + _offerRejected + _interviewWithdrew;

    final stages = [
      _FunnelItem('Applied', _appliedStage, ColorPick.primary),
      _FunnelItem('Interviewed', _interviewStage, ColorPick.primary.withValues(alpha: 0.8)),
      _FunnelItem('Rejected', rejected, ColorPick.primary.withValues(alpha: 0.6)),
      _FunnelItem('Offer Sent', _offerStage, ColorPick.primary.withValues(alpha: 0.4)),
      _FunnelItem('Hired', _hired, ColorPick.primary.withValues(alpha: 0.2)),
    ];

    final maxVal = stages
        .map((s) => s.value)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 999999);

    return _card(
      title: 'Hiring Stage',
      height: 280,
      child: Expanded(
        child: Row(
          children: [
            // ── Legend column ──
            SizedBox(
              width: 100.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stages
                    .map(
                      (s) => Padding(
                    padding: EdgeInsets.only(bottom: 10.sp),
                    child: Row(
                      children: [
                        Container(
                          width: 10.sp,
                          height: 10.sp,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.color,
                          ),
                        ),
                        SizedBox(width: 6.sp),
                        Expanded(
                          child: Text(
                            s.label,
                            style: StyleText.fontSize10Weight400.copyWith(
                              fontSize: 10.sp,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
            // ── Funnel bars (centered, decreasing width) ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fullWidth = constraints.maxWidth;
                  // Each stage gets a fraction of the max width,
                  // decreasing from top to bottom (funnel effect)
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(stages.length, (i) {
                      // Funnel: width decreases linearly from 100% to ~30%
                      final funnelFraction =
                          1.0 - (i / (stages.length)) * 0.7;
                      final barWidth = fullWidth * funnelFraction;
                      final barHeight = 32.sp;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.sp),
                        child: ClipPath(
                          clipper: _TrapezoidClipper(
                            // Next stage width ratio for trapezoid bottom
                            bottomWidthFraction: i < stages.length - 1
                                ? (1.0 -
                                ((i + 1) / (stages.length)) * 0.7)
                                : (1.0 - (i / (stages.length)) * 0.7) *
                                0.85,
                            topWidthFraction: funnelFraction,
                          ),
                          child: Container(
                            width: fullWidth,
                            height: barHeight,
                            color: stages[i].color,
                            child: Center(
                              child: Text(
                                _fmtNum(stages[i].value),
                                style: StyleText.fontSize11Weight600.copyWith(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewStage() {
    // "Passed" includes everyone who moved on to an offer or a hire — they
    // cannot have reached those stages without passing the interview.
    final passed = applications.where(_passedInterview).length;
    final failed = _interviewFailed;
    final withdrew = _interviewWithdrew;
    final total = passed + failed + withdrew; // = everyone who was interviewed
    final pPct = total > 0 ? (passed / total * 100).round() : 0;
    final fPct = total > 0 ? (failed / total * 100).round() : 0;
    final wPct = total > 0 ? 100 - pPct - fPct : 0;
    return _card(
      title: 'Interview Stage',
      height: 280,
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendRow(_Ch.green, '$pPct%', 'Passed'),
                  SizedBox(height: 8.h),
                  _legendRow(_Ch.lightGreen, '$fPct%', 'Failed'),
                  SizedBox(height: 8.h),
                  _legendRow(_Ch.grey, '$wPct%', 'Candidate Withdrew'),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  sections: [
                    PieChartSectionData(
                      value: passed.toDouble().clamp(0.1, double.infinity),
                      color: _Ch.green,
                      radius: 60.sp,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: failed.toDouble().clamp(0.1, double.infinity),
                      color: _Ch.lightGreen,
                      radius: 60.sp,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: withdrew.toDouble().clamp(0.1, double.infinity),
                      color: _Ch.grey,
                      radius: 60.sp,
                      title: '',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobOffer() {
    // A hired candidate approved their offer — their status simply moved on.
    final approved = applications.where(_approvedOffer).length;
    final items = [
      _PieItem('Approved', approved.toDouble(), ColorPick.activeColor),
      // Pending = orange (yellow read as another shade of the same state).
      _PieItem('Pending', _offerPending.toDouble(), _Ch.orange),
      _PieItem('Rejected', _offerRejected.toDouble(), _Ch.red),
    ];
    final sum = approved + _offerPending + _offerRejected;
    return _card(
      title: 'Job Offer',
      height: 280,
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Padding(
                    padding: EdgeInsets.only(bottom: 8.sp),
                    child: Row(
                      children: [
                        Container(
                          width: 10.sp,
                          height: 10.sp,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.color,
                          ),
                        ),
                        SizedBox(width: 6.sp),
                        Expanded(
                          child: Text(
                            item.label,
                            style: StyleText.fontSize11Weight400.copyWith(
                              fontSize: 11.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          _fmtNum(item.value.toInt()),
                          style: StyleText.fontSize11Weight600.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40.sp,
                      sections: items
                          .map(
                            (item) => PieChartSectionData(
                          value: item.value.clamp(0.1, double.infinity),
                          color: item.color,
                          radius: 28.sp,
                          title: '',
                        ),
                      )
                          .toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmtNum(sum),
                        style: StyleText.fontSize16Weight700.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Total',
                        style: StyleText.fontSize10Weight400.copyWith(
                          fontSize: 10.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistributionChart() {
    final dist = _scoreDistribution;
    final segments = [
      _ScoreSegment('Poor', dist['Poor'] ?? 0, _Ch.poor),
      _ScoreSegment('Weak', dist['Weak'] ?? 0, _Ch.weak),
      _ScoreSegment('Good', dist['Good'] ?? 0, _Ch.good),
      _ScoreSegment('Very Good', dist['Very Good'] ?? 0, _Ch.veryGood),
      _ScoreSegment('Excellent', dist['Excellent'] ?? 0, _Ch.excellent),
    ];
    final total = segments.fold<int>(0, (s, e) => s + e.value);
    return _card(
      title: 'Candidate Score Distribution',
      height: 280,
      child: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: segments
                  .map(
                    (s) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10.sp,
                      height: 10.sp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.color,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      s.label,
                      style: StyleText.fontSize14Weight400.copyWith(
                        fontSize: 9.sp,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _fmtNum(s.value),
                      style: StyleText.fontSize10Weight700.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
                  .toList(),
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Row(
                children: total > 0
                    ? segments
                    .map(
                      (s) => Flexible(
                    flex: s.value.clamp(1, 999999),
                    child: Container(height: 20.sp, color: s.color),
                  ),
                )
                    .toList()
                    : [
                  Expanded(
                    child: Container(
                      height: 20.sp,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required double height,
    required Widget child,
    String? subtitle,
  }) {
    final innerChild = child is Expanded ? child.child : child;
    return Container(
      height: height.h,
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StyleText.fontSize13Weight600.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: StyleText.fontSize11Weight400.copyWith(fontSize: 11.sp, color: Colors.black87),
            ),
          ],
          SizedBox(height: 10.h),
          Expanded(child: innerChild),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String percent, String label) => Row(
    children: [
      Container(
        width: 12.sp,
        height: 12.sp,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      SizedBox(width: 6.sp),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            percent,
            style: StyleText.fontSize14Weight700.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: StyleText.fontSize11Weight400.copyWith(fontSize: 11.sp, color: Colors.black87),
          ),
        ],
      ),
    ],
  );

  // ── Nice axis scale — same as careers_charts.dart ──────────────────────────
  double _niceMax(List<double> values) {
    if (values.isEmpty) return 10;
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    if (dataMax == 0) return 10;
    final intMax = dataMax.ceil();
    if (intMax <= 10) return 10;
    if (intMax <= 20) return 20;
    if (intMax <= 50) return ((intMax / 10).ceil() * 10).toDouble();
    if (intMax <= 100) return ((intMax / 20).ceil() * 20).toDouble();
    if (intMax <= 500) return ((intMax / 50).ceil() * 50).toDouble();
    return ((intMax / 100).ceil() * 100).toDouble();
  }

  double _niceInterval(double maxY) {
    if (maxY <= 5)   return 1;
    if (maxY <= 10)  return 2;
    if (maxY <= 20)  return 5;
    if (maxY <= 50)  return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    if (maxY <= 500) return 100;
    return (maxY / 5).ceilToDouble();
  }

  String _fmtNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
