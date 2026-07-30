import 'package:flutter/material.dart';

class AssetClassificationUtils {
  static const trackableAsset = 'Trackable Asset';
  static const thirdPartyAsset = 'Third-Party Asset';

  static bool isTrackableAsset(String value) {
    return value.trim().toLowerCase() == trackableAsset.toLowerCase();
  }

  static bool canPrintBarcode(String value) {
    return isTrackableAsset(value);
  }

  static Color classificationColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'public':
        return Colors.green;
      case 'restricted':
        return Colors.lightBlue;
      case 'confidential':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }
}
