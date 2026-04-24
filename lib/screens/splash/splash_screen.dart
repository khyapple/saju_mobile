import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cosmic_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _fadeOutCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // 로고 등장 (0~800ms)
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // 링 확산 (300ms~)
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringScale = Tween<double>(begin: 0.5, end: 2.5).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );

    // 텍스트 등장 (600ms~)
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );

    // 페이드 아웃 (마지막)
    _fadeOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _ringCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    _fadeOutCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _navigate();
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.go('/profiles');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _ringCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeOut,
        child: CosmicBackground(
          showStars: false,
          child: Stack(
            children: [
              // 애니메이션 별
              const Positioned.fill(child: AnimatedStarField()),

              // 중앙 글로우
              Center(
                child: AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, __) => Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          kGold.withOpacity(0.10 * _logoOpacity.value),
                          kCosmicPurple.withOpacity(0.05 * _logoOpacity.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 확산 링
              Center(
                child: AnimatedBuilder(
                  animation: _ringCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _ringScale.value,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kGold.withOpacity(_ringOpacity.value * 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 로고 — 로그인 화면 사양과 일치
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: child,
                        ),
                      ),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kGold.withOpacity(0.5),
                            width: 1.5,
                          ),
                          gradient: RadialGradient(
                            colors: [
                              kGold.withOpacity(0.12),
                              kGold.withOpacity(0.03),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kGold.withOpacity(0.18),
                              blurRadius: 50,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 68,
                              height: 68,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // 앱 이름 — 로그인 화면과 동일 사양
                    AnimatedBuilder(
                      animation: _textCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: child,
                        ),
                      ),
                      child: Builder(builder: (ctx) {
                        final l10n = AppLocalizations.of(ctx);
                        return Column(
                          children: [
                            Text(
                              l10n.appTitle,
                              style: TextStyle(
                                fontFamily: 'ShillaCulture',
                                fontSize: 40,
                                color: kGold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 8,
                                shadows: [
                                  Shadow(
                                    color: kGold.withOpacity(0.3),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Image.asset(
                              'assets/images/divider_center_02.png',
                              height: 8,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.aiSajuAnalysis,
                              style: TextStyle(
                                fontSize: 12,
                                color: kDark.withOpacity(0.5),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
