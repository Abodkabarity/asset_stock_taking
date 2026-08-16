import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/barcode_print_service.dart';
import '../../../core/utils/asset_classification_utils.dart';
import '../../../data/models/asset_stock_model.dart';
import '../data/web_asset_repository.dart';
import '../utils/web_dropdown_options.dart';
import '../utils/web_page_route.dart';
import '../widgets/web_asset_image.dart';
import '../widgets/web_asset_info_table.dart';
import '../widgets/web_asset_shell.dart';
import '../widgets/web_hover_surface.dart';
import 'web_asset_add_page.dart';
import 'web_asset_edit_page.dart';

class WebAssetViewPage extends StatelessWidget {
  final AssetStockModel asset;

  const WebAssetViewPage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return WebAssetShell(
      selectedSection: WebShellSection.assets,
      title: 'Asset View',
      onAddAsset: () {
        Navigator.push(
          context,
          webPageRoute(WebAssetAddPage(initialBranch: asset.location)),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: WebAssetDetailsContent(
              asset: asset,
              onBack: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

class WebAssetDetailsContent extends StatelessWidget {
  final AssetStockModel asset;
  final VoidCallback? onBack;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onEdit;

  const WebAssetDetailsContent({
    super.key,
    required this.asset,
    this.onBack,
    this.onPrevious,
    this.onNext,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Assets'),
              ),
              const SizedBox(width: 16),
            ],
            const Icon(Icons.extension_outlined, color: AppColors.primaryColor),
            const SizedBox(width: 10),
            const Text(
              'Asset Details',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.headerText,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: onNext,
              label: const Text('Next'),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _TopCard(asset: asset, onEdit: onEdit),
        const SizedBox(height: 22),
        _TabsCard(key: ValueKey(asset.itemCode), asset: asset),
      ],
    );
  }
}

class _TopCard extends StatelessWidget {
  final AssetStockModel asset;
  final VoidCallback? onEdit;

  const _TopCard({required this.asset, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return WebHoverSurface(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  asset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (AssetClassificationUtils.canPrintBarcode(
                asset.assetClassification,
              )) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final pdf = await BarcodePrintService.generateBarcodePdf(
                      assets: [asset],
                    );
                    await Printing.layoutPdf(onLayout: (_) async => pdf);
                  },
                  icon: const Icon(Icons.print, size: 17),
                  label: const Text('Print'),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  if (onEdit != null) {
                    onEdit!();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WebAssetEditPage(asset: asset),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 17),
                label: const Text('Edit Asset'),
              ),
              const SizedBox(width: 8),
              _MoreActionsButton(asset: asset),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1120) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _assetImage(),
                    const SizedBox(width: 22),
                    Expanded(flex: 3, child: _primaryInfo()),
                    const SizedBox(width: 22),
                    Expanded(flex: 2, child: _secondaryInfo()),
                  ],
                );
              }

              if (constraints.maxWidth >= 720) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _assetImage(),
                        const SizedBox(width: 22),
                        Expanded(child: _primaryInfo()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _secondaryInfo(),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _assetImage()),
                  const SizedBox(height: 18),
                  _primaryInfo(),
                  const SizedBox(height: 18),
                  _secondaryInfo(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _assetImage() {
    return WebAssetImage(path: asset.imagePath, width: 290, height: 260);
  }

  Widget _primaryInfo() {
    return WebAssetInfoTable(
      rows: [
        ('Asset Tag ID', asset.itemCode),
        ('Purchase Date', _date(asset.createdAt)),
        ('Cost', asset.cost.toStringAsFixed(2)),
        ('Brand', asset.brand),
        ('Model', asset.model),
      ],
    );
  }

  Widget _secondaryInfo() {
    return WebAssetInfoTable(
      rows: [
        ('Location', asset.location),
        ('Category', asset.category),
        ('Sub Category', asset.subCategory),
        ('Asset Type', asset.assetClassification),
        ('Status', asset.status),
      ],
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _MoreActionsButton extends StatelessWidget {
  final AssetStockModel asset;

  const _MoreActionsButton({required this.asset});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'move':
            await _showTransferDialog(context, asset);
            break;
          case 'maintenance':
            await _updateStatus(context, asset, 'Maintenance');
            break;
          case 'dispose':
            await _updateStatus(context, asset, 'Disposed');
            break;
          case 'reserve':
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'dispose', child: Text('Dispose')),
        const PopupMenuItem(value: 'maintenance', child: Text('Maintenance')),
        if (asset.status.trim().toLowerCase() != 'reserved')
          const PopupMenuItem(value: 'move', child: Text('Move / Transfer')),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xff16864a),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            Text('More Actions', style: TextStyle(color: Colors.white)),
            SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    AssetStockModel asset,
    String status,
  ) async {
    final repository = WebAssetRepository();
    await repository.updateStatus(itemCode: asset.itemCode, status: status);
    await repository.addActivityLog(
      itemCode: asset.itemCode,
      action: status.toLowerCase() == 'maintenance'
          ? 'maintenance_status'
          : 'dispose_status',
      description: 'Status changed from ${asset.status} to $status',
      fromBranch: asset.location,
      toBranch: asset.location,
      metadata: {'previous_status': asset.status, 'status': status},
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Asset marked as $status')));
  }

  Future<void> _showTransferDialog(
    BuildContext context,
    AssetStockModel asset,
  ) async {
    if (asset.status.trim().toLowerCase() == 'reserved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This asset is reserved. Use Reserve > Transfer or Unreserve first.',
          ),
        ),
      );
      return;
    }
    final repository = WebAssetRepository();
    final branches = alphabetizedWebOptions(await repository.getBranches());
    if (!context.mounted) return;

    String branch = branches.contains(asset.location)
        ? asset.location
        : (branches.isEmpty ? asset.location : branches.first);

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Transfer Asset'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${asset.name} | ${asset.itemCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TransferBox(
                            title: 'From',
                            branch: asset.location,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward),
                        ),
                        Expanded(
                          child: _TransferBox(title: 'To', branch: branch),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: branch,
                      decoration: const InputDecoration(
                        labelText: 'To Branch',
                        border: OutlineInputBorder(),
                      ),
                      items: alphabetizedWebOptions(branches).map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setDialogState(() {
                          branch = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    await repository.transferAsset(itemCode: asset.itemCode, branch: branch);
    await repository.addActivityLog(
      itemCode: asset.itemCode,
      action: 'transfer',
      description: 'Transferred from ${asset.location} to $branch',
      fromBranch: asset.location,
      toBranch: branch,
      metadata: const {},
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Asset transferred')));
  }
}

class _TransferBox extends StatelessWidget {
  final String title;
  final String branch;

  const _TransferBox({required this.title, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff6f8fb),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.subText)),
          const SizedBox(height: 6),
          Text(branch, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TabsCard extends StatefulWidget {
  final AssetStockModel asset;

  const _TabsCard({super.key, required this.asset});

  @override
  State<_TabsCard> createState() => _TabsCardState();
}

class _TabsCardState extends State<_TabsCard> {
  String selectedTab = 'Details';

  @override
  Widget build(BuildContext context) {
    return WebHoverSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TabHeader(
            selectedTab: selectedTab,
            onSelected: (tab) {
              setState(() {
                selectedTab = tab;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: _TabContent(tab: selectedTab, asset: widget.asset),
          ),
        ],
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onSelected;

  const _TabHeader({required this.selectedTab, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Details',
      'Photos',
      'Warranty',
      'Maint.',
      'Reserve',
      'Audit',
      'History',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final selected = tab == selectedTab;

          return Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(tab),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final String tab;
  final AssetStockModel asset;

  const _TabContent({required this.tab, required this.asset});

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 'Photos':
        return _PhotosTab(asset: asset);
      case 'Warranty':
        return _WarrantyTab(asset: asset);
      case 'Maint.':
        return _MaintenanceTab(asset: asset);
      case 'Reserve':
        return const _EmptyTab(
          title: 'Reserve',
          message: 'No reserve records for this asset.',
        );
      case 'Audit':
        return _AuditTab(asset: asset);
      case 'History':
        return _HistoryTab(asset: asset);
      default:
        return _DetailsTab(asset: asset);
    }
  }
}

class _DetailsTab extends StatelessWidget {
  final AssetStockModel asset;

  const _DetailsTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 190, child: Text('Miscellaneous')),
            Expanded(
              child: WebAssetInfoTable(
                rows: [
                  ('Serial No', asset.serialNo),
                  ('Description', asset.description),
                  ('Warranty', asset.hasWarranty ? 'Yes' : 'No'),
                  ('Asset Type', asset.assetClassification),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: WebAssetInfoTable(
                rows: [
                  ('Date Created', _dateTime(asset.createdAt)),
                  ('Current Branch', asset.location),
                  ('Status', asset.status),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final AssetStockModel asset;

  const _PhotosTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    final photos = [
      ('Asset Photo', asset.imagePath),
      if (asset.hasWarranty) ('Warranty Photo', asset.warrantyImagePath),
    ];

    return Wrap(
      spacing: 22,
      runSpacing: 22,
      children: photos.map((photo) {
        return _PhotoTile(title: photo.$1, url: photo.$2);
      }).toList(),
    );
  }
}

class _WarrantyTab extends StatelessWidget {
  final AssetStockModel asset;

  const _WarrantyTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    if (!asset.hasWarranty) {
      return const _EmptyTab(title: 'Warranty', message: 'No warranty saved.');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: WebAssetInfoTable(
            rows: [
              ('Warranty', 'Yes'),
              ('Description', asset.warrantyDescription),
              (
                'Start Date',
                asset.warrantyStartDate.isEmpty ? '-' : asset.warrantyStartDate,
              ),
              (
                'End Date',
                asset.warrantyEndDate.isEmpty ? '-' : asset.warrantyEndDate,
              ),
              (
                'Warranty Serial No.',
                asset.warrantySerialNo.isEmpty ? '-' : asset.warrantySerialNo,
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        _PhotoTile(title: 'Warranty Photo', url: asset.warrantyImagePath),
      ],
    );
  }
}

class _MaintenanceTab extends StatelessWidget {
  final AssetStockModel asset;

  const _MaintenanceTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    final inMaintenance = asset.status.toLowerCase() == 'maintenance';
    return WebAssetInfoTable(
      rows: [
        (
          'Maintenance Status',
          inMaintenance ? 'Under maintenance' : 'No active maintenance',
        ),
        ('Current Status', asset.status),
        ('Last Known Date', _dateTime(asset.createdAt)),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  final AssetStockModel asset;

  const _AuditTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    return WebAssetInfoTable(
      rows: [
        ('Asset Tag ID', asset.itemCode),
        ('Asset Inventory', asset.assetInventory),
        ('Classification', asset.classification),
        ('Created At', _dateTime(asset.createdAt)),
      ],
    );
  }
}

class _HistoryTab extends StatefulWidget {
  final AssetStockModel asset;

  const _HistoryTab({required this.asset});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final repository = WebAssetRepository();
  late Future<List<Map<String, dynamic>>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = repository.getAssetActivityLogs(widget.asset.itemCode);
  }

  @override
  void didUpdateWidget(covariant _HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.itemCode != widget.asset.itemCode) {
      historyFuture = repository.getAssetActivityLogs(widget.asset.itemCode);
    }
  }

  void _refresh() {
    setState(() {
      historyFuture = repository.getAssetActivityLogs(widget.asset.itemCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 190,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text(
                    'Loading complete asset history...',
                    style: TextStyle(color: AppColors.subText),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data ?? const <Map<String, dynamic>>[];
        final hasCreationRecord = records.any((record) {
          final action = record['action']?.toString().toLowerCase() ?? '';
          return action == 'asset_created' || action == 'inventory_created';
        });
        final events = <_HistoryEvent>[
          for (final record in records) _HistoryEvent.fromRecord(record),
          if (!hasCreationRecord)
            _HistoryEvent(
              action: 'asset_created',
              title: 'Asset Created',
              date: _dateTime(widget.asset.createdAt),
              details:
                  'Initial record created at ${widget.asset.location}. User information was not recorded for this legacy event.',
              userName: 'Legacy record',
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xffedf3ff),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.manage_history_rounded,
                    color: AppColors.primaryColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Activity History',
                        style: TextStyle(
                          color: AppColors.headerText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Every web operation and the user who performed it',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff3f6fb),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${events.length} events',
                    style: const TextStyle(
                      color: Color(0xff60718a),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh history',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < events.length; index++)
              _HistoryTimelineItem(
                event: events[index],
                isLast: index == events.length - 1,
              ),
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String title;
  final String? url;

  const _PhotoTile({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          WebAssetImage(path: url, width: 260, height: 190),
        ],
      ),
    );
  }
}

class _HistoryEvent {
  final String action;
  final String title;
  final String date;
  final String details;
  final String userName;
  final String? fromBranch;
  final String? toBranch;

  const _HistoryEvent({
    required this.action,
    required this.title,
    required this.date,
    required this.details,
    required this.userName,
    this.fromBranch,
    this.toBranch,
  });

  factory _HistoryEvent.fromRecord(Map<String, dynamic> record) {
    final action = record['action']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(
      record['created_at']?.toString() ?? '',
    )?.toLocal();
    return _HistoryEvent(
      action: action,
      title: _historyActionTitle(action),
      date: createdAt == null ? '-' : _dateTime(createdAt),
      details: record['description']?.toString().trim().isNotEmpty == true
          ? record['description'].toString().trim()
          : _historyActionTitle(action),
      userName: record['user_name']?.toString().trim().isNotEmpty == true
          ? record['user_name'].toString().trim()
          : 'System / legacy',
      fromBranch: record['from_branch']?.toString(),
      toBranch: record['to_branch']?.toString(),
    );
  }
}

class _HistoryTimelineItem extends StatefulWidget {
  final _HistoryEvent event;
  final bool isLast;

  const _HistoryTimelineItem({required this.event, required this.isLast});

  @override
  State<_HistoryTimelineItem> createState() => _HistoryTimelineItemState();
}

class _HistoryTimelineItemState extends State<_HistoryTimelineItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final color = _historyActionColor(event.action);
    final route = _historyRoute(event.fromBranch, event.toBranch);

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: hovered ? 38 : 34,
                  height: hovered ? 38 : 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: hovered ? 0.17 : 0.10),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: color.withValues(alpha: hovered ? 0.42 : 0.20),
                    ),
                  ),
                  child: Icon(
                    _historyActionIcon(event.action),
                    color: color,
                    size: 19,
                  ),
                ),
                if (!widget.isLast)
                  Container(
                    width: 2,
                    height: 62,
                    color: const Color(0xffe5ebf4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: hovered ? color.withValues(alpha: 0.045) : Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: hovered
                      ? color.withValues(alpha: 0.26)
                      : const Color(0xffe5ebf4),
                ),
                boxShadow: hovered
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 18,
                          spreadRadius: -7,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 650;
                  final activity = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.headerText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.details,
                        style: const TextStyle(
                          color: Color(0xff66758d),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      if (route != null) ...[
                        const SizedBox(height: 7),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.route_outlined,
                              size: 14,
                              color: Color(0xff7c8ba1),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                route,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xff65758d),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                  final actor = Column(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffedf4ff),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primaryColor,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event.userName,
                              style: const TextStyle(
                                color: Color(0xff2457ad),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.date,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [activity, const SizedBox(height: 11), actor],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: activity),
                      const SizedBox(width: 18),
                      actor,
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _historyActionTitle(String action) {
  switch (action.trim().toLowerCase()) {
    case 'asset_created':
      return 'Asset Created';
    case 'inventory_created':
      return 'Inventory Created';
    case 'asset_updated':
      return 'Asset Updated';
    case 'transfer':
      return 'Asset Moved';
    case 'dispose':
      return 'Asset Disposed';
    case 'dispose_update':
      return 'Disposal Record Updated';
    case 'maintenance':
      return 'Maintenance Added';
    case 'maintenance_update':
    case 'maintenance_status':
    case 'maintenance_schedule_updated':
      return 'Maintenance Updated';
    case 'maintenance_snoozed':
      return 'Maintenance Postponed';
    case 'maintenance_completed':
      return 'Maintenance Completed';
    case 'check_out':
      return 'Asset Checked Out';
    case 'check_in':
      return 'Asset Checked In';
    case 'reserve':
      return 'Asset Reserved';
    case 'unreserve':
      return 'Reservation Released';
    case 'reserve_transfer':
      return 'Reserved Asset Transferred';
    case 'dispose_status':
      return 'Disposal Status Changed';
    default:
      final words = action.replaceAll('_', ' ').trim();
      return words.isEmpty ? 'Asset Activity' : words;
  }
}

IconData _historyActionIcon(String action) {
  switch (action.trim().toLowerCase()) {
    case 'asset_created':
    case 'inventory_created':
      return Icons.add_box_outlined;
    case 'asset_updated':
      return Icons.edit_outlined;
    case 'transfer':
    case 'reserve_transfer':
      return Icons.swap_horiz_rounded;
    case 'dispose':
    case 'dispose_update':
    case 'dispose_status':
      return Icons.delete_outline_rounded;
    case 'maintenance':
    case 'maintenance_update':
    case 'maintenance_status':
      return Icons.build_outlined;
    case 'check_out':
      return Icons.assignment_ind_outlined;
    case 'check_in':
      return Icons.assignment_return_outlined;
    case 'reserve':
    case 'unreserve':
      return Icons.bookmark_outline_rounded;
    default:
      return Icons.history_rounded;
  }
}

Color _historyActionColor(String action) {
  final value = action.trim().toLowerCase();
  if (value.contains('dispose')) return const Color(0xffe5484d);
  if (value.contains('maintenance')) return const Color(0xfff59f00);
  if (value.contains('reserve')) return const Color(0xff7950f2);
  if (value.contains('check')) return const Color(0xff0ca678);
  if (value.contains('transfer') || value == 'move') {
    return const Color(0xff4263eb);
  }
  return AppColors.primaryColor;
}

String? _historyRoute(String? from, String? to) {
  final cleanFrom = from?.trim() ?? '';
  final cleanTo = to?.trim() ?? '';
  if (cleanFrom.isEmpty && cleanTo.isEmpty) return null;
  if (cleanFrom.isNotEmpty && cleanTo.isNotEmpty && cleanFrom != cleanTo) {
    return '$cleanFrom → $cleanTo';
  }
  return cleanTo.isNotEmpty ? cleanTo : cleanFrom;
}

class _EmptyTab extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyTab({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppColors.subText)),
      ],
    );
  }
}

String _dateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year} $hour:$minute';
}
