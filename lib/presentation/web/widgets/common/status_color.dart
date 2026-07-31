part of '../../../pages/web_asset_dashboard_page.dart';

Color _assetStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'damaged':
    case 'bad':
    case 'disposed':
    case 'lost':
      return const Color(0xFFE53935);
    case 'maintenance':
    case 'in maintenance':
      return const Color(0xFFF59E0B);
    case 'new':
      return const Color(0xFF2563EB);
    case 'reserved':
      return const Color(0xFF7C3AED);
    case 'good':
    case 'active':
      return const Color(0xFF22A447);
    default:
      return AppColors.subText;
  }
}
