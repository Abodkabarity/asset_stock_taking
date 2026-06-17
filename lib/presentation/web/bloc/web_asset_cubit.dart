import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/web_asset_repository.dart';
import 'web_asset_state.dart';

class WebAssetCubit extends Cubit<WebAssetState> {
  final WebAssetRepository repository;

  WebAssetCubit({required this.repository}) : super(const WebAssetState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));

    final branches = await repository.getBranches();
    final assets = await repository.getAssets();
    final masterItems = await repository.getMasterItems();

    emit(
      WebAssetState(
        branches: branches,
        assets: assets,
        masterItems: masterItems,
        loading: false,
      ),
    );
  }
}
