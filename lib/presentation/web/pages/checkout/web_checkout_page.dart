part of '../../../pages/web_asset_dashboard_page.dart';

extension _CheckoutPageExtension on _WebAssetDashboardPageState {
  Widget _checkoutPanel() {
    final available = assets
        .where(_isOperationallyAvailable)
        .toList(growable: false);
    return _checkoutWorkspace(
      isCheckIn: false,
      total: activeCheckouts.length,
      primaryLabel: 'Select Asset',
      onPrimary: _openCheckoutAssetPicker,
      body: activeCheckouts.isEmpty
          ? const _CheckoutEmptyState(
              icon: Icons.assignment_ind_outlined,
              title: 'No assets are currently checked out',
              message:
                  'Select an available asset to assign it to a team member.',
            )
          : _ActiveCheckoutList(
              checkouts: activeCheckouts,
              onCheckIn: _openCheckinDetails,
            ),
      stats: [
        _CheckoutStat(
          icon: Icons.assignment_ind_outlined,
          color: const Color(0xff4263eb),
          title: 'Available Assets',
          value: available.length.toString(),
          subtitle: 'Ready to assign',
        ),
        _CheckoutStat(
          icon: Icons.person_outline_rounded,
          color: const Color(0xff0f9f8f),
          title: 'Checked Out',
          value: activeCheckouts.length.toString(),
          subtitle: 'Currently assigned',
        ),
        _CheckoutStat(
          icon: Icons.groups_2_outlined,
          color: const Color(0xff7950f2),
          title: 'People',
          value: checkoutPeople.length.toString(),
          subtitle: 'Available assignees',
        ),
      ],
    );
  }

  Widget _checkinPanel() => _checkoutWorkspace(
    isCheckIn: true,
    total: activeCheckouts.length,
    primaryLabel: 'Select Checked-out Asset',
    onPrimary: _openCheckinAssetPicker,
    body: activeCheckouts.isEmpty
        ? const _CheckoutEmptyState(
            icon: Icons.assignment_return_outlined,
            title: 'Nothing waiting for check-in',
            message:
                'Checked-out assets will appear here when they are ready to return.',
          )
        : _ActiveCheckoutList(
            checkouts: activeCheckouts,
            onCheckIn: _openCheckinDetails,
          ),
    stats: [
      _CheckoutStat(
        icon: Icons.pending_actions_outlined,
        color: const Color(0xfff59f00),
        title: 'Pending Returns',
        value: activeCheckouts.length.toString(),
        subtitle: 'Assets to check in',
      ),
      _CheckoutStat(
        icon: Icons.today_outlined,
        color: const Color(0xffe8590c),
        title: 'Due Today',
        value: _dueCheckoutsCount().toString(),
        subtitle: 'Expected return date',
      ),
      _CheckoutStat(
        icon: Icons.person_outline_rounded,
        color: const Color(0xff4263eb),
        title: 'Assigned People',
        value: activeCheckouts
            .map((row) => row['assigned_to']?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .length
            .toString(),
        subtitle: 'Current custody',
      ),
    ],
  );

  int _dueCheckoutsCount() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return activeCheckouts.where((row) {
      final due = DateTime.tryParse(row['due_date']?.toString() ?? '');
      if (due == null) return false;
      final dateOnly = DateTime(due.year, due.month, due.day);
      return !dateOnly.isAfter(todayOnly);
    }).length;
  }

  Widget _checkoutWorkspace({
    required bool isCheckIn,
    required int total,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required List<_CheckoutStat> stats,
    required Widget body,
  }) {
    final title = isCheckIn ? 'Check-in Center' : 'Check-out Center';
    final description = isCheckIn
        ? 'Return assigned assets, preserve their custody history and restore availability.'
        : 'Assign assets to your team with a clear custody trail and expected return date.';
    final color = isCheckIn ? const Color(0xff0f9f8f) : const Color(0xff4263eb);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 136),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCheckIn
                  ? const [
                      Color(0xff083c4a),
                      Color(0xff0f716d),
                      Color(0xff159b8b),
                    ]
                  : const [
                      Color(0xff102b50),
                      Color(0xff174b82),
                      Color(0xff2463a8),
                    ],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final information = Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    child: Icon(
                      isCheckIn
                          ? Icons.assignment_return_rounded
                          : Icons.assignment_ind_rounded,
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
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            _CheckoutCountBadge(label: '$total active'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xffd9e8f8),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xff9fd8ff),
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Every action is recorded in asset history',
                              style: TextStyle(
                                color: Color(0xffd9e8f8),
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
                onPressed: onPrimary,
                icon: Icon(
                  isCheckIn
                      ? Icons.assignment_return_outlined
                      : Icons.add_rounded,
                ),
                label: Text(primaryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              );
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 20),
                        action,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: information),
                        const SizedBox(width: 20),
                        action,
                      ],
                    );
            },
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth = width >= 1000
                ? (width - 32) / 3
                : width >= 680
                ? (width - 16) / 2
                : width;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stats
                  .map(
                    (stat) => SizedBox(
                      width: cardWidth,
                      child: _MaintenanceStatCard(
                        icon: stat.icon,
                        color: stat.color,
                        title: stat.title,
                        value: stat.value,
                        subtitle: stat.subtitle,
                      ),
                    ),
                  )
                  .toList(),
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
                  Icon(
                    isCheckIn
                        ? Icons.inventory_2_outlined
                        : Icons.people_alt_outlined,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isCheckIn ? 'Assets Pending Check-in' : 'Active Check-outs',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$total records',
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              body,
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openCheckoutAssetPicker() async {
    final picked = await _showAssetSearchPicker(
      actionLabel: 'Continue to Check-out',
    );
    if (picked == null || picked.isEmpty) return;
    for (final asset in picked) {
      if (!mounted) return;
      final complete = await _openCheckoutDetails(asset);
      if (!complete) break;
    }
  }

  Future<void> _openCheckinAssetPicker() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CheckinPickerDialog(checkouts: activeCheckouts),
    );
    if (selected != null && mounted) await _openCheckinDetails(selected);
  }

  Future<bool> _openCheckoutDetails(AssetStockModel asset) async {
    final checkoutDate = TextEditingController(
      text: _formatPickerDate(DateTime.now()),
    );
    final dueDate = TextEditingController();
    final notes = TextEditingController();
    String? personId;
    String? assignee;
    var checkoutToType = 'Person';
    String? assignedLocation;
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
                  Icons.assignment_ind_rounded,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Check out asset')),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            content: SizedBox(
              width: 760,
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
                            label: 'Check-out Date',
                            controller: checkoutDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CheckoutDateInput(
                            label: 'Due Date (optional)',
                            controller: dueDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check-out to',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 10,
                      children: ['Person', 'Location']
                          .map(
                            (type) => ChoiceChip(
                              label: Text(type),
                              avatar: Icon(
                                type == 'Person'
                                    ? Icons.person_outline
                                    : Icons.location_on_outlined,
                                size: 18,
                              ),
                              selected: checkoutToType == type,
                              onSelected: (_) => setDialogState(() {
                                checkoutToType = type;
                                assignee = type == 'Location'
                                    ? assignedLocation
                                    : null;
                                personId = null;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    if (checkoutToType == 'Person')
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: personId,
                              decoration: const InputDecoration(
                                labelText: 'Assign to person *',
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
                                assignee = checkoutPeople
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
                                  assignee = person['full_name']?.toString();
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
                        initialValue: assignedLocation,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assign to location *',
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
                          assignedLocation = value;
                          assignee = value;
                        }),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
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
                      onChanged: (value) =>
                          setDialogState(() => selectedDepartment = value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notes,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Check-out Notes',
                        hintText: 'Purpose, handover notes or expected use…',
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
                onPressed: assignee == null || assignee!.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('Check Out'),
              ),
            ],
          ),
        ),
      );
      if (saved != true || assignee == null) return false;
      await webRepository.checkOutAsset(
        asset: asset,
        assignedTo: assignee!,
        personId: personId,
        checkoutDate: checkoutDate.text,
        dueDate: dueDate.text,
        notes: notes.text,
        checkoutToType: checkoutToType,
        assignedLocation: assignedLocation ?? '',
        department: selectedDepartment ?? '',
      );
      await webRepository.addActivityLog(
        itemCode: asset.itemCode,
        action: 'check_out',
        description: 'Checked out to $assignee',
        fromBranch: asset.location,
        metadata: {
          'assigned_to': assignee,
          'checkout_to_type': checkoutToType,
          'assigned_location': assignedLocation,
          'department': selectedDepartment,
          'checkout_date': checkoutDate.text,
          'due_date': dueDate.text,
          'notes': notes.text,
        },
      );
      await _loadData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${asset.name} checked out to $assignee')),
        );
      return true;
    } finally {
      checkoutDate.dispose();
      dueDate.dispose();
      notes.dispose();
    }
  }

  Future<void> _openCheckinDetails(Map<String, dynamic> checkout) async {
    final returnDate = TextEditingController(
      text: _formatPickerDate(DateTime.now()),
    );
    final notes = TextEditingController();
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
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
                Icons.assignment_return_rounded,
                color: Color(0xff0f9f8f),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Check in asset')),
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckoutRecordSummary(checkout: checkout),
                  const SizedBox(height: 22),
                  _CheckoutDateInput(
                    label: 'Return Date *',
                    controller: returnDate,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Check-in Notes',
                      hintText: 'Condition on return or other notes…',
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
                backgroundColor: const Color(0xff0f9f8f),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Check In'),
            ),
          ],
        ),
      );
      if (saved != true) return;
      final itemCode = checkout['item_code']?.toString() ?? '';
      await webRepository.checkInAsset(
        checkout: checkout,
        returnDate: returnDate.text,
        notes: notes.text,
      );
      await webRepository.addActivityLog(
        itemCode: itemCode,
        action: 'check_in',
        description: 'Checked in from ${checkout['assigned_to'] ?? 'assignee'}',
        toBranch: checkout['location']?.toString(),
        metadata: {
          'return_date': returnDate.text,
          'notes': notes.text,
          'checkout_id': checkout['id'],
        },
      );
      await _loadData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset checked in successfully')),
        );
    } finally {
      returnDate.dispose();
      notes.dispose();
    }
  }

  Future<Map<String, dynamic>?> _showAddPersonDialog() async {
    final name = TextEditingController();
    final employeeId = TextEditingController();
    final title = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    try {
      final values = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
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
                Icons.person_add_alt_1_rounded,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Add a person')),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: employeeId,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: title,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty)
                  Navigator.pop(context, {
                    'name': name.text,
                    'employeeId': employeeId.text,
                    'title': title.text,
                    'phone': phone.text,
                    'email': email.text,
                  });
              },
              child: const Text('Add Person'),
            ),
          ],
        ),
      );
      if (values == null) return null;
      final person = await webRepository.addPerson(
        fullName: values['name']!,
        employeeId: values['employeeId'] ?? '',
        title: values['title'] ?? '',
        phone: values['phone'] ?? '',
        email: values['email'] ?? '',
      );
      if (mounted) {
        _updateWebState(
          () => checkoutPeople = [...checkoutPeople, person]
            ..sort(
              (a, b) => (a['full_name']?.toString() ?? '')
                  .toLowerCase()
                  .compareTo((b['full_name']?.toString() ?? '').toLowerCase()),
            ),
        );
      }
      return person;
    } finally {
      name.dispose();
      employeeId.dispose();
      title.dispose();
      phone.dispose();
      email.dispose();
    }
  }
}

class _CheckoutStat {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  const _CheckoutStat({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class _CheckoutCountBadge extends StatelessWidget {
  final String label;
  const _CheckoutCountBadge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CheckoutDateInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _CheckoutDateInput({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: true,
    onTap: () async {
      final now = DateTime.now();
      final initial =
          DateTime.tryParse(controller.text.split('/').reversed.join('-')) ??
          now;
      final date = await showWebSingleDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        title: label,
      );
      if (date != null)
        controller.text =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    },
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: const Icon(Icons.calendar_month_outlined),
    ),
  );
}

class _CheckoutAssetSummary extends StatelessWidget {
  final AssetStockModel asset;
  const _CheckoutAssetSummary({required this.asset});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xfff4f8ff),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffd8e5fb)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${asset.itemCode} · ${asset.location}',
                style: const TextStyle(color: AppColors.subText),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CheckoutRecordSummary extends StatelessWidget {
  final Map<String, dynamic> checkout;
  const _CheckoutRecordSummary({required this.checkout});
  @override
  Widget build(BuildContext context) {
    final name = checkout['asset_name']?.toString() ?? '';
    final code = checkout['item_code']?.toString() ?? '';
    final person = checkout['assigned_to']?.toString() ?? '';
    final date = checkout['checkout_date']?.toString() ?? '';
    final destination = checkout['assigned_location']?.toString().trim() ?? '';
    final department = checkout['department']?.toString().trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffeffbf8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffcbeee5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            '$code · Checked out to $person',
            style: const TextStyle(color: AppColors.subText),
          ),
          if (destination.isNotEmpty || department.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                [
                  destination,
                  department,
                ].where((value) => value.isNotEmpty).join(' · '),
                style: const TextStyle(color: AppColors.subText),
              ),
            ),
          if (date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'Checked out: $date',
                style: const TextStyle(color: AppColors.subText),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckoutEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _CheckoutEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 210,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: const Color(0xff9bacbf)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subText),
          ),
        ],
      ),
    ),
  );
}

class _ActiveCheckoutList extends StatelessWidget {
  final List<Map<String, dynamic>> checkouts;
  final ValueChanged<Map<String, dynamic>> onCheckIn;
  const _ActiveCheckoutList({required this.checkouts, required this.onCheckIn});
  @override
  Widget build(BuildContext context) => Column(
    children: checkouts
        .map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xfffbfcff),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffe1e8f3)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  final details = Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xffeaf1ff),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['asset_name']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${row['item_code'] ?? ''} · ${row['assigned_to'] ?? ''}',
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
                  final button = OutlinedButton.icon(
                    onPressed: () => onCheckIn(row),
                    icon: const Icon(
                      Icons.assignment_return_outlined,
                      size: 18,
                    ),
                    label: const Text('Check In'),
                  );
                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            details,
                            const SizedBox(height: 12),
                            button,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: details),
                            button,
                          ],
                        );
                },
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _CheckinPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> checkouts;
  const _CheckinPickerDialog({required this.checkouts});
  @override
  State<_CheckinPickerDialog> createState() => _CheckinPickerDialogState();
}

class _CheckinPickerDialogState extends State<_CheckinPickerDialog> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final q = search.trim().toLowerCase();
    final records = widget.checkouts
        .where(
          (row) =>
              q.isEmpty ||
              '${row['asset_name']} ${row['item_code']} ${row['assigned_to']}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Select checked-out asset'),
      content: SizedBox(
        width: 720,
        height: 440,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => search = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search asset, tag ID or assignee',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('No checked-out assets found'))
                  : ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = records[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.inventory_2_outlined),
                          ),
                          title: Text(row['asset_name']?.toString() ?? ''),
                          subtitle: Text(
                            '${row['item_code'] ?? ''} · ${row['assigned_to'] ?? ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, row),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
