import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/preferences_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      imageUrl: 'https://storage.letudiant.fr/mediatheque/letudiant/7/9/2774679-travailler-dans-le-football-632x421.jpg',
      accentColor: Color(0xFF1A56DB),
      icon: Icons.workspace_premium_rounded,
      title: 'Coupons Premium',
      description:
          'Accédez aux meilleures sélections de coupons analysés par nos experts sportifs chaque jour.',
    ),
    _OnboardingPage(
      imageUrl: 'https://us.123rf.com/450wm/bigmouse/bigmouse2201/bigmouse220100015/180208753-un-ballon-de-football-3d-d%C3%A9taill%C3%A9-et-r%C3%A9aliste-marque-un-filet-de-but-sur-fond-de-terrain-de-football.jpg?ver=6',
      accentColor: Color(0xFF1E3A8A),
      icon: Icons.trending_up_rounded,
      title: 'Taux de réussite élevé',
      description:
          'Nos coupons sont sélectionnés avec rigueur pour maximiser vos chances de gain.',
    ),
    _OnboardingPage(
      imageUrl: 'https://static.lejdd.fr/lmnr/var/jdd/public/media/image/2022/12/04/18/au-fait-quelle-est-la-taille-d-un-terrain-de-football.jpg?VersionId=dlQNA97JmKOI20c1njWXbK9RznUSl4kU',
      accentColor: Color(0xFF1A56DB),
      icon: Icons.notifications_active_rounded,
      title: 'Alertes instantanées',
      description:
          'Recevez une notification dès qu\'un nouveau coupon est disponible. Ne manquez aucune opportunité.',
    ),
  ];

  Future<void> _done() async {
    await ref.read(prefsProvider).setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _done();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    final size   = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Slides plein écran ────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _SlideBackground(
              page: _pages[i],
              screenHeight: size.height,
            ),
          ),

          // ── Bouton Passer (haut droite) ───────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _done,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Passer',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),

          // ── Panel bas fixe ────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomPanel(
              pages: _pages,
              currentPage: _page,
              isLast: isLast,
              onNext: _next,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide : fond plein écran ─────────────────────────────────────────────────

class _SlideBackground extends StatelessWidget {
  final _OnboardingPage page;
  final double screenHeight;

  const _SlideBackground({required this.page, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image de fond (à remplacer par de vraies photos)
        _BackgroundVisual(page: page),

        // Dégradé du bas pour lisibilité du panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fond visuel (placeholder images) ─────────────────────────────────────────

class _BackgroundVisual extends StatelessWidget {
  final _OnboardingPage page;
  const _BackgroundVisual({required this.page});

  @override
  Widget build(BuildContext context) {
    // Tente de charger l'image asset. Si elle n'existe pas encore,
    // affiche un fond coloré avec une icône.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond couleur
        ColoredBox(color: page.accentColor),

        // Motif décoratif
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),

        // Icône centrale
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 160),
            child: Icon(
              page.icon,
              size: 120,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),

        // Image réseau plein écran
        Image.network(
          page.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Panel inférieur ───────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final List<_OnboardingPage> pages;
  final int currentPage;
  final bool isLast;
  final VoidCallback onNext;

  const _BottomPanel({
    required this.pages,
    required this.currentPage,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateurs de page
            Row(
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == currentPage ? 28 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i == currentPage
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            Text(
              pages[currentPage].title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              pages[currentPage].description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 32),

            // Bouton
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isLast ? 'Commencer' : 'Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modèle de données ─────────────────────────────────────────────────────────

class _OnboardingPage {
  final String imageUrl;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.imageUrl,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.description,
  });
}
