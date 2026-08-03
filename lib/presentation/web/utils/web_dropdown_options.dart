List<String> alphabetizedWebOptions(Iterable<String> values) {
  final unique = <String, String>{};
  for (final rawValue in values) {
    final value = rawValue.trim();
    if (value.isEmpty) continue;
    unique.putIfAbsent(value.toLowerCase(), () => value);
  }

  final result = unique.values.toList();
  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

String? preferredAssetStore(Iterable<String> values) {
  final sorted = alphabetizedWebOptions(values);
  for (final value in sorted) {
    if (value.toLowerCase() == 'asset store') return value;
  }
  return sorted.isEmpty ? null : sorted.first;
}
