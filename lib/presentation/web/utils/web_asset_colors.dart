import 'package:flutter/material.dart';

class WebAssetColors {
  static Color classification(String classification) {
    switch (classification.trim().toLowerCase()) {
      case 'public':
        return Colors.green;
      case 'restricted':
        return Colors.lightBlue;
      case 'confidential':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
