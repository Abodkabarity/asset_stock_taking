part of '../../../pages/web_asset_dashboard_page.dart';

class _TransferHeroCard extends StatelessWidget {
  final String title;
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onSelectAssets;

  const _TransferHeroCard({
    required this.title,
    required this.totalAssets,
    required this.selectedBranch,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 136),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
            stops: [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff174b82).withValues(alpha: 0.24),
              blurRadius: 34,
              spreadRadius: -10,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                right: -90,
                top: -130,
                child: Container(
                  width: 310,
                  height: 310,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Positioned(
                right: 155,
                bottom: -115,
                child: Container(
                  width: 245,
                  height: 245,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff59d5e0).withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: 42,
                top: 20,
                child: Transform.rotate(
                  angle: -0.13,
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 142,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 820;

                    final information = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.17),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '$totalAssets assets',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Move assets between branches and sites with a clear, '
                                'organized transfer workflow and better visibility.',
                                style: TextStyle(
                                  color: Color(0xffd9e8f8),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xff9fd8ff),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      selectedBranch ?? 'All Branches',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xffd9e8f8),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final actions = Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        _MaintenanceHeroButton(
                          icon: Icons.add_box_outlined,
                          label: 'Select Asset',
                          filled: true,
                          onTap: onSelectAssets,
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          information,
                          const SizedBox(height: 16),
                          actions,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: information),
                        const SizedBox(width: 24),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferMoveRequest {
  final List<AssetStockModel> assets;
  final String destination;

  const _TransferMoveRequest({required this.assets, required this.destination});
}

class _TransferAssetGroup {
  final String key;
  final List<AssetStockModel> assets;

  const _TransferAssetGroup({required this.key, required this.assets});

  AssetStockModel get representative => assets.first;
  int get quantity => assets.length;
}

class _TransferAssetPickerDialog extends StatefulWidget {
  final List<AssetStockModel> assets;
  final List<String> locations;
  final String? initialLocation;

  const _TransferAssetPickerDialog({
    required this.assets,
    required this.locations,
    required this.initialLocation,
  });

  @override
  State<_TransferAssetPickerDialog> createState() =>
      _TransferAssetPickerDialogState();
}

class _TransferAssetPickerDialogState
    extends State<_TransferAssetPickerDialog> {
  final searchController = TextEditingController();
  String search = '';
  String? sourceLocation;
  String? destination;
  String? selectedGroupKey;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    sourceLocation = widget.initialLocation;
    _selectDefaultDestination();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _sameLocation(String? first, String? second) =>
      first?.trim().toLowerCase() == second?.trim().toLowerCase();

  bool get _groupByAssetCode {
    final normalized = sourceLocation?.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return normalized == 'asset store' || normalized == 'assets store';
  }

  List<String> get _destinationOptions => widget.locations
      .where((location) => !_sameLocation(location, sourceLocation))
      .toList(growable: false);

  void _selectDefaultDestination() {
    final options = _destinationOptions;
    if (destination == null || !options.contains(destination)) {
      destination = options.isEmpty ? null : options.first;
    }
  }

  List<_TransferAssetGroup> get groups {
    final query = search.trim().toLowerCase();
    final grouped = <String, List<AssetStockModel>>{};

    for (final asset in widget.assets) {
      if (!_sameLocation(asset.location, sourceLocation)) continue;
      final matches =
          query.isEmpty ||
          asset.name.toLowerCase().contains(query) ||
          asset.assetCode.toLowerCase().contains(query) ||
          asset.itemCode.toLowerCase().contains(query) ||
          asset.category.toLowerCase().contains(query) ||
          asset.subCategory.toLowerCase().contains(query);
      if (!matches) continue;

      final key = _groupByAssetCode && asset.assetCode.trim().isNotEmpty
          ? asset.assetCode.trim()
          : asset.itemCode.trim();
      grouped.putIfAbsent(key, () => <AssetStockModel>[]).add(asset);
    }

    final result = grouped.entries.map((entry) {
      entry.value.sort((a, b) => a.itemCode.compareTo(b.itemCode));
      return _TransferAssetGroup(key: entry.key, assets: entry.value);
    }).toList();
    result.sort((a, b) {
      final byName = a.representative.name.toLowerCase().compareTo(
        b.representative.name.toLowerCase(),
      );
      return byName == 0 ? a.key.compareTo(b.key) : byName;
    });
    return result;
  }

  _TransferAssetGroup? get selectedGroup {
    for (final group in groups) {
      if (group.key == selectedGroupKey) return group;
    }
    return null;
  }

  void _changeSource(String? value) {
    setState(() {
      sourceLocation = value;
      selectedGroupKey = null;
      quantity = 0;
      _selectDefaultDestination();
    });
  }

  void _selectGroup(_TransferAssetGroup group) {
    setState(() {
      selectedGroupKey = group.key;
      quantity = group.quantity;
    });
  }

  void _setQuantity(int value) {
    setState(() => quantity = value);
  }

  void _submit() {
    final group = selectedGroup;
    final target = destination;
    if (group == null ||
        target == null ||
        target.trim().isEmpty ||
        quantity < 1 ||
        quantity > group.quantity) {
      return;
    }
    final selectedAssets = group.assets.take(quantity).toList(growable: false);
    Navigator.pop(
      context,
      _TransferMoveRequest(assets: selectedAssets, destination: target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups;
    final selected = selectedGroup;
    final totalUnits = visibleGroups.fold<int>(
      0,
      (sum, group) => sum + group.quantity,
    );

    return AlertDialog(
      backgroundColor: const Color(0xfff7f9fd),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 19, 16, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(bottom: BorderSide(color: Color(0xffe4eaf3))),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff4263eb), Color(0xff15aabf)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x304263EB),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: Colors.white,
                size: 26,
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
                      color: Color(0xff17243b),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Asset Store products are grouped by Asset Code for faster quantity transfers.',
                    style: TextStyle(
                      color: Color(0xff7d8ba1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
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
        width: 1040,
        height: (MediaQuery.sizeOf(context).height - 210).clamp(420.0, 620.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => search = value),
                      decoration: InputDecoration(
                        hintText: 'Search product, asset code or item code',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: search.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => search = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 19),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(sourceLocation),
                      initialValue: sourceLocation,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Current location',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                      items: widget.locations
                          .map(
                            (location) => DropdownMenuItem(
                              value: location,
                              child: Text(
                                location,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _changeSource,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _groupByAssetCode
                        ? const [Color(0xffedf3ff), Color(0xffeafafa)]
                        : const [Color(0xfff4f6fa), Color(0xfff8f9fc)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: _groupByAssetCode
                        ? const Color(0xffc9dbff)
                        : const Color(0xffe1e7ef),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _groupByAssetCode
                          ? Icons.auto_awesome_motion_rounded
                          : Icons.inventory_2_outlined,
                      color: const Color(0xff4263eb),
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _groupByAssetCode
                            ? 'Grouped by Asset Code — one row per product'
                            : 'Individual asset selection for this location',
                        style: const TextStyle(
                          color: Color(0xff3f506c),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _TransferCountPill(
                      label: '${visibleGroups.length} products',
                    ),
                    const SizedBox(width: 8),
                    _TransferCountPill(label: '$totalUnits units'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffdfe6f0)),
                  ),
                  child: visibleGroups.isEmpty
                      ? const _TransferGroupEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(10),
                          itemCount: visibleGroups.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final group = visibleGroups[index];
                            return _TransferGroupTile(
                              group: group,
                              selected: group.key == selectedGroupKey,
                              grouped: _groupByAssetCode,
                              onTap: () => _selectGroup(group),
                            );
                          },
                        ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: selected == null
                    ? const SizedBox.shrink(key: ValueKey('no-selection'))
                    : _TransferQuantityPanel(
                        key: ValueKey(selected.key),
                        group: selected,
                        quantity: quantity,
                        destination: destination,
                        destinationOptions: _destinationOptions,
                        onQuantityChanged: _setQuantity,
                        onDestinationChanged: (value) =>
                            setState(() => destination = value),
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed:
              selected == null ||
                  destination == null ||
                  quantity < 1 ||
                  quantity > selected.quantity
              ? null
              : _submit,
          icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
          label: Text(
            selected == null
                ? 'Select a product'
                : quantity < 1
                ? 'Enter quantity'
                : 'Move $quantity unit${quantity == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff4263eb),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _TransferCountPill extends StatelessWidget {
  final String label;

  const _TransferCountPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffd9e4f4)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xff60718a),
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _TransferGroupTile extends StatefulWidget {
  final _TransferAssetGroup group;
  final bool selected;
  final bool grouped;
  final VoidCallback onTap;

  const _TransferGroupTile({
    required this.group,
    required this.selected,
    required this.grouped,
    required this.onTap,
  });

  @override
  State<_TransferGroupTile> createState() => _TransferGroupTileState();
}

class _TransferGroupTileState extends State<_TransferGroupTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final asset = widget.group.representative;
    final active = widget.selected || hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(active ? 4 : 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: widget.selected
              ? const Color(0xffedf3ff)
              : hovered
              ? const Color(0xfff8faff)
              : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: widget.selected
                ? const Color(0xff6d8cff)
                : hovered
                ? const Color(0xffbfd0ee)
                : const Color(0xffedf1f6),
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x14294F87),
                    blurRadius: 17,
                    offset: Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(13),
          child: Row(
            children: [
              _AssetImage(path: asset.imagePath),
              const SizedBox(width: 13),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff24324a),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff8d99aa),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: _SearchResultInfo(
                  icon: widget.grouped
                      ? Icons.qr_code_2_rounded
                      : Icons.confirmation_number_outlined,
                  label: widget.grouped ? 'Asset Code' : 'Item Code',
                  value: widget.grouped ? asset.assetCode : asset.itemCode,
                ),
              ),
              Expanded(
                flex: 2,
                child: _SearchResultInfo(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: asset.location,
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 88),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffeaf8f5),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xffc8ebe4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.group.quantity}',
                      style: const TextStyle(
                        color: Color(0xff0f8f80),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Available',
                      style: TextStyle(
                        color: Color(0xff5d8d87),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: widget.selected ? .5 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  widget.selected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: const Color(0xff4263eb),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferQuantityPanel extends StatelessWidget {
  final _TransferAssetGroup group;
  final int quantity;
  final String? destination;
  final List<String> destinationOptions;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String?> onDestinationChanged;

  const _TransferQuantityPanel({
    super.key,
    required this.group,
    required this.quantity,
    required this.destination,
    required this.destinationOptions,
    required this.onQuantityChanged,
    required this.onDestinationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final codes = group.assets
        .take(quantity)
        .map((asset) => asset.itemCode)
        .toList(growable: false);
    final codePreview = codes.length <= 3
        ? codes.join('  •  ')
        : '${codes.take(2).join('  •  ')}  •  +${codes.length - 2} more';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffeef3ff), Color(0xfff4fbfb)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffc9d9f5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUANTITY TO MOVE',
                  style: TextStyle(
                    color: Color(0xff71809a),
                    fontSize: 9.5,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                TextFormField(
                  key: ValueKey('quantity-${group.key}'),
                  initialValue: '${group.quantity}',
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (value) {
                    onQuantityChanged(int.tryParse(value) ?? 0);
                  },
                  decoration: InputDecoration(
                    labelText: 'Qty to move',
                    hintText: 'Enter quantity',
                    prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                    suffixText: 'of ${group.quantity}',
                    errorText: quantity < 1 || quantity > group.quantity
                        ? 'Enter a value from 1 to ${group.quantity}'
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffcfdaeb)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xff4263eb),
                        width: 1.6,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffe5485d)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              key: ValueKey(destination),
              initialValue: destination,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Move to branch',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: destinationOptions
                  .map(
                    (location) => DropdownMenuItem(
                      value: location,
                      child: Text(location, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onDestinationChanged,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ITEM CODES THAT WILL MOVE',
                  style: TextStyle(
                    color: Color(0xff71809a),
                    fontSize: 9.5,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  codePreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff2664c7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferGroupEmptyState extends StatelessWidget {
  const _TransferGroupEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 46, color: Color(0xff9aa8bd)),
        SizedBox(height: 11),
        Text(
          'No transferable assets in this location',
          style: TextStyle(
            color: Color(0xff34425a),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Try another location or clear the search.',
          style: TextStyle(color: Color(0xff8c99ab), fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _TransferInformationIcon extends StatelessWidget {
  const _TransferInformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xff4169e1).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Color(0xff4169e1),
        size: 20,
      ),
    );
  }
}

class _ModernTransferTableHeader extends StatelessWidget {
  final String operationLabel;

  const _ModernTransferTableHeader({required this.operationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5fb),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56, child: _ModernTransferHeaderText('Photo')),
          const Expanded(
            flex: 2,
            child: _ModernTransferHeaderText('Asset Tag ID'),
          ),
          const Expanded(
            flex: 3,
            child: _ModernTransferHeaderText('Asset Details'),
          ),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Status')),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernTransferHeaderText(
              operationLabel,
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTransferHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernTransferHeaderText(
    this.label, {
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff53627a),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _ModernTransferAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onDetails;
  final VoidCallback onOperation;

  const _ModernTransferAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.actionLabel,
    required this.actionIcon,
    required this.onDetails,
    required this.onOperation,
  });

  @override
  State<_ModernTransferAssetRow> createState() =>
      _ModernTransferAssetRowState();
}

class _ModernTransferAssetRowState extends State<_ModernTransferAssetRow> {
  bool hovered = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (!mounted) return;
      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.025, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(4 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white,
                          const Color(0xfff7faff),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffb9ccef),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff294f87,
                            ).withValues(alpha: 0.065 * hoverValue),
                            blurRadius: 20,
                            spreadRadius: -8,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Hero(
                              tag: 'transfer-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: WebAssetColors.classification(
                                          asset.classification,
                                        ).withValues(alpha: 0.26),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    asset.itemCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff2664c7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff24324a),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (asset.category.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      asset.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff96a1b1),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _StatusPill(status: asset.status),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.location.trim().isEmpty
                                          ? '-'
                                          : asset.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 146,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _TransferActionButton(
                                label: widget.actionLabel,
                                icon: widget.actionIcon,
                                onTap: widget.onOperation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TransferActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TransferActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TransferActionButton> createState() => _TransferActionButtonState();
}

class _TransferActionButtonState extends State<_TransferActionButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.025 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xff4263eb),
                          const Color(0xff3451d1),
                          value,
                        )!,
                        Color.lerp(
                          const Color(0xff5475f5),
                          const Color(0xff4263eb),
                          value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xff4263eb,
                        ).withValues(alpha: 0.20 + (value * 0.10)),
                        blurRadius: 13 + (value * 5),
                        spreadRadius: -5,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransferEmptyState extends StatelessWidget {
  final bool hasSearch;

  const _TransferEmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 285),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
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
                    colors: [Color(0xffedf3ff), Color(0xffe8f6fb)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffd7e4fa)),
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.compare_arrows_rounded,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching transferable assets'
                    : 'No assets available for transfer',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSearch
                    ? 'Try another asset name, tag ID or location.'
                    : 'Assets will appear here once they are available to move between locations.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferHistoryTableHeader extends StatelessWidget {
  const _TransferHistoryTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: const Color(0xfff1f5fb),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xffdfe7f2)),
    ),
    child: const Row(
      children: [
        Expanded(flex: 3, child: _ModernTransferHeaderText('Asset')),
        Expanded(flex: 2, child: _ModernTransferHeaderText('From Branch')),
        SizedBox(width: 52),
        Expanded(flex: 2, child: _ModernTransferHeaderText('To Branch')),
        Expanded(flex: 2, child: _ModernTransferHeaderText('Moved On')),
        Expanded(
          flex: 3,
          child: _ModernTransferHeaderText('Movement / Performed by'),
        ),
      ],
    ),
  );
}

class _TransferHistoryRow extends StatefulWidget {
  final Map<String, dynamic> record;
  final AssetStockModel? asset;

  const _TransferHistoryRow({required this.record, required this.asset});

  @override
  State<_TransferHistoryRow> createState() => _TransferHistoryRowState();
}

class _TransferHistoryRowState extends State<_TransferHistoryRow> {
  bool hovered = false;

  String _value(String key) => widget.record[key]?.toString().trim() ?? '';

  String get _dateLabel {
    final value = DateTime.tryParse(_value('created_at'))?.toLocal();
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final itemCode = _value('item_code');
    final from = _value('from_branch');
    final to = _value('to_branch');
    final description = _value('description');
    final performedBy = _value('user_name').isEmpty
        ? 'System'
        : _value('user_name');

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: hovered ? const Color(0xfff7faff) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hovered ? const Color(0xffb9ccef) : const Color(0xffedf1f6),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: const Color(0xff294f87).withValues(alpha: .07),
                    blurRadius: 20,
                    spreadRadius: -8,
                    offset: const Offset(0, 9),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _AssetImage(path: widget.asset?.imagePath ?? ''),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset?.name.trim().isNotEmpty == true
                              ? widget.asset!.name
                              : 'Asset',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff24324a),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          itemCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff2664c7),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _TransferLocationCell(value: from)),
            const SizedBox(
              width: 52,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xff4263eb),
                size: 20,
              ),
            ),
            Expanded(flex: 2, child: _TransferLocationCell(value: to)),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: Color(0xff94a0b2),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _dateLabel,
                      style: const TextStyle(
                        color: Color(0xff59687f),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description.isEmpty
                        ? 'Transferred from $from to $to'
                        : description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff6d7a8e),
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: Color(0xff1ea97c),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          performedBy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff1b8062),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferLocationCell extends StatelessWidget {
  final String value;

  const _TransferLocationCell({required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xffedf4ff),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: Color(0xff4263eb),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff46546b),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _TransferHistoryEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onSelectAsset;

  const _TransferHistoryEmptyState({
    required this.hasSearch,
    required this.onSelectAsset,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 260),
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: const Color(0xfffbfcfe),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xffe6ebf2)),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xffedf4ff),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffd4e1ff)),
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.swap_horiz_rounded,
              color: const Color(0xff4263eb),
              size: 34,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            hasSearch
                ? 'No matching movements found'
                : 'No completed transfers yet',
            style: const TextStyle(
              color: Color(0xff26354d),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasSearch
                ? 'Try another asset, tag ID or branch.'
                : 'Select an asset to create the first movement record.',
            style: const TextStyle(color: Color(0xff8b98aa), fontSize: 12),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onSelectAsset,
              icon: const Icon(Icons.add_box_outlined, color: Colors.white),
              label: const Text(
                'Select Asset',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4263eb),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
