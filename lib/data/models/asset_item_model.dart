class AssetItemModel {
  final String name;

  final String itemCode;

  final String category;

  final String subCategory;

  final String classification;

  AssetItemModel({
    required this.name,

    required this.itemCode,

    required this.category,

    required this.subCategory,

    required this.classification,
  });

  factory AssetItemModel.fromJson(Map<String, dynamic> json) {
    return AssetItemModel(
      name: json['name'] ?? '',

      itemCode: json['item_code'] ?? '',

      category: json['category'] ?? '',

      subCategory: json['sub_category'] ?? '',

      classification: json['classification'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,

      'item_code': itemCode,

      'category': category,

      'sub_category': subCategory,

      'classification': classification,
    };
  }
}
