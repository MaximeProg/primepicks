import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/review_datasource.dart';
import '../../domain/entities/review_entity.dart';
import '../providers/review_provider.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final reviewsAsync = ref.watch(reviewsProvider);
    final statsAsync   = ref.watch(reviewStatsProvider);
    final user         = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Avis & Témoignages'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reviewsProvider);
          ref.invalidate(reviewStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Statistiques ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => _StatsHeader(
                  average: (stats['average_rating'] as num?)?.toDouble() ?? 0,
                  total:   (stats['total_reviews'] as num?)?.toInt() ?? 0,
                  isDark:  isDark,
                ),
              ),
            ),

            // ── Bouton laisser un avis ───────────────────────────────────────
            if (user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _showForm
                        ? _ReviewForm(
                            key: const ValueKey('form'),
                            onSubmitted: () {
                              setState(() => _showForm = false);
                              ref.invalidate(reviewsProvider);
                              ref.invalidate(reviewStatsProvider);
                            },
                            onCancel: () => setState(() => _showForm = false),
                          )
                        : _LeaveReviewButton(
                            key: const ValueKey('button'),
                            onTap: () => setState(() => _showForm = true),
                          ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Liste des avis ───────────────────────────────────────────────
            reviewsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const _ReviewCardSkeleton(),
                  childCount: 4,
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Impossible de charger les avis.\n$e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ),
              data: (reviews) => reviews.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun avis pour le moment.\nSoyez le premier à partager votre expérience !',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _ReviewCard(review: reviews[i], isDark: isDark),
                          childCount: reviews.length,
                        ),
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final double average;
  final int    total;
  final bool   isDark;

  const _StatsHeader({required this.average, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF0E3A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  average > 0 ? average.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                _StarRow(rating: average.round(), size: 20, activeColor: Colors.amber),
                const SizedBox(height: 4),
                Text(
                  '$total avis validé${total > 1 ? "s" : ""}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.workspace_premium_rounded, size: 64, color: Colors.white24),
        ],
      ),
    );
  }
}

class _LeaveReviewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LeaveReviewButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.rate_review_outlined),
      label: const Text('Laisser un avis'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFF1A56DB)),
        foregroundColor: const Color(0xFF1A56DB),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReviewForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const _ReviewForm({super.key, required this.onSubmitted, required this.onCancel});

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  int    _rating  = 0;
  final  _ctrl    = TextEditingController();
  bool   _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une note.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final ds = ReviewDatasource(ref.read(apiClientProvider));
      await ds.submitReview(rating: _rating, comment: _ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis envoyé ! Il sera visible après validation.'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E2A3A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Votre note', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),

          // Étoiles interactives
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: i < _rating ? Colors.amber : Colors.grey[400],
                ),
              ),
            )),
          ),

          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience (facultatif)…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final bool         isDark;

  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                child: Text(
                  (review.authorName ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1A56DB),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName ?? 'Utilisateur',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              _StarRow(rating: review.rating, size: 15, activeColor: Colors.amber),
            ],
          ),

          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return '${d.day} ${months[d.month - 1]}. ${d.year}';
  }
}

class _StarRow extends StatelessWidget {
  final int    rating;
  final double size;
  final Color  activeColor;

  const _StarRow({required this.rating, required this.size, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: i < rating ? activeColor : Colors.grey[350],
      )),
    );
  }
}

class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
