import 'package:asset_stock_taking/presentation/pages/select_project_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../bloc/asset_bloc.dart';

class SelectBranchPage extends StatefulWidget {
  const SelectBranchPage({super.key});

  @override
  State<SelectBranchPage> createState() => _SelectBranchPageState();
}

class _SelectBranchPageState extends State<SelectBranchPage> {
  String? selectedBranch;

  @override
  void initState() {
    super.initState();

    context.read<AssetBloc>().add(LoadInitialData(branch: '', project: ''));
  }

  void _continue() {
    if (selectedBranch == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please Select Branch')));

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectProjectPage(branch: selectedBranch!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      body: SafeArea(
        child: BlocBuilder<AssetBloc, AssetState>(
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),

                child: Container(
                  width: double.infinity,

                  constraints: const BoxConstraints(maxWidth: 450),

                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),

                        blurRadius: 20,

                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 70,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Asset Stock Taking',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 28,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Please Select Branch',

                        textAlign: TextAlign.center,

                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      if (state.syncingMaster)
                        Column(
                          children: [
                            const CircularProgressIndicator(),

                            const SizedBox(height: 12),

                            Text(state.masterMessage ?? ''),
                          ],
                        ),

                      if (state.masterDownloaded && !state.syncingMaster)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.green.shade50,

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                              ),

                              const SizedBox(width: 8),

                              Text(
                                state.masterMessage ?? '',

                                style: TextStyle(
                                  color: Colors.green.shade700,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),

                      DropdownButtonFormField<String>(
                        initialValue: selectedBranch,

                        items: state.branches.map((e) {
                          return DropdownMenuItem<String>(
                            value: e,

                            child: Text(e),
                          );
                        }).toList(),

                        onChanged: (v) {
                          selectedBranch = v;

                          setState(() {});
                        },

                        decoration: InputDecoration(
                          labelText: 'Branch',

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        height: 55,

                        child: ElevatedButton(
                          onPressed: _continue,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: const Text(
                            'Continue',

                            style: TextStyle(
                              fontSize: 18,

                              color: Colors.white,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
