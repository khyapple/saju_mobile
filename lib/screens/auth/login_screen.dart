import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mounted) context.go('/profiles');
    } on AuthException catch (e) {
      final msg = (e.message.contains('Invalid login credentials') || e.message.contains('invalid_credentials'))
          ? '이메일 또는 비밀번호를 확인해주세요.'
          : e.message;
      setState(() => _error = msg);
    } catch (_) {
      setState(() => _error = '이메일 또는 비밀번호를 확인해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
    } catch (_) {
      if (mounted) setState(() => _error = '소셜 로그인에 실패했습니다.');
    }
  }

  Future<void> _forgotPassword() async {
    final emailInput = _emailCtrl.text.trim();
    final ctrl = TextEditingController(text: emailInput);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('비밀번호 찾기',
          style: TextStyle(color: kDark, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('가입한 이메일로 재설정 링크를 보내드립니다.',
              style: TextStyle(color: kTextMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: kDark, fontSize: 15),
              decoration: _inputDeco(hint: 'example@email.com'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('전송', style: TextStyle(color: kGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final email = ctrl.text.trim();
    if (email.isEmpty) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호 재설정 이메일을 보냈습니다. 스팸함도 확인해주세요.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 전송에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 로고
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kGold.withOpacity(0.5), width: 1.5),
                            gradient: RadialGradient(
                              colors: [
                                kGold.withOpacity(0.12),
                                kGold.withOpacity(0.03),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kGold.withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('命', style: TextStyle(fontSize: 36, color: kGold, fontWeight: FontWeight.w300)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '사  주',
                          style: TextStyle(
                            color: kGold, fontWeight: FontWeight.w300,
                            letterSpacing: 10, fontSize: 34,
                            shadows: [
                              Shadow(color: kGold.withOpacity(0.3), blurRadius: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 44, height: 0.5, color: kGold.withOpacity(0.4)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('◈', style: TextStyle(color: kGold.withOpacity(0.6), fontSize: 9)),
                            ),
                            Container(width: 44, height: 0.5, color: kGold.withOpacity(0.4)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('AI 사주 분석',
                          style: TextStyle(fontSize: 12, color: kTextMuted, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 로그인 폼 - 글래스 카드
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    blur: 10,
                    fillColor: const Color(0x0CFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('로그인',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kDark)),
                        const SizedBox(height: 20),

                        // 이메일
                        _field(controller: _emailCtrl, label: '이메일', hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),

                        // 비밀번호
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('비밀번호',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              onSubmitted: (_) => _login(),
                              style: const TextStyle(fontSize: 15, color: kDark),
                              decoration: _inputDeco(
                                hint: '••••••••',
                                suffix: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                                    color: kTextMuted, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 비밀번호 찾기
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                            child: const Text('비밀번호 찾기',
                              style: TextStyle(fontSize: 12, color: kTextMuted)),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kErrorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kErrorColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: kErrorColor, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!, style: const TextStyle(color: kErrorColor, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        PrimaryButton(text: '로그인', onPressed: _login, loading: _loading),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Container(height: 0.5, color: kGlassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('또는', style: TextStyle(fontSize: 11, color: kDark.withOpacity(0.4))),
                      ),
                      Expanded(child: Container(height: 0.5, color: kGlassBorder)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 소셜 로그인 - 글래스 스타일
                  _socialBtn(
                    label: 'Google로 계속하기',
                    icon: const Text('G', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                    onTap: () => _handleSocialLogin(OAuthProvider.google),
                  ),
                  const SizedBox(height: 10),
                  _socialBtn(
                    label: 'Apple로 계속하기',
                    icon: const Text('', style: TextStyle(fontSize: 16, color: Colors.white)),
                    onTap: () => _handleSocialLogin(OAuthProvider.apple),
                  ),
                  const SizedBox(height: 10),
                  _socialBtn(
                    label: 'Facebook으로 계속하기',
                    icon: const Text('f', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1877F2))),
                    onTap: () => _handleSocialLogin(OAuthProvider.facebook),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('계정이 없으신가요?  ',
                        style: TextStyle(color: kDark.withOpacity(0.5), fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: const Text('회원가입',
                          style: TextStyle(color: kGold, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: kDark),
          decoration: _inputDeco(hint: hint),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({required String hint, Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kDark.withOpacity(0.3), fontSize: 14),
    filled: true,
    fillColor: const Color(0x08FFFFFF),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kGlassBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kGlassBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGold, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _socialBtn({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0x08FFFFFF),
              side: BorderSide(color: kGlassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 10),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kDark.withOpacity(0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
