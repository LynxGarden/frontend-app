import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper around the Supabase client.
///
/// Call [SupabaseClientWrapper.init] once from `main.dart` before
/// `runApp()`. After initialization, use the static getters to access
/// auth, database, storage, and edge-function clients.
class SupabaseClientWrapper {
  SupabaseClientWrapper._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Initialize Supabase. Must be called exactly once before any other
  /// Supabase usage (typically in `main()`).
  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    // The publishable key (sb_publishable_...) is the current client-side key.
    final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (url == null ||
        url.isEmpty ||
        publishableKey == null ||
        publishableKey.isEmpty) {
      throw StateError(
        'Missing Supabase env vars. Set SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY in your .env file.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  /// Supabase Auth client (sign-in, sign-up, session, etc.).
  static GoTrueClient get auth => _client.auth;

  /// Shorthand for building Supabase PostgREST queries.
  ///
  /// Usage: `SupabaseClientWrapper.db('table_name').select(...)`.
  static SupabaseQueryBuilder db(String table) => _client.from(table);

  /// Call a Postgres function (RPC).
  ///
  /// Usage: `await SupabaseClientWrapper.rpc('assign_template', params: {...})`.
  static PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
  }) =>
      _client.rpc<T>(fn, params: params);

  /// Supabase Storage client (upload / download files).
  static SupabaseStorageClient get storage => _client.storage;

  /// Supabase Edge Functions client.
  ///
  /// Usage: `SupabaseClientWrapper.functions.invoke('fn-name', body: {...})`.
  static FunctionsClient get functions => _client.functions;
}
