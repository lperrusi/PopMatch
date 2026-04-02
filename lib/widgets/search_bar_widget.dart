import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// A reusable search bar widget with customizable functionality
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final String? initialValue;
  final Function(String) onSearch;
  final Function()? onClear;
  final bool showClearButton;
  final bool autoFocus;
  final TextInputAction textInputAction;
  final bool enabled;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search...',
    this.initialValue,
    required this.onSearch,
    this.onClear,
    this.showClearButton = true,
    this.autoFocus = false,
    this.textInputAction = TextInputAction.search,
    this.enabled = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autoFocus,
        textInputAction: widget.textInputAction,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryRed,
          ),
          suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.primaryRed,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: widget.onSearch,
        onChanged: (value) {
          setState(() {
            // Trigger rebuild to show/hide clear button
          });
          if (value.isEmpty) {
            widget.onClear?.call();
          }
        },
      ),
    );
  }
} 