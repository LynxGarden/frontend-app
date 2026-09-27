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

  /// A realtime stream of rows from [table], emitting the current snapshot and
  /// then re-emitting on every insert/update/delete (RLS-scoped to the caller).
  ///
  /// Usage: `SupabaseClientWrapper.stream('assignments', primaryKey: ['id'])
  ///   .eq('person_id', id)`. Requires the table to be in the
  /// `supabase_realtime` publication (backend migration).
  static SupabaseStreamFilterBuilder stream(
    String table, {
    required List<String> primaryKey,
  }) =>
      _client.from(table).stream(primaryKey: primaryKey);

  /// Supabase Storage client (upload / download files).
  static SupabaseStorageClient get storage => _client.storage;

  /// Supabase Edge Functions client.
  ///
  /// Usage: `SupabaseClientWrapper.functions.invoke('fn-name', body: {...})`.
  static FunctionsClient get functions => _client.functions;

  /// A realtime channel for broadcast/presence (e.g. chat typing indicators).
  ///
  /// Usage: `SupabaseClientWrapper.channel('typing:$conversationId')`.
  static RealtimeChannel channel(String name) => _client.channel(name);

  /// Tear down every open realtime subscription (chat streams, typing channels,
  /// live assignments). Called on logout / account deletion so no channel keeps
  /// delivering the previous account's data on a shared device.
  static Future<void> removeAllChannels() => _client.removeAllChannels();
}
