import 'package:hive/hive.dart';

import '../../models/asset_item_model.dart';

class LocalMasterDatasource {
  final masterBox = Hive.box('master_box');

  final settingsBox = Hive.box('settings_box');

  Future<void> saveMaster(List<AssetItemModel> items) async {
    await masterBox.put('master', items.map((e) => e.toJson()).toList());
  }

  List<AssetItemModel> getMaster() {
    final data = masterBox.get('master', defaultValue: []);

    return (data as List)
        .map((e) => AssetItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveLastSync(String value) async {
    await settingsBox.put('master_last_sync', value);
  }

  String? getLastSync() {
    return settingsBox.get('master_last_sync');
  }
}
