part of 'asset_bloc.dart';

abstract class AssetEvent extends Equatable {
  const AssetEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialData extends AssetEvent {
  final String branch;

  final String project;

  const LoadInitialData({required this.branch, required this.project});

  @override
  List<Object?> get props => [branch, project];
}

class SaveAssetEvent extends AssetEvent {
  final AssetStockModel model;

  final String branch;

  final String project;

  const SaveAssetEvent(
    this.model, {
    required this.branch,
    required this.project,
  });

  @override
  List<Object?> get props => [model, branch, project];
}

class UploadAssetsEvent extends AssetEvent {
  const UploadAssetsEvent();

  @override
  List<Object?> get props => [];
}

class DeleteAssetEvent extends AssetEvent {
  final String itemCode;
  final String branch;

  final String project;

  const DeleteAssetEvent({
    required this.itemCode,
    required this.branch,

    required this.project,
  });

  @override
  List<Object?> get props => [itemCode, branch, project];
}
