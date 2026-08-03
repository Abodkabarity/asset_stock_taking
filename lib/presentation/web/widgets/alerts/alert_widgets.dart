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
              'There are no maintenance alerts due in the next 3 days.',
              style: TextStyle(color: AppColors.subText),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHeroCard extends StatelessWidget {
  final int totalAlerts;
  final int dueToday;
  final String scopeLabel;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;

  const _AlertHeroCard({
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
        constraints: const BoxConstraints(minHeight: 170),
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
                  horizontal: 28,
                  vertical: 25,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    final heading = Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .16),
                            ),
                          ),
                          child: const Icon(
                            Icons.notification_important_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Maintenance Alert Center',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '$totalAlerts active alerts • $dueToday due today • $scopeLabel',
                                style: const TextStyle(
                                  color: Color(0xFFC8D8EC),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Review schedules, reschedule maintenance, complete work and open the related asset.',
                                style: TextStyle(
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
                          const SizedBox(height: 18),
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
