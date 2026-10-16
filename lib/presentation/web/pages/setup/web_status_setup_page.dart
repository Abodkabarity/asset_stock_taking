import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/asset_status.dart';
import '../../../../data/models/asset_status_option.dart';
import '../../data/web_asset_repository.dart';

class WebStatusSetupPage extends StatefulWidget {
  final WebAssetRepository repository;
  const WebStatusSetupPage({super.key, required this.repository});
  @override
  State<WebStatusSetupPage> createState() => _WebStatusSetupPageState();
}

class _WebStatusSetupPageState extends State<WebStatusSetupPage> {
  final search = TextEditingController();
  List<AssetStatusOption> options = [];
  bool loading = true;
  String? error;
  String? pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.repository.getStatusOptions();
      if (!mounted) return;
      setState(() {
        options = rows;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Could not load statuses. Please try again.';
        });
      }
    }
  }

  Future<void> _edit([AssetStatusOption? option]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _StatusOptionDialog(repository: widget.repository, original: option),
    );
    if (saved == true) await _load();
  }

  Future<void> _setActive(AssetStatusOption option, bool active) async {
    setState(() => pending = option.value);
    try {
      await widget.repository.setStatusOptionActive(option.value, active);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active
                ? 'Status restored'
                : 'Status removed from selection lists. Existing assets are preserved.',
          ),
          action: active
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () => _setActive(option, true),
                ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update the status. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = options
        .where(
          (option) =>
              option.isActive &&
              option.label.toLowerCase().contains(
                search.text.trim().toLowerCase(),
              ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xff102b50), Color(0xff2463a8)],
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 18,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statuses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Manage asset status options',
                        style: TextStyle(color: Color(0xffd9e8f8)),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: loading || error != null ? null : () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff174b82),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffdfe7f2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search statuses',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Refresh statuses',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Physical conditions and operational states stay separate. Renaming a status updates its displayed name; deleting it keeps existing assets and history.',
                style: TextStyle(color: AppColors.subText, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                Column(
                  children: [
                    Text(error!),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              else if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No statuses found')),
                )
              else
                ...rows.map(
                  (option) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffe3eaf4)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.isOperation
                              ? Icons.work_outline_rounded
                              : Icons.verified_outlined,
                          color: AppColors.primaryColor,
                          size: 21,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.isOperation
                                    ? 'Operational state'
                                    : 'Physical condition',
                                style: const TextStyle(
                                  color: AppColors.subText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit ${option.label}',
                          onPressed: pending != null
                              ? null
                              : () => _edit(option),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xff4263eb),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete ${option.label}',
                          onPressed: pending != null
                              ? null
                              : () => _setActive(option, false),
                          icon: pending == option.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xffd64052),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!loading && error == null)
                Text(
                  '${rows.length} statuses',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusOptionDialog extends StatefulWidget {
  final WebAssetRepository repository;
  final AssetStatusOption? original;
  const _StatusOptionDialog({required this.repository, this.original});
  @override
  State<_StatusOptionDialog> createState() => _StatusOptionDialogState();
}

class _StatusOptionDialogState extends State<_StatusOptionDialog> {
  late final TextEditingController name;
  late String kind;
  String operation = AssetStatus.maintenance;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.original?.label ?? '');
    kind = widget.original?.kind ?? 'condition';
    if (widget.original?.isOperation == true) {
      operation = widget.original!.value;
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repository.saveStatusOption(
        original: widget.original,
        label: name.text,
        kind: kind,
        operation: operation,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          saving = false;
          error = failure is ArgumentError
              ? failure.message.toString()
              : failure is StateError
              ? failure.message
              : 'Could not save the status. Check for a duplicate name and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(widget.original == null ? 'Add Status' : 'Edit Status'),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                maxLength: 80,
                enabled: !saving,
                decoration: const InputDecoration(labelText: 'Status name'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'condition',
                    child: Text('Physical condition'),
                  ),
                  DropdownMenuItem(
                    value: 'operation',
                    child: Text('Operational state'),
                  ),
                ],
                onChanged: saving || widget.original != null
                    ? null
                    : (next) {
                        if (next != null) setState(() => kind = next);
                      },
              ),
              if (kind == 'operation') ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: operation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Operation'),
                  items: AssetStatus.operations
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == AssetStatus.maintenance
                                ? 'Under Maintenance'
                                : value,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: saving || widget.original != null
                      ? null
                      : (next) {
                          if (next != null) setState(() => operation = next);
                        },
                ),
              ],
              if (widget.original != null)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'The status meaning stays unchanged for existing assets.',
                    style: TextStyle(color: AppColors.subText, fontSize: 12),
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xffd64052)),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Save Status'),
        ),
      ],
    ),
  );
}
