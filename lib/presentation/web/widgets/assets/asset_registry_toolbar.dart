part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final List<String> statuses;
  final int resultsCount;
  final bool hasFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClearFilters;

  const _AssetRegistryToolbar({
    required this.searchController,
    required this.selectedStatus,
    required this.statuses,
    required this.resultsCount,
    required this.hasFilters,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final searchField = Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xfff8fafd),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText:
              'Search asset name, tag ID, category, brand, site or location',
          hintStyle: const TextStyle(
            color: Color(0xff909caf),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xff61718a),
            size: 21,
          ),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );

    final statusFilter = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafd),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey('registry-status-${selectedStatus ?? 'all'}'),
        initialValue: selectedStatus ?? '__all__',
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xff63738b),
        ),
        decoration: const InputDecoration(
          labelText: 'Status',
          labelStyle: TextStyle(color: Color(0xff8794a7), fontSize: 11),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: '__all__',
            child: Text(
              'All Statuses',
              style: TextStyle(
                color: Color(0xff34435a),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...statuses.map((status) {
            return DropdownMenuItem<String>(
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
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff34435a),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (value) {
          onStatusChanged(value == '__all__' ? null : value);
        },
      ),
    );

    final resultBox = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffedf4ff),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffd4e1ff)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            color: Color(0xff4263eb),
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            '$resultsCount results',
            style: const TextStyle(
              color: Color(0xff3156c8),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    final clearButton = Tooltip(
      message: 'Clear filters',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasFilters ? onClearFilters : null,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hasFilters
                  ? const Color(0xfffff3f3)
                  : const Color(0xfff5f7fa),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: hasFilters
                    ? const Color(0xffffd3d5)
                    : const Color(0xffe3e8ef),
              ),
            ),
            child: Icon(
              Icons.filter_alt_off_rounded,
              size: 20,
              color: hasFilters
                  ? const Color(0xffd9485f)
                  : const Color(0xffb0b8c5),
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: statusFilter),
                  const SizedBox(width: 10),
                  resultBox,
                  const SizedBox(width: 10),
                  clearButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 11),
            SizedBox(width: 190, child: statusFilter),
            const SizedBox(width: 11),
            resultBox,
            const SizedBox(width: 9),
            clearButton,
          ],
        );
      },
    );
  }
}
