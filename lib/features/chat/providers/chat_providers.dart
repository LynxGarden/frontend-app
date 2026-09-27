import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/chat/data/chat_repository.dart';
import 'package:lynx_app/features/chat/data/models/assigned_staff.dart';
import 'package:lynx_app/features/chat/data/models/chat_message.dart';
import 'package:lynx_app/features/chat/data/models/conversation.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Key for a 1:1 conversation: the client and the specific staff member.
typedef ChatKey = ({String client, String staff});

/// The conversation between a client and a staff member (created on first open).
final conversationProvider =
    FutureProvider.family<Conversation, ChatKey>((ref, key) {
  return ChatRepository.getOrCreateConversation(key.client, key.staff);
});

/// The staff (coach/physio) assigned to a client — the client's master list
/// and the care team on a client record.
final assignedStaffProvider =
    FutureProvider.family<List<AssignedStaff>, String>((ref, clientPersonId) {
  return ChatRepository.listAssignedStaff(clientPersonId);
});

/// Realtime messages for a conversation, oldest → newest.
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  return ChatRepository.messagesStream(conversationId);
});

/// Fast one-shot fetch of recent messages — paints the history instantly while
/// the realtime [messagesProvider] connects.
final recentMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  return ChatRepository.recentMessages(conversationId);
});

/// Signed URL for a private chat image, cached by storage path.
final chatImageUrlProvider =
    FutureProvider.family<String, String>((ref, path) {
  return ChatRepository.imageSignedUrl(path);
});

/// The signed-in CLIENT's total unread count (messages from any staff, unread).
/// Drives the red badge on the client's Chat tab.
final clientUnreadCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.isStaff) return Stream.value(0);
  return ChatRepository.clientMessagesStream(user.personId).map(
    (msgs) => msgs
        .where((m) => m.senderPersonId != user.personId && !m.isRead)
        .length,
  );
});

/// The signed-in CLIENT's unread count PER staff member (keyed by the staff
/// person id). Drives the badges on the master chat list rows.
final clientUnreadByStaffProvider = StreamProvider<Map<String, int>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.isStaff) return Stream.value(const {});
  return ChatRepository.clientMessagesStream(user.personId).map((msgs) {
    final counts = <String, int>{};
    for (final m in msgs) {
      if (m.senderPersonId != user.personId && !m.isRead) {
        // sender is the staff → coach_person_id is that staff.
        counts[m.coachPersonId] = (counts[m.coachPersonId] ?? 0) + 1;
      }
    }
    return counts;
  });
});

/// Per-client unread counts for the signed-in COACH (messages from each client
/// that are unread). Drives the red badges on the Clients-list cards.
final coachUnreadCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || !user.isStaff) return Stream.value(const {});
  return ChatRepository.coachMessagesStream(user.personId).map((msgs) {
    final counts = <String, int>{};
    for (final m in msgs) {
      if (m.isFromClient && !m.isRead) {
        counts[m.clientPersonId] = (counts[m.clientPersonId] ?? 0) + 1;
      }
    }
    return counts;
  });
});
