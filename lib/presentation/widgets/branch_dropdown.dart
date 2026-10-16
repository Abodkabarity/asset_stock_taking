import 'dart:math' as math;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Shared branch selector for mobile screens, web filters and action dialogs.
class BranchDropdown extends StatefulWidget {
  final List<String> branches;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final InputDecoration decoration;
  final bool includeAllBranches;
  final String? allBranchesValue;
  final String? allBranchesLabel;
  final FormFieldValidator<String>? validator;

  const BranchDropdown({
    super.key,
    required this.branches,
    required this.value,
    required this.onChanged,
    this.decoration = const InputDecoration(labelText: 'Branch'),
    this.includeAllBranches = false,
    this.allBranchesValue,
    this.allBranchesLabel,
    this.validator,
  });

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Match Arabic names with or without diacritics and common alef variants.
  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .trim();

  bool _matches(_BranchChoice choice, String query) {
    final name = _normalize(choice.label);
    return _normalize(query).split(RegExp(r'\s+')).every(name.contains);
  }

  @override
  Widget build(BuildContext context) {
    final arabic =
        Localizations.localeOf(context).languageCode == 'ar' ||
        Directionality.of(context) == TextDirection.rtl;
    final allLabel =
        widget.allBranchesLabel ?? (arabic ? 'جميع الفروع' : 'All Branches');
    final names =
        widget.branches.where((name) => name.trim().isNotEmpty).toSet().toList()
          ..sort((a, b) => _normalize(a).compareTo(_normalize(b)));
    final choices = [
      if (widget.includeAllBranches)
        _BranchChoice(widget.allBranchesValue, allLabel, isAll: true),
      for (final name in names) _BranchChoice(name, name),
    ];
    final selected =
        widget.includeAllBranches && widget.value == widget.allBranchesValue
        ? _BranchChoice(widget.allBranchesValue, allLabel, isAll: true)
        : widget.value == null
        ? null
        : _BranchChoice(widget.value, widget.value!);
    final searchProps = TextFieldProps(
      controller: _searchController,
      autofocus: true,
      autocorrect: false,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      containerBuilder: (context, field) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: field,
      ),
      decoration: InputDecoration(
        hintText: arabic ? 'ابحث باسم الفرع…' : 'Search branches…',
        hintStyle: const TextStyle(color: AppColors.subText, fontSize: 13),
        filled: true,
        fillColor: AppColors.bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: arabic ? 'مسح البحث' : 'Clear search',
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              arabic ? 'اختر الفرع' : 'Select branch',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${names.length}',
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    Widget itemBuilder(
      BuildContext context,
      _BranchChoice choice,
      bool disabled,
      bool isSelected,
    ) {
      return Semantics(
        selected: isSelected,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blueSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                choice.isAll
                    ? Icons.grid_view_rounded
                    : Icons.storefront_outlined,
                size: 19,
                color: isSelected ? AppColors.primaryColor : AppColors.subText,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  choice.label,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isSelected ? AppColors.primaryColor : AppColors.text,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryColor,
                  size: 19,
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget emptyBuilder(BuildContext context, String query) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.subText,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              arabic ? 'لا توجد فروع مطابقة' : 'No branches found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              arabic
                  ? 'جرّب اسماً آخر أو امسح البحث'
                  : 'Try another name or clear your search',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.subText),
            ),
          ],
        ),
      ),
    );

    Widget containerBuilder(BuildContext context, Widget popup) =>
        Directionality(
          textDirection: Directionality.of(this.context),
          child: Column(
            children: [
              Expanded(child: popup),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    final count = choices
                        .where((c) => !c.isAll && _matches(c, value.text))
                        .length;
                    return Text(
                      arabic
                          ? '$count من ${names.length} فرع'
                          : '$count of ${names.length} branches',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subText,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

    final media = MediaQuery.of(context);
    final compact = media.size.width < 600;
    final height = math.min(
      420.0,
      math.max(180.0, media.size.height - media.viewInsets.bottom - 100),
    );
    final popupProps = compact
        ? PopupProps<_BranchChoice>.modalBottomSheet(
            showSearchBox: true,
            showSelectedItems: true,
            searchDelay: Duration.zero,
            searchFieldProps: searchProps,
            title: title,
            itemBuilder: itemBuilder,
            emptyBuilder: emptyBuilder,
            containerBuilder: containerBuilder,
            constraints: BoxConstraints(maxHeight: height),
            modalBottomSheetProps: const ModalBottomSheetProps(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              clipBehavior: Clip.antiAlias,
            ),
          )
        : PopupProps<_BranchChoice>.menu(
            showSearchBox: true,
            showSelectedItems: true,
            searchDelay: Duration.zero,
            searchFieldProps: searchProps,
            title: title,
            itemBuilder: itemBuilder,
            emptyBuilder: emptyBuilder,
            containerBuilder: containerBuilder,
            constraints: BoxConstraints(maxHeight: height),
            menuProps: MenuProps(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 12,
              shadowColor: AppColors.navy.withValues(alpha: .18),
              margin: const EdgeInsets.only(top: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
            ),
          );

    return DropdownSearch<_BranchChoice>(
      selectedItem: selected,
      enabled: widget.onChanged != null,
      items: (filter, loadProps) => choices,
      itemAsString: (choice) => choice.label,
      compareFn: (a, b) => a.value == b.value && a.isAll == b.isAll,
      filterFn: _matches,
      onBeforePopupOpening: (_) {
        _searchController.clear();
        return true;
      },
      onSelected: (choice) => widget.onChanged?.call(choice?.value),
      validator: widget.validator == null
          ? null
          : (choice) => widget.validator!(choice?.value),
      decoratorProps: DropDownDecoratorProps(
        baseStyle: const TextStyle(fontSize: 14, color: AppColors.text),
        decoration: widget.decoration.copyWith(
          hintText:
              widget.decoration.hintText ??
              (arabic ? 'اختر الفرع' : 'Select branch'),
          prefixIcon:
              widget.decoration.prefixIcon ??
              const Icon(Icons.storefront_outlined, size: 20),
          border:
              widget.decoration.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
        ),
      ),
      dropdownBuilder: (context, choice) => Text(
        choice?.label ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      suffixProps: const DropdownSuffixProps(
        dropdownButtonProps: DropdownButtonProps(
          iconClosed: Icon(Icons.keyboard_arrow_down_rounded, size: 21),
          color: AppColors.subText,
        ),
      ),
      popupProps: popupProps,
    );
  }
}

class _BranchChoice {
  final String? value;
  final String label;
  final bool isAll;

  const _BranchChoice(this.value, this.label, {this.isAll = false});
}
