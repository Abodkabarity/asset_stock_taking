import 'package:flutter/material.dart';

import '../../../core/utils/asset_classification_utils.dart';

class WebAssetColors {
  static Color classification(String classification) {
    return AssetClassificationUtils.classificationColor(classification);
  }
}
