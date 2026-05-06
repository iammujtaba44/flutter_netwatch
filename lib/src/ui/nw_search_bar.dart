import 'package:flutter/material.dart';

class NWSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const NWSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        autofocus: true,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search URL, method, status...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

enum NWStatusFilter {
  all,
  success,
  redirect,
  clientError,
  serverError,
  slow,
  errors,
}

extension NWStatusFilterX on NWStatusFilter {
  String get label => switch (this) {
        NWStatusFilter.all => 'All',
        NWStatusFilter.success => '2xx',
        NWStatusFilter.redirect => '3xx',
        NWStatusFilter.clientError => '4xx',
        NWStatusFilter.serverError => '5xx',
        NWStatusFilter.slow => 'Slow ⚡',
        NWStatusFilter.errors => 'Errors',
      };
}
