import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/config/app_flavor.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/config/deeplink_config.dart';
import 'package:lynx_app/core/theme/app_theme.dart';
import 'package:lynx_app/core/router/app_router.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Default entrypoint — resolves the flavor from `--dart-define=FLAVOR=`
/// (defaults to dev). The flavored entrypoints (`main_dev.dart`,
/// `main_prod.dart`) call [bootstrap] directly.
Future<void> main() => bootstrap(Flavor.fromEnv());

/// Shared startup for every flavor: load the flavor's env, init Supabase,
/// then run the app.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFlavor.current = flavor;

  Object? initError;
  try {
    await dotenv.load(fileName: flavor.envFile);
    await SupabaseClientWrapper.init();
    DeepLinkConfig.debugPrintSummary();

    // TODO: Initialize additional services here:
    // await OneSignalService.init();
  } catch (e, st) {
    debugPrint('App initialization failed: $e\n$st');
    initError = e;
  }

  runApp(ProviderScope(child: MyApp(initError: initError)));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, this.initError});

  final Object? initError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initError != null) {
      return MaterialApp(
        title: 'Lynx',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _SetupRequiredPage(error: initError),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Lynx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

/// Shown when Supabase / .env isn't configured yet.
class _SetupRequiredPage extends StatelessWidget {
  const _SetupRequiredPage({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Setup Required', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    "Supabase isn't configured yet. The app can't sign users in or sign them up.",
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fix: Open .env and set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text('Technical details:', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SelectableText(error.toString(), style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
