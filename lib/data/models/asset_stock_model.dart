class AssetStockModel {
  final int? id;

  final String name;

  final String assetCode;

  final String itemCode;

  final String category;

  final String subCategory;

  final double cost;

  final String classification;

  final String assetClassification;

  final String assetInventory;

  final String location;

  final String projectName;

  final String? localImagePath;

  final String status;

  final String? imagePath;

  final String brand;

  final String model;

  final String serialNo;

  final String description;

  final bool hasWarranty;

  final String warrantyDescription;

  final String warrantyStartDate;

  final String warrantyEndDate;

  final String warrantySerialNo;

  final String? warrantyImagePath;

  final String? localWarrantyImagePath;

  /// Web disposal evidence. These fields stay optional so existing mobile
  /// records and older local Hive payloads remain fully compatible.
  final String disposedDate;

  final String disposedTo;

  final String disposedNotes;

  final String? disposedImagePath;

  final bool isSynced;

  final bool isDeleted;

  /// FOR SORTING
  final DateTime createdAt;

  AssetStockModel({
    this.id,
    required this.name,
    required this.assetCode,
    required this.itemCode,
    required this.category,
    required this.subCategory,
    required this.classification,
    required this.assetClassification,
    required this.assetInventory,
    required this.location,
    required this.projectName,
    required this.status,
    required this.brand,
    required this.model,
    required this.serialNo,
    this.description = '',
    this.hasWarranty = false,
    this.warrantyDescription = '',
    this.warrantyStartDate = '',
    this.warrantyEndDate = '',
    this.warrantySerialNo = '',
    this.warrantyImagePath,
    this.localWarrantyImagePath,
    this.disposedDate = '',
    this.disposedTo = '',
    this.disposedNotes = '',
    this.disposedImagePath,
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
      if (id != null) 'id': id,
      'name': name,
      'asset_code': assetCode,
      'item_code': itemCode,
      'category': category,
      'sub_category': subCategory,
      'classification': classification,
      'asset_classification': assetClassification,
      'asset_inventory': assetInventory,
      'location': location,
      'project_name': projectName,
      'status': status,
      'brand': brand,
      'model': model,
      'serial_no': serialNo,
      'description': description,
      'has_warranty': hasWarranty,
      'warranty_description': warrantyDescription,
      'warranty_start_date': warrantyStartDate,
      'warranty_end_date': warrantyEndDate,
      'warranty_serial_no': warrantySerialNo,
      'warranty_image_path': warrantyImagePath,
      'local_warranty_image_path': localWarrantyImagePath,
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
      id: json['id'],

      name: json['name']?.toString() ?? '',

      assetCode: json['asset_code']?.toString() ?? '',

      itemCode: json['item_code']?.toString() ?? '',

      category: json['category']?.toString() ?? '',

      subCategory: json['sub_category']?.toString() ?? '',

      classification: json['classification']?.toString() ?? '',

      assetClassification: json['asset_classification']?.toString() ?? '',

      assetInventory: json['asset_inventory']?.toString() ?? '',

      location: json['location']?.toString() ?? '',

      projectName: json['project_name']?.toString() ?? '',

      status: json['status']?.toString() ?? '',

      brand: json['brand']?.toString() ?? '',

      cost: (json['cost'] ?? 0).toDouble(),

      model: json['model']?.toString() ?? '',

      localImagePath: json['local_image_path']?.toString(),

      serialNo: json['serial_no']?.toString() ?? '',

      description: json['description']?.toString() ?? '',

      hasWarranty: json['has_warranty'] ?? false,

      warrantyDescription: json['warranty_description']?.toString() ?? '',

      warrantyStartDate: json['warranty_start_date']?.toString() ?? '',

      warrantyEndDate: json['warranty_end_date']?.toString() ?? '',

      warrantySerialNo: json['warranty_serial_no']?.toString() ?? '',

      warrantyImagePath: json['warranty_image_path']?.toString(),

      localWarrantyImagePath: json['local_warranty_image_path']?.toString(),

      disposedDate: json['disposed_date']?.toString() ?? '',

      disposedTo: json['disposed_to']?.toString() ?? '',

      disposedNotes: json['disposed_notes']?.toString() ?? '',

      disposedImagePath: json['disposed_image_path']?.toString(),

      isSynced: json['is_synced'] ?? false,

      isDeleted: json['is_deleted'] ?? false,

      imagePath: json['image_path']?.toString(),

      createdAt:
          (DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          )?.toLocal()) ??
          DateTime.now(),
    );
  }

  /// =========================================================
  /// COPY WITH
  /// =========================================================
  AssetStockModel copyWith({
    int? id,
    bool? isSynced,
    bool? isDeleted,
    String? assetCode,
    String? itemCode,
    String? imagePath,
    DateTime? createdAt,
    double? cost,
    String? localImagePath,
    String? description,
    bool? hasWarranty,
    String? warrantyDescription,
    String? warrantyStartDate,
    String? warrantyEndDate,
    String? warrantySerialNo,
    String? warrantyImagePath,
    String? localWarrantyImagePath,
    String? disposedDate,
    String? disposedTo,
    String? disposedNotes,
    String? disposedImagePath,
  }) {
    return AssetStockModel(
      id: id ?? this.id,

      name: name,

      assetCode: assetCode ?? this.assetCode,

      itemCode: itemCode ?? this.itemCode,

      category: category,

      cost: cost ?? this.cost,

      subCategory: subCategory,

      classification: classification,

      assetClassification: assetClassification,

      assetInventory: assetInventory,

      location: location,

      projectName: projectName,

      status: status,

      brand: brand,

      model: model,

      serialNo: serialNo,

      description: description ?? this.description,

      hasWarranty: hasWarranty ?? this.hasWarranty,

      warrantyDescription: warrantyDescription ?? this.warrantyDescription,

      warrantyStartDate: warrantyStartDate ?? this.warrantyStartDate,

      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,

      warrantySerialNo: warrantySerialNo ?? this.warrantySerialNo,

      warrantyImagePath: warrantyImagePath ?? this.warrantyImagePath,

      localWarrantyImagePath:
          localWarrantyImagePath ?? this.localWarrantyImagePath,

      disposedDate: disposedDate ?? this.disposedDate,

      disposedTo: disposedTo ?? this.disposedTo,

      disposedNotes: disposedNotes ?? this.disposedNotes,

      disposedImagePath: disposedImagePath ?? this.disposedImagePath,

      isSynced: isSynced ?? this.isSynced,

      isDeleted: isDeleted ?? this.isDeleted,

      imagePath: imagePath ?? this.imagePath,

      localImagePath: localImagePath ?? this.localImagePath,

      createdAt: createdAt ?? this.createdAt,
    );
  }
}
