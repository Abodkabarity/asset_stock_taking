part of '../../../pages/web_asset_dashboard_page.dart';

class _ListToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final String? selectedStatus;
  final List<String> statuses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onExport;
  final bool showStatusAndExport;

  const _ListToolbar({
    required this.searchController,
    required this.searchHint,
    required this.selectedStatus,
    required this.statuses,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onExport,
    this.showStatusAndExport = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: showStatusAndExport ? 195 : 280,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        if (showStatusAndExport) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 135,
            child: DropdownButtonFormField<String>(
              key: ValueKey(selectedStatus),
              initialValue: selectedStatus ?? '__all__',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: '__all__',
                  child: Text('All Statuses'),
                ),
                ...statuses.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _assetStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(status, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) =>
                  onStatusChanged(value == '__all__' ? null : value),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onExport,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export'),
          ),
        ],
      ],
    );
  }
}
