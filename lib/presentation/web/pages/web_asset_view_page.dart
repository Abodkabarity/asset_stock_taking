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
    await WebAssetRepository().updateStatus(
      itemCode: asset.itemCode,
      status: status,
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

class _HistoryTab extends StatelessWidget {
  final AssetStockModel asset;

  const _HistoryTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    final events = [
      _HistoryEvent(
        title: 'Asset Created',
        date: _dateTime(asset.createdAt),
        details: asset.location,
      ),
      _HistoryEvent(
        title: 'Current Status',
        date: _dateTime(asset.createdAt),
        details: asset.status,
      ),
      _HistoryEvent(
        title: 'Current Location',
        date: _dateTime(asset.createdAt),
        details: asset.location,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((event) => event).toList(),
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

class _HistoryEvent extends StatelessWidget {
  final String title;
  final String date;
  final String details;

  const _HistoryEvent({
    required this.title,
    required this.date,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 170,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 170, child: Text(date)),
          Expanded(child: Text(details)),
        ],
      ),
    );
  }
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
