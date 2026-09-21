import 'package:lynx_app/core/config/app_flavor.dart';
import 'package:lynx_app/main.dart';

/// Prod flavor entrypoint — loads `.env.prod` (live cloud Supabase).
/// Run with: flutter run -t lib/main_prod.dart --release
Future<void> main() => bootstrap(Flavor.prod);
