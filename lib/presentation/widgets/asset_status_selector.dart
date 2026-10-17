import 'package:flutter/material.dart';
import '../../core/services/asset_status_catalog.dart';
import '../../data/models/asset_status_option.dart';

/// Every configured choice edits the physical status only.
class AssetStatusSelector extends StatelessWidget {
  final String value;
  final List<AssetStatusOption> options;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const AssetStatusSelector({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectable = options.where((option) => option.isActive).toList();
    if (!selectable.any((option) => option.value == value)) {
      selectable.add(
        AssetStatusOption(value: value, label: AssetStatusCatalog.label(value)),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('asset-status-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Status'),
      items: selectable
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: !enabled
          ? null
          : (next) {
              if (next != null) onChanged(next);
            },
    );
  }
}
