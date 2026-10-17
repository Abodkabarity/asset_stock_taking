import '../../core/utils/asset_status.dart';

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

  final String operationalStatus;
  final int conditionRevision;
  // Local-only intent. Repeated offline edits share the same server revision.
  final bool hasPendingConditionChange;
  int get conditionRevisionForUpload =>
      conditionRevision + (hasPendingConditionChange ? 1 : 0);

  bool get isAvailable => operationalStatus == AssetStatus.available;
  bool get isInMaintenance => operationalStatus == AssetStatus.maintenance;
  bool get isDisposed => operationalStatus == AssetStatus.disposed;
  bool get isReserved => operationalStatus == AssetStatus.reserved;
  bool get needsConditionReview => status == AssetStatus.unknown;

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
    required String status,
    String? operationalStatus,
    this.conditionRevision = 0,
    this.hasPendingConditionChange = false,
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
  }) : status = AssetStatus.condition(status, allowWorkflowNames: true),
       operationalStatus = AssetStatus.operation(operationalStatus);

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
      'operational_status': operationalStatus,
      'condition_revision': conditionRevision,
      'has_pending_condition_change': hasPendingConditionChange,
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
    final rawStatus = json['status']?.toString() ?? '';
    final operation = json['operational_status']?.toString();
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

      status: AssetStatus.condition(
        rawStatus,
        allowWorkflowNames: operation != null,
      ),
      operationalStatus: AssetStatus.operation(
        operation,
        legacyCondition: rawStatus,
      ),
      conditionRevision: (json['condition_revision'] as num?)?.toInt() ?? 0,
      hasPendingConditionChange: json['has_pending_condition_change'] == true,

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
    String? status,
    String? operationalStatus,
    int? conditionRevision,
    bool? hasPendingConditionChange,
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

      status: status ?? this.status,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      conditionRevision: conditionRevision ?? this.conditionRevision,
      hasPendingConditionChange:
          hasPendingConditionChange ?? this.hasPendingConditionChange,

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
