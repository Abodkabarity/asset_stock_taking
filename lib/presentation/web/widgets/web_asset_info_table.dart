import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class WebAssetInfoTable extends StatelessWidget {
  final List<(String, String)> rows;

  const WebAssetInfoTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppColors.border),
      columnWidths: const {0: FixedColumnWidth(150), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows.map((row) {
        return TableRow(
          children: [
            Container(
              color: const Color(0xfffffae8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Text(row.$1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Text(
                row.$2.trim().isEmpty ? '-' : row.$2,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
