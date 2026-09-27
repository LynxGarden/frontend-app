import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/chat/data/models/assigned_staff.dart';
import 'package:lynx_app/features/chat/data/models/chat_message.dart';
import 'package:lynx_app/features/chat/data/models/conversation.dart';
import 'package:lynx_app/shared/models/app_user.dart';

/// Data layer for chat. Text + image messages between a client and their
/// assigned coach, delivered realtime; typing indicators ride a realtime
/// broadcast channel (no DB). All writes are RLS-scoped to the two participants.
class ChatRepository {
  const ChatRepository._();

  static const _imageBucket = 'chat-images';

  /// Resolve (creating if needed) the 1:1 conversation between a client and a
  /// specific staff member. Callable by the client (with assigned staff) or by
  /// the staff member themselves (auto-assigns).
  static Future<Conversation> getOrCreateConversation(
      String clientPersonId, String staffPersonId) async {
    try {
      // Function returns a single `conversations` composite → an object (a
      // SETOF would return a list; handle both defensively).
      final res = await SupabaseClientWrapper.rpc(
        'get_or_create_conversation',
        params: {'p_client': clientPersonId, 'p_staff': staffPersonId},
      );
      final map = res is List ? res.first : res;
      return Conversation.fromJson(Map<String, dynamic>.from(map as Map));
    } catch (e) {
      throw AppException('Could not open the chat.', cause: e);
    }
  }

  /// The staff (coach/physio) assigned to a client — the client's master chat
  /// list (and the care-team list a coach sees on the client record).
  static Future<List<AssignedStaff>> listAssignedStaff(
      String clientPersonId) async {
    try {
      final rows = await SupabaseClientWrapper.rpc<List<dynamic>>(
        'list_client_staff',
        params: {'p_client': clientPersonId},
      );
      return rows
          .map((r) => AssignedStaff.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('Could not load the care team.', cause: e);
    }
  }

  /// Staff in the tenant (coach/physio/owner) who can be assigned to a client —
  /// for the staff-side assign picker.
  static Future<List<AssignedStaff>> listAssignableStaff(
      String tenantId) async {
    try {
      final rows = await SupabaseClientWrapper.db('person_roles')
          .select(
              'role, users_data!inner(id, first_name, last_name, avatar_kind, avatar_value)')
          .eq('tenant_id', tenantId)
          .inFilter('role', ['coach', 'physio', 'owner']);
      final seen = <String>{};
      final staff = <AssignedStaff>[];
      for (final r in (rows as List)) {
        final u = (r as Map)['users_data'] as Map<String, dynamic>;
        final id = u['id'] as String;
        if (!seen.add(id)) continue;
        staff.add(AssignedStaff(
          staffPersonId: id,
          role: appRoleFromString(r['role'] as String? ?? 'coach') ??
              AppRole.coach,
          firstName: u['first_name'] as String?,
          lastName: u['last_name'] as String?,
          avatarKind: u['avatar_kind'] as String?,
          avatarValue: u['avatar_value'] as String?,
        ));
      }
      return staff;
    } catch (e) {
      throw AppException('Could not load staff.', cause: e);
    }
  }

  /// Assign a staff member to a client (staff-only, via RLS).
  static Future<void> assignStaff({
    required String tenantId,
    required String clientPersonId,
    required String staffPersonId,
    required String createdBy,
  }) async {
    try {
      await SupabaseClientWrapper.db('client_staff').insert({
        'tenant_id': tenantId,
        'client_person_id': clientPersonId,
        'staff_person_id': staffPersonId,
        'created_by': createdBy,
      });
    } catch (e) {
      throw AppException('Could not assign staff.', cause: e);
    }
  }

  /// Remove a staff assignment (staff-only, via RLS).
  static Future<void> unassignStaff({
    required String clientPersonId,
    required String staffPersonId,
  }) async {
    try {
      await SupabaseClientWrapper.db('client_staff')
          .delete()
          .eq('client_person_id', clientPersonId)
          .eq('staff_person_id', staffPersonId);
    } catch (e) {
      throw AppException('Could not remove staff.', cause: e);
    }
  }

  /// Realtime stream of a conversation's messages, oldest → newest. Capped to a
  /// recent window so a long history doesn't bloat the initial payload.
  static Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return SupabaseClientWrapper.stream('messages', primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .limit(200)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  /// A fast one-shot fetch of the most recent messages (oldest → newest). Used
  /// to paint the history instantly while the realtime stream connects.
  static Future<List<ChatMessage>> recentMessages(String conversationId,
      {int limit = 50}) async {
    try {
      final rows = await SupabaseClientWrapper.db('messages')
          .select(
              'id, conversation_id, sender_person_id, client_person_id, coach_person_id, body, image_path, created_at, read_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);
      final list = (rows as List)
          .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
          .toList();
      return list.reversed.toList(); // oldest → newest
    } catch (e) {
      throw AppException('Could not load the conversation.', cause: e);
    }
  }

  /// Realtime stream of every message in the CLIENT's conversation (drives the
  /// client's unread badge).
  static Stream<List<ChatMessage>> clientMessagesStream(String clientPersonId) {
    return SupabaseClientWrapper.stream('messages', primaryKey: ['id'])
        .eq('client_person_id', clientPersonId)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  /// Realtime stream of every message across the COACH's clients (drives the
  /// Clients-list badges — recompute unread-per-client on each emission).
  static Stream<List<ChatMessage>> coachMessagesStream(String coachPersonId) {
    return SupabaseClientWrapper.stream('messages', primaryKey: ['id'])
        .eq('coach_person_id', coachPersonId)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  /// Send a text and/or image message. [imagePath] is a storage path returned
  /// by [uploadImage].
  static Future<void> sendMessage({
    required String conversationId,
    required String senderPersonId,
    String? body,
    String? imagePath,
  }) async {
    final text = body?.trim();
    if ((text == null || text.isEmpty) && imagePath == null) return;
    final data = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_person_id': senderPersonId,
    };
    if (text != null && text.isNotEmpty) data['body'] = text;
    if (imagePath != null) data['image_path'] = imagePath;
    try {
      await SupabaseClientWrapper.db('messages').insert(data);
    } catch (e) {
      throw AppException('Could not send your message.', cause: e);
    }
  }

  /// Upload an image to `{conversationId}/{ts}.{ext}` and return its path.
  static Future<String> uploadImage({
    required String conversationId,
    required File file,
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      // Map extension → a MIME the bucket accepts (jpeg/png/webp). `jpg` must
      // become `image/jpeg`, not `image/jpg` (which the bucket rejects).
      const mimes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      };
      final contentType = mimes[ext] ?? 'image/jpeg';
      final ts = DateTime.now().microsecondsSinceEpoch;
      final path = '$conversationId/msg_$ts.$ext';
      await SupabaseClientWrapper.storage.from(_imageBucket).upload(
            path,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      return path;
    } catch (e) {
      throw AppException('Could not upload the image.', cause: e);
    }
  }

  /// A signed URL for a private chat image (default 1h).
  static Future<String> imageSignedUrl(String path,
      {int expiresIn = 3600}) async {
    try {
      return await SupabaseClientWrapper.storage
          .from(_imageBucket)
          .createSignedUrl(path, expiresIn);
    } catch (e) {
      throw AppException('Could not load the image.', cause: e);
    }
  }

  /// Mark every message the caller RECEIVED in [conversationId] as read.
  static Future<void> markRead(String conversationId) async {
    try {
      await SupabaseClientWrapper.rpc<void>(
        'mark_conversation_read',
        params: {'p_conversation': conversationId},
      );
    } catch (_) {
      // Non-fatal: read receipts are best-effort.
    }
  }

  /// Per-client unread counts for the calling coach (Clients-list badges).
  static Future<Map<String, int>> coachUnreadCounts() async {
    try {
      final rows =
          await SupabaseClientWrapper.rpc<List<dynamic>>('coach_unread_counts');
      return {
        for (final r in rows)
          (r as Map<String, dynamic>)['client_person_id'] as String:
              (r['unread'] as num).toInt(),
      };
    } catch (_) {
      return const {};
    }
  }
}
