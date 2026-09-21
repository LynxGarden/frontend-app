import 'package:flutter/material.dart';

/// Dismisses the keyboard when the user taps outside a focused field,
/// without stealing taps from interactive children (buttons, list items).
///
/// Wrap a screen's body in this instead of a raw `GestureDetector` with
/// `HitTestBehavior.opaque` (which would swallow taps meant for children).
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
