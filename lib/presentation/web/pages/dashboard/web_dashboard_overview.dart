part of '../../../pages/web_asset_dashboard_page.dart';

extension _DashboardOverviewExtension on _WebAssetDashboardPageState {
  Widget _dashboard() {
    final monthStart = DateTime(alertMonth.year, alertMonth.month, 1);
    final leadingDays = monthStart.weekday % 7;
    final daysInMonth = DateTime(alertMonth.year, alertMonth.month + 1, 0).day;
    final calendarRows = ((leadingDays + daysInMonth) / 7).ceil();
    // Includes the panel header, content padding, calendar controls and
    // borders. Keep a small safety allowance for browser text metrics.
    final dashboardDetailHeight = 178 + (calendarRows * 78.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.extension,
                color: AppColors.primaryColor,
                title: 'Active Assets',
                value: activeCount.toString(),
                subtitle: 'Total Assets: ${visibleAssets.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.payments_outlined,
                color: Colors.redAccent,
                title: 'Value of Assets',
                value: totalValue.toStringAsFixed(2),
                subtitle: 'AED',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.delete_outline,
                color: Colors.orange,
                title: 'Disposed Assets',
                value: disposedCount.toString(),
                subtitle: 'Archived in place',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.build,
                color: Colors.deepPurple,
                title: 'Maintenance',
                value: maintenanceCount.toString(),
                subtitle: 'Assets under work',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _categoryPanel(height: dashboardDetailHeight)),
            const SizedBox(width: 14),
            Expanded(child: _alertPanel(height: dashboardDetailHeight)),
          ],
        ),
        const SizedBox(height: 14),
        _assetsPanel(limit: 8),
      ],
    );
  }

  Widget _categoryPanel({double? height}) {
    final Map<String, int> counts = {};
    for (final asset in visibleAssets) {
      final key = asset.category.trim().isEmpty
          ? 'Uncategorized'
          : asset.category;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return SizedBox(
      height: height,
      child: _Panel(
        title: 'Asset Value by Category',
        expandChild: true,
        child: counts.isEmpty
            ? const SizedBox(height: 220, child: Center(child: Text('No data')))
            : Column(
                children: counts.entries.map((entry) {
                  return Expanded(
                    child: _DashboardCategoryRow(
                      label: entry.key,
                      count: entry.value,
                      percent: entry.value / visibleAssets.length,
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  Future<void> _showMaintenanceRecordDialog(Map<String, dynamic> record) async {
    final itemCode = record['item_code']?.toString() ?? '';
    final asset = _assetByItemCode(itemCode);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 36,
            vertical: 28,
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
          contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Asset Maintenance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 640,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    labelColor: AppColors.headerText,
                    unselectedLabelColor: AppColors.headerText,
                    indicatorColor: AppColors.primaryColor,
                    indicatorWeight: 2,
                    tabs: [
                      Tab(text: 'Maintenance Details'),
                      Tab(text: 'Asset Details'),
                    ],
                  ),
                  Container(
                    height: 330,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: _InfoTable(
                              rows: [
                                _InfoRow(
                                  'Title',
                                  record['title']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Details',
                                  record['details']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Due Date',
                                  _formatDisplayDate(
                                    record['due_date']?.toString(),
                                  ),
                                ),
                                _InfoRow(
                                  'Maintenance By',
                                  record['maintenance_by']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Maintenance Status',
                                  record['status']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Date completed',
                                  _formatDisplayDate(
                                    record['completed_date']?.toString(),
                                  ),
                                ),
                                _InfoRow(
                                  'Maintenance Cost',
                                  record['cost']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Repeating',
                                  record['repeating'] == true ? 'Yes' : 'No',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: asset == null
                              ? Center(
                                  child: Text(
                                    itemCode.isEmpty
                                        ? 'Asset not found'
                                        : 'Asset $itemCode not found',
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      child: _LargeAssetImage(
                                        path: asset.imagePath,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: _InfoTable(
                                          rows: [
                                            _InfoRow(
                                              'Asset Tag ID',
                                              asset.itemCode,
                                            ),
                                            _InfoRow('Description', asset.name),
                                            _InfoRow(
                                              'Purchase Date',
                                              _formatPickerDate(
                                                asset.createdAt,
                                              ),
                                            ),
                                            const _InfoRow(
                                              'Purchased from',
                                              '-',
                                            ),
                                            _InfoRow(
                                              'Cost',
                                              asset.cost.toStringAsFixed(2),
                                            ),
                                            _InfoRow('Brand', asset.brand),
                                            _InfoRow('Model', asset.model),
                                            _InfoRow(
                                              'Serial No',
                                              asset.serialNo,
                                            ),
                                            _InfoRow(
                                              'Location',
                                              asset.location,
                                            ),
                                            _InfoRow(
                                              'Category',
                                              asset.category,
                                            ),
                                            _InfoRow(
                                              'Sub Category',
                                              asset.subCategory,
                                            ),
                                            const _InfoRow('Department', '-'),
                                            _InfoRow('Status', asset.status),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (asset != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAssetDetails(asset);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'More Details',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _alertPanel({double? height}) {
    final monthStart = DateTime(alertMonth.year, alertMonth.month);

    final leadingDays = monthStart.weekday % 7;

    final gridStart = monthStart.subtract(Duration(days: leadingDays));

    final daysInMonth = DateTime(alertMonth.year, alertMonth.month + 1, 0).day;

    final calendarRows = ((leadingDays + daysInMonth) / 7).ceil();
    final calendarItemCount = calendarRows * 7;
    final monthLabel =
        '${_monthName(alertMonth.month).toUpperCase()} ${alertMonth.year}';
    final recordsByDate = <String, List<Map<String, dynamic>>>{};

    for (final record in maintenanceRecords) {
      final recordBranch = record['branch']?.toString() ?? '';
      if (selectedBranch != null && recordBranch != selectedBranch) continue;
      final date = _maintenanceRecordDate(record);
      if (date == null) continue;
      final key = _dateKey(date);
      recordsByDate.putIfAbsent(key, () => []).add(record);
    }

    return SizedBox(
      height: height,
      child: _Panel(
        title: 'Alert',
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _AlertChip(label: 'Assets Due', color: Color(0xff4f83ff)),
              SizedBox(width: 5),
              _AlertChip(label: 'Maintenance', color: Color(0xff8e54c9)),
              SizedBox(width: 5),
              _AlertChip(label: 'Warranty', color: Color(0xffff6868)),
              SizedBox(width: 5),
              _AlertChip(label: 'Lease', color: Color(0xffffb23f)),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(42, 34),
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    _updateWebState(() {
                      alertMonth = DateTime(
                        alertMonth.year,
                        alertMonth.month - 1,
                      );
                    });
                  },
                  child: const Icon(Icons.chevron_left, size: 19),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(42, 34),
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    _updateWebState(() {
                      alertMonth = DateTime(
                        alertMonth.year,
                        alertMonth.month + 1,
                      );
                    });
                  },
                  child: const Icon(Icons.chevron_right, size: 19),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Month',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _CalendarDayHeader('Sun'),
                _CalendarDayHeader('Mon'),
                _CalendarDayHeader('Tue'),
                _CalendarDayHeader('Wed'),
                _CalendarDayHeader('Thu'),
                _CalendarDayHeader('Fri'),
                _CalendarDayHeader('Sat'),
              ],
            ),
            SizedBox(
              height: calendarRows * 78.0,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 78,
                ),
                itemCount: calendarItemCount,
                itemBuilder: (context, index) {
                  final date = gridStart.add(Duration(days: index));
                  final isCurrentMonth = date.month == alertMonth.month;
                  final today = DateTime.now();
                  final isToday =
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final records = recordsByDate[_dateKey(date)] ?? const [];

                  return _DashboardCalendarDay(
                    date: date,
                    isCurrentMonth: isCurrentMonth,
                    isToday: isToday,
                    records: records,
                    onRecordTap: _showMaintenanceRecordDialog,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCalendarDay extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final List<Map<String, dynamic>> records;
  final ValueChanged<Map<String, dynamic>> onRecordTap;

  const _DashboardCalendarDay({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.records,
    required this.onRecordTap,
  });

  @override
  State<_DashboardCalendarDay> createState() => _DashboardCalendarDayState();
}

class _DashboardCalendarDayState extends State<_DashboardCalendarDay> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final accent = widget.records.isEmpty
              ? AppColors.primaryColor
              : const Color(0xff8e54c9);
          final baseColor = widget.isToday
              ? const Color(0xfffff7de)
              : Colors.white;

          return Transform.translate(
            offset: Offset(0, -2.5 * value),
            child: Transform.scale(
              scale: 1 + (.018 * value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    baseColor,
                    accent.withValues(alpha: .075),
                    value,
                  ),
                  borderRadius: BorderRadius.circular(7 * value),
                  border: Border.all(
                    color: Color.lerp(AppColors.border, accent, value)!,
                    width: 1 + (.35 * value),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .18 * value),
                      blurRadius: 16,
                      spreadRadius: -5,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 190),
                      width: 24 + (3 * value),
                      height: 24 + (3 * value),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12 * value),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.date.day.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hovered
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: widget.isCurrentMonth
                              ? Color.lerp(
                                  const Color(0xff0051c8),
                                  accent,
                                  value,
                                )
                              : const Color(0xffaac8ef),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    ...widget.records.take(1).map((record) {
                      final itemCode = record['asset_name']?.toString() ?? '';
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => widget.onRecordTap(record),
                          borderRadius: BorderRadius.circular(5),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 190),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2 + value,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xff9b55c7),
                                  Color.lerp(
                                    const Color(0xff9b55c7),
                                    const Color(0xff6f42c1),
                                    value,
                                  )!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4 + value),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xff8e54c9,
                                  ).withValues(alpha: .20 * value),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              itemCode.isEmpty ? 'Maintenance' : itemCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (widget.records.length > 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+${widget.records.length - 1} more',
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCategoryRow extends StatefulWidget {
  final String label;
  final int count;
  final double percent;

  const _DashboardCategoryRow({
    required this.label,
    required this.count,
    required this.percent,
  });

  @override
  State<_DashboardCategoryRow> createState() => _DashboardCategoryRowState();
}

class _DashboardCategoryRowState extends State<_DashboardCategoryRow> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, hoverValue, child) {
          final accent = Color.lerp(
            AppColors.primaryColor,
            const Color(0xff15aabf),
            hoverValue,
          )!;
          return Transform.translate(
            offset: Offset(4 * hoverValue, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.transparent,
                  const Color(0xfff1f6ff),
                  hoverValue,
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: accent.withValues(alpha: .16 * hoverValue),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .10 * hoverValue),
                    blurRadius: 16,
                    spreadRadius: -7,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color.lerp(
                          const Color(0xff344054),
                          const Color(0xff174c82),
                          hoverValue,
                        ),
                        fontSize: 12.3,
                        fontWeight: hovered ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: widget.percent),
                      duration: const Duration(milliseconds: 760),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, child) {
                        return Container(
                          height: 10 + (3 * hoverValue),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xffeaf1fc),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress.clamp(.006, 1.0),
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryColor, accent],
                                ),
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(
                                      alpha: .28 * hoverValue,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 38,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .06 + (.08 * hoverValue)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      widget.count.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.lerp(
                          const Color(0xff4f5f77),
                          accent,
                          hoverValue,
                        ),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
