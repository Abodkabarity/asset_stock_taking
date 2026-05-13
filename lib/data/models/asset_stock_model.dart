class AssetStockModel {
  final String name;

  final String assetCode;

  final String itemCode;

  final String category;

  final String subCategory;

  final String classification;

  final String location;

  final String projectName;

  final String status;
  final String? imagePath;
  final String brand;

  final String model;

  final String serialNo;

  final bool isSynced;

  final bool isDeleted;

  AssetStockModel({
    required this.name,
    required this.assetCode,
    required this.itemCode,
    required this.category,
    required this.subCategory,
    required this.classification,
    required this.location,
    required this.projectName,
    required this.status,
    required this.brand,
    required this.model,
    required this.serialNo,
    this.isSynced = false,
    this.isDeleted = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'asset_code': assetCode,
      'item_code': itemCode,
      'category': category,
      'sub_category': subCategory,
      'classification': classification,
      'location': location,
      'project_name': projectName,
      'status': status,
      'brand': brand,
      'model': model,
      'serial_no': serialNo,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'image_path': imagePath,
    };
  }

  factory AssetStockModel.fromJson(Map<String, dynamic> json) {
    return AssetStockModel(
      name: json['name']?.toString() ?? '',

      assetCode: json['asset_code']?.toString() ?? '',

      itemCode: json['item_code']?.toString() ?? '',

      category: json['category']?.toString() ?? '',

      subCategory: json['sub_category']?.toString() ?? '',

      classification: json['classification']?.toString() ?? '',

      location: json['location']?.toString() ?? '',

      projectName: json['project_name']?.toString() ?? '',

      status: json['status']?.toString() ?? '',

      brand: json['brand']?.toString() ?? '',

      model: json['model']?.toString() ?? '',

      serialNo: json['serial_no']?.toString() ?? '',

      isSynced: json['is_synced'] ?? false,

      isDeleted: json['is_deleted'] ?? false,

      imagePath: json['image_path']?.toString(),
    );
  }

  AssetStockModel copyWith({
    bool? isSynced,
    bool? isDeleted,
    String? assetCode,
    String? imagePath,
  }) {
    return AssetStockModel(
      name: name,
      assetCode: assetCode ?? this.assetCode,
      itemCode: itemCode,
      category: category,
      subCategory: subCategory,
      classification: classification,
      location: location,
      projectName: projectName,
      status: status,
      brand: brand,
      model: model,
      serialNo: serialNo,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
