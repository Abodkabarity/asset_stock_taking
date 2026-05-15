import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/asset_excel_service.dart';
import '../../core/services/barcode_print_service.dart';
import '../../domain/repositories/asset_repository.dart';
import '../../injection_container.dart';
import '../bloc/asset_bloc.dart';
import 'asset_stock_page.dart';

class SelectProjectPage extends StatefulWidget {
  final String branch;

  const SelectProjectPage({super.key, required this.branch});

  @override
  State<SelectProjectPage> createState() => _SelectProjectPageState();
}

class _SelectProjectPageState extends State<SelectProjectPage> {
  List<String> projects = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final result = await sl.get<AssetRepository>().getProjects(widget.branch);

    projects = result;

    loading = false;

    setState(() {});
  }

  Future<void> _addProject() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text('Add Project'),

          content: TextField(
            controller: controller,

            decoration: InputDecoration(
              hintText: 'Project Name',
              filled: true,
              fillColor: AppColors.backgroundWidget,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.secondaryColor),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),

              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                final project = controller.text.trim();

                final rootContext = context;

                Navigator.of(context).pop();

                Future.delayed(Duration.zero, () async {
                  await sl.get<AssetRepository>().addProject(
                    branch: widget.branch,
                    project: project,
                  );

                  if (!rootContext.mounted) return;

                  await Navigator.push(
                    rootContext,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => sl<AssetBloc>()
                          ..add(
                            LoadInitialData(
                              branch: widget.branch,
                              project: project,
                            ),
                          ),
                        child: AssetStockPage(
                          branch: widget.branch,
                          project: project,
                        ),
                      ),
                    ),
                  );

                  await _loadProjects();
                });
              },

              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,

        title: const Text(
          'Asset Stock Taking Project',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        backgroundColor: AppColors.primaryColor,

        actions: [
          IconButton(
            onPressed: () async {
              final assets = await sl.get<AssetRepository>().getAssetsForBranch(
                branch: widget.branch,
              );

              if (assets.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('No Data Found')));

                return;
              }

              await AssetExcelService.exportAssets(
                assets: assets,
                fileName: '${widget.branch}_all_assets',
              );
            },

            icon: const Icon(Icons.file_download),
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),

            onPressed: () async {
              /// GET CLASSIFICATIONS
              final classifications = await sl
                  .get<AssetRepository>()
                  .getClassifications(widget.branch);

              if (!context.mounted) return;

              String? selectedClassification;

              /// DIALOG
              final result = await showDialog<String>(
                context: context,

                builder: (_) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Select Classification'),

                    content: DropdownButtonFormField<String>(
                      initialValue: selectedClassification,

                      decoration: InputDecoration(
                        labelText: 'Classification',

                        filled: true,
                        fillColor: AppColors.backgroundWidget,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),

                      items: classifications.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedClassification = value;
                        });
                      },
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.secondaryColor),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, selectedClassification);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                        ),
                        child: const Text(
                          'Print',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (result == null) {
                return;
              }

              /// GET ALL ASSETS ONLINE
              final response = await sl
                  .get<AssetRepository>()
                  .getAssetsForPrint(
                    branch: widget.branch,
                    classification: result,
                  );

              if (response.isEmpty) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No Assets Found')),
                );

                return;
              }

              /// GENERATE PDF
              final pdf = await BarcodePrintService.generateBarcodePdf(
                assets: response,
              );

              /// PRINT
              await Printing.layoutPdf(onLayout: (_) async => pdf);
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProject,

        backgroundColor: AppColors.primaryColor,

        label: const Text('Add Project', style: TextStyle(color: Colors.white)),

        icon: const Icon(Icons.add, color: Colors.white),
      ),

      body: loading
          ? Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),

                  fit: BoxFit.fill,
                ),
              ),

              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),

                  fit: BoxFit.fill,
                ),
              ),

              child: ListView.builder(
                itemCount: projects.length,

                itemBuilder: (_, index) {
                  final project = projects[index];

                  return Card(
                    margin: const EdgeInsets.all(12),

                    child: ListTile(
                      leading: const Icon(Icons.folder),

                      title: Text(project),

                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),

                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,

                            builder: (_) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),

                                title: const Text('Delete Project'),

                                content: Text(
                                  'Are you sure you want to delete "$project" ?',
                                ),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },

                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),

                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },

                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result != true) {
                            return;
                          }

                          /// DELETE PROJECT FROM SERVER
                          await sl.get<AssetRepository>().deleteProject(
                            branch: widget.branch,
                            project: project,
                          );

                          /// DELETE LOCAL PROJECT DATA
                          await sl.get<AssetRepository>().clearLocalProject(
                            branch: widget.branch,
                            project: project,
                          );

                          /// RELOAD
                          await _loadProjects();
                        },
                      ),

                      onTap: () async {
                        await Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<AssetBloc>()
                                ..add(
                                  LoadInitialData(
                                    branch: widget.branch,

                                    project: project,
                                  ),
                                ),

                              child: AssetStockPage(
                                branch: widget.branch,

                                project: project,
                              ),
                            ),
                          ),
                        );

                        _loadProjects();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
