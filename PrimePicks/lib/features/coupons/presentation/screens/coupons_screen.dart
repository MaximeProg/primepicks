import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/subscriptions/presentation/providers/subscription_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/coupon_provider.dart';
import '../widgets/coupon_card.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subAsync = ref.watch(mySubscriptionProvider);
    final hasActiveSub = subAsync.valueOrNull?.isActive ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Coupons'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Gratuits'),
            Tab(text: 'Premium'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FreeTab(hasActiveSub: hasActiveSub),
          _PremiumTab(hasActiveSub: hasActiveSub),
        ],
      ),
    );
  }
}

// ── Onglet Gratuit ─────────────────────────────────────────────────────────────

class _FreeTab extends ConsumerWidget {
  final bool hasActiveSub;
  const _FreeTab({required this.hasActiveSub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicCouponsProvider);

    return async.when(
      loading: () => _ShimmerList(),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(publicCouponsProvider),
      ),
      data: (list) {
        final free = list.where((c) => c.isFree).toList();
        if (free.isEmpty) {
          return const EmptyState(
            icon: Icons.confirmation_number_outlined,
            title: 'Aucun coupon gratuit',
            subtitle: 'Les coupons gratuits apparaîtront ici.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(publicCouponsProvider),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: free.length,
            itemBuilder: (_, i) => CouponCard(coupon: free[i]),
          ),
        );
      },
    );
  }
}

// ── Onglet Premium ─────────────────────────────────────────────────────────────

class _PremiumTab extends ConsumerStatefulWidget {
  final bool hasActiveSub;
  const _PremiumTab({required this.hasActiveSub});

  @override
  ConsumerState<_PremiumTab> createState() => _PremiumTabState();
}

class _PremiumTabState extends ConsumerState<_PremiumTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(premiumCouponsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si non abonné, on ne déclenche pas l'appel API premium (403 garanti)
    if (!widget.hasActiveSub) {
      return _LockedPremiumView();
    }

    final async = ref.watch(premiumCouponsProvider);

    return async.when(
      loading: () => _ShimmerList(),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.read(premiumCouponsProvider.notifier).refresh(),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.workspace_premium_rounded,
            title: 'Aucun coupon premium',
            subtitle: 'Les nouveaux coupons apparaîtront ici.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(premiumCouponsProvider.notifier).refresh(),
          color: AppColors.primary,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: list.length + 1,
            itemBuilder: (_, i) {
              if (i == list.length) {
                return ref.read(premiumCouponsProvider.notifier).hasMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(height: 16);
              }
              return CouponCard(coupon: list[i]);
            },
          ),
        );
      },
    );
  }
}

class _LockedPremiumView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicCouponsProvider);
    final list = async.valueOrNull ?? [];
    final premium = list.where((c) => !c.isFree).toList();

    return Stack(
      children: [
        if (premium.isNotEmpty)
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: premium.length,
            itemBuilder: (_, i) => CouponCard(coupon: premium[i], locked: true),
          ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contenu Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Abonnez-vous pour accéder à tous les coupons avec analyse détaillée.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 5,
      itemBuilder: (_, __) => const ShimmerCouponCard(),
    );
  }
}

