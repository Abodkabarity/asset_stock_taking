import 'package:flutter/material.dart';
import '../../core/services/asset_status_catalog.dart';
import '../../core/utils/asset_status.dart';
import '../../data/models/asset_status_option.dart';

class AssetStatusSelector extends StatelessWidget {
  final String value;
  final String condition;
  final String currentOperation;
  final List<AssetStatusOption> options;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onConditionChanged;
  final bool enabled;

  const AssetStatusSelector({
    super.key,
    required this.value,
    required this.condition,
    required this.options,
    required this.onChanged,
    required this.onConditionChanged,
    this.currentOperation = AssetStatus.available,
    this.enabled = true,
  });

  AssetStatusOption get selected => options.firstWhere(
    (option) => option.value == value,
    orElse: () => AssetStatusOption(
      value: value,
      label: AssetStatusCatalog.label(value),
      kind: AssetStatus.legacyOperation(value) == null
          ? 'condition'
          : 'operation',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selectable = options.where((option) => option.isActive).toList();
    if (!selectable.any((option) => option.value == value)) {
      selectable.add(selected);
    }
    final conditions = selectable
        .where((option) => !option.isOperation)
        .toList();
    if (!conditions.any((option) => option.value == condition)) {
      conditions.add(
        AssetStatusOption(
          value: condition,
          label: AssetStatusCatalog.label(condition),
          kind: 'condition',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('asset-status-$value'),
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Status'),
          items: selectable
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  enabled:
                      !option.isOperation ||
                      currentOperation == AssetStatus.available ||
                      option.value == currentOperation,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: !enabled
              ? null
              : (next) {
                  if (next != null) onChanged(next);
                },
        ),
        if (selected.isOperation) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('asset-physical-$condition'),
            initialValue: condition,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Physical condition',
              helperText: 'Condition of the asset during this operation.',
            ),
            items: conditions
                .map(
                  (option) => DropdownMenuItem(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: !enabled
                ? null
                : (next) {
                    if (next != null) onConditionChanged(next);
                  },
          ),
        ],
      ],
    );
  }
}
