import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
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
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload disponible uniquement sur l\'app mobile')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;

    setState(() => _sending = true);
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'image.jpg';
      final result = await ref.read(apiClientProvider).uploadBytes<Map<String, dynamic>>(
        '/support/upload',
        bytes,
        filename,
      );
      final url = result['url'] as String;
      await ref.read(ticketChatProvider(widget.ticketId).notifier).sendMedia(url, 'IMAGE');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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

    if (isImage) {
      return GestureDetector(
        onTap: () => _openFullscreen(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: mediaUrl,
            width: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 200,
              height: 140,
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 200,
              height: 80,
              color: Colors.black12,
              child: const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 32),
              ),
            ),
          ),
        ),
      );
    }

    // PDF / VIDEO / FILE
    final (icon, label) = switch (mediaType) {
      'VIDEO' => (Icons.videocam_rounded, 'Vidéo'),
      'PDF'   => (Icons.picture_as_pdf_rounded, 'PDF'),
      _       => (Icons.attach_file_rounded, 'Fichier'),
    };

    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(mediaUrl);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isUser ? Colors.white70 : AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isUser ? Colors.white : AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullscreenImage(url: mediaUrl),
      ),
    );
  }
}

class _FullscreenImage extends StatelessWidget {
  final String url;
  const _FullscreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
              tooltip: 'Ouvrir dans le navigateur',
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
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
