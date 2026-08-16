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
    final branchItems = ['__all__', ...alphabetizedWebOptions(branches)];
    final availableWidth = MediaQuery.sizeOf(context).width - 270;
    final compactActions = availableWidth < 1450;
    final compactProfile = availableWidth < 1660;

    final currentTitle = titleOverride ?? _title;
    final currentSubtitle = subtitleOverride ?? _subtitle;

    return Container(
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFAFCFF), Color(0xFFF5F9FF)],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D174C82),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 330,
            top: -105,
            child: Container(
              width: 210,
              height: 210,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x142878F0), Color(0x002878F0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const _HeaderMenuButton(),
                SizedBox(
                  width: 220,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 330),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .16),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(currentTitle),
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currentSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                  compact: compactActions,
                ),
                _TopNavIcon(
                  icon: Icons.add_box_outlined,
                  label: 'Add Inventory',
                  onTap: onAddInventory,
                  compact: compactActions,
                ),
                _TopNavIcon(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  onTap: onPrint,
                  compact: compactActions,
                ),
                const Spacer(),
                _HeaderBranchSelector(
                  value: branchValue,
                  items: branchItems,
                  onChanged: (value) =>
                      onBranchChanged(value == '__all__' ? null : value),
                ),
                const SizedBox(width: 9),
                _HeaderRefreshButton(onPressed: onRefresh),
                const SizedBox(width: 10),
                Container(width: 1, height: 34, color: AppColors.border),
                const SizedBox(width: 12),
                _HeaderProfile(compact: compactProfile),
              ],
            ),
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
      case WebAssetSection.checkout:
        return 'Check Out';
      case WebAssetSection.checkin:
        return 'Check In';
      case WebAssetSection.reserve:
        return 'Reserve';
      case WebAssetSection.setupAssets:
        return 'Asset Master';
      case WebAssetSection.setupBranches:
        return 'Branches';
      case WebAssetSection.setupClassifications:
        return 'Classifications';
      case WebAssetSection.setupCategories:
        return 'Categories';
      case WebAssetSection.setupSubCategories:
        return 'Sub Categories';
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
      case WebAssetSection.checkout:
        return 'Assign an asset to a person';
      case WebAssetSection.checkin:
        return 'Return checked-out assets to service';
      case WebAssetSection.reserve:
        return 'Reserve assets for their planned destination';
      case WebAssetSection.setupAssets:
        return 'Manage asset master definitions';
      case WebAssetSection.setupBranches:
        return 'Manage pharmacy branches and locations';
      case WebAssetSection.setupClassifications:
        return 'Manage asset confidentiality classifications';
      case WebAssetSection.setupCategories:
        return 'Manage master asset categories';
      case WebAssetSection.setupSubCategories:
        return 'Manage master asset sub categories';
    }
  }
}

class _HeaderMenuButton extends StatefulWidget {
  const _HeaderMenuButton();

  @override
  State<_HeaderMenuButton> createState() => _HeaderMenuButtonState();
}

class _HeaderMenuButtonState extends State<_HeaderMenuButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: hovered ? 1.055 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 130,
          height: 80,
          padding: const EdgeInsets.all(5),
          transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Transform.scale(
              scale: 1,
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/logo_APG_loop.gif',
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.local_pharmacy_rounded,
                    color: Color(0xFF1278ED),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBranchSelector extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _HeaderBranchSelector({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_HeaderBranchSelector> createState() => _HeaderBranchSelectorState();
}

class _HeaderBranchSelectorState extends State<_HeaderBranchSelector> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 194,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: hovered
              ? const [
                  BoxShadow(
                    color: Color(0x302878F0),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: DropdownButtonFormField<String>(
          key: ValueKey(widget.value),
          initialValue: widget.value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Branch',
            isDense: true,
            prefixIcon: Icon(
              Icons.storefront_outlined,
              size: 18,
              color: hovered ? AppColors.primaryColor : AppColors.subText,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hovered ? const Color(0xFF8DCDF5) : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 1.4,
              ),
            ),
          ),
          items: widget.items
              .map((branch) {
                return DropdownMenuItem(
                  value: branch,
                  child: Text(
                    branch == '__all__' ? 'All Branches' : branch,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .toList(growable: false),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class _HeaderRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _HeaderRefreshButton({required this.onPressed});

  @override
  State<_HeaderRefreshButton> createState() => _HeaderRefreshButtonState();
}

class _HeaderRefreshButtonState extends State<_HeaderRefreshButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Tooltip(
        message: 'Refresh',
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hovered ? AppColors.blueSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: hovered
                  ? Border.all(color: const Color(0xFFB8D9FF))
                  : null,
            ),
            child: AnimatedRotation(
              turns: hovered ? .12 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.refresh_rounded,
                size: 22,
                color: hovered ? AppColors.primaryColor : AppColors.headerText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderProfile extends StatefulWidget {
  final bool compact;

  const _HeaderProfile({this.compact = false});

  @override
  State<_HeaderProfile> createState() => _HeaderProfileState();
}

class _HeaderProfileState extends State<_HeaderProfile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WebAppUser?>(
      valueListenable: WebAuthSession.currentUser,
      builder: (context, user, _) => PopupMenuButton<String>(
        tooltip: 'Account menu',
        offset: const Offset(0, 52),
        color: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) async {
          if (value != 'sign_out') return;
          await WebAuthRepository().signOut();
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            enabled: false,
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.userName ?? 'Administrator',
                    style: const TextStyle(
                      color: AppColors.headerText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'sign_out',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 19, color: Color(0xFFE5485D)),
                SizedBox(width: 10),
                Text(
                  'Sign out',
                  style: TextStyle(
                    color: Color(0xFFE5485D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: widget.compact
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(5, 5, 10, 5),
            decoration: BoxDecoration(
              color: !widget.compact && hovered
                  ? AppColors.blueSoft.withValues(alpha: .75)
                  : null,
              borderRadius: BorderRadius.circular(24),
              border: !widget.compact && hovered
                  ? Border.all(color: const Color(0xFFCEE2FF))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  constraints: BoxConstraints(
                    minWidth: widget.compact ? 145 : 39,
                    maxWidth: widget.compact ? 172 : 39,
                  ),
                  height: 39,
                  padding: widget.compact
                      ? const EdgeInsets.fromLTRB(6, 5, 8, 5)
                      : EdgeInsets.zero,
                  transform: Matrix4.translationValues(
                    0,
                    widget.compact && hovered ? -2 : 0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      widget.compact ? 20 : 999,
                    ),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.cyan],
                    ),
                    boxShadow: hovered
                        ? const [
                            BoxShadow(
                              color: Color(0x5500BDEB),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: widget.compact
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 29,
                              height: 29,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .32),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                user?.userName ?? 'Administrator',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: hovered ? .5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            user?.initials ?? 'AP',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          user?.userName ?? 'Administrator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        user?.roleLabel ?? 'Administrator',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.subText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.subText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final WebAssetSection section;
  final int alertCount;
  final WebAlertView selectedAlertView;
  final Map<WebAlertView, int> alertUnreadCounts;
  final ValueChanged<WebAlertView> onAlertSelected;
  final ValueChanged<WebAssetSection> onSelected;
  final VoidCallback onAddAsset;
  final VoidCallback onAddInventory;
  final bool addingAsset;
  final bool addingInventory;

  const _Sidebar({
    required this.section,
    required this.alertCount,
    required this.selectedAlertView,
    required this.alertUnreadCounts,
    required this.onAlertSelected,
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
                        'Asset Managment',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Al Ain Pharmacy',
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
                  _AlertsSidebarGroup(
                    selected: section == WebAssetSection.alerts,
                    selectedView: selectedAlertView,
                    totalUnread: alertCount,
                    unreadCounts: alertUnreadCounts,
                    onSelected: onAlertSelected,
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

                  _SetupSidebarGroup(selected: section, onSelected: onSelected),
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

class _AlertsSidebarGroup extends StatefulWidget {
  final bool selected;
  final WebAlertView selectedView;
  final int totalUnread;
  final Map<WebAlertView, int> unreadCounts;
  final ValueChanged<WebAlertView> onSelected;

  const _AlertsSidebarGroup({
    required this.selected,
    required this.selectedView,
    required this.totalUnread,
    required this.unreadCounts,
    required this.onSelected,
  });

  @override
  State<_AlertsSidebarGroup> createState() => _AlertsSidebarGroupState();
}

class _AlertsSidebarGroupState extends State<_AlertsSidebarGroup> {
  late bool expanded = widget.selected;

  @override
  void didUpdateWidget(covariant _AlertsSidebarGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.notifications_none_rounded,
          label: 'Alerts',
          badge: widget.totalUnread > 0 ? widget.totalUnread.toString() : null,
          selected: widget.selected,
          onTap: () {
            setState(() => expanded = !expanded);
            if (!widget.selected) widget.onSelected(widget.selectedView);
          },
          trailing: AnimatedRotation(
            turns: expanded ? .25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      _alertItem(
                        WebAlertView.checkoutDue,
                        Icons.assignment_ind_outlined,
                        'Check-out Due',
                        const Color(0xfff59f00),
                      ),
                      _alertItem(
                        WebAlertView.maintenanceDue,
                        Icons.build_circle_outlined,
                        'Maintenance Due',
                        const Color(0xfff59f00),
                      ),
                      _alertItem(
                        WebAlertView.maintenanceOverdue,
                        Icons.warning_amber_rounded,
                        'Maintenance Overdue',
                        const Color(0xffe53935),
                      ),
                      _alertItem(
                        WebAlertView.warrantyExpiry,
                        Icons.verified_user_outlined,
                        'Warranty Expiry',
                        const Color(0xffe83e5b),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }

  Widget _alertItem(
    WebAlertView view,
    IconData icon,
    String label,
    Color color,
  ) {
    final unread = widget.unreadCounts[view] ?? 0;
    return _SidebarSubItem(
      icon: icon,
      label: label,
      selected: widget.selected && widget.selectedView == view,
      badge: unread > 0 ? unread.toString() : null,
      badgeColor: color,
      onTap: () => widget.onSelected(view),
    );
  }
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
      section == WebAssetSection.maintenance ||
      section == WebAssetSection.checkout ||
      section == WebAssetSection.checkin ||
      section == WebAssetSection.reserve;

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
                      _SidebarSubItem(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Check Out',
                        selected: widget.selected == WebAssetSection.checkout,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.checkout),
                      ),
                      _SidebarSubItem(
                        icon: Icons.assignment_return_outlined,
                        label: 'Check In',
                        selected: widget.selected == WebAssetSection.checkin,
                        onTap: () => widget.onSelected(WebAssetSection.checkin),
                      ),
                      _SidebarSubItem(
                        icon: Icons.bookmark_added_outlined,
                        label: 'Reserve',
                        selected: widget.selected == WebAssetSection.reserve,
                        onTap: () => widget.onSelected(WebAssetSection.reserve),
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

class _SetupSidebarGroup extends StatefulWidget {
  final WebAssetSection selected;
  final ValueChanged<WebAssetSection> onSelected;

  const _SetupSidebarGroup({required this.selected, required this.onSelected});

  @override
  State<_SetupSidebarGroup> createState() => _SetupSidebarGroupState();
}

class _SetupSidebarGroupState extends State<_SetupSidebarGroup> {
  late bool expanded;

  bool _isSetup(WebAssetSection section) =>
      section == WebAssetSection.setupAssets ||
      section == WebAssetSection.setupBranches ||
      section == WebAssetSection.setupClassifications ||
      section == WebAssetSection.setupCategories ||
      section == WebAssetSection.setupSubCategories;

  @override
  void initState() {
    super.initState();
    expanded = _isSetup(widget.selected);
  }

  @override
  void didUpdateWidget(covariant _SetupSidebarGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSetup(widget.selected) && !_isSetup(oldWidget.selected)) {
      expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.tune_rounded,
          label: 'Setup',
          selected: false,
          onTap: () => setState(() => expanded = !expanded),
          trailing: AnimatedRotation(
            turns: expanded ? .25 : 0,
            duration: const Duration(milliseconds: 220),
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
                        icon: Icons.add_box_outlined,
                        label: 'Add Asset',
                        selected:
                            widget.selected == WebAssetSection.setupAssets,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.setupAssets),
                      ),
                      _SidebarSubItem(
                        icon: Icons.add_business_outlined,
                        label: 'Add Branch',
                        selected:
                            widget.selected == WebAssetSection.setupBranches,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.setupBranches),
                      ),
                      _SidebarSubItem(
                        icon: Icons.security_outlined,
                        label: 'Add Classification',
                        selected:
                            widget.selected ==
                            WebAssetSection.setupClassifications,
                        onTap: () => widget.onSelected(
                          WebAssetSection.setupClassifications,
                        ),
                      ),
                      _SidebarSubItem(
                        icon: Icons.category_outlined,
                        label: 'Add Category',
                        selected:
                            widget.selected == WebAssetSection.setupCategories,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.setupCategories),
                      ),
                      _SidebarSubItem(
                        icon: Icons.account_tree_outlined,
                        label: 'Add Sub Category',
                        selected:
                            widget.selected ==
                            WebAssetSection.setupSubCategories,
                        onTap: () => widget.onSelected(
                          WebAssetSection.setupSubCategories,
                        ),
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
                : hovered
                ? const LinearGradient(
                    colors: [Color(0x33294AEF), Color(0x3300BDEB)],
                  )
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
                : hovered
                ? const [
                    BoxShadow(
                      color: Color(0x5500BDEB),
                      blurRadius: 22,
                      spreadRadius: -5,
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

class _SidebarSubItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final Color badgeColor;

  const _SidebarSubItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeColor = AppColors.primaryColor,
  });

  @override
  State<_SidebarSubItem> createState() => _SidebarSubItemState();
}

class _SidebarSubItemState extends State<_SidebarSubItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          height: 38,
          margin: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: .13),
                      AppColors.cyan.withValues(alpha: .09),
                    ],
                  )
                : hovered
                ? LinearGradient(
                    colors: [
                      AppColors.primaryColor.withValues(alpha: .18),
                      AppColors.cyan.withValues(alpha: .13),
                    ],
                  )
                : null,
            border: hovered && !widget.selected
                ? Border.all(color: AppColors.cyan.withValues(alpha: .22))
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: .22),
                      blurRadius: 18,
                      spreadRadius: -6,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.only(left: 40, right: 14),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: widget.selected || hovered
                    ? AppColors.cyan
                    : Colors.white54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: widget.selected || hovered
                        ? Colors.white
                        : Colors.white60,
                    fontWeight: hovered || widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.badge != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: hovered
                        ? [
                            BoxShadow(
                              color: widget.badgeColor.withValues(alpha: .45),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    widget.badge!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNavIcon extends StatefulWidget {
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
  State<_TopNavIcon> createState() => _TopNavIconState();
}

class _TopNavIconState extends State<_TopNavIcon> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Tooltip(
        message: widget.label,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: hovered ? AppColors.blueSoft.withValues(alpha: .82) : null,
              borderRadius: BorderRadius.circular(11),
              border: hovered
                  ? Border.all(color: const Color(0xFFCEE2FF))
                  : null,
              boxShadow: hovered
                  ? const [
                      BoxShadow(
                        color: Color(0x202878F0),
                        blurRadius: 15,
                        offset: Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: hovered ? .025 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    widget.icon,
                    size: 21,
                    color: hovered
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                  ),
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: hovered ? AppColors.primaryColor : AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
