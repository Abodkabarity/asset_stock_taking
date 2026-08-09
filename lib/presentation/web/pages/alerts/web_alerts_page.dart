part of '../../../pages/web_asset_dashboard_page.dart';

class _UnifiedAlertEntry {
  final WebAlertView view;
  final String id;
  final String itemCode;
  final String assetName;
  final String title;
  final String description;
  final String branch;
  final String assignedTo;
  final DateTime date;
  final AssetStockModel? asset;
  final Map<String, dynamic>? source;

  const _UnifiedAlertEntry({
    required this.view,
    required this.id,
    required this.itemCode,
    required this.assetName,
    required this.title,
    required this.description,
    required this.branch,
    required this.assignedTo,
    required this.date,
    required this.asset,
    this.source,
  });
}

extension _AlertsPageExtension on _WebAssetDashboardPageState {
  Widget _alertsPanel() => _unifiedAlertsPanel();

  Map<WebAlertView, int> get _alertUnreadCounts => {
    for (final view in WebAlertView.values)
      view: _alertEntriesFor(view)
          .where(
            (entry) =>
                _alertDaysFromToday(entry.date) <= 7 &&
                !_seenAlertKeys.contains(_alertEntryKey(entry)),
          )
          .length,
  };

  String _alertEntryKey(_UnifiedAlertEntry entry) =>
      '${entry.view.name}:${entry.id}:${entry.itemCode}:${entry.date.toIso8601String().split('T').first}';

  List<_UnifiedAlertEntry> _alertEntriesFor(WebAlertView view) {
    final todayValue = DateTime.now();
    final today = DateTime(todayValue.year, todayValue.month, todayValue.day);
    final entries = <_UnifiedAlertEntry>[];

    if (view == WebAlertView.checkoutDue) {
      for (final row in activeCheckouts) {
        final date = _parseAlertDate(row['due_date']);
        if (date == null) continue;
        final days = _alertDaysFromToday(date, today);
        if (days > 7) continue;
        final itemCode = row['item_code']?.toString() ?? '';
        entries.add(
          _UnifiedAlertEntry(
            view: view,
            id: row['id']?.toString() ?? itemCode,
            itemCode: itemCode,
            assetName: row['asset_name']?.toString() ?? itemCode,
            title: days < 0 ? 'Check-out overdue' : 'Check-in expected soon',
            description:
                'Assigned to ${row['assigned_to']?.toString().trim().isNotEmpty == true ? row['assigned_to'] : 'Unassigned'}',
            branch: row['location']?.toString() ?? '',
            assignedTo: row['assigned_to']?.toString() ?? '',
            date: date,
            asset: _assetByItemCode(itemCode),
            source: row,
          ),
        );
      }
    } else if (view == WebAlertView.maintenanceDue ||
        view == WebAlertView.maintenanceOverdue) {
      for (final row in maintenanceRecords) {
        final status = row['status']?.toString().trim().toLowerCase() ?? '';
        if (status == 'completed' || status == 'closed') continue;
        final date = _parseAlertDate(row['due_date'] ?? row['completed_date']);
        if (date == null) continue;
        final days = _alertDaysFromToday(date, today);
        if (view == WebAlertView.maintenanceDue && (days < 0 || days > 7)) {
          continue;
        }
        if (view == WebAlertView.maintenanceOverdue && days >= 0) continue;
        final itemCode = row['item_code']?.toString() ?? '';
        entries.add(
          _UnifiedAlertEntry(
            view: view,
            id: row['id']?.toString() ?? itemCode,
            itemCode: itemCode,
            assetName: row['asset_name']?.toString() ?? itemCode,
            title: row['title']?.toString().trim().isNotEmpty == true
                ? row['title'].toString()
                : 'Scheduled maintenance',
            description: row['details']?.toString() ?? '',
            branch: row['branch']?.toString() ?? '',
            assignedTo: row['maintenance_by']?.toString() ?? '',
            date: date,
            asset: _assetByItemCode(itemCode),
            source: row,
          ),
        );
      }
    } else {
      for (final asset in assets) {
        if (!asset.hasWarranty) continue;
        final date = _parseAlertDate(asset.warrantyEndDate);
        if (date == null) continue;
        entries.add(
          _UnifiedAlertEntry(
            view: view,
            id: asset.id?.toString() ?? asset.itemCode,
            itemCode: asset.itemCode,
            assetName: asset.name,
            title: 'Asset warranty',
            description: asset.warrantyDescription.trim().isEmpty
                ? 'Warranty coverage information'
                : asset.warrantyDescription,
            branch: asset.location,
            assignedTo: asset.warrantySerialNo,
            date: date,
            asset: asset,
          ),
        );
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  DateTime? _parseAlertDate(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  int _alertDaysFromToday(DateTime date, [DateTime? cleanToday]) {
    final now = cleanToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).difference(today).inDays;
  }

  String _alertViewTitle(WebAlertView view) {
    switch (view) {
      case WebAlertView.checkoutDue:
        return 'Check-out Due';
      case WebAlertView.maintenanceDue:
        return 'Maintenance Due';
      case WebAlertView.maintenanceOverdue:
        return 'Maintenance Overdue';
      case WebAlertView.warrantyExpiry:
        return 'Warranty Expiry';
    }
  }

  IconData _alertViewIcon(WebAlertView view) {
    switch (view) {
      case WebAlertView.checkoutDue:
        return Icons.assignment_return_outlined;
      case WebAlertView.maintenanceDue:
        return Icons.build_circle_outlined;
      case WebAlertView.maintenanceOverdue:
        return Icons.warning_amber_rounded;
      case WebAlertView.warrantyExpiry:
        return Icons.verified_user_outlined;
    }
  }

  Widget _unifiedAlertsPanel() {
    final todayValue = DateTime.now();
    final today = DateTime(todayValue.year, todayValue.month, todayValue.day);
    final search = alertSearchQuery.trim().toLowerCase();
    final allForView = _alertEntriesFor(selectedAlertView);
    final scoped = allForView
        .where((entry) {
          if (selectedBranch != null && entry.branch != selectedBranch) {
            return false;
          }
          if (search.isNotEmpty) {
            final searchable = [
              entry.assetName,
              entry.itemCode,
              entry.title,
              entry.description,
              entry.branch,
              entry.assignedTo,
            ].join(' ').toLowerCase();
            if (!searchable.contains(search)) return false;
          }
          final days = _alertDaysFromToday(entry.date, today);
          switch (alertUrgencyFilter) {
            case 'Overdue':
              return days < 0;
            case 'Due today':
              return days == 0;
            case 'Upcoming':
              return days > 0;
            default:
              return true;
          }
        })
        .toList(growable: false);
    final overdue = scoped.where((entry) => entry.date.isBefore(today)).length;
    final dueSoon = scoped.where((entry) {
      final days = _alertDaysFromToday(entry.date, today);
      return days >= 0 && days <= 7;
    }).length;
    final affectedBranches = scoped
        .map((entry) => entry.branch.trim())
        .where((branch) => branch.isNotEmpty)
        .toSet()
        .length;
    final paged = _paginate(scoped, WebAssetSection.alerts);
    final exportAssets = <String, AssetStockModel>{};
    for (final entry in scoped) {
      if (entry.asset != null) exportAssets[entry.itemCode] = entry.asset!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlertHeroCard(
          title: 'Smart Alert Center',
          description:
              '${_alertViewTitle(selectedAlertView)} · deadlines, expiry and overdue activity in one workspace.',
          totalAlerts: scoped.length,
          dueToday: dueSoon,
          scopeLabel: selectedBranch ?? 'All branches',
          onRefresh: _loadData,
          onExport: exportAssets.isEmpty
              ? null
              : () => _exportList(
                  exportAssets.values.toList(growable: false),
                  '${selectedAlertView.name}_alerts',
                ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _AlertSummaryCard(
                icon: _alertViewIcon(selectedAlertView),
                color: const Color(0xff4263eb),
                label: 'Total Records',
                value: scoped.length.toString(),
                note: _alertViewTitle(selectedAlertView),
              ),
              _AlertSummaryCard(
                icon: Icons.upcoming_outlined,
                color: const Color(0xfff59f00),
                label: 'Due Within 7 Days',
                value: dueSoon.toString(),
                note: 'Requires upcoming attention',
              ),
              _AlertSummaryCard(
                icon: Icons.error_outline_rounded,
                color: const Color(0xffe53935),
                label: 'Overdue / Expired',
                value: overdue.toString(),
                note: 'Requires immediate action',
              ),
              _AlertSummaryCard(
                icon: Icons.account_tree_outlined,
                color: const Color(0xff0f9f8f),
                label: 'Affected Branches',
                value: affectedBranches.toString(),
                note: selectedBranch ?? 'Across current scope',
              ),
            ];
            final width = constraints.maxWidth >= 1040
                ? (constraints.maxWidth - 36) / 4
                : constraints.maxWidth >= 600
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 16),
        _UnifiedAlertsDirectory(
          title: _alertViewTitle(selectedAlertView),
          icon: _alertViewIcon(selectedAlertView),
          entries: paged.items,
          totalResults: scoped.length,
          searchController: alertSearchController,
          searchQuery: alertSearchQuery,
          urgencyFilter: alertUrgencyFilter,
          onSearchChanged: (value) => _updateWebState(() {
            alertSearchQuery = value;
            _resetPage(WebAssetSection.alerts);
          }),
          onUrgencyChanged: (value) => _updateWebState(() {
            alertUrgencyFilter = value;
            _resetPage(WebAssetSection.alerts);
          }),
          onViewAsset: (entry) {
            if (entry.asset != null) _showAssetDetails(entry.asset!);
          },
          onEditMaintenance: (entry) {
            if (entry.source != null &&
                (entry.view == WebAlertView.maintenanceDue ||
                    entry.view == WebAlertView.maintenanceOverdue)) {
              _editAlertSchedule(entry.source!);
            }
          },
          currentPage: paged.currentPage,
          totalPages: paged.totalPages,
          onPageChanged: (page) => _changePage(WebAssetSection.alerts, page),
        ),
      ],
    );
  }

  Widget _legacyAlertsPanel() {
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final search = alertSearchQuery.trim().toLowerCase();

    final scopedAlerts =
        maintenanceAlerts.where((alert) {
          final branch = alert['branch']?.toString().trim() ?? '';
          if (selectedBranch != null && branch != selectedBranch) return false;

          if (search.isNotEmpty) {
            final searchable = [
              alert['asset_name'],
              alert['item_code'],
              alert['title'],
              alert['maintenance_by'],
              alert['branch'],
            ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
            if (!searchable.contains(search)) return false;
          }

          final date = _alertDate(alert);
          final days = date == null
              ? 999
              : DateTime(
                  date.year,
                  date.month,
                  date.day,
                ).difference(cleanToday).inDays;
          switch (alertUrgencyFilter) {
            case 'Overdue':
              return days < 0;
            case 'Due today':
              return days == 0;
            case 'Upcoming':
              return days > 0;
            default:
              return true;
          }
        }).toList()..sort((a, b) {
          final first = _alertDate(a);
          final second = _alertDate(b);
          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;
          return first.compareTo(second);
        });

    final alertAssets = <AssetStockModel>[];
    for (final alert in scopedAlerts) {
      final asset = _assetByItemCode(alert['item_code']?.toString() ?? '');
      if (asset != null) alertAssets.add(asset);
    }

    final dueToday = scopedAlerts.where((alert) {
      final date = _alertDate(alert);
      if (date == null) return false;
      return DateTime(date.year, date.month, date.day) == cleanToday;
    }).length;
    final upcoming = scopedAlerts.where((alert) {
      final date = _alertDate(alert);
      if (date == null) return false;
      return DateTime(date.year, date.month, date.day).isAfter(cleanToday);
    }).length;
    final affectedBranches = scopedAlerts
        .map((alert) => alert['branch']?.toString().trim() ?? '')
        .where((branch) => branch.isNotEmpty)
        .toSet()
        .length;
    final pagedAlerts = _paginate(scopedAlerts, WebAssetSection.alerts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlertHeroCard(
          totalAlerts: scopedAlerts.length,
          dueToday: dueToday,
          scopeLabel: selectedBranch ?? 'All branches',
          onRefresh: _loadData,
          onExport: alertAssets.isEmpty
              ? null
              : () => _exportList(alertAssets, 'maintenance_alerts'),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _AlertSummaryCard(
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFFE53935),
                label: 'Active Alerts',
                value: scopedAlerts.length.toString(),
                note: 'Open maintenance reminders',
              ),
              _AlertSummaryCard(
                icon: Icons.today_outlined,
                color: const Color(0xFFE53935),
                label: 'Due Today',
                value: dueToday.toString(),
                note: 'Requires immediate attention',
              ),
              _AlertSummaryCard(
                icon: Icons.upcoming_outlined,
                color: const Color(0xFFF59E0B),
                label: 'Upcoming',
                value: upcoming.toString(),
                note: 'Scheduled in the next 3 days',
              ),
              _AlertSummaryCard(
                icon: Icons.account_tree_outlined,
                color: AppColors.primaryColor,
                label: 'Affected Branches',
                value: affectedBranches.toString(),
                note: selectedBranch ?? 'Across the current scope',
              ),
            ];

            if (constraints.maxWidth >= 1040) {
              return Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    Expanded(child: cards[index]),
                    if (index != cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            }

            final width = constraints.maxWidth >= 600
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        WebHoverSurface(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final searchField = TextField(
                      controller: alertSearchController,
                      onChanged: (value) {
                        _updateWebState(() {
                          alertSearchQuery = value;
                          _resetPage(WebAssetSection.alerts);
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search asset, tag, maintenance title, engineer or branch',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: alertSearchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  alertSearchController.clear();
                                  _updateWebState(() {
                                    alertSearchQuery = '';
                                    _resetPage(WebAssetSection.alerts);
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                    final filter = DropdownButtonFormField<String>(
                      initialValue: alertUrgencyFilter,
                      decoration: InputDecoration(
                        labelText: 'Urgency',
                        prefixIcon: const Icon(Icons.tune_rounded, size: 19),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All alerts'),
                        ),
                        DropdownMenuItem(
                          value: 'Due today',
                          child: Text('Due today'),
                        ),
                        DropdownMenuItem(
                          value: 'Overdue',
                          child: Text('Overdue'),
                        ),
                        DropdownMenuItem(
                          value: 'Upcoming',
                          child: Text('Upcoming'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _updateWebState(() {
                          alertUrgencyFilter = value;
                          _resetPage(WebAssetSection.alerts);
                        });
                      },
                    );

                    if (constraints.maxWidth < 760) {
                      return Column(
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          filter,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        SizedBox(width: 210, child: filter),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueSoft,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(
                            '${scopedAlerts.length} results',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(20),
                child: scopedAlerts.isEmpty
                    ? const _AlertEmptyState()
                    : Column(
                        children: [
                          ...pagedAlerts.items.map((alert) {
                            final itemCode =
                                alert['item_code']?.toString() ?? '';
                            final asset = _assetByItemCode(itemCode);
                            final urgency = _alertUrgency(alert);
                            return _AlertRecordCard(
                              assetName: alert['asset_name']?.toString() ?? '',
                              itemCode: itemCode,
                              title: alert['title']?.toString() ?? '',
                              dueDate: _formatDisplayDate(
                                alert['due_date']?.toString(),
                              ),
                              branch: alert['branch']?.toString() ?? '',
                              maintenanceBy:
                                  alert['maintenance_by']?.toString() ?? '',
                              urgencyLabel: urgency.$1,
                              urgencyColor: urgency.$2,
                              onViewAsset: asset == null
                                  ? null
                                  : () => _showAssetDetails(asset),
                              onEditSchedule: () => _editAlertSchedule(alert),
                              onSnooze: () => _snoozeAlert(alert),
                              onComplete: () => _completeAlert(alert, asset),
                            );
                          }),
                          if (pagedAlerts.totalPages > 1) ...[
                            const SizedBox(height: 8),
                            _PaginationBar(
                              currentPage: pagedAlerts.currentPage,
                              totalPages: pagedAlerts.totalPages,
                              totalItems: pagedAlerts.totalItems,
                              pageSize:
                                  _WebAssetDashboardPageState._assetsPerPage,
                              onPageChanged: (page) =>
                                  _changePage(WebAssetSection.alerts, page),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _alertDate(Map<String, dynamic> alert) {
    final value = alert['due_date']?.toString();
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  (String, Color) _alertUrgency(Map<String, dynamic> alert) {
    final date = _alertDate(alert);
    if (date == null) return ('Date required', const Color(0xFF64748B));
    final now = DateTime.now();
    final days = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days < 0) return ('Overdue', const Color(0xFFE53935));
    if (days == 0) return ('Due today', const Color(0xFFE53935));
    if (days == 1) return ('Due tomorrow', const Color(0xFFF59E0B));
    return ('Due in $days days', const Color(0xFF2F6FED));
  }

  Future<void> _editAlertSchedule(Map<String, dynamic> alert) async {
    final recordId = alert['id'];
    if (recordId == null) {
      _showAlertActionError('This maintenance record has no database ID.');
      return;
    }

    final dueController = TextEditingController(
      text: _formatDisplayDate(alert['due_date']?.toString()),
    );
    final assignedController = TextEditingController(
      text: alert['maintenance_by']?.toString() ?? '',
    );
    final detailsController = TextEditingController(
      text: alert['details']?.toString() ?? '',
    );
    var status = alert['status']?.toString() ?? 'Open';

    final save = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 14, 15),
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit maintenance schedule',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${alert['asset_name'] ?? ''} • ${alert['item_code'] ?? ''}',
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DateTextField(
                      controller: dueController,
                      label: 'Maintenance due date',
                      onTap: () => _pickDateInto(dueController, setDialogState),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          ['Open', 'In Progress', 'Completed'].contains(status)
                          ? status
                          : 'Open',
                      decoration: _inputDecoration('Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(value: 'Open', child: Text('Open')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => status = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: assignedController,
                      decoration: _inputDecoration('Maintenance by'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: detailsController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _inputDecoration('Work notes'),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true) {
      dueController.dispose();
      assignedController.dispose();
      detailsController.dispose();
      return;
    }

    final dueDate = _databaseDate(dueController.text);
    final itemCode = alert['item_code']?.toString() ?? '';
    await webRepository.updateMaintenanceRecord(
      recordId: recordId,
      values: {
        'due_date': dueDate,
        'status': status,
        'maintenance_by': assignedController.text.trim(),
        'details': detailsController.text.trim(),
        if (status == 'Completed')
          'completed_date': _databaseDate(_formatPickerDate(DateTime.now())),
      },
    );
    await webRepository.addActivityLog(
      itemCode: itemCode,
      action: 'maintenance_schedule_updated',
      description: 'Maintenance schedule updated from Alerts',
      metadata: {'due_date': dueDate, 'status': status},
    );
    dueController.dispose();
    assignedController.dispose();
    detailsController.dispose();
    await _loadData();
  }

  Future<void> _snoozeAlert(Map<String, dynamic> alert) async {
    final recordId = alert['id'];
    final currentDate = _alertDate(alert);
    if (recordId == null || currentDate == null) {
      _showAlertActionError('A valid maintenance date is required.');
      return;
    }
    final nextDate = currentDate.add(const Duration(days: 7));
    await webRepository.updateMaintenanceRecord(
      recordId: recordId,
      values: {'due_date': _isoDate(nextDate)},
    );
    await webRepository.addActivityLog(
      itemCode: alert['item_code']?.toString() ?? '',
      action: 'maintenance_snoozed',
      description: 'Maintenance postponed by 7 days from Alerts',
      metadata: {'due_date': _isoDate(nextDate)},
    );
    await _loadData();
  }

  Future<void> _completeAlert(
    Map<String, dynamic> alert,
    AssetStockModel? asset,
  ) async {
    final recordId = alert['id'];
    if (recordId == null) {
      _showAlertActionError('This maintenance record has no database ID.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete maintenance?'),
        content: Text(
          'Mark maintenance for ${alert['asset_name'] ?? alert['item_code'] ?? 'this asset'} as completed?',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark completed'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final completedDate = _isoDate(DateTime.now());
    await webRepository.updateMaintenanceRecord(
      recordId: recordId,
      values: {'status': 'Completed', 'completed_date': completedDate},
    );
    await webRepository.addActivityLog(
      itemCode: alert['item_code']?.toString() ?? '',
      action: 'maintenance_completed',
      description: 'Maintenance completed from Alerts',
      metadata: {'completed_date': completedDate},
    );
    if (asset != null) {
      await webRepository.updateStatus(
        itemCode: asset.itemCode,
        status: 'Good',
      );
    }
    await _loadData();
  }

  void _showAlertActionError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _databaseDate(String value) {
    final clean = value.trim();
    if (clean.isEmpty || clean == '-') return null;
    final slashParts = clean.split('/');
    if (slashParts.length == 3) {
      return '${slashParts[2].padLeft(4, '0')}-'
          '${slashParts[1].padLeft(2, '0')}-'
          '${slashParts[0].padLeft(2, '0')}';
    }
    final parsed = DateTime.tryParse(clean);
    return parsed == null ? null : _isoDate(parsed);
  }

  String _isoDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
