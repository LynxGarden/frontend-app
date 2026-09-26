import 'package:flutter/material.dart';

import 'package:lynx_app/features/settings/presentation/settings_screen.dart';
import 'package:lynx_app/features/training/presentation/train_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/feature_placeholder.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';

/// Tabs a client sees: Train · Progress · Settings.
class ClientShell extends StatelessWidget {
  const ClientShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return MainShell(
      tabs: [
        ShellTab(
          label: l.navTrain,
          sfSymbol: 'figure.run',
          materialIcon: Icons.fitness_center,
          screen: const TrainScreen(),
        ),
        ShellTab(
          label: l.navProgress,
          sfSymbol: 'chart.line.uptrend.xyaxis',
          materialIcon: Icons.trending_up,
          screen: FeaturePlaceholder(
            title: l.progressTitle,
            icon: Icons.trending_up,
          ),
        ),
        ShellTab(
          label: l.navSettings,
          sfSymbol: 'gearshape',
          materialIcon: Icons.settings_outlined,
          screen: const SettingsScreen(),
        ),
      ],
    );
  }
}
