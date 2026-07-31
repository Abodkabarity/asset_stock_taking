part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistryRecentPanel extends StatelessWidget {
  final List<AssetStockModel> assets;
  final Future<void> Function(AssetStockModel asset) onDetails;
  final Future<void> Function(AssetStockModel asset) onTransfer;
  final Future<bool> Function(AssetStockModel asset) onMaintenance;
  final Future<bool> Function(AssetStockModel asset) onDispose;

  const _AssetRegistryRecentPanel({
    required this.assets,
    required this.onDetails,
    required this.onTransfer,
    required this.onMaintenance,
    required this.onDispose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffdfe7f2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1d3557).withValues(alpha: 0.045),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xff4263eb).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xff4263eb),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Assets',
                          style: TextStyle(
                            color: Color(0xff17243b),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Recently created active asset records',
                          style: TextStyle(
                            color: Color(0xff8a97a9),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f5fb),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '${assets.length} records',
                      style: const TextStyle(
                        color: Color(0xff60718a),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xffe8edf4)),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1120
                    ? 1120.0
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const _AssetRegistryTableHeader(),
                          if (assets.isEmpty)
                            const SizedBox(
                              height: 150,
                              child: Center(
                                child: Text(
                                  'No recent assets found',
                                  style: TextStyle(
                                    color: Color(0xff8794a7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            const SizedBox(height: 8),
                            for (var index = 0; index < assets.length; index++)
                              _AssetRegistryRow(
                                key: ValueKey(
                                  'recent-${assets[index].itemCode}',
                                ),
                                asset: assets[index],
                                animationDelay: index * 28,
                                onDetails: () {
                                  onDetails(assets[index]);
                                },
                                onTransfer: () {
                                  onTransfer(assets[index]);
                                },
                                onMaintenance: () {
                                  onMaintenance(assets[index]);
                                },
                                onDispose: () {
                                  onDispose(assets[index]);
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
