/// Physical condition and workflow state are independent dimensions.
class AssetStatus {
  static const available = 'Available';
  static const maintenance = 'Maintenance';
  static const checkedOut = 'Checked Out';
  static const reserved = 'Reserved';
  static const disposed = 'Disposed';
  static const unknown = 'Unknown';

  static const conditions = [
    'New',
    'Good',
    'Very Good',
    'Bad',
    'Damaged',
    unknown,
  ];
  static const operations = [
    available,
    maintenance,
    checkedOut,
    reserved,
    disposed,
    'Lost',
    'Sold',
    'Assigned',
  ];

  static String? legacyOperation(String value) {
    switch (value.trim().toLowerCase()) {
      case 'available':
        return available;
      case 'maintenance':
      case 'under maintenance':
      case 'in maintenance':
        return maintenance;
      case 'checked out':
        return checkedOut;
      case 'reserved':
        return reserved;
      case 'disposed':
        return disposed;
      case 'lost':
        return 'Lost';
      case 'sold':
        return 'Sold';
      case 'assigned':
        return 'Assigned';
      default:
        return null;
    }
  }

  static String condition(String value) {
    final clean = value.trim();
    if (clean.isEmpty ||
        clean.toLowerCase() == 'unknown' ||
        legacyOperation(clean) != null) {
      return unknown;
    }
    return clean;
  }

  static String operation(String? value, {String legacyCondition = ''}) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return legacyOperation(legacyCondition) ?? available;
    for (final option in operations) {
      if (option.toLowerCase() == clean.toLowerCase()) return option;
    }
    // Never treat an unrecognized server state as available for transfer.
    return clean;
  }

  static bool isClosedMaintenance(String value) =>
      ['completed', 'done', 'closed'].contains(value.trim().toLowerCase());
}
