import 'package:get_it/get_it.dart';

import 'data/datasource/local/local_asset_datasource.dart';
import 'data/datasource/local/local_master_datasource.dart';
import 'data/remote/asset_remote_datasource.dart';
import 'data/remote/repositories/asset_repository_impl.dart';
import 'domain/repositories/asset_repository.dart';
import 'presentation/bloc/asset_bloc.dart';

final sl = GetIt.instance;

void setup() {
  /// LOCAL DATASOURCE
  sl.registerLazySingleton<LocalAssetDatasource>(() => LocalAssetDatasource());

  /// REMOTE DATASOURCE
  sl.registerLazySingleton<AssetRemoteDatasource>(
    () => AssetRemoteDatasource(),
  );

  /// REPOSITORY
  sl.registerLazySingleton<AssetRepository>(
    () => AssetRepositoryImpl(
      remoteDatasource: sl<AssetRemoteDatasource>(),

      localDatasource: sl<LocalAssetDatasource>(),
      localMasterDatasource: sl<LocalMasterDatasource>(),
    ),
  );
  sl.registerLazySingleton(() => LocalMasterDatasource());

  /// BLOC
  sl.registerFactory(() => AssetBloc(repository: sl<AssetRepository>()));
}
