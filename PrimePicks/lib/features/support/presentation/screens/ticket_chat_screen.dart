import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/support_provider.dart';
import '../../domain/entities/ticket_entity.dart';

class TicketChatScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketChatScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Le FamilyAsyncNotifier charge automatiquement le ticket via build(arg)
    // On déclenche juste le provider au premier frame pour initialiser le WS
    Future.microtask(() =>
        ref.read(ticketChatProvider(widget.ticketId)));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      await ref
          .read(ticketChatProvider(widget.ticketId).notifier)
          .sendText(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    // Sur web, on ne peut pas uploader directement — on notifie l'utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload d\'images disponible sur l\'app mobile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final chatAsync = ref.watch(ticketChatProvider(widget.ticketId));

    // Auto-scroll quand de nouveaux messages arrivent
    ref.listen(ticketChatProvider(widget.ticketId), (_, next) {
      if (next is AsyncData) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: chatAsync.when(
          loading: () => const Text('Chargement...'),
          error:   (_, __) => const Text('Support'),
          data:    (t) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.subject,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              Text(
                _statusLabel(t.status),
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(t.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      body: chatAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, __) => const ShimmerBox.wide(height: 60, radius: 12),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(ticketChatProvider(widget.ticketId).notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (ticket) => Column(
          children: [
            // ── Messages ────────────────────────────────────────────────────
            Expanded(
              child: ticket.messages.isEmpty
                  ? const Center(
                      child: Text('Aucun message',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: ticket.messages.length,
                      itemBuilder: (_, i) => _MessageBubble(
                        msg: ticket.messages[i],
                        isDark: isDark,
                      ),
                    ),
            ),
            // ── Input ────────────────────────────────────────────────────────
            if (!ticket.isClosed)
              _ChatInput(
                controller: _textCtrl,
                sending: _sending,
                isDark: isDark,
                onSend: _sendText,
                onPickImage: _pickImage,
              )
            else
              _ClosedBanner(isDark: isDark),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'OPEN'        => 'Ouvert',
    'IN_PROGRESS' => 'En cours de traitement',
    'CLOSED'      => 'Fermé',
    _             => s,
  };

  Color _statusColor(String s) => switch (s) {
    'OPEN'        => AppColors.primary,
    'IN_PROGRESS' => AppColors.warning,
    'CLOSED'      => AppColors.textSecondary,
    _             => AppColors.textSecondary,
  };
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final TicketMessageEntity msg;
  final bool isDark;
  const _MessageBubble({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isFromUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _Avatar(isDark: isDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : AppColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.border,
                          ),
                  ),
                  child: _BubbleContent(msg: msg, isUser: isUser, isDark: isDark),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Fmt.time(msg.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 12,
                        color: msg.isRead
                            ? AppColors.primary
                            : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final TicketMessageEntity msg;
  final bool isUser;
  final bool isDark;
  const _BubbleContent({required this.msg, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (msg.hasMedia) {
      return _MediaPreview(mediaUrl: msg.mediaUrl!, mediaType: msg.mediaType ?? 'FILE',
          isUser: isUser, isDark: isDark);
    }
    return Text(
      msg.content ?? '',
      style: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: isUser
            ? Colors.white
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final String mediaUrl;
  final String mediaType;
  final bool isUser;
  final bool isDark;
  const _MediaPreview({
    required this.mediaUrl,
    required this.mediaType,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = mediaType == 'IMAGE';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isImage ? Icons.image_rounded : Icons.attach_file_rounded,
          size: 18,
          color: isUser ? Colors.white70 : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          isImage ? 'Image' : 'Fichier',
          style: TextStyle(
            fontSize: 13,
            color: isUser ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isDark;
  const _Avatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.primary),
    );
  }
}

// ── Chat input ────────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.isDark,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onPickImage,
              icon: const Icon(Icons.attach_file_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Joindre un fichier',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sending ? AppColors.textTertiary : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Closed banner ─────────────────────────────────────────────────────────────

class _ClosedBanner extends StatelessWidget {
  final bool isDark;
  const _ClosedBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceVariant,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 16,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Ce ticket est fermé',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
