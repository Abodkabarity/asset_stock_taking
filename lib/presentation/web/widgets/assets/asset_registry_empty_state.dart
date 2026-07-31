part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistryEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _AssetRegistryEmptyState({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      margin: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffedf3ff), Color(0xffe9f7fb)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffd6e4fa)),
                ),
                child: Icon(
                  hasFilters
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasFilters ? 'No matching assets found' : 'No assets available',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasFilters
                    ? 'Change your search terms or clear the current filters.'
                    : 'New asset records will appear in this directory.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(height: 17),
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff4263eb),
                    side: const BorderSide(color: Color(0xffbdccef)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
