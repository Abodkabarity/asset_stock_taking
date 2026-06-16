class AssetItemModel {
  final String name;

  final String itemCode;

  final String category;

  final String subCategory;

  final String classification;

  final String assetClassification;

  final String assetInventory;

  AssetItemModel({
    required this.name,

    required this.itemCode,

    required this.category,

    required this.subCategory,

    required this.classification,

    required this.assetClassification,

    required this.assetInventory,
  });

  factory AssetItemModel.fromJson(Map<String, dynamic> json) {
    return AssetItemModel(
      name: json['name'] ?? '',

      itemCode: json['item_code'] ?? '',

      category: json['category'] ?? '',

      subCategory: json['sub_category'] ?? '',

      classification: json['classification'] ?? '',

      assetClassification: json['asset_classification'] ?? '',

      assetInventory: json['asset_inventory'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,

      'item_code': itemCode,

      'category': category,

      'sub_category': subCategory,

      'classification': classification,

      'asset_classification': assetClassification,

      'asset_inventory': assetInventory,
    };
  }
}
