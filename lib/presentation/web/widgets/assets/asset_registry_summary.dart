part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistrySummaryStrip extends StatelessWidget {
  final int totalAssets;
  final double totalValue;
  final int locationsCount;
  final int categoriesCount;
  final bool inventoryMode;

  const _AssetRegistrySummaryStrip({
    required this.totalAssets,
    required this.totalValue,
    required this.locationsCount,
    required this.categoriesCount,
    this.inventoryMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AssetRegistryMetricData(
        icon: Icons.widgets_outlined,
        color: const Color(0xff4263eb),
        label: inventoryMode ? 'Visible Inventory' : 'Visible Assets',
        value: totalAssets.toString(),
        caption: 'Current filtered scope',
      ),
      _AssetRegistryMetricData(
        icon: Icons.payments_outlined,
        color: const Color(0xff0f9f8f),
        label: inventoryMode ? 'Inventory Value' : 'Asset Value',
        value: totalValue.toStringAsFixed(2),
        caption: 'Total value in AED',
      ),
      _AssetRegistryMetricData(
        icon: Icons.location_on_outlined,
        color: const Color(0xfff59f00),
        label: 'Locations',
        value: locationsCount.toString(),
        caption: inventoryMode
            ? 'Distinct inventory locations'
            : 'Distinct asset locations',
      ),
      _AssetRegistryMetricData(
        icon: Icons.category_outlined,
        color: const Color(0xff7950f2),
        label: 'Categories',
        value: categoriesCount.toString(),
        caption: inventoryMode
            ? 'Inventory category groups'
            : 'Asset category groups',
      ),
    ];

    return WebHoverLift(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xfff9fbff), Color(0xfff7fafc)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffdfe7f2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff183b66).withValues(alpha: 0.035),
              blurRadius: 20,
              spreadRadius: -10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    Expanded(child: _AssetRegistryMetric(data: metrics[index])),
                    if (index != metrics.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            }

            final itemWidth = constraints.maxWidth >= 560
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics.map((metric) {
                return SizedBox(
                  width: itemWidth,
                  child: _AssetRegistryMetric(data: metric),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _AssetRegistryMetricData {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;

  const _AssetRegistryMetricData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });
}

class _AssetRegistryMetric extends StatelessWidget {
  final _AssetRegistryMetricData data;

  const _AssetRegistryMetric({required this.data});

  @override
  Widget build(BuildContext context) {
    return WebDashboardMetricCard(
      icon: data.icon,
      color: data.color,
      title: data.label,
      value: data.value,
      subtitle: data.caption,
      height: 102,
    );
  }
}
