class AssetStockModel {
  final String name;

  final String assetCode;

  final String itemCode;

  final String category;

  final String subCategory;
  final double cost;
  final String classification;

  final String location;

  final String projectName;
  final String? localImagePath;
  final String status;

  final String? imagePath;

  final String brand;

  final String model;

  final String serialNo;

  final bool isSynced;

  final bool isDeleted;

  /// FOR SORTING
  final DateTime createdAt;

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
    required this.createdAt,
    this.isSynced = false,
    this.isDeleted = false,
    this.imagePath,
    this.localImagePath,
    required this.cost,
  });

  /// =========================================================
  /// TO JSON
  /// =========================================================
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
      'created_at': createdAt.toIso8601String(),
      'cost': cost,
      'local_image_path': localImagePath,
    };
  }

  /// =========================================================
  /// FROM JSON
  /// =========================================================
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
      cost: (json['cost'] ?? 0).toDouble(),
      model: json['model']?.toString() ?? '',
      localImagePath: json['local_image_path']?.toString(),
      serialNo: json['serial_no']?.toString() ?? '',

      isSynced: json['is_synced'] ?? false,

      isDeleted: json['is_deleted'] ?? false,

      imagePath: json['image_path']?.toString(),

      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// =========================================================
  /// COPY WITH
  /// =========================================================
  AssetStockModel copyWith({
    bool? isSynced,
    bool? isDeleted,
    String? assetCode,
    String? imagePath,
    DateTime? createdAt,
    double? cost,
    String? localImagePath,
  }) {
    return AssetStockModel(
      name: name,

      assetCode: assetCode ?? this.assetCode,

      itemCode: itemCode,

      category: category,
      cost: cost ?? this.cost,
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
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
