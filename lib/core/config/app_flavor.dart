/// Build flavors. Two are wired: [dev] (local/staging Supabase) and [prod]
/// (the live cloud project). The active flavor is chosen by the entrypoint
/// (`lib/main_dev.dart` / `lib/main_prod.dart`) or a `--dart-define=FLAVOR=`.
enum Flavor {
  dev,
  prod;

  /// The dotenv file this flavor loads (must be registered under `assets:` in
  /// pubspec.yaml).
  String get envFile => switch (this) {
        Flavor.dev => '.env',
        Flavor.prod => '.env.prod',
      };

  /// Suffix shown next to the app name in non-prod builds.
  String? get bannerLabel => switch (this) {
        Flavor.dev => 'DEV',
        Flavor.prod => null,
      };

  bool get isProd => this == Flavor.prod;

  /// Resolve from a compile-time define; defaults to [dev].
  static Flavor fromEnv() {
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    return Flavor.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => Flavor.dev,
    );
  }
}

/// Holds the flavor resolved at startup, for read-only access anywhere.
class AppFlavor {
  AppFlavor._();
  static Flavor current = Flavor.dev;
}
