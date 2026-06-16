import 'package:asset_stock_taking/presentation/pages/select_branch_page.dart';
import 'package:asset_stock_taking/presentation/pages/web_asset_dashboard_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'injection_container.dart';
import 'presentation/bloc/asset_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox('asset_box');
  await Hive.openBox('master_box');

  await Hive.openBox('settings_box');

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseKey,
  );
  setup();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssetBloc>(
      create: (_) => sl<AssetBloc>(),

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        home: kIsWeb ? const WebAssetDashboardPage() : const SelectBranchPage(),
      ),
    );
  }
}
