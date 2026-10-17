class AssetStatusOption {
  final String value;
  final String label;
  final bool isActive;
  final int sortOrder;

  const AssetStatusOption({
    required this.value,
    required this.label,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory AssetStatusOption.fromJson(Map<String, dynamic> row) =>
      AssetStatusOption(
        value: row['value'] as String,
        label: row['label'] as String,
        isActive: row['is_active'] == true,
        sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      );

  static const defaults = [
    AssetStatusOption(
      value: 'Maintenance',
      label: 'Under Maintenance',
      sortOrder: 0,
    ),
    AssetStatusOption(value: 'Damaged', label: 'Damaged', sortOrder: 1),
    AssetStatusOption(value: 'Lost', label: 'Lost', sortOrder: 2),
    AssetStatusOption(value: 'Disposed', label: 'Disposed', sortOrder: 3),
    AssetStatusOption(value: 'Sold', label: 'Sold', sortOrder: 4),
    AssetStatusOption(value: 'New', label: 'New', sortOrder: 5),
    AssetStatusOption(value: 'Good', label: 'Good', sortOrder: 6),
    AssetStatusOption(value: 'Assigned', label: 'Assigned', sortOrder: 7),
  ];
}
