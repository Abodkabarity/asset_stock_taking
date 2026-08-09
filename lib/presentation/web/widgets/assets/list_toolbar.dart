part of '../../../pages/web_asset_dashboard_page.dart';

class _ListToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final String? selectedStatus;
  final List<String> statuses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onExport;
  final DateTimeRange? selectedDateRange;
  final VoidCallback? onPickDateRange;

  const _ListToolbar({
    required this.searchController,
    required this.searchHint,
    required this.selectedStatus,
    required this.statuses,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onExport,
    this.selectedDateRange,
    this.onPickDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 195,
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
        ...[
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
                ...alphabetizedWebOptions(statuses).map(
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
            onPressed: onPickDateRange,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              backgroundColor: selectedDateRange == null
                  ? null
                  : const Color(0xffedf4ff),
            ),
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              selectedDateRange == null
                  ? 'Date range'
                  : '${_date(selectedDateRange!.start)} – ${_date(selectedDateRange!.end)}',
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

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}
