import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lynx_app/core/theme/app_theme.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Logical sizes we render every screen at, to catch overflows on the smallest
/// and a large modern phone.
class TestDevice {
  const TestDevice(this.name, this.size, this.dpr);
  final String name;
  final Size size;
  final double dpr;

  static const iphoneSE = TestDevice('iPhone SE', Size(375, 667), 2.0);
  static const iphone17Pro = TestDevice('iPhone 17 Pro', Size(402, 874), 3.0);

  static const all = [iphoneSE, iphone17Pro];
}

/// Pump [child] inside the real app theme + localizations + a ProviderScope with
/// [overrides], at [device]'s size, then assert nothing overflowed or threw.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  required TestDevice device,
}) async {
  tester.view.physicalSize = device.size * device.dpr;
  tester.view.devicePixelRatio = device.dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  // Let async providers resolve and animations settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  expect(
    tester.takeException(),
    isNull,
    reason: 'Overflow/exception on ${device.name}',
  );
}

/// Run [body] once per device, each as its own `testWidgets` case.
void forEachDevice(
  String description,
  Future<void> Function(WidgetTester tester, TestDevice device) body,
) {
  for (final device in TestDevice.all) {
    testWidgets('$description · ${device.name}', (tester) => body(tester, device));
  }
}
