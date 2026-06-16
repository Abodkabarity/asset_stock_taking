class AssetClassificationUtils {
  static const trackableAsset = 'Trackable Asset';
  static const thirdPartyAsset = 'Third-Party Asset';

  static bool canPrintBarcode(String value) {
    final normalized = value.trim().toLowerCase();

    return normalized == trackableAsset.toLowerCase() ||
        normalized == thirdPartyAsset.toLowerCase();
  }
}
