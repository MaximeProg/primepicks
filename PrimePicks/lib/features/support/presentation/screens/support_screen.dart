import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../data/datasources/support_datasource.dart';
import '../providers/support_provider.dart';
import '../../domain/entities/ticket_entity.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau ticket', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ref.watch(ticketsProvider).when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const ShimmerBox.wide(height: 80, radius: 12),
        ),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(ticketsProvider),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyState(
              icon: Icons.headset_mic_rounded,
              title: 'Aucun ticket',
              subtitle: 'Contactez notre équipe pour toute question ou problème.',
              actionLabel: 'Créer un ticket',
              onAction: () => _showNewTicketDialog(context, ref),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(ticketsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _TicketTile(ticket: tickets[i], isDark: isDark),
            ),
          );
        },
      ),
    );
  }

  void _showNewTicketDialog(BuildContext context, WidgetRef ref) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewTicketSheet(
        subjectCtrl: subjectCtrl,
        messageCtrl: messageCtrl,
        formKey: formKey,
        onSubmit: (subject, message) async {
          final ds = ref.read(supportDatasourceProvider);
          final ticket = await ds.createTicket(subject, message);
          ref.invalidate(ticketsProvider);
          if (context.mounted) {
            Navigator.pop(context);
            context.push('/support/${ticket.id}');
          }
        },
      ),
    );
  }
}

// ── Ticket tile ───────────────────────────────────────────────────────────────

class _TicketTile extends StatelessWidget {
  final TicketSummaryEntity ticket;
  final bool isDark;
  const _TicketTile({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusStyle(ticket.status);
    final hasUnread = ticket.unreadCount > 0;

    return GestureDetector(
      onTap: () => context.push('/support/${ticket.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: hasUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.headset_mic_rounded, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ticket.lastMessage != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      ticket.lastMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    Fmt.relative(ticket.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      '${ticket.unreadCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _statusStyle(String status) => switch (status) {
    'OPEN'        => (AppColors.primary, 'Ouvert'),
    'IN_PROGRESS' => (AppColors.warning, 'En cours'),
    'CLOSED'      => (AppColors.textSecondary, 'Fermé'),
    _             => (AppColors.textSecondary, status),
  };
}

// ── New ticket bottom sheet ───────────────────────────────────────────────────

class _NewTicketSheet extends StatefulWidget {
  final TextEditingController subjectCtrl;
  final TextEditingController messageCtrl;
  final GlobalKey<FormState> formKey;
  final Future<void> Function(String, String) onSubmit;
  const _NewTicketSheet({
    required this.subjectCtrl,
    required this.messageCtrl,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Nouveau ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet',
                hintText: 'Décrivez brièvement votre problème',
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Sujet requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Décrivez votre problème en détail',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Message requis' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Envoyer',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onSubmit(
        widget.subjectCtrl.text.trim(),
        widget.messageCtrl.text.trim(),
      );
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }
}
