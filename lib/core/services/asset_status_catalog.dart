import 'package:flutter/foundation.dart';
import '../../data/models/asset_status_option.dart';

/// Keeps labels shared across status selectors and existing asset badges.
class AssetStatusCatalog {
  static final options = ValueNotifier<List<AssetStatusOption>>(
    AssetStatusOption.defaults,
  );

  static String label(String value) {
    for (final option in options.value) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  static List<AssetStatusOption> get active =>
      options.value.where((option) => option.isActive).toList(growable: false);
}
