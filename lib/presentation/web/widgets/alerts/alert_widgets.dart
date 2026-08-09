part of '../../../pages/web_asset_dashboard_page.dart';

class _AlertSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String note;

  const _AlertSummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return WebDashboardMetricCard(
      icon: icon,
      color: color,
      title: label,
      value: value,
      subtitle: note,
    );
  }
}

class _AlertEmptyState extends StatelessWidget {
  const _AlertEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Everything looks clear',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No records match this alert view and the selected filters.',
              style: TextStyle(color: AppColors.subText),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHeroCard extends StatelessWidget {
  final String title;
  final String description;
  final int totalAlerts;
  final int dueToday;
  final String scopeLabel;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;

  const _AlertHeroCard({
    this.title = 'Maintenance Alert Center',
    this.description =
        'Review schedules, reschedule maintenance, complete work and open the related asset.',
    required this.totalAlerts,
    required this.dueToday,
    required this.scopeLabel,
    required this.onRefresh,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 136),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2344), Color(0xFF174C82), Color(0xFF2369B5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF174C82).withValues(alpha: .24),
              blurRadius: 34,
              spreadRadius: -10,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                right: -48,
                top: -82,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .055),
                  ),
                ),
              ),
              Positioned(
                right: 48,
                bottom: -72,
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 165,
                  color: Colors.white.withValues(alpha: .055),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    final heading = Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .16),
                            ),
                          ),
                          child: const Icon(
                            Icons.notification_important_outlined,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$totalAlerts records • $dueToday due within 7 days • $scopeLabel',
                                style: const TextStyle(
                                  color: Color(0xFFC8D8EC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Color(0xFF9FB7D3),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final actions = Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: .32),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: onExport,
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Export Alerts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF174C82),
                          ),
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading,
                          const SizedBox(height: 16),
                          actions,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 24),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertRecordCard extends StatelessWidget {
  final String assetName;
  final String itemCode;
  final String title;
  final String dueDate;
  final String branch;
  final String maintenanceBy;
  final String urgencyLabel;
  final Color urgencyColor;
  final VoidCallback? onViewAsset;
  final VoidCallback? onEditSchedule;
  final VoidCallback? onSnooze;
  final VoidCallback? onComplete;

  const _AlertRecordCard({
    required this.assetName,
    required this.itemCode,
    required this.title,
    required this.dueDate,
    required this.branch,
    required this.maintenanceBy,
    required this.urgencyLabel,
    required this.urgencyColor,
    this.onViewAsset,
    this.onEditSchedule,
    this.onSnooze,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: WebHoverSurface(
        borderRadius: BorderRadius.circular(18),
        color: Color.lerp(Colors.white, urgencyColor, .025)!,
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final details = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.build_circle_outlined,
                    color: urgencyColor,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 9,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            assetName.isEmpty ? itemCode : assetName,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            itemCode,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _AlertChip(label: urgencyLabel, color: urgencyColor),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        title.isEmpty ? 'Scheduled maintenance' : title,
                        style: const TextStyle(
                          color: Color(0xFF3B4B63),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 18,
                        runSpacing: 7,
                        children: [
                          _AlertMetadata(
                            icon: Icons.event_outlined,
                            label: 'Due $dueDate',
                          ),
                          _AlertMetadata(
                            icon: Icons.location_on_outlined,
                            label: branch.isEmpty ? 'No branch' : branch,
                          ),
                          _AlertMetadata(
                            icon: Icons.engineering_outlined,
                            label: maintenanceBy.isEmpty
                                ? 'Unassigned'
                                : maintenanceBy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEditSchedule,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 17),
                  label: const Text('Edit schedule'),
                ),
                OutlinedButton.icon(
                  onPressed: onSnooze,
                  icon: const Icon(Icons.update_rounded, size: 17),
                  label: const Text('+7 days'),
                ),
                ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16864A),
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Open asset details',
                  onPressed: onViewAsset,
                  icon: const Icon(Icons.open_in_new_rounded, size: 19),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 15),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 20),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertMetadata extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AlertMetadata({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.subText),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.subText, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _AlertViewTabs extends StatelessWidget {
  final WebAlertView selected;
  final Map<WebAlertView, int> counts;
  final Map<WebAlertView, int> unreadCounts;
  final ValueChanged<WebAlertView> onSelected;

  const _AlertViewTabs({
    required this.selected,
    required this.counts,
    required this.unreadCounts,
    required this.onSelected,
  });

  String _label(WebAlertView view) => switch (view) {
    WebAlertView.checkoutDue => 'Check-out Due',
    WebAlertView.maintenanceDue => 'Maintenance Due',
    WebAlertView.maintenanceOverdue => 'Maintenance Overdue',
    WebAlertView.warrantyExpiry => 'Warranty Expiry',
  };

  IconData _icon(WebAlertView view) => switch (view) {
    WebAlertView.checkoutDue => Icons.assignment_return_outlined,
    WebAlertView.maintenanceDue => Icons.build_circle_outlined,
    WebAlertView.maintenanceOverdue => Icons.warning_amber_rounded,
    WebAlertView.warrantyExpiry => Icons.verified_user_outlined,
  };

  Color _color(WebAlertView view) => switch (view) {
    WebAlertView.checkoutDue => const Color(0xFFF59F00),
    WebAlertView.maintenanceDue => const Color(0xFF7C4DDB),
    WebAlertView.maintenanceOverdue => const Color(0xFFE53935),
    WebAlertView.warrantyExpiry => const Color(0xFFEF476F),
  };

  @override
  Widget build(BuildContext context) {
    return WebHoverSurface(
      liftOnHover: false,
      padding: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 920
              ? (constraints.maxWidth - 30) / 4
              : constraints.maxWidth >= 520
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: WebAlertView.values
                .map((view) {
                  final active = selected == view;
                  final color = _color(view);
                  final unread = unreadCounts[view] ?? 0;
                  return SizedBox(
                    width: itemWidth,
                    child: Material(
                      color: active
                          ? color.withValues(alpha: .11)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelected(view),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? color.withValues(alpha: .65)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  _icon(view),
                                  color: color,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _label(view),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: active ? color : AppColors.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${counts[view] ?? 0} records',
                                      style: const TextStyle(
                                        color: AppColors.subText,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _UnifiedAlertsDirectory extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_UnifiedAlertEntry> entries;
  final int totalResults;
  final TextEditingController searchController;
  final String searchQuery;
  final String urgencyFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onUrgencyChanged;
  final ValueChanged<_UnifiedAlertEntry> onViewAsset;
  final ValueChanged<_UnifiedAlertEntry> onEditMaintenance;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _UnifiedAlertsDirectory({
    required this.title,
    required this.icon,
    required this.entries,
    required this.totalResults,
    required this.searchController,
    required this.searchQuery,
    required this.urgencyFilter,
    required this.onSearchChanged,
    required this.onUrgencyChanged,
    required this.onViewAsset,
    required this.onEditMaintenance,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverSurface(
      liftOnHover: false,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: AppColors.primaryColor, size: 23),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Review deadlines and open the related asset record',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _AlertChip(
                  label: '$totalResults records',
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final search = TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search asset, tag ID, person or branch',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    );
                    final filter = DropdownButtonFormField<String>(
                      initialValue: urgencyFilter,
                      decoration: const InputDecoration(
                        labelText: 'Urgency',
                        prefixIcon: Icon(Icons.tune_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All alerts'),
                        ),
                        DropdownMenuItem(
                          value: 'Overdue',
                          child: Text('Overdue'),
                        ),
                        DropdownMenuItem(
                          value: 'Due today',
                          child: Text('Due today'),
                        ),
                        DropdownMenuItem(
                          value: 'Upcoming',
                          child: Text('Upcoming'),
                        ),
                      ],
                      onChanged: (value) => onUrgencyChanged(value ?? 'All'),
                    );
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: [search, const SizedBox(height: 10), filter],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: 12),
                        SizedBox(width: 230, child: filter),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const _AlertEmptyState()
                else
                  ...entries.map(
                    (entry) => _UnifiedAlertCard(
                      entry: entry,
                      onViewAsset: () => onViewAsset(entry),
                      onEditMaintenance: () => onEditMaintenance(entry),
                    ),
                  ),
                if (totalResults > 0) ...[
                  const SizedBox(height: 7),
                  _PaginationBar(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    totalItems: totalResults,
                    pageSize: _WebAssetDashboardPageState._assetsPerPage,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedAlertCard extends StatefulWidget {
  final _UnifiedAlertEntry entry;
  final VoidCallback onViewAsset;
  final VoidCallback onEditMaintenance;

  const _UnifiedAlertCard({
    required this.entry,
    required this.onViewAsset,
    required this.onEditMaintenance,
  });

  @override
  State<_UnifiedAlertCard> createState() => _UnifiedAlertCardState();
}

class _UnifiedAlertCardState extends State<_UnifiedAlertCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final days = date.difference(today).inDays;
    final isExpired = days < 0;
    final isDueSoon = days >= 0 && days <= 7;
    final color = isExpired
        ? const Color(0xFFE53935)
        : isDueSoon
        ? const Color(0xFFF59F00)
        : const Color(0xFF2878F0);
    final status = isExpired
        ? entry.view == WebAlertView.warrantyExpiry
              ? 'Expired ${-days}d ago'
              : 'Overdue by ${-days}d'
        : days == 0
        ? 'Due today'
        : isDueSoon
        ? 'Due in $days days'
        : 'Active';
    final dateLabel =
        '${entry.date.day.toString().padLeft(2, '0')}/'
        '${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}';
    final isMaintenance =
        entry.view == WebAlertView.maintenanceDue ||
        entry.view == WebAlertView.maintenanceOverdue;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color.lerp(Colors.white, color, hovered ? .055 : .025),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: color.withValues(alpha: hovered ? .42 : .20),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .13),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: hovered ? .18 : .11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_entryIcon(entry.view), color: color, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            entry.assetName.isEmpty
                                ? entry.itemCode
                                : entry.assetName,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            entry.itemCode,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _AlertChip(label: status, color: color),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.title,
                        style: const TextStyle(
                          color: Color(0xFF3B4B63),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (entry.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          entry.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 17,
                        runSpacing: 6,
                        children: [
                          _AlertMetadata(
                            icon: Icons.event_outlined,
                            label: dateLabel,
                          ),
                          _AlertMetadata(
                            icon: Icons.location_on_outlined,
                            label: entry.branch.isEmpty
                                ? 'No branch'
                                : entry.branch,
                          ),
                          if (entry.assignedTo.trim().isNotEmpty)
                            _AlertMetadata(
                              icon: entry.view == WebAlertView.warrantyExpiry
                                  ? Icons.numbers_outlined
                                  : Icons.person_outline_rounded,
                              label: entry.assignedTo,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isMaintenance)
                  OutlinedButton.icon(
                    onPressed: widget.onEditMaintenance,
                    icon: const Icon(Icons.edit_calendar_outlined, size: 17),
                    label: const Text('Edit schedule'),
                  ),
                OutlinedButton.icon(
                  onPressed: entry.asset == null ? null : widget.onViewAsset,
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('View asset'),
                ),
              ],
            );
            if (constraints.maxWidth < 830) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 13),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _entryIcon(WebAlertView view) => switch (view) {
    WebAlertView.checkoutDue => Icons.assignment_return_outlined,
    WebAlertView.maintenanceDue => Icons.build_circle_outlined,
    WebAlertView.maintenanceOverdue => Icons.warning_amber_rounded,
    WebAlertView.warrantyExpiry => Icons.verified_user_outlined,
  };
}
