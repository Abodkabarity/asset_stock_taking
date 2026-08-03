part of '../../../pages/web_asset_dashboard_page.dart';

extension _DashboardOverviewExtension on _WebAssetDashboardPageState {
  Widget _dashboard() {
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
            Expanded(child: _categoryPanel()),
            const SizedBox(width: 14),
            Expanded(child: _alertPanel()),
          ],
        ),
        const SizedBox(height: 14),
        _assetsPanel(limit: 8),
      ],
    );
  }

  Widget _categoryPanel() {
    final Map<String, int> counts = {};
    for (final asset in visibleAssets) {
      final key = asset.category.trim().isEmpty
          ? 'Uncategorized'
          : asset.category;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return _Panel(
      title: 'Asset Value by Category',
      child: counts.isEmpty
          ? const SizedBox(height: 220, child: Center(child: Text('No data')))
          : Column(
              children: counts.entries.map((entry) {
                final percent = entry.value / visibleAssets.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(99),
                            value: percent,
                            color: AppColors.primaryColor,
                            backgroundColor: AppColors.backgroundWidget,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 24,
                        child: Text(
                          entry.value.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

  Widget _alertPanel() {
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

    return _Panel(
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

                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xfffff7de) : Colors.white,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrentMonth
                              ? const Color(0xff0051c8)
                              : const Color(0xffaac8ef),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...records.take(1).map((record) {
                        final itemCode = record['asset_name']?.toString() ?? '';
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => _showMaintenanceRecordDialog(record),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff9b55c7),
                                borderRadius: BorderRadius.circular(4),
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
                      if (records.length > 1)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${records.length - 1} more',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
