part of '../../../pages/web_asset_dashboard_page.dart';

class _TopBar extends StatelessWidget {
  final WebAssetSection section;
  final String? titleOverride;
  final String? subtitleOverride;
  final String? selectedBranch;
  final List<String> branches;
  final ValueChanged<String?> onBranchChanged;
  final VoidCallback onAssets;
  final VoidCallback onAddAsset;
  final VoidCallback onAddInventory;
  final VoidCallback onPrint;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.section,
    this.titleOverride,
    this.subtitleOverride,
    required this.selectedBranch,
    required this.branches,
    required this.onBranchChanged,
    required this.onAssets,
    required this.onAddAsset,
    required this.onAddInventory,
    required this.onPrint,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final branchValue = selectedBranch ?? '__all__';
    final branchItems = ['__all__', ...branches];
    final compactActions = MediaQuery.sizeOf(context).width < 1500;

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xF9FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded, color: AppColors.headerText),
          ),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleOverride ?? _title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 3),
              Text(
                subtitleOverride ?? _subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.subText),
              ),
            ],
          ),
          const SizedBox(width: 24),
          _TopNavIcon(
            icon: Icons.inventory_2_outlined,
            label: 'Assets',
            onTap: onAssets,
            compact: compactActions,
          ),
          _TopNavIcon(
            icon: Icons.add_circle_outline,
            label: 'Add Asset',
            onTap: onAddAsset,
          ),
          _TopNavIcon(
            icon: Icons.add_box_outlined,
            label: 'Add Inventory',
            onTap: onAddInventory,
          ),
          _TopNavIcon(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: onPrint,
            compact: compactActions,
          ),
          const Spacer(),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: branchValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: branchItems.map((branch) {
                return DropdownMenuItem(
                  value: branch,
                  child: Text(
                    branch == '__all__' ? 'All Branches' : branch,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                onBranchChanged(value == '__all__' ? null : value);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 22),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 34, color: AppColors.border),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.cyan],
              ),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al Ain Team',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Administrator',
                style: TextStyle(fontSize: 11, color: AppColors.subText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (section) {
      case WebAssetSection.dashboard:
        return 'Dashboard';
      case WebAssetSection.alerts:
        return 'Alerts';
      case WebAssetSection.assets:
        return 'List of Assets';
      case WebAssetSection.inventory:
        return 'List of Inventory';
      case WebAssetSection.transfer:
        return 'Move Assets';
      case WebAssetSection.dispose:
        return 'Disposed Assets';
      case WebAssetSection.maintenance:
        return 'Maintenance';
    }
  }

  String get _subtitle {
    switch (section) {
      case WebAssetSection.dashboard:
        return 'Overview & statistics';
      case WebAssetSection.alerts:
        return 'Time-sensitive asset notifications';
      case WebAssetSection.assets:
        return 'Browse, filter and manage assets';
      case WebAssetSection.inventory:
        return 'Inventory asset register';
      case WebAssetSection.transfer:
        return 'Move assets between locations';
      case WebAssetSection.dispose:
        return 'Disposed asset register';
      case WebAssetSection.maintenance:
        return 'Assets currently under maintenance';
    }
  }
}

class _Sidebar extends StatelessWidget {
  final WebAssetSection section;
  final int alertCount;
  final ValueChanged<WebAssetSection> onSelected;
  final VoidCallback onAddAsset;
  final VoidCallback onAddInventory;
  final bool addingAsset;
  final bool addingInventory;

  const _Sidebar({
    required this.section,
    required this.alertCount,
    required this.onSelected,
    required this.onAddAsset,
    required this.onAddInventory,
    required this.addingAsset,
    required this.addingInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06172F), Color(0xFF082B55), Color(0xFF061B36)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 25, 16, 25),
            child: Row(
              children: [
                _DashboardBrandMark(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Al Ain Pharmacy',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'ASSET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    selected: section == WebAssetSection.dashboard,
                    onTap: () => onSelected(WebAssetSection.dashboard),
                  ),
                  _SidebarItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Alerts',
                    badge: alertCount > 0 ? alertCount.toString() : null,
                    selected: section == WebAssetSection.alerts,
                    onTap: () => onSelected(WebAssetSection.alerts),
                  ),
                  _SidebarGroup(
                    selected: section,
                    onSelected: onSelected,
                    onAddAsset: onAddAsset,
                    addingAsset: addingAsset,
                  ),
                  _InventorySidebarGroup(
                    selected: section,
                    onSelected: onSelected,
                    onAddInventory: onAddInventory,
                    addingInventory: addingInventory,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(15, 15, 15, 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MANAGEMENT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _SidebarItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    selected: false,
                    onTap: () => onSelected(WebAssetSection.dashboard),
                  ),
                  _SidebarItem(
                    icon: Icons.tune_rounded,
                    label: 'Setup',
                    selected: false,
                    onTap: () => onSelected(WebAssetSection.dashboard),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBrandMark extends StatelessWidget {
  const _DashboardBrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.cyan, AppColors.primaryColor],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x5500C6F7),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: const Icon(
      Icons.medication_liquid_outlined,
      color: Colors.white,
      size: 28,
    ),
  );
}

class _SidebarGroup extends StatefulWidget {
  final WebAssetSection selected;
  final ValueChanged<WebAssetSection> onSelected;
  final VoidCallback onAddAsset;
  final bool addingAsset;

  const _SidebarGroup({
    required this.selected,
    required this.onSelected,
    required this.onAddAsset,
    required this.addingAsset,
  });

  @override
  State<_SidebarGroup> createState() => _SidebarGroupState();
}

class _SidebarGroupState extends State<_SidebarGroup> {
  late bool expanded;

  bool _isAssetSection(WebAssetSection section) =>
      section == WebAssetSection.assets ||
      section == WebAssetSection.transfer ||
      section == WebAssetSection.dispose ||
      section == WebAssetSection.maintenance;

  @override
  void initState() {
    super.initState();
    expanded = _isAssetSection(widget.selected);
  }

  @override
  void didUpdateWidget(covariant _SidebarGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAssetSection(widget.selected) &&
        !_isAssetSection(oldWidget.selected)) {
      expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.extension_outlined,
          label: 'Assets',
          selected: false,
          onTap: () => setState(() => expanded = !expanded),
          trailing: AnimatedRotation(
            turns: expanded ? .25 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: Colors.white70,
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      _SidebarSubItem(
                        icon: Icons.format_list_bulleted,
                        label: 'List of Assets',
                        selected:
                            widget.selected == WebAssetSection.assets &&
                            !widget.addingAsset,
                        onTap: () => widget.onSelected(WebAssetSection.assets),
                      ),
                      _SidebarSubItem(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Add Asset',
                        selected: widget.addingAsset,
                        onTap: widget.onAddAsset,
                      ),
                      _SidebarSubItem(
                        icon: Icons.open_with,
                        label: 'Move',
                        selected: widget.selected == WebAssetSection.transfer,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.transfer),
                      ),
                      _SidebarSubItem(
                        icon: Icons.change_circle_outlined,
                        label: 'Dispose',
                        selected: widget.selected == WebAssetSection.dispose,
                        onTap: () => widget.onSelected(WebAssetSection.dispose),
                      ),
                      _SidebarSubItem(
                        icon: Icons.settings_suggest_outlined,
                        label: 'Maintenance',
                        selected:
                            widget.selected == WebAssetSection.maintenance,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.maintenance),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

class _InventorySidebarGroup extends StatefulWidget {
  final WebAssetSection selected;
  final ValueChanged<WebAssetSection> onSelected;
  final VoidCallback onAddInventory;
  final bool addingInventory;

  const _InventorySidebarGroup({
    required this.selected,
    required this.onSelected,
    required this.onAddInventory,
    required this.addingInventory,
  });

  @override
  State<_InventorySidebarGroup> createState() => _InventorySidebarGroupState();
}

class _InventorySidebarGroupState extends State<_InventorySidebarGroup> {
  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.selected == WebAssetSection.inventory;
  }

  @override
  void didUpdateWidget(covariant _InventorySidebarGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == WebAssetSection.inventory &&
        oldWidget.selected != WebAssetSection.inventory) {
      expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.inventory_2_outlined,
          label: 'Inventory',
          selected: false,
          onTap: () => setState(() => expanded = !expanded),
          trailing: AnimatedRotation(
            turns: expanded ? .25 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: Colors.white70,
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      _SidebarSubItem(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'List of Inventory',
                        selected:
                            widget.selected == WebAssetSection.inventory &&
                            !widget.addingInventory,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.inventory),
                      ),
                      _SidebarSubItem(
                        icon: Icons.add_box_outlined,
                        label: 'Add Inventory',
                        selected: widget.addingInventory,
                        onTap: widget.onAddInventory,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          height: 48,
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFF294AEF), Color(0xFF00BDEB)],
                  )
                : null,
            color: !widget.selected && hovered
                ? Colors.white.withValues(alpha: .075)
                : null,
            borderRadius: BorderRadius.circular(13),
            boxShadow: widget.selected
                ? const [
                    BoxShadow(
                      color: Color(0x552358FF),
                      blurRadius: 20,
                      offset: Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.selected || hovered
                    ? Colors.white
                    : Colors.white70,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: widget.selected || hovered
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.badge != null)
                CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.redAccent,
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 38,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.only(left: 40, right: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.cyan : Colors.white54,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _TopNavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: AppColors.secondaryColor),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
