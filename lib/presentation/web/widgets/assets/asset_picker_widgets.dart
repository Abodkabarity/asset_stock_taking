part of '../../../pages/web_asset_dashboard_page.dart';

class _MultiAssetSearchDialog extends StatefulWidget {
  final List<AssetStockModel> assets;
  final List<String> branches;
  final String? initialBranch;
  final String actionLabel;

  const _MultiAssetSearchDialog({
    required this.assets,
    required this.branches,
    required this.initialBranch,
    required this.actionLabel,
  });

  @override
  State<_MultiAssetSearchDialog> createState() =>
      _MultiAssetSearchDialogState();
}

class _MultiAssetSearchDialogState extends State<_MultiAssetSearchDialog> {
  final searchController = TextEditingController();
  final Map<String, AssetStockModel> selectedAssets = {};
  String search = '';
  String? selectedBranch;

  @override
  void initState() {
    super.initState();
    selectedBranch = widget.initialBranch;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<AssetStockModel> get suggestions {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return widget.assets
        .where((asset) {
          final matchesBranch =
              selectedBranch == null || asset.location == selectedBranch;
          final matchesSearch =
              asset.name.toLowerCase().contains(query) ||
              asset.itemCode.toLowerCase().contains(query) ||
              asset.assetCode.toLowerCase().contains(query) ||
              asset.description.toLowerCase().contains(query) ||
              asset.category.toLowerCase().contains(query) ||
              asset.subCategory.toLowerCase().contains(query) ||
              asset.brand.toLowerCase().contains(query) ||
              asset.location.toLowerCase().contains(query);
          return matchesBranch && matchesSearch;
        })
        .toList(growable: false);
  }

  void _toggleAsset(AssetStockModel asset) {
    setState(() {
      if (selectedAssets.containsKey(asset.itemCode)) {
        selectedAssets.remove(asset.itemCode);
      } else {
        selectedAssets[asset.itemCode] = asset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = suggestions;

    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Expanded(child: Text('Select Assets')),
          if (selectedAssets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${selectedAssets.length} selected',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (value) => setState(() => search = value),
                    decoration: InputDecoration(
                      hintText: 'Search by asset, tag ID or location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                searchController.clear();
                                setState(() => search = '');
                              },
                              icon: const Icon(Icons.close, size: 19),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedBranch,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ...alphabetizedWebOptions(widget.branches).map(
                        (branch) => DropdownMenuItem<String>(
                          value: branch,
                          child: Text(branch, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedBranch = value),
                  ),
                ),
              ],
            ),
            if (selectedAssets.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedAssets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final asset = selectedAssets.values.elementAt(index);
                    return InputChip(
                      label: Text('${asset.itemCode} · ${asset.location}'),
                      onDeleted: () => _toggleAsset(asset),
                      deleteIcon: const Icon(Icons.close, size: 17),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: search.trim().isEmpty
                    ? const _AssetSearchPrompt()
                    : results.isEmpty
                    ? const Center(child: Text('No matching assets found'))
                    : Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: AppColors.blueSoft,
                            child: Text(
                              '${results.length} matching assets',
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final asset = results[index];
                                final isSelected = selectedAssets.containsKey(
                                  asset.itemCode,
                                );
                                return Material(
                                  color: isSelected
                                      ? const Color(0xfffff8de)
                                      : Colors.white,
                                  child: InkWell(
                                    onTap: () => _toggleAsset(asset),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (_) =>
                                                _toggleAsset(asset),
                                          ),
                                          _AssetImage(path: asset.imagePath),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  asset.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  asset.itemCode,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: _SearchResultInfo(
                                              icon: Icons.location_on_outlined,
                                              label: 'Location',
                                              value: asset.location,
                                            ),
                                          ),
                                          _StatusPill(status: asset.status),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: selectedAssets.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  selectedAssets.values.toList(growable: false),
                ),
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          label: Text(
            selectedAssets.isEmpty
                ? widget.actionLabel
                : '${widget.actionLabel} (${selectedAssets.length})',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _AssetSearchPrompt extends StatelessWidget {
  const _AssetSearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search, size: 48, color: AppColors.subText),
          SizedBox(height: 10),
          Text(
            'Start typing to find assets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 5),
          Text(
            'Suggestions will appear with their location',
            style: TextStyle(color: AppColors.subText),
          ),
        ],
      ),
    );
  }
}

class _SearchResultInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SearchResultInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.subText),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.subText),
              ),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
