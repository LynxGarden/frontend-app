import 'package:lynx_app/core/config/app_flavor.dart';
import 'package:lynx_app/main.dart';

/// Dev flavor entrypoint — loads `.env` (local / staging Supabase).
/// Run with: flutter run -t lib/main_dev.dart
Future<void> main() => bootstrap(Flavor.dev);
