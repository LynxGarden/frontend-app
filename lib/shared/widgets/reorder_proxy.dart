import 'dart:ui';

import 'package:flutter/material.dart';

/// A [ReorderableListView.proxyDecorator] that lifts the dragged item with a
/// **transparent** Material and a gentle scale — instead of the framework's
/// default opaque, square, elevated surface that otherwise shows as a boxy
/// "container" behind our rounded cards. The card keeps its own rounded corners,
/// border and shadow while being dragged.
Widget roundedReorderProxy(
    Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, inner) {
      final t = Curves.easeInOut.transform(animation.value);
      return Transform.scale(
        scale: lerpDouble(1.0, 1.03, t)!,
        child: inner,
      );
    },
    // A transparent Material so no square backing paints behind the card; the
    // item's own decoration (rounded border + shadow) is all that shows.
    child: Material(color: Colors.transparent, child: child),
  );
}
