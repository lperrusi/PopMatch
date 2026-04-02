import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Widget for displaying search suggestions and history
class SearchSuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final List<String> history;
  final Function(String) onSuggestionTap;
  final Function(String)? onHistoryItemTap;
  final Function(String)? onHistoryItemRemove;
  final bool showHistory;

  const SearchSuggestionsWidget({
    super.key,
    this.suggestions = const [],
    this.history = const [],
    required this.onSuggestionTap,
    this.onHistoryItemTap,
    this.onHistoryItemRemove,
    this.showHistory = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions
          if (suggestions.isNotEmpty) ...[
            _buildSectionHeader('Suggestions'),
            ...suggestions.map((suggestion) => _buildSuggestionItem(
              context,
              suggestion,
              Icons.search,
              onSuggestionTap,
            )),
          ],
          
          // History
          if (showHistory && history.isNotEmpty) ...[
            if (suggestions.isNotEmpty) _buildDivider(),
            _buildSectionHeader('Recent Searches'),
            ...history.map((item) => _buildHistoryItem(
              context,
              item,
              onHistoryItemTap,
              onHistoryItemRemove,
            )),
          ],
        ],
      ),
    );
  }

  /// Builds a section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Builds a suggestion item
  Widget _buildSuggestionItem(
    BuildContext context,
    String suggestion,
    IconData icon,
    Function(String) onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: AppTheme.primaryRed,
      ),
      title: Text(
        suggestion,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: () => onTap(suggestion),
      dense: true,
    );
  }

  /// Builds a history item
  Widget _buildHistoryItem(
    BuildContext context,
    String item,
    Function(String)? onTap,
    Function(String)? onRemove,
  ) {
    return ListTile(
      leading: Icon(
        Icons.history,
        size: 20,
        color: AppTheme.primaryRed,
      ),
      title: Text(
        item,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onRemove(item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          : null,
      onTap: () => onTap?.call(item),
      dense: true,
    );
  }

  /// Builds a divider
  Widget _buildDivider() {
    return const Divider(height: 1);
  }
} 