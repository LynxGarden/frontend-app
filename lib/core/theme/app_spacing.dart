import 'package:flutter/widgets.dart';

/// Soft, warm depth. Elevation comes from shadow + a hairline border, never
/// Material elevation (which we keep at 0). Two stacked shadows read as a
/// gentle iOS-style lift on the cream brand.
class AppShadows {
  AppShadows._();

  /// Card / floating-surface lift.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14004225), blurRadius: 18, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A004225), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Stronger lift for floating bars / sheets.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x22004225), blurRadius: 30, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0F004225), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

/// Standard border radii used throughout the app.
class AppRadius {
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 18.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
  static const double pill = 99.0;
}

/// Standard spacing values used throughout the app.
class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}
