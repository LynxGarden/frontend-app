import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:lynx_app/core/storage/secure_storage_service.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';
import 'package:lynx_app/features/calendar/data/health_repository.dart';

/// Minimal Strava OAuth + activity import.
///
/// Config comes from dotenv (`STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET`,
/// `STRAVA_REDIRECT_URI`). Tokens are kept in secure storage. The redirect that
/// returns the `code` must be routed back into [completeAuth] by the app's
/// deep-link handler; until that + a registered Strava app are configured,
/// [connect] returns false gracefully.
class StravaService {
  StravaService._();

  static const _tokenKey = 'strava_access_token';
  static const _refreshKey = 'strava_refresh_token';
  static const _expiryKey = 'strava_expires_at';

  static String? get _clientId => dotenv.env['STRAVA_CLIENT_ID'];
  static String? get _clientSecret => dotenv.env['STRAVA_CLIENT_SECRET'];
  static String? get _redirectUri => dotenv.env['STRAVA_REDIRECT_URI'];

  static bool get isConfigured =>
      (_clientId?.isNotEmpty ?? false) &&
      (_clientSecret?.isNotEmpty ?? false) &&
      (_redirectUri?.isNotEmpty ?? false);

  static Future<bool> get isConnected async =>
      (await SecureStorageService.read(_tokenKey))?.isNotEmpty ?? false;

  /// Launches the Strava authorization page. The redirect carries a `code` that
  /// the deep-link handler must pass to [completeAuth]. Returns false if the app
  /// isn't configured or the URL couldn't be opened.
  static Future<bool> connect() async {
    if (!isConfigured) return false;
    final uri = Uri.https('www.strava.com', '/oauth/authorize', {
      'client_id': _clientId!,
      'redirect_uri': _redirectUri!,
      'response_type': 'code',
      'approval_prompt': 'auto',
      'scope': 'read,activity:read',
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[strava] launch failed: $e');
      return false;
    }
  }

  /// Exchanges an authorization [code] for tokens (call from the deep-link
  /// handler). Returns true on success.
  static Future<bool> completeAuth(String code) async {
    if (!isConfigured) return false;
    try {
      final res = await http.post(
        Uri.https('www.strava.com', '/oauth/token'),
        body: {
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );
      if (res.statusCode != 200) return false;
      await _storeTokens(jsonDecode(res.body) as Map<String, dynamic>);
      return true;
    } catch (e) {
      debugPrint('[strava] token exchange failed: $e');
      return false;
    }
  }

  static Future<void> disconnect() async {
    await SecureStorageService.delete(_tokenKey);
    await SecureStorageService.delete(_refreshKey);
    await SecureStorageService.delete(_expiryKey);
  }

  /// Fetches recent Strava activities, persists them as activity health logs,
  /// and returns the imported count. No-op (0) when not connected.
  static Future<int> importAndSave({
    required String tenantId,
    required String personId,
    int days = 30,
  }) async {
    final token = await _validAccessToken();
    if (token == null) return 0;
    try {
      final after =
          DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch ~/
              1000;
      final res = await http.get(
        Uri.https('www.strava.com', '/api/v3/athlete/activities',
            {'after': '$after', 'per_page': '100'}),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return 0;
      final list = (jsonDecode(res.body) as List).whereType<Map>().toList();
      final inputs = <HealthLogInput>[];
      for (final a in list) {
        final moving = (a['moving_time'] as num?)?.toDouble() ?? 0;
        final start = a['start_date'] as String?;
        inputs.add(HealthLogInput(
          type: HealthLogType.activity,
          source: HealthLogSource.strava,
          value: moving > 0 ? moving / 60.0 : null,
          unit: 'min',
          data: {
            'kind': a['type'] ?? 'workout',
            'name': a['name'],
            'distance_m': a['distance'],
          },
          notes: a['name'] as String?,
          loggedAt: start != null ? DateTime.tryParse(start) : null,
        ));
      }
      await HealthRepository.addMany(
          tenantId: tenantId, personId: personId, inputs: inputs);
      return inputs.length;
    } catch (e) {
      debugPrint('[strava] import failed: $e');
      return 0;
    }
  }

  // --- tokens ---------------------------------------------------------------
  static Future<void> _storeTokens(Map<String, dynamic> json) async {
    await SecureStorageService.write(_tokenKey, json['access_token'] as String);
    if (json['refresh_token'] != null) {
      await SecureStorageService.write(
          _refreshKey, json['refresh_token'] as String);
    }
    if (json['expires_at'] != null) {
      await SecureStorageService.write(
          _expiryKey, json['expires_at'].toString());
    }
  }

  /// Returns a valid access token, refreshing it if expired. Null if not linked.
  static Future<String?> _validAccessToken() async {
    final token = await SecureStorageService.read(_tokenKey);
    if (token == null || token.isEmpty) return null;
    final expiryStr = await SecureStorageService.read(_expiryKey);
    final expiry = int.tryParse(expiryStr ?? '');
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expiry == null || expiry - 60 > nowSec) return token;
    return (await _refresh()) ?? token;
  }

  static Future<String?> _refresh() async {
    if (!isConfigured) return null;
    final refresh = await SecureStorageService.read(_refreshKey);
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.https('www.strava.com', '/oauth/token'),
        body: {
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
          'grant_type': 'refresh_token',
          'refresh_token': refresh,
        },
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      await _storeTokens(json);
      return json['access_token'] as String?;
    } catch (e) {
      debugPrint('[strava] refresh failed: $e');
      return null;
    }
  }
}
