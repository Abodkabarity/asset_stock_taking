import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String title;

  final T? value;

  final List<DropdownMenuItem<T>> items;

  final void Function(T?) onChanged;

  const CustomDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
