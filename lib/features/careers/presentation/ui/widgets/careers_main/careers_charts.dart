part of '../../pages/careers_main.dart';

extension _CareersCharts on _CareersMainPageDashboardState {
  Widget _chartRow({required Widget left, required Widget right}) {
    // BUG-06: charts stack one per row on a phone (titles used to wrap one
    // letter per line in half-width cards).
    if (AdminLayout.isPhone(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          if (right is! SizedBox) ...[SizedBox(height: 16.h), right],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: 16.w),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildApplicationsReceivedChart(CareersDashboardData dash) {
    // BUG-151: one empty-state style for every chart.
    if (dash.appReceivedValues.every((v) => v <= 0)) {
      return _chartCard(
        title: 'Applications Received',
        height: 280,
        child: Expanded(child: _emptyState('No applications yet')),
      );
    }
    return _chartCard(
      title: 'Applications Received',
      subtitle: '',
      height: 280,
      child: Expanded(
        child: BarChart(
          BarChartData(
            maxY: _niceMax(dash.appReceivedValues),
            alignment: BarChartAlignment.spaceAround,
            barGroups: dash.appReceivedValues.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    width: 18.sp,
                    color: ColorPick.primary,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ],
                showingTooltipIndicators: e.value > 0 ? [0] : [],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24.sp,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i >= 0 && i < dash.appReceivedLabels.length) {
                      return Text(dash.appReceivedLabels[i],
                          style: StyleText.fontSize10Weight400.copyWith(fontSize: 9.sp, color: Colors.grey.shade800));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: false,
              drawVerticalLine: false,
              horizontalInterval: _niceInterval(_niceMax(dash.appReceivedValues)),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: const Color(0xFFEFF3F9), strokeWidth: 1),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4.sp,
                getTooltipColor: (_) => Colors.transparent,
                tooltipBorder: BorderSide.none,
                getTooltipItem: (group, _, rod, __) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    StyleText.fontSize10Weight500.copyWith(
                        fontWeight: FontWeight.w600, color: AppColors.text),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobPostingStatusChart(CareersDashboardData dash) {
    final legends = [
      _LegendItem('Active', ColorPick.activeColor),
      _LegendItem('Closed', ColorPick.red),
      _LegendItem('Scheduled', ColorPick.scheduled),
      _LegendItem('Draft', ColorPick.draftColor),
    ];
    // BUG-21: one bar per STATUS, coloured like the legend.
    final barColors = [
      ColorPick.activeColor,
      ColorPick.red,
      ColorPick.scheduled,
      ColorPick.draftColor,
    ];
    final totals = List<double>.generate(
      dash.jobPostingLabels.length,
      (i) =>
          dash.jobPostingActive[i] +
          dash.jobPostingClosed[i] +
          dash.jobPostingScheduled[i] +
          dash.jobPostingDraft[i],
    );
    final maxY = _niceMax(totals);
    // BUG-151: bare 0 / 1 axes → the shared empty state.
    if (totals.every((t) => t <= 0)) {
      return _chartCard(
        title: 'Job Posting Status',
        height: 280,
        child: Expanded(child: _emptyState('No jobs yet')),
      );
    }

    return _chartCard(
      title: 'Job Posting Status',
      height: 280,
      legendItems: legends,
      child: Expanded(
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            barGroups: List.generate(dash.jobPostingLabels.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: totals[i],
                    width: 22.sp,
                    color: barColors[i % barColors.length],
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35.sp,
                  interval: _niceInterval(maxY),
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: StyleText.fontSize10Weight400
                          .copyWith(color: Colors.grey.shade800)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24.sp,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i >= 0 && i < dash.jobPostingLabels.length) {
                      return Text(dash.jobPostingLabels[i],
                          style: StyleText.fontSize10Weight400.copyWith(fontSize: 9.sp, color: Colors.grey.shade800));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _niceInterval(maxY),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: const Color(0xFFEFF3F9), strokeWidth: 1),
            ),
            barTouchData: BarTouchData(enabled: false),
          ),
        ),
      ),
    );
  }

  Widget _buildHiringStageChart(CareersDashboardData dash) {
    return SizedBox(
      height: 280.h,
      child: FunnelChartWidget(
        title: 'Hiring Stage',
        titleColor: ColorPick.primary,
        items: dash.hiringStages
            .map((s) => FunnelChartItem(label: s.label, value: s.value))
            .toList(),
        lightMode: true,
        height: 280,
      ),
    );
  }

  Widget _buildJobStatusChart(CareersDashboardData dash) {
    final statusColors = {
      'Active': ColorPick.primary,
      'Scheduled': ColorPick.primary.withOpacity(0.7),
      'Closed': ColorPick.primary.withOpacity(0.4),
      'Draft': ColorPick.primary.withOpacity(0.2),
    };
    // BUG-38: percentages are part / total of the slices (they could read
    // "100%, 100%, 200%"), the centre says "Total Jobs", and an empty dataset
    // shows an empty state instead of a fake "No Data — 1" slice.
    final sliceTotal =
        dash.jobStatus.values.fold<double>(0, (s, v) => s + v);
    if (sliceTotal <= 0) {
      return _chartCard(
        title: 'Job Status',
        height: 280,
        child: Expanded(child: _emptyState('No jobs yet')),
      );
    }
    final total = sliceTotal;

    return _chartCard(
      title: 'Job Status',
      height: 280,
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dash.jobStatus.entries.map((e) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.sp),
                    child: Row(
                      children: [
                        Container(
                          width: 12.sp, height: 12.sp,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColors[e.key] ?? Colors.grey),
                        ),
                        SizedBox(width: 6.sp),
                        Expanded(child: Text(e.key, style: StyleText.fontSize12Weight400.copyWith(color: Colors.black87))),
                        Text(e.value.toInt().toString(),
                            style: StyleText.fontSize12Weight600.copyWith(color: Colors.black87)),
                      ],
                    ),
                  );
                }).toList(),
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
                      centerSpaceRadius: 40.sp,
                      sections: dash.jobStatus.entries.map((e) {
                        final percent = (e.value / total * 100).round();
                        return PieChartSectionData(
                          value: e.value,
                          color: statusColors[e.key] ?? Colors.grey,
                          radius: 28.sp,
                          title: '$percent%',
                          showTitle: true,
                          // Outside the ring so it is never squeezed onto the
                          // edge (BUG-38).
                          titleStyle: StyleText.fontSize10Weight500.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          titlePositionPercentageOffset: 1.55,
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total\nJobs', textAlign: TextAlign.center,
                          style: StyleText.fontSize10Weight400.copyWith(fontSize: 9.sp, color: Colors.black87)),
                      Text(dash.jobStatusTotal.toString(),
                          style: StyleText.fontSize18Weight500.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
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

  Widget _buildCandidateQualityChart(CareersDashboardData dash) {
    if (dash.totalApplications <= 0) {
      return _chartCard(
        title: 'Candidate Quality',
        height: 280,
        child: Expanded(child: _emptyState('No applicants yet')),
      );
    }
    return _chartCard(
      title: 'Candidate Quality',
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
                  _qualityLegendRow('${dash.qualifiedPercent.toInt()}%', 'Qualified', ColorPick.primary),
                  SizedBox(height: 8.sp),
                  _qualityLegendRow('${dash.unqualifiedPercent.toInt()}%', 'Unqualified', _ChartColors.grey),
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
                      centerSpaceRadius: 40.sp,
                      sections: [
                        PieChartSectionData(value: dash.qualifiedPercent, color: ColorPick.primary, radius: 28.sp, title: ''),
                        PieChartSectionData(value: dash.unqualifiedPercent, color: _ChartColors.grey, radius: 28.sp, title: ''),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total Applicants', style: StyleText.fontSize10Weight400.copyWith(fontSize: 9.sp, color: Colors.black87)),
                      Text(_formatLargeNumber(dash.totalApplications),
                          style: StyleText.fontSize16Weight700.copyWith(color: Colors.black)),
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

  Widget _qualityLegendRow(String percent, String label, Color color) {
    return Row(
      children: [
        Container(width: 12.sp, height: 12.sp, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        SizedBox(width: 6.sp),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(percent,
                style: StyleText.fontSize14Weight700
                    .copyWith(color: Colors.black)),
            Text(label, style: StyleText.fontSize11Weight400.copyWith(color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildJobsPerformanceChart(CareersDashboardData dash) {
    final legends = [
      _LegendItem('Applications', ColorPick.primary),
      _LegendItem('Interviews', ColorPick.primary.withOpacity(0.7)),
      _LegendItem('Hires', ColorPick.primary.withOpacity(0.4)),
    ];
    final rowColors = [
      ColorPick.primary,
      ColorPick.primary.withOpacity(0.7),
      ColorPick.primary.withOpacity(0.4),
    ];

    return _chartCard(
      title: 'Jobs Performance',
      height: 280,
      legendItems: legends,
      child: Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final roleCount = dash.performanceRoles.length;
            if (roleCount == 0) return _emptyState('No jobs yet'); // BUG-151
            final rowValues = [dash.performanceApplications, dash.performanceInterviews, dash.performanceHires];
            final cellSpacing = 4.sp;
            final labelHeight = 30.h;
            final availableHeight = constraints.maxHeight - labelHeight - 8.sp;
            final rowCount = rowValues.length;
            final cellHeight = (availableHeight - (cellSpacing * (rowCount - 1))) / rowCount;

            // BUG-39: each row is labelled (Applications / Interviews / Hires)
            // instead of relying on three near-identical shades of red.
            const rowLabels = ['Applications', 'Interviews', 'Hires'];
            final double labelColW = 70.w;
            final double rowH = cellHeight.clamp(24.0, 60.0);
            return Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: labelColW,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(rowCount, (r) => Padding(
                            padding: EdgeInsets.only(
                                bottom: r < rowCount - 1 ? cellSpacing : 0),
                            child: SizedBox(
                              height: rowH,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(rowLabels[r],
                                    style: StyleText.fontSize10Weight400
                                        .copyWith(fontSize: 9.sp, color: Colors.grey.shade800)),
                              ),
                            ),
                          )),
                        ),
                      ),
                      ...List.generate(roleCount, (colIndex) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: List.generate(rowCount, (rowIndex) {
                              final value = rowIndex < rowValues.length && colIndex < rowValues[rowIndex].length
                                  ? rowValues[rowIndex][colIndex].toInt()
                                  : 0;
                              return Padding(
                                padding: EdgeInsets.only(bottom: rowIndex < rowCount - 1 ? cellSpacing : 0),
                                child: Tooltip(
                                  message: '${rowLabels[rowIndex]}: $value',
                                  child: Container(
                                  width: double.infinity,
                                  height: rowH,
                                  decoration: BoxDecoration(color: rowColors[rowIndex], borderRadius: BorderRadius.circular(4.r)),
                                  child: Center(child: Text(value.toString(),
                                      style: StyleText.fontSize12Weight600
                                          .copyWith(color: ColorPick.white))),
                                ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    }),
                    ],
                  ),
                ),
                SizedBox(height: 8.sp),
                Row(
                  children: [
                    SizedBox(width: labelColW),
                    ...List.generate(roleCount, (i) {
                    return Expanded(
                      // Job titles as typed (no auto Title-Case).
                      child: Text(dash.performanceRoles[i], textAlign: TextAlign.center,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize10Weight400.copyWith(fontSize: 9.sp, color: Colors.grey.shade800)),
                    );
                  }),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobOfferChart(CareersDashboardData dash) {
    final total = dash.jobOfferApproved + dash.jobOfferPending + dash.jobOfferRejected;
    // BUG-151: a blank donut with "0 Total" → the shared empty state.
    if (total <= 0) {
      return _chartCard(
        title: 'Job Offer',
        height: 280,
        child: Expanded(child: _emptyState('No job offers yet')),
      );
    }
    final items = [
      _PieItem('Approved', dash.jobOfferApproved.toDouble(), ColorPick.activeColor),
      _PieItem('Pending', dash.jobOfferPending.toDouble(), _ChartColors.yellow),
      _PieItem('Rejected', dash.jobOfferRejected.toDouble(), ColorPick.red),
    ];

    return _chartCard(
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
                children: items.map((item) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.sp),
                    child: Row(
                      children: [
                        Container(width: 12.sp, height: 12.sp,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: item.color)),
                        SizedBox(width: 6.sp),
                        Expanded(child: Text(item.label, style: StyleText.fontSize12Weight400.copyWith(color: Colors.black87))),
                        Text(_formatLargeNumber(item.value.toInt()),
                            style: StyleText.fontSize12Weight600.copyWith(color: Colors.black87)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: 10.sp),
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40.sp,
                    sections: items.map((item) => PieChartSectionData(
                        value: item.value, color: item.color, radius: 28.sp, title: '')).toList(),
                  )),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatLargeNumber(total),
                          style: StyleText.fontSize16Weight700.copyWith(color: Colors.black)),
                      Text('Total', style: StyleText.fontSize10Weight400.copyWith(color: Colors.black87)),
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

  Widget _buildScoreDistributionChart(CareersDashboardData dash) {
    // BUG-84 / BUG-151: no scored applicant → empty state (the bar used to be
    // fully coloured in 5 equal parts with every band at 0).
    if (dash.scoreDistribution.every((s) => s.value <= 0)) {
      return _chartCard(
        title: 'Candidate Score Distribution',
        height: 280,
        child: Expanded(child: _emptyState('No scored applicants yet')),
      );
    }
    return SizedBox(
      height: 280.h,
      child: SegmentedScoreBarWidget(
        title: 'Candidate Score Distribution',
        titleColor: ColorPick.primary,
        segments: dash.scoreDistribution
            .map((s) => ScoreSegment(label: s.label, value: s.value, color: _hexToColor(s.colorHex)))
            .toList(),
        lightMode: true,
        height: 280,
      ),
    );
  }

  Widget _buildEmploymentTypesChart(CareersDashboardData dash) {
    final entries = dash.employmentTypes.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0) {
      return _chartCard(
        title: 'Employment Types',
        height: 280,
        child: Expanded(child: _emptyState('No jobs yet')),
      );
    }
    final typeColors = [
      ColorPick.primary,
      ColorPick.primary.withValues(alpha: 0.75),
      ColorPick.primary.withValues(alpha: 0.5),
      ColorPick.primary.withValues(alpha: 0.25),
    ];

    return _chartCard(
      title: 'Employment Types',
      height: 280,
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final percent = total > 0 ? (e.value / total * 100) : 0.0;
                  final barColor = i < typeColors.length ? typeColors[i] : typeColors.last;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.sp),
                    child: Row(
                      children: [
                        SizedBox(width: 40.sp,
                            child: Text('${percent.toInt()}%',
                                style: StyleText.fontSize11Weight600
                                    .copyWith(color: Colors.black87))),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(height: 14.sp,
                                  decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(4.r))),
                              FractionallySizedBox(
                                widthFactor: (percent / 100).clamp(0.0, 1.0),
                                child: Container(height: 14.sp,
                                    decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4.r))),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.sp),
                        SizedBox(width: 70.sp,
                            child: Text(e.key, style: StyleText.fontSize11Weight400.copyWith(color: Colors.black87))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: 10.sp),
            Expanded(
              flex: 2,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  return PieChartSectionData(
                      value: e.value,
                      color: i < typeColors.length ? typeColors[i] : typeColors.last,
                      radius: 50.sp, title: '');
                }).toList(),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required double height,
    required Widget child,
    String? subtitle,
    List<_LegendItem>? legendItems,
  }) {
    return Container(
      height: height.h,
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: StyleText.fontSize14Weight700
                        .copyWith(color: ColorPick.primary)),
              ),
              if (legendItems != null)
                Wrap(
                  spacing: 10.sp,
                  children: legendItems.map((l) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8.sp, height: 8.sp,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: l.color)),
                      SizedBox(width: 4.sp),
                      Text(l.label, style: StyleText.fontSize10Weight400.copyWith(color: Colors.black87)),
                    ],
                  )).toList(),
                ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.sp),
            Text(subtitle,
                style: StyleText.fontSize11Weight400
                    .copyWith(color: Colors.black87)),
          ],
          SizedBox(height: 12.sp),
          child,
        ],
      ),
    );
  }

  /// Shared empty state for charts with no data.
  Widget _emptyState(String text) => Center(
        child: Text(text,
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText)),
      );

  double _niceMax(List<double> values) {
    if (values.isEmpty) return 10;
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    // BUG-21: auto-scale small values (every bar = 1 used to get a 0–10 axis).
    if (dataMax <= 0) return 1;
    final intMax = dataMax.ceil();
    if (intMax <= 5) return intMax.toDouble();
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

  String _formatLargeNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
