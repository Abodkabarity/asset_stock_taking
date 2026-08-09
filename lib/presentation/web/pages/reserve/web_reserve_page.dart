part of '../../../pages/web_asset_dashboard_page.dart';

extension _ReservePageExtension on _WebAssetDashboardPageState {
  Widget _reservePanel() {
    final available = assets
        .where(_isOperationallyAvailable)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReserveHeroCard(
          activeCount: activeReservations.length,
          onSelectAsset: _openReserveAssetPicker,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 1000
                ? (width - 32) / 3
                : width >= 680
                ? (width - 16) / 2
                : width;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _MaintenanceStatCard(
                    icon: Icons.bookmark_added_outlined,
                    color: const Color(0xff7950f2),
                    title: 'Reserved Assets',
                    value: activeReservations.length.toString(),
                    subtitle: 'Temporarily protected from transfer',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MaintenanceStatCard(
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xff4263eb),
                    title: 'Available to Reserve',
                    value: available.length.toString(),
                    subtitle: 'Assets ready for reservation',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MaintenanceStatCard(
                    icon: Icons.location_on_outlined,
                    color: const Color(0xff0f9f8f),
                    title: 'Destination Locations',
                    value: activeReservations
                        .map(
                          (row) =>
                              row['target_location']?.toString().trim() ?? '',
                        )
                        .where((value) => value.isNotEmpty)
                        .toSet()
                        .length
                        .toString(),
                    subtitle: 'Where reservations are planned',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffdfe7f2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: Color(0xff7950f2),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Active Reservations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${activeReservations.length} records',
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (activeReservations.isEmpty)
                const _CheckoutEmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'No active reservations',
                  message:
                      'Reserve an asset to protect it until it is transferred or released.',
                )
              else
                ...activeReservations.map(
                  (reservation) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReservationTile(
                      reservation: reservation,
                      onUnreserve: () => _unreserveAsset(reservation),
                      onTransfer: () => _transferReservedAsset(reservation),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openReserveAssetPicker() async {
    final picked = await _showAssetSearchPicker(
      actionLabel: 'Continue to Reserve',
    );
    if (picked == null || picked.isEmpty) return;
    for (final asset in picked) {
      if (!mounted) return;
      final completed = await _openReserveDetails(asset);
      if (!completed) break;
    }
  }

  Future<bool> _openReserveDetails(AssetStockModel asset) async {
    final startDate = TextEditingController(
      text: _formatPickerDate(DateTime.now()),
    );
    final endDate = TextEditingController();
    final notes = TextEditingController();
    var reserveForType = 'Person';
    String? personId;
    String? reservedFor;
    String? targetLocation;
    String? selectedDepartment;
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 36,
              vertical: 28,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.bookmark_added_outlined,
                  color: Color(0xff7950f2),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Reserve asset')),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            content: SizedBox(
              width: 780,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CheckoutAssetSummary(asset: asset),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _CheckoutDateInput(
                            label: 'Reserve from *',
                            controller: startDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CheckoutDateInput(
                            label: 'Reserve until *',
                            controller: endDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reserve for',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 10,
                      children: ['Person', 'Location'].map((type) {
                        return ChoiceChip(
                          label: Text(type),
                          avatar: Icon(
                            type == 'Person'
                                ? Icons.person_outline
                                : Icons.location_on_outlined,
                            size: 18,
                          ),
                          selected: reserveForType == type,
                          onSelected: (_) => setDialogState(() {
                            reserveForType = type;
                            reservedFor = type == 'Location'
                                ? targetLocation
                                : null;
                            personId = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    if (reserveForType == 'Person')
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: personId,
                              decoration: const InputDecoration(
                                labelText: 'Person *',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  alphabetizedWebOptions(
                                    checkoutPeople.map(
                                      (person) =>
                                          person['full_name']?.toString() ?? '',
                                    ),
                                  ).map((name) {
                                    final person = checkoutPeople.firstWhere(
                                      (row) =>
                                          row['full_name']?.toString() == name,
                                    );
                                    return DropdownMenuItem(
                                      value: person['id']?.toString(),
                                      child: Text(name),
                                    );
                                  }).toList(),
                              onChanged: (value) => setDialogState(() {
                                personId = value;
                                reservedFor = checkoutPeople
                                    .firstWhere(
                                      (row) => row['id']?.toString() == value,
                                    )['full_name']
                                    ?.toString();
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final person = await _showAddPersonDialog();
                              if (person != null) {
                                setDialogState(() {
                                  personId = person['id']?.toString();
                                  reservedFor = person['full_name']?.toString();
                                });
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('New'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: targetLocation,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Location to reserve for *',
                          border: OutlineInputBorder(),
                        ),
                        items: alphabetizedWebOptions(branches)
                            .map(
                              (branch) => DropdownMenuItem(
                                value: branch,
                                child: Text(branch),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setDialogState(() {
                          targetLocation = value;
                          reservedFor = value;
                        }),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: targetLocation,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Transfer destination *',
                              border: OutlineInputBorder(),
                            ),
                            items: alphabetizedWebOptions(branches)
                                .map(
                                  (branch) => DropdownMenuItem(
                                    value: branch,
                                    child: Text(branch),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setDialogState(() {
                              targetLocation = value;
                              if (reserveForType == 'Location') {
                                reservedFor = value;
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedDepartment,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Department (optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: alphabetizedWebOptions(departments)
                                .map(
                                  (department) => DropdownMenuItem(
                                    value: department,
                                    child: Text(department),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setDialogState(
                              () => selectedDepartment = value,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notes,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Reservation notes',
                        hintText:
                            'Reason, delivery instructions or confirmation notes…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7950f2),
                ),
                onPressed:
                    reservedFor == null ||
                        reservedFor!.trim().isEmpty ||
                        targetLocation == null ||
                        targetLocation!.trim().isEmpty ||
                        endDate.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                icon: const Icon(Icons.bookmark_added_outlined),
                label: const Text('Reserve'),
              ),
            ],
          ),
        ),
      );
      if (saved != true || reservedFor == null || targetLocation == null) {
        return false;
      }
      await webRepository.reserveAsset(
        asset: asset,
        reserveForType: reserveForType,
        reservedFor: reservedFor!,
        personId: personId,
        targetLocation: targetLocation!,
        department: selectedDepartment ?? '',
        startDate: startDate.text,
        endDate: endDate.text,
        notes: notes.text,
      );
      await webRepository.addActivityLog(
        itemCode: asset.itemCode,
        action: 'reserve',
        description: 'Reserved for $reservedFor at $targetLocation',
        fromBranch: asset.location,
        toBranch: targetLocation,
        metadata: {
          'reserve_for_type': reserveForType,
          'reserved_for': reservedFor,
          'target_location': targetLocation,
          'department': selectedDepartment,
          'start_date': startDate.text,
          'end_date': endDate.text,
          'notes': notes.text,
        },
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${asset.name} is now reserved')),
        );
      }
      return true;
    } finally {
      startDate.dispose();
      endDate.dispose();
      notes.dispose();
    }
  }

  Future<void> _unreserveAsset(Map<String, dynamic> reservation) async {
    final confirmed = await _confirmReservationAction(
      title: 'Release reservation?',
      message: 'The asset will become available for normal transfer again.',
      label: 'Unreserve',
      color: const Color(0xffe8590c),
    );
    if (!confirmed) return;
    await webRepository.unreserveAsset(reservation: reservation);
    await webRepository.addActivityLog(
      itemCode: reservation['item_code']?.toString() ?? '',
      action: 'unreserve',
      description: 'Reservation released',
      fromBranch: reservation['source_location']?.toString(),
      metadata: {'reservation_id': reservation['id']},
    );
    await _loadData();
  }

  Future<void> _transferReservedAsset(Map<String, dynamic> reservation) async {
    final destination = reservation['target_location']?.toString().trim() ?? '';
    if (destination.isEmpty) return;
    final confirmed = await _confirmReservationAction(
      title: 'Transfer reserved asset?',
      message:
          'This completes the reservation and transfers the asset to $destination.',
      label: 'Transfer',
      color: AppColors.primaryColor,
    );
    if (!confirmed) return;
    await webRepository.transferReservedAsset(reservation: reservation);
    await webRepository.addActivityLog(
      itemCode: reservation['item_code']?.toString() ?? '',
      action: 'reserve_transfer',
      description: 'Reservation completed and transferred to $destination',
      fromBranch: reservation['source_location']?.toString(),
      toBranch: destination,
      metadata: {'reservation_id': reservation['id']},
    );
    await _loadData();
  }

  Future<bool> _confirmReservationAction({
    required String title,
    required String message,
    required String label,
    required Color color,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () => Navigator.pop(context, true),
                child: Text(label),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ReserveHeroCard extends StatelessWidget {
  final int activeCount;
  final VoidCallback onSelectAsset;

  const _ReserveHeroCard({
    required this.activeCount,
    required this.onSelectAsset,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 136),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff31205e), Color(0xff5b3aa6), Color(0xff7651dc)],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final info = Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
              ),
              child: const Icon(
                Icons.bookmark_added_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Reservation Center',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _CheckoutCountBadge(label: '$activeCount active'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Protect an asset for its planned destination until it is released or transferred.',
                    style: TextStyle(
                      color: Color(0xffe5ddff),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xffd8c7ff),
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Reserved assets cannot be moved normally',
                        style: TextStyle(
                          color: Color(0xffe5ddff),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
        final action = ElevatedButton.icon(
          onPressed: onSelectAsset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff5b3aa6),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Select Asset'),
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 20), action],
              )
            : Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 20),
                  action,
                ],
              );
      },
    ),
  );
}

class _ReservationTile extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onUnreserve;
  final VoidCallback onTransfer;

  const _ReservationTile({
    required this.reservation,
    required this.onUnreserve,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final assetName = reservation['asset_name']?.toString() ?? '';
    final itemCode = reservation['item_code']?.toString() ?? '';
    final reservedFor = reservation['reserved_for']?.toString() ?? '';
    final destination = reservation['target_location']?.toString() ?? '';
    final date = reservation['end_date']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xfffcfbff),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe6ddff)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xfff0eaff),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.bookmark_added_outlined,
                  color: Color(0xff7950f2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            assetName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _ReserveStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCode · For $reservedFor · Transfer to $destination${date.isEmpty ? '' : ' · Until $date'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUnreserve,
                icon: const Icon(Icons.lock_open_rounded, size: 17),
                label: const Text('Unreserve'),
              ),
              ElevatedButton.icon(
                onPressed: onTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                label: const Text('Transfer'),
              ),
            ],
          );
          return constraints.maxWidth < 840
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 12), actions],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
        },
      ),
    );
  }
}

class _ReserveStatusBadge extends StatelessWidget {
  const _ReserveStatusBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xfff0eaff),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Reserved',
      style: TextStyle(
        color: Color(0xff6941c6),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
