import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/asset_stock_model.dart';
import '../../../widgets/branch_dropdown.dart';
import '../web_asset_image.dart';

class TransferMoveRequest {
  final List<AssetStockModel> assets;
  final String destination;

  const TransferMoveRequest({required this.assets, required this.destination});
}

enum _SelectionMode { quantity, codes }

class _AssetGroup {
  final String key;
  final List<AssetStockModel> assets;

  const _AssetGroup(this.key, this.assets);
  AssetStockModel get product => assets.first;
}

/// Both selection methods produce the exact assets shown in the review panel.
class TransferAssetPickerDialog extends StatefulWidget {
  final List<AssetStockModel> assets;
  final List<String> locations;
  final String? initialLocation;

  const TransferAssetPickerDialog({
    super.key,
    required this.assets,
    required this.locations,
    required this.initialLocation,
  });

  @override
  State<TransferAssetPickerDialog> createState() =>
      _TransferAssetPickerDialogState();
}

class _TransferAssetPickerDialogState extends State<TransferAssetPickerDialog> {
  static const _accent = Color(0xff4263eb);
  final _search = TextEditingController();
  final _codeSearch = TextEditingController();
  final _quantity = TextEditingController();
  final _selectedCodes = <String>{};
  _SelectionMode _mode = _SelectionMode.quantity;
  String? _source;
  String? _destination;
  String? _groupKey;

  @override
  void initState() {
    super.initState();
    _source = widget.initialLocation;
    _resetDestination();
  }

  @override
  void dispose() {
    _search.dispose();
    _codeSearch.dispose();
    _quantity.dispose();
    super.dispose();
  }

  String _normalize(String? value) =>
      (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  List<String> get _destinations => widget.locations
      .where((location) => _normalize(location) != _normalize(_source))
      .toList(growable: false);

  void _resetDestination() {
    final options = _destinations;
    if (!options.contains(_destination)) {
      _destination = options.isEmpty ? null : options.first;
    }
  }

  List<_AssetGroup> get _groups {
    final grouped = <String, List<AssetStockModel>>{};
    final seenCodes = <String>{};
    for (final asset in widget.assets) {
      if (_normalize(asset.location) != _normalize(_source) ||
          asset.itemCode.trim().isEmpty ||
          !seenCodes.add(asset.itemCode)) {
        continue;
      }
      final key = asset.assetCode.trim().isEmpty
          ? 'item:${asset.itemCode}'
          : 'asset:${asset.assetCode.trim()}';
      grouped.putIfAbsent(key, () => []).add(asset);
    }
    final result = grouped.entries.map((entry) {
      entry.value.sort((a, b) => a.itemCode.compareTo(b.itemCode));
      return _AssetGroup(entry.key, entry.value);
    }).toList();
    result.sort((a, b) {
      final byName = _normalize(
        a.product.name,
      ).compareTo(_normalize(b.product.name));
      return byName == 0 ? a.key.compareTo(b.key) : byName;
    });
    return result;
  }

  bool _matchesProduct(_AssetGroup group) {
    final query = _normalize(_search.text);
    return query.isEmpty ||
        group.assets.any(
          (asset) => [
            asset.name,
            asset.assetCode,
            asset.itemCode,
            asset.category,
            asset.subCategory,
          ].any((value) => _normalize(value).contains(query)),
        );
  }

  _AssetGroup? get _selectedGroup {
    for (final group in _groups) {
      if (group.key == _groupKey) return group;
    }
    return null;
  }

  List<AssetStockModel> _assetsToMove(_AssetGroup? group) {
    if (group == null) return [];
    if (_mode == _SelectionMode.codes) {
      return group.assets
          .where((asset) => _selectedCodes.contains(asset.itemCode))
          .toList();
    }
    final count = int.tryParse(_quantity.text) ?? 0;
    if (count < 1 || count > group.assets.length) return [];
    return group.assets.take(count).toList();
  }

  void _selectProduct(_AssetGroup group) {
    if (_groupKey == group.key) return;
    setState(() {
      _groupKey = group.key;
      _quantity.text = '${group.assets.length}';
      _selectedCodes.clear();
      _codeSearch.clear();
    });
  }

  void _changeSource(String? value) {
    setState(() {
      _source = value;
      _groupKey = null;
      _selectedCodes.clear();
      _quantity.clear();
      _codeSearch.clear();
      _resetDestination();
    });
  }

  void _submit() {
    final assets = _assetsToMove(_selectedGroup);
    if (assets.isEmpty || !_destinations.contains(_destination)) return;
    Navigator.pop(
      context,
      TransferMoveRequest(assets: assets, destination: _destination!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups.where(_matchesProduct).toList();
    final selected = _selectedGroup;
    final moving = _assetsToMove(selected);
    final canMove = moving.isNotEmpty && _destinations.contains(_destination);
    return AlertDialog(
      backgroundColor: AppColors.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accent, Color(0xff15aabf)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select assets to move',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Move by quantity or choose the exact item codes.',
                    style: TextStyle(color: AppColors.subText, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 1100,
        height:
            (MediaQuery.sizeOf(context).height -
                    (MediaQuery.sizeOf(context).width < 600 ? 320 : 220) -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(180.0, 620.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 880 && constraints.maxHeight >= 440;
              final products = _productList(groups);
              final details = selected == null
                  ? _emptyDetails()
                  : _selectionDetails(selected, moving);
              return Column(
                children: [
                  _filters(constraints.maxWidth),
                  const SizedBox(height: 16),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: products),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: details),
                            ],
                          )
                        : ListView(
                            children: [
                              SizedBox(height: 220, child: products),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: selected == null ? 150 : 560,
                                child: details,
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          key: const ValueKey('confirm-transfer'),
          onPressed: canMove ? _submit : null,
          icon: const Icon(Icons.compare_arrows_rounded),
          label: Text(
            selected == null
                ? 'Select a product'
                : moving.isEmpty
                ? (_mode == _SelectionMode.codes
                      ? 'Select item codes'
                      : 'Enter valid quantity')
                : 'Move ${moving.length} unit${moving.length == 1 ? '' : 's'}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _filters(double width) {
    final search = TextField(
      key: const ValueKey('product-search'),
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search product, asset code or item code',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear product search',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(_search.clear),
              ),
      ),
    );
    final location = BranchDropdown(
      key: const ValueKey('transfer-source'),
      branches: widget.locations,
      value: _source,
      onChanged: _changeSource,
      decoration: const InputDecoration(
        labelText: 'Current location',
        prefixIcon: Icon(Icons.warehouse_outlined),
      ),
    );
    if (width < 600) {
      return Column(children: [search, const SizedBox(height: 12), location]);
    }
    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: location),
      ],
    );
  }

  BoxDecoration get _card => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  );

  Widget _productList(List<_AssetGroup> groups) => Container(
    decoration: _card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 18, color: _accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Available products',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                '${groups.length} products',
                style: const TextStyle(color: AppColors.subText, fontSize: 11),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: groups.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No matching assets in this location',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  key: const ValueKey('transfer-products'),
                  padding: const EdgeInsets.all(10),
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _productTile(groups[index]),
                ),
        ),
      ],
    ),
  );

  Widget _productTile(_AssetGroup group) {
    final product = group.product;
    final selected = group.key == _groupKey;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? AppColors.blueSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? _accent : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('product-${group.key}'),
          onTap: () => _selectProduct(group),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: WebAssetImage(
                    path: product.imagePath,
                    width: 40,
                    height: 40,
                    enableViewer: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.assetCode.trim().isEmpty
                            ? product.itemCode
                            : product.assetCode,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf8f5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${group.assets.length}',
                        style: const TextStyle(
                          color: Color(0xff0f8f80),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const Text(
                        'Available',
                        style: TextStyle(color: Color(0xff5d8d87), fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // A checkmark must stay upright; rotating the selection icon inverted it.
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: _accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyDetails() => Container(
    decoration: _card,
    padding: const EdgeInsets.all(24),
    child: const Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, color: AppColors.subText, size: 34),
            SizedBox(height: 12),
            Text(
              'Choose a product',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Then enter a quantity or select specific item codes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.subText, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _selectionDetails(_AssetGroup group, List<AssetStockModel> moving) {
    final manual = _mode == _SelectionMode.codes;
    final query = _normalize(_codeSearch.text);
    final visibleCodes = group.assets
        .where(
          (asset) =>
              _normalize(asset.itemCode).contains(query) ||
              _normalize(asset.serialNo).contains(query),
        )
        .toList();
    final rows = manual ? visibleCodes : moving;
    final count = int.tryParse(_quantity.text) ?? 0;
    return Container(
      decoration: _card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            group.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${group.assets.length} available at $_source',
            style: const TextStyle(color: AppColors.subText, fontSize: 11),
          ),
          const SizedBox(height: 14),
          SegmentedButton<_SelectionMode>(
            segments: const [
              ButtonSegment(
                value: _SelectionMode.quantity,
                icon: Icon(Icons.numbers_rounded, size: 17),
                label: Text('By quantity'),
              ),
              ButtonSegment(
                value: _SelectionMode.codes,
                icon: Icon(Icons.checklist_rounded, size: 17),
                label: Text('Specific codes'),
              ),
            ],
            showSelectedIcon: false,
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.single),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.blueSoft,
              selectedForegroundColor: _accent,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (manual) ...[
            TextField(
              key: const ValueKey('item-code-search'),
              controller: _codeSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search item code or serial number',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _codeSearch.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear code search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(_codeSearch.clear),
                      ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${moving.length} selected',
                    key: const ValueKey('selected-code-count'),
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: visibleCodes.isEmpty
                      ? null
                      : () => setState(
                          () => _selectedCodes.addAll(
                            visibleCodes.map((asset) => asset.itemCode),
                          ),
                        ),
                  child: Text(
                    query.isEmpty ? 'Select all' : 'Select visible',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: _selectedCodes.isEmpty
                      ? null
                      : () => setState(_selectedCodes.clear),
                  child: const Text('Clear', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ] else ...[
            TextField(
              key: const ValueKey('transfer-quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Quantity to move',
                suffixText: 'of ${group.assets.length}',
                prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                errorText: count < 1 || count > group.assets.length
                    ? 'Enter a value from 1 to ${group.assets.length}'
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Available codes are selected automatically. Review them below.',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: Material(
              key: const ValueKey('transfer-item-codes'),
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          manual
                              ? 'No matching item codes'
                              : 'Enter a valid quantity to preview item codes',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: ValueKey(_mode),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final asset = rows[index];
                        if (!manual) {
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: const Icon(
                              Icons.confirmation_number_outlined,
                              color: _accent,
                              size: 18,
                            ),
                            title: Text(
                              asset.itemCode,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return CheckboxListTile(
                          key: ValueKey('item-code-${asset.itemCode}'),
                          value: _selectedCodes.contains(asset.itemCode),
                          selected: _selectedCodes.contains(asset.itemCode),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: _accent,
                          title: Text(
                            asset.itemCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: asset.serialNo.trim().isEmpty
                              ? null
                              : Text(
                                  'S/N ${asset.serialNo}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              _selectedCodes.add(asset.itemCode);
                            } else {
                              _selectedCodes.remove(asset.itemCode);
                            }
                          }),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          BranchDropdown(
            key: const ValueKey('transfer-destination'),
            branches: _destinations,
            value: _destination,
            onChanged: (value) => setState(() => _destination = value),
            decoration: const InputDecoration(
              labelText: 'Move to branch',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${moving.length} unit${moving.length == 1 ? '' : 's'} will move',
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
