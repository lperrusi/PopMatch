import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';

/// Reusable 6-digit code entry (auto-advance, backspace-to-previous, paste of a
/// full code into the first box). Calls [onCompleted] when all 6 are filled and
/// [onChanged] on every edit. Cursor is popcorn gold.
class AuthCodeInput extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  const AuthCodeInput({
    super.key,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  @override
  State<AuthCodeInput> createState() => AuthCodeInputState();
}

class AuthCodeInputState extends State<AuthCodeInput> {
  static const int _length = 6;
  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());

  String get code => _controllers.map((c) => c.text).join();

  /// Clears all boxes and refocuses the first (used after a failed attempt).
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) _nodes.first.requestFocus();
    widget.onChanged?.call('');
  }

  void _onChanged(int index, String value) {
    // Handle paste of a full code into one box.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, _length - 1);
      _nodes[next].requestFocus();
      _emit();
      return;
    }
    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    _emit();
  }

  void _emit() {
    final c = code;
    widget.onChanged?.call(c);
    if (c.length == _length && !c.contains('')) {
      widget.onCompleted?.call(c);
    }
  }

  KeyEventResult _onKey(int index, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _emit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_length, (index) {
        return SizedBox(
          width: 46,
          height: 58,
          child: Focus(
            onKeyEvent: (node, event) => _onKey(index, node, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _nodes[index],
              autofocus: widget.autofocus && index == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: index == 0 ? _length : 1,
              cursorColor: AppTheme.popcornGold,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.authCream,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppTheme.authInputBg,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.authBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.popcornGold, width: 2),
                ),
              ),
              onChanged: (v) => _onChanged(index, v),
            ),
          ),
        );
      }),
    );
  }
}
