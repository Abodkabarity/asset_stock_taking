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
    this.title = 'Asset Stock Taking',
    this.onAddAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffedf1f6),
      body: Row(
        children: [
          _ShellSidebar(
            selectedSection: selectedSection,
            onAddAsset: onAddAsset,
          ),
          Expanded(
            child: Column(
              children: [
                _ShellTopBar(title: title, onAddAsset: onAddAsset),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onAddAsset;

  const _ShellTopBar({required this.title, required this.onAddAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/icon.png', height: 50, width: 58),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 32),
          _TopLink(
            icon: Icons.inventory_2_outlined,
            label: 'Assets',
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          _TopLink(
            icon: Icons.add_circle_outline,
            label: 'Asset',
            onTap: onAddAsset ?? () => _goHome(context, WebAssetSection.assets),
          ),
          _TopLink(
            icon: Icons.file_download_outlined,
            label: 'Export',
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          _TopLink(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _goHome(context, WebAssetSection.dashboard),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _TopLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.headerText),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ShellSidebar extends StatelessWidget {
  final WebShellSection selectedSection;
  final VoidCallback? onAddAsset;

  const _ShellSidebar({
    required this.selectedSection,
    required this.onAddAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 28, 22, 24),
            color: AppColors.primaryColor,
            child: const Text(
              'Al Ain Pharmacy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.home_outlined,
            label: 'Dashboard',
            selected: selectedSection == WebShellSection.dashboard,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.notifications_none,
            label: 'Alerts',
            selected: selectedSection == WebShellSection.alerts,
            onTap: () => _goHome(context, WebAssetSection.alerts),
          ),
          _SidebarItem(
            icon: Icons.extension_outlined,
            label: 'Assets',
            selected: true,
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          _SidebarSubItem(
            icon: Icons.format_list_bulleted,
            label: 'List of Assets',
            selected: selectedSection == WebShellSection.assets,
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          _SidebarSubItem(
            icon: Icons.open_with,
            label: 'Move',
            selected: selectedSection == WebShellSection.transfer,
            onTap: () => _goHome(context, WebAssetSection.transfer),
          ),
          _SidebarSubItem(
            icon: Icons.change_circle_outlined,
            label: 'Dispose',
            selected: selectedSection == WebShellSection.dispose,
            onTap: () => _goHome(context, WebAssetSection.dispose),
          ),
          _SidebarSubItem(
            icon: Icons.settings_suggest_outlined,
            label: 'Maintenance',
            selected: selectedSection == WebShellSection.maintenance,
            onTap: () => _goHome(context, WebAssetSection.maintenance),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            selected: selectedSection == WebShellSection.inventory,
            onTap: () => _goHome(context, WebAssetSection.inventory),
          ),
          _SidebarItem(
            icon: Icons.description_outlined,
            label: 'Reports',
            selected: false,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Setup',
            selected: false,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        color: selected ? const Color(0xffffbd0a) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.deepOrange),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            if (badge != null)
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.redAccent,
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
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
        height: 43,
        color: selected ? const Color(0xffefefef) : Colors.white,
        padding: const EdgeInsets.only(left: 56, right: 22),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.deepOrange),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
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
