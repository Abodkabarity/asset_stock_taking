import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../pages/web_asset_dashboard_page.dart';

enum WebShellSection { dashboard, assets, transfer, dispose, maintenance }

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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/icon.png', height: 36, width: 46),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 28),
          _TopLink(
            icon: Icons.format_list_bulleted,
            label: 'Assets',
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          _TopLink(
            icon: Icons.add_circle_outline,
            label: 'Asset',
            onTap: onAddAsset ?? () => _goHome(context, WebAssetSection.assets),
          ),
          _TopLink(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
          const Spacer(),
          const Icon(Icons.access_time, size: 18, color: AppColors.headerText),
          const SizedBox(width: 8),
          const Text('Changelog'),
          const SizedBox(width: 16),
          const Icon(Icons.local_offer_outlined, size: 18),
          const SizedBox(width: 8),
          const Text('Buy Asset Tags'),
          const SizedBox(width: 22),
          const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 8),
          const Text(
            'mahmoud alkouz',
            style: TextStyle(fontWeight: FontWeight.bold),
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
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 16),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Al Ain Pharmacy',
                    style: TextStyle(
                      color: AppColors.headerText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_double_arrow_left, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),
          _SidebarItem(
            icon: Icons.home_outlined,
            label: 'Dashboard',
            selected: selectedSection == WebShellSection.dashboard,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.notifications_none,
            label: 'Alerts',
            badge: '1',
            selected: false,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
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
            icon: Icons.add_circle_outline,
            label: 'Add an Asset',
            selected: false,
            onTap: onAddAsset ?? () => _goHome(context, WebAssetSection.assets),
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
          _SidebarSubItem(
            icon: Icons.event_available_outlined,
            label: 'Reserve',
            selected: false,
            onTap: () => _goHome(context, WebAssetSection.assets),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            selected: false,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.list_alt_outlined,
            label: 'Lists',
            selected: false,
            onTap: () => _goHome(context, WebAssetSection.dashboard),
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
        height: 41,
        color: selected ? const Color(0xffffbd0a) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Icon(icon, size: 19, color: Colors.deepOrange),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
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
        height: 37,
        color: selected ? const Color(0xffefefef) : Colors.white,
        padding: const EdgeInsets.only(left: 48, right: 16),
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
