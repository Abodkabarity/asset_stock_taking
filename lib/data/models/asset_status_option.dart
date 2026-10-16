import '../../core/utils/asset_status.dart';

class AssetStatusOption {
  final String value;
  final String label;
  final String kind;
  final bool isActive;
  final int sortOrder;

  const AssetStatusOption({
    required this.value,
    required this.label,
    required this.kind,
    this.isActive = true,
    this.sortOrder = 0,
  });

  bool get isOperation => kind == 'operation';

  factory AssetStatusOption.fromJson(Map<String, dynamic> row) =>
      AssetStatusOption(
        value: row['value'] as String,
        label: row['label'] as String,
        kind: row['kind'] as String,
        isActive: row['is_active'] == true,
        sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      );

  AssetStatusSelection select({
    required String condition,
    String operation = AssetStatus.available,
  }) => AssetStatusSelection(
    condition: isOperation ? condition : value,
    operation: isOperation ? value : operation,
  );

  static const defaults = [
    AssetStatusOption(
      value: 'Maintenance',
      label: 'Under Maintenance',
      kind: 'operation',
      sortOrder: 0,
    ),
    AssetStatusOption(
      value: 'Damaged',
      label: 'Damaged',
      kind: 'condition',
      sortOrder: 1,
    ),
    AssetStatusOption(
      value: 'Lost',
      label: 'Lost',
      kind: 'operation',
      sortOrder: 2,
    ),
    AssetStatusOption(
      value: 'Disposed',
      label: 'Disposed',
      kind: 'operation',
      sortOrder: 3,
    ),
    AssetStatusOption(
      value: 'Sold',
      label: 'Sold',
      kind: 'operation',
      sortOrder: 4,
    ),
    AssetStatusOption(
      value: 'New',
      label: 'New',
      kind: 'condition',
      sortOrder: 5,
    ),
    AssetStatusOption(
      value: 'Good',
      label: 'Good',
      kind: 'condition',
      sortOrder: 6,
    ),
    AssetStatusOption(
      value: 'Assigned',
      label: 'Assigned',
      kind: 'operation',
      sortOrder: 7,
    ),
  ];
}

class AssetStatusSelection {
  final String condition;
  final String operation;
  const AssetStatusSelection({
    required this.condition,
    required this.operation,
  });
}
