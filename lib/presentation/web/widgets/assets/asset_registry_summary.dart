part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistrySummaryStrip extends StatelessWidget {
  final int totalAssets;
  final double totalValue;
  final int locationsCount;
  final int categoriesCount;

  const _AssetRegistrySummaryStrip({
    required this.totalAssets,
    required this.totalValue,
    required this.locationsCount,
    required this.categoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AssetRegistryMetricData(
        icon: Icons.widgets_outlined,
        color: const Color(0xff4263eb),
        label: 'Visible Assets',
        value: totalAssets.toString(),
        caption: 'Current filtered scope',
      ),
      _AssetRegistryMetricData(
        icon: Icons.payments_outlined,
        color: const Color(0xff0f9f8f),
        label: 'Asset Value',
        value: totalValue.toStringAsFixed(2),
        caption: 'Total value in AED',
      ),
      _AssetRegistryMetricData(
        icon: Icons.location_on_outlined,
        color: const Color(0xfff59f00),
        label: 'Locations',
        value: locationsCount.toString(),
        caption: 'Distinct asset locations',
      ),
      _AssetRegistryMetricData(
        icon: Icons.category_outlined,
        color: const Color(0xff7950f2),
        label: 'Categories',
        value: categoriesCount.toString(),
        caption: 'Asset category groups',
      ),
    ];

    return Container(
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
                  if (index != metrics.length - 1)
                    Container(
                      width: 1,
                      height: 54,
                      color: const Color(0xffe4eaf2),
                    ),
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

class _AssetRegistryMetric extends StatefulWidget {
  final _AssetRegistryMetricData data;

  const _AssetRegistryMetric({required this.data});

  @override
  State<_AssetRegistryMetric> createState() => _AssetRegistryMetricState();
}

class _AssetRegistryMetricState extends State<_AssetRegistryMetric> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -2.5 * value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.transparent,
                  data.color.withValues(alpha: 0.045),
                  value,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: data.color.withValues(
                        alpha: 0.10 + (0.04 * value),
                      ),
                      borderRadius: BorderRadius.circular(13 - (value * 1.5)),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22 + value),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff7d8a9e),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff1a2940),
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xffa0aaba),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
