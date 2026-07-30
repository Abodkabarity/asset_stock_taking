import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../pages/web_asset_dashboard_page.dart';

enum WebShellSection {
  dashboard,
  alerts,
  assets,
  inventory,
  transfer,
  dispose,
  maintenance,
}

class WebAssetShell extends StatelessWidget {
  final Widget child;
  final WebShellSection selectedSection;
  final String title;
  final VoidCallback? onAddAsset;

  const WebAssetShell({
    super.key,
    required this.child,
    required this.selectedSection,
    this.title = 'Assets',
    this.onAddAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _ShellSidebar(selectedSection: selectedSection),
          Expanded(
            child: Stack(
              children: [
                const Positioned(
                  right: -140,
                  top: -180,
                  child: _AmbientGlow(size: 430, color: Color(0x111769FF)),
                ),
                const Positioned(
                  left: 80,
                  bottom: -220,
                  child: _AmbientGlow(size: 480, color: Color(0x0D00C6F7)),
                ),
                Column(
                  children: [
                    _ShellTopBar(title: title, onAddAsset: onAddAsset),
                    Expanded(child: child),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;
  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _ShellTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onAddAsset;

  const _ShellTopBar({required this.title, required this.onAddAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Al Ain Pharmacy Asset Management',
                style: TextStyle(fontSize: 12, color: AppColors.subText),
              ),
            ],
          ),
          const Spacer(),
          _TopLink(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
          _TopLink(
            icon: Icons.add_rounded,
            label: 'Add Asset',
            highlighted: true,
            onTap: onAddAsset ?? () => _goHome(context, WebAssetSection.assets),
          ),
          const SizedBox(width: 14),
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
}

class _TopLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _TopLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  State<_TopLink> createState() => _TopLinkState();
}

class _TopLinkState extends State<_TopLink> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.highlighted
        ? AppColors.primaryColor
        : AppColors.headerText;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: hovered || widget.highlighted
                ? AppColors.blueSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.highlighted
                ? Border.all(
                    color: AppColors.primaryColor.withValues(alpha: .25),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 19, color: foreground),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellSidebar extends StatefulWidget {
  final WebShellSection selectedSection;

  const _ShellSidebar({required this.selectedSection});

  @override
  State<_ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends State<_ShellSidebar> {
  late bool assetsExpanded;

  bool _isAssetSection(WebShellSection section) =>
      section == WebShellSection.assets ||
      section == WebShellSection.transfer ||
      section == WebShellSection.dispose ||
      section == WebShellSection.maintenance;

  @override
  void initState() {
    super.initState();
    assetsExpanded = _isAssetSection(widget.selectedSection);
  }

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
      child: Stack(
        children: [
          Positioned(
            left: -100,
            bottom: -40,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: .06),
              ),
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 27, 18, 26),
                child: _Brand(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _SidebarItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Dashboard',
                      selected:
                          widget.selectedSection == WebShellSection.dashboard,
                      onTap: () => _goHome(context, WebAssetSection.dashboard),
                    ),
                    _SidebarItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Alerts',
                      selected:
                          widget.selectedSection == WebShellSection.alerts,
                      onTap: () => _goHome(context, WebAssetSection.alerts),
                    ),
                    _SidebarItem(
                      icon: Icons.view_in_ar_outlined,
                      label: 'Assets',
                      selected: false,
                      onTap: () =>
                          setState(() => assetsExpanded = !assetsExpanded),
                      trailing: AnimatedRotation(
                        turns: assetsExpanded ? .25 : 0,
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
                        child: assetsExpanded
                            ? Column(
                                children: [
                                  _SidebarSubItem(
                                    icon: Icons.format_list_bulleted,
                                    label: 'List of Assets',
                                    selected:
                                        widget.selectedSection ==
                                        WebShellSection.assets,
                                    onTap: () => _goHome(
                                      context,
                                      WebAssetSection.assets,
                                    ),
                                  ),
                                  _SidebarSubItem(
                                    icon: Icons.open_with,
                                    label: 'Move',
                                    selected:
                                        widget.selectedSection ==
                                        WebShellSection.transfer,
                                    onTap: () => _goHome(
                                      context,
                                      WebAssetSection.transfer,
                                    ),
                                  ),
                                  _SidebarSubItem(
                                    icon: Icons.change_circle_outlined,
                                    label: 'Dispose',
                                    selected:
                                        widget.selectedSection ==
                                        WebShellSection.dispose,
                                    onTap: () => _goHome(
                                      context,
                                      WebAssetSection.dispose,
                                    ),
                                  ),
                                  _SidebarSubItem(
                                    icon: Icons.settings_suggest_outlined,
                                    label: 'Maintenance',
                                    selected:
                                        widget.selectedSection ==
                                        WebShellSection.maintenance,
                                    onTap: () => _goHome(
                                      context,
                                      WebAssetSection.maintenance,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ),
                    _SidebarItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      selected:
                          widget.selectedSection == WebShellSection.inventory,
                      onTap: () => _goHome(context, WebAssetSection.inventory),
                    ),
                    const SizedBox(height: 10),
                    const _SidebarLabel('MANAGEMENT'),
                    _SidebarItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      selected: false,
                      onTap: () => _goHome(context, WebAssetSection.dashboard),
                    ),
                    _SidebarItem(
                      icon: Icons.tune_rounded,
                      label: 'Setup',
                      selected: false,
                      onTap: () => _goHome(context, WebAssetSection.dashboard),
                    ),
                    _SidebarItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help / Support',
                      selected: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, color: AppColors.cyan),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Smart asset control',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
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
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
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
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  final String label;
  const _SidebarLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(15, 8, 15, 7),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || hovered;
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
                size: 21,
                color: active ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 13.5,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.selected)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.only(left: 40, right: 14),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
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
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _goHome(BuildContext context, WebAssetSection section) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => WebAssetDashboardPage(initialSection: section),
    ),
    (route) => false,
  );
}
