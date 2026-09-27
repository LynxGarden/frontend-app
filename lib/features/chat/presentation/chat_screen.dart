import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/chat/data/chat_repository.dart';
import 'package:lynx_app/features/chat/data/models/chat_message.dart';
import 'package:lynx_app/features/chat/data/models/conversation.dart';
import 'package:lynx_app/features/chat/providers/chat_providers.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// 1:1 chat with a client's assigned coach. Used by BOTH sides — pass the
/// client's person id ([clientPersonId]) as the conversation key (the client
/// passes their own id; the coach passes the client's id) and a [title] for the
/// other party. Realtime messages, typing indicator, rich-text + image messages.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.clientPersonId,
    required this.staffPersonId,
    required this.title,
  });

  final String clientPersonId;
  final String staffPersonId;
  final String title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final QuillController _quill = QuillController.basic();
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _editorScroll = ScrollController();
  RealtimeChannel? _typing;
  Timer? _stopTypingTimer;
  Timer? _clearOtherTypingTimer;
  bool _otherTyping = false;
  bool _sending = false;
  File? _pendingImage;
  String? _convId;
  String? _me;

  @override
  void initState() {
    super.initState();
    _quill.addListener(_onEdit);
  }

  @override
  void dispose() {
    _quill.removeListener(_onEdit);
    _stopTypingTimer?.cancel();
    _clearOtherTypingTimer?.cancel();
    if (_typing != null) {
      _broadcastTyping(false);
      _typing!.unsubscribe();
    }
    _quill.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  void _onEdit() {
    _broadcastTyping(true);
    _stopTypingTimer?.cancel();
    _stopTypingTimer = Timer(
        const Duration(milliseconds: 1500), () => _broadcastTyping(false));
    setState(() {}); // refresh the send button state
  }

  // ---- typing indicator (realtime broadcast) --------------------------------

  void _initTyping(String conversationId, String me) {
    if (_convId == conversationId) return;
    _convId = conversationId;
    _me = me;
    _typing = SupabaseClientWrapper.channel('typing:$conversationId')
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          if (payload['person'] == me) return;
          final isTyping = payload['typing'] == true;
          if (!mounted) return;
          setState(() => _otherTyping = isTyping);
          _clearOtherTypingTimer?.cancel();
          if (isTyping) {
            _clearOtherTypingTimer = Timer(const Duration(seconds: 4), () {
              if (mounted) setState(() => _otherTyping = false);
            });
          }
        },
      )
      ..subscribe();
  }

  void _broadcastTyping(bool typing) {
    _typing?.sendBroadcastMessage(
      event: 'typing',
      payload: {'person': _me, 'typing': typing},
    );
  }

  // ---- formatting -----------------------------------------------------------

  void _toggle(Attribute attr) {
    HapticFeedback.selectionClick();
    final current = _quill.getSelectionStyle().attributes[attr.key];
    final active = current != null && current.value == attr.value;
    _quill.formatSelection(active ? Attribute.clone(attr, null) : attr);
    _editorFocus.requestFocus();
  }

  // ---- images ---------------------------------------------------------------

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _pendingImage = File(picked.path)); // preview, don't send yet
  }

  // ---- sending --------------------------------------------------------------

  bool get _hasText => _quill.document.toPlainText().trim().isNotEmpty;

  Future<void> _send(Conversation conv, String me) async {
    final md = _quillToMarkdown(_quill.document).trim();
    final img = _pendingImage;
    if (md.isEmpty && img == null) return;

    _quill.clear();
    setState(() {
      _pendingImage = null;
      _sending = img != null;
    });
    _broadcastTyping(false);
    HapticFeedback.lightImpact();
    try {
      String? imagePath;
      if (img != null) {
        imagePath =
            await ChatRepository.uploadImage(conversationId: conv.id, file: img);
      }
      await ChatRepository.sendMessage(
        conversationId: conv.id,
        senderPersonId: me,
        body: md.isEmpty ? null : md,
        imagePath: imagePath,
      );
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final convAsync = ref.watch(conversationProvider(
        (client: widget.clientPersonId, staff: widget.staffPersonId)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: convAsync.when(
              loading: () => const _ChatSkeleton(),
              error: (e, _) => _ErrorState(
                message: e is AppException ? e.message : l.chatNoCoach,
              ),
              data: (conv) {
                if (user != null) _initTyping(conv.id, user.personId);
                return _ChatBody(
                  conversation: conv,
                  me: user?.personId ?? '',
                  otherTyping: _otherTyping,
                  topInset: AppNavBar.estimatedHeight(context),
                  quill: _quill,
                  editorFocus: _editorFocus,
                  editorScroll: _editorScroll,
                  sending: _sending,
                  canSend: (_hasText || _pendingImage != null) && !_sending,
                  pendingImage: _pendingImage,
                  onRemoveImage: () => setState(() => _pendingImage = null),
                  onPickImage: _sending ? null : _pickImage,
                  onToggle: _toggle,
                  onSend: user == null ? null : () => _send(conv, user.personId),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppNavBar(title: widget.title, blurred: true, frost: 1.0),
          ),
        ],
      ),
    );
  }
}

/// Convert a Quill document to markdown (bold/italic/strike/code + bullet &
/// numbered lists) so it stores + renders like every other message body.
String _quillToMarkdown(Document doc) {
  final ops = doc.toDelta().toList();
  final out = StringBuffer();
  final line = StringBuffer();

  String inline(String text, Map<String, dynamic>? a) {
    if (a == null) return text;
    var s = text;
    if (a['code'] == true) s = '`$s`';
    if (a['bold'] == true) s = '**$s**';
    if (a['italic'] == true) s = '*$s*';
    if (a['strike'] == true) s = '~~$s~~';
    return s;
  }

  void flush(Map<String, dynamic>? block) {
    final prefix = switch (block?['list']) {
      'bullet' => '- ',
      'ordered' => '1. ',
      _ => '',
    };
    out.writeln('$prefix${line.toString()}');
    line.clear();
  }

  for (final op in ops) {
    final data = op.data;
    if (data is! String) continue; // skip embeds
    final attrs = op.attributes;
    final parts = data.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) line.write(inline(parts[i], attrs));
      if (i < parts.length - 1) flush(attrs); // the '\n' carries block attrs
    }
  }
  if (line.isNotEmpty) out.write(line);
  return out.toString().trimRight();
}

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({
    required this.conversation,
    required this.me,
    required this.otherTyping,
    required this.topInset,
    required this.quill,
    required this.editorFocus,
    required this.editorScroll,
    required this.sending,
    required this.canSend,
    required this.pendingImage,
    required this.onRemoveImage,
    required this.onPickImage,
    required this.onToggle,
    required this.onSend,
  });

  final Conversation conversation;
  final String me;
  final bool otherTyping;
  final double topInset;
  final QuillController quill;
  final FocusNode editorFocus;
  final ScrollController editorScroll;
  final bool sending;
  final bool canSend;
  final File? pendingImage;
  final VoidCallback onRemoveImage;
  final VoidCallback? onPickImage;
  final void Function(Attribute) onToggle;
  final VoidCallback? onSend;

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody> {
  final ScrollController _scroll = ScrollController();
  bool _atBottom = true; // reverse list: offset 0 == bottom (newest)
  bool _hasNew = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom = _scroll.offset <= 120;
    if (atBottom != _atBottom) {
      setState(() {
        _atBottom = atBottom;
        if (atBottom) _hasNew = false;
      });
    }
  }

  void _toBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    setState(() => _hasNew = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));
    final recentAsync =
        ref.watch(recentMessagesProvider(widget.conversation.id));

    final raw = messagesAsync.valueOrNull ?? recentAsync.valueOrNull;
    final messages = raw == null
        ? null
        : ([...raw]..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

    final visible = TickerMode.valuesOf(context).enabled;
    if (visible &&
        messages != null &&
        messages.any((m) => m.senderPersonId != widget.me && !m.isRead)) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ChatRepository.markRead(widget.conversation.id));
    }

    // A new message arrived while the user is scrolled up → offer to jump down.
    final count = messages?.length ?? 0;
    if (messages != null && count > _lastCount && !_atBottom && !_hasNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasNew = true);
      });
    }
    _lastCount = count;

    Widget list;
    if (messages == null) {
      list = (messagesAsync.hasError && recentAsync.hasError)
          ? _ErrorState(message: l.somethingWentWrong)
          : const _ChatSkeleton();
    } else if (messages.isEmpty && !widget.otherTyping) {
      list = Center(
        child: Text(l.noMessagesYet,
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
      );
    } else {
      final itemCount = messages.length + (widget.otherTyping ? 1 : 0);
      list = ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: EdgeInsets.fromLTRB(AppSpacing.md,
            widget.topInset + AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        itemCount: itemCount,
        itemBuilder: (context, i) {
          if (widget.otherTyping && i == 0) return const _TypingBubble();
          final idx =
              messages.length - 1 - (widget.otherTyping ? i - 1 : i);
          final m = messages[idx];
          return _MessageBubble(message: m, mine: m.isMine(widget.me));
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: list),
              if (!_atBottom)
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _JumpButton(
                    hasNew: _hasNew,
                    label: l.seeNewMessages,
                    onTap: _toBottom,
                  ),
                ),
            ],
          ),
        ),
        _Composer(
          quill: widget.quill,
          editorFocus: widget.editorFocus,
          editorScroll: widget.editorScroll,
          sending: widget.sending,
          canSend: widget.canSend,
          pendingImage: widget.pendingImage,
          onRemoveImage: widget.onRemoveImage,
          onPickImage: widget.onPickImage,
          onToggle: widget.onToggle,
          onSend: widget.onSend,
        ),
      ],
    );
  }
}

/// "Scroll to bottom" control: a circular down-arrow when scrolled up, or a
/// "See new messages" pill when a new message arrived while scrolled up.
class _JumpButton extends StatelessWidget {
  const _JumpButton(
      {required this.hasNew, required this.label, required this.onTap});
  final bool hasNew;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (hasNew) {
      return Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.onPrimary)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: 18, color: AppColors.onPrimary),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(
          side: BorderSide(color: AppColors.surfaceBorder)),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.keyboard_arrow_down,
              color: AppColors.primary, size: 24),
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = mine ? AppColors.primary : AppColors.surface;
    final fg = mine ? AppColors.onPrimary : AppColors.textPrimary;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        padding: message.hasImage
            ? const EdgeInsets.all(3)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: mine ? null : Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasImage) _ChatImage(path: message.imagePath!),
            if (message.body != null && message.body!.isNotEmpty)
              Padding(
                padding: message.hasImage
                    ? const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm,
                        AppSpacing.sm, AppSpacing.xs)
                    : EdgeInsets.zero,
                child: MarkdownBody(
                  data: message.body!,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTextStyles.body.copyWith(color: fg),
                    strong: AppTextStyles.body
                        .copyWith(color: fg, fontWeight: FontWeight.w700),
                    em: AppTextStyles.body
                        .copyWith(color: fg, fontStyle: FontStyle.italic),
                    del: AppTextStyles.body.copyWith(
                        color: fg, decoration: TextDecoration.lineThrough),
                    listBullet: AppTextStyles.body.copyWith(color: fg),
                    code: AppTextStyles.bodySmall.copyWith(
                        color: fg, backgroundColor: fg.withValues(alpha: 0.1)),
                    pPadding: EdgeInsets.zero,
                    listBulletPadding: const EdgeInsets.only(right: 6),
                    blockSpacing: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatImage extends ConsumerWidget {
  const _ChatImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(chatImageUrlProvider(path));
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: urlAsync.when(
          loading: () => Container(
              width: 200, height: 200, color: AppColors.skeletonBase),
          error: (_, _) => Container(
              width: 200,
              height: 120,
              color: AppColors.surfaceLight,
              child: Icon(Icons.broken_image_outlined,
                  color: AppColors.textTertiary)),
          data: (url) => CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
                width: 200, height: 200, color: AppColors.skeletonBase),
          ),
        ),
      ),
    );
  }
}

/// Animated "…" three-dot typing indicator (no text label).
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _dot(i),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(int i) {
    final t = (_c.value - i * 0.2) % 1.0;
    final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 7,
        height: 7,
        decoration:
            BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.quill,
    required this.editorFocus,
    required this.editorScroll,
    required this.sending,
    required this.canSend,
    required this.pendingImage,
    required this.onRemoveImage,
    required this.onPickImage,
    required this.onToggle,
    required this.onSend,
  });

  final QuillController quill;
  final FocusNode editorFocus;
  final ScrollController editorScroll;
  final bool sending;
  final bool canSend;
  final File? pendingImage;
  final VoidCallback onRemoveImage;
  final VoidCallback? onPickImage;
  final void Function(Attribute) onToggle;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pending image preview (send with the message, not automatically).
            if (pendingImage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(pendingImage!,
                            width: 92, height: 92, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: GestureDetector(
                          onTap: onRemoveImage,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Formatting toolbar.
            Row(
              children: [
                _FmtButton(
                    icon: Icons.format_bold,
                    onTap: () => onToggle(Attribute.bold)),
                _FmtButton(
                    icon: Icons.format_italic,
                    onTap: () => onToggle(Attribute.italic)),
                _FmtButton(
                    icon: Icons.format_list_bulleted,
                    onTap: () => onToggle(Attribute.ul)),
                _FmtButton(
                    icon: Icons.format_list_numbered,
                    onTap: () => onToggle(Attribute.ol)),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onPickImage,
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.image_outlined, color: AppColors.primary),
                ),
                Expanded(
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 44, maxHeight: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: QuillEditor.basic(
                      controller: quill,
                      focusNode: editorFocus,
                      scrollController: editorScroll,
                      config: QuillEditorConfig(
                        placeholder: l.messagePlaceholder,
                        padding: EdgeInsets.zero,
                        expands: false,
                        scrollable: true,
                        minHeight: 24,
                        maxHeight: 120,
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            AppTextStyles.body
                                .copyWith(color: AppColors.textPrimary),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                          placeHolder: DefaultTextBlockStyle(
                            AppTextStyles.body
                                .copyWith(color: AppColors.textTertiary),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: canSend ? onSend : null,
                  icon: Icon(Icons.arrow_upward_rounded,
                      color:
                          canSend ? AppColors.primary : AppColors.textTertiary),
                  style: IconButton.styleFrom(
                    backgroundColor: canSend
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact markdown-format toolbar button.
class _FmtButton extends StatelessWidget {
  const _FmtButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }
}

/// Loading placeholder shaped like a chat: alternating left/right bubbles
/// settled at the bottom, matching the real message list.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    const bubbles = <({bool mine, double w, double h})>[
      (mine: false, w: 170, h: 44),
      (mine: true, w: 120, h: 36),
      (mine: false, w: 210, h: 58),
      (mine: true, w: 150, h: 40),
      (mine: false, w: 90, h: 36),
      (mine: true, w: 190, h: 50),
    ];
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final b in bubbles)
              Align(
                alignment: b.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SkeletonBox(
                      width: b.w, height: b.h, borderRadius: AppRadius.lg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}
