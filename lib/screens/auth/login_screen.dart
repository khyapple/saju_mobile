import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cosmic_background.dart';

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
    final l10n = AppLocalizations.of(context);
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mounted) context.go('/profiles');
    } on AuthException catch (e) {
      final msg = (e.message.contains('Invalid login credentials') || e.message.contains('invalid_credentials'))
          ? l10n.loginFailed
          : e.message;
      setState(() => _error = msg);
    } catch (_) {
      setState(() => _error = l10n.loginFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    final l10n = AppLocalizations.of(context);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.socialLoginFailed);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final emailInput = _emailCtrl.text.trim();
    final ctrl = TextEditingController(text: emailInput);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.forgotPassword,
          style: const TextStyle(color: kDark, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.forgotPasswordDesc,
              style: const TextStyle(color: kTextMuted, fontSize: 13)),
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
            child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.send, style: const TextStyle(color: kGold, fontWeight: FontWeight.w600)),
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
          SnackBar(content: Text(l10n.resetEmailSent)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.resetEmailFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // 로고 — 할당 공간은 그대로, 내부 요소 크기만 축소
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 96, height: 96,
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
                                width: 68, height: 68,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          l10n.appTitle,
                          style: TextStyle(
                            fontFamily: 'ShillaCulture',
                            fontSize: 40,
                            color: kGold,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                            shadows: [
                              Shadow(color: kGold.withOpacity(0.3), blurRadius: 22),
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
                    ),
                  ),
                  const SizedBox(height: 64),

                  // 로그인 폼 — 박스 없이 배치, 3요소 가로폭 일치
                  Center(
                    child: SizedBox(
                      width: 260,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 이메일 — floating label
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 15, color: kDark),
                            decoration: _inputDeco(label: l10n.email),
                          ),
                          const SizedBox(height: 14),

                          // 비밀번호 — floating label
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            onSubmitted: (_) => _login(),
                            style: const TextStyle(fontSize: 15, color: kDark),
                            decoration: _inputDeco(
                              label: l10n.password,
                              suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                                  color: kTextMuted, size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),

                          // 비밀번호 찾기
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                              child: Text(l10n.forgotPassword,
                                style: const TextStyle(fontSize: 12, color: kTextMuted)),
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
                          const SizedBox(height: 4),

                          PrimaryButton(
                            text: l10n.login,
                            onPressed: _login,
                            loading: _loading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Container(height: 0.5, color: kGlassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(l10n.orContinueWith, style: TextStyle(fontSize: 11, color: kDark.withOpacity(0.4))),
                      ),
                      Expanded(child: Container(height: 0.5, color: kGlassBorder)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 소셜 로그인 - 원형 아이콘 버튼 (실제 브랜드 로고, 흰색)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialCircle(
                        icon: const FaIcon(FontAwesomeIcons.google, size: 18, color: Colors.white),
                        tooltip: l10n.continueWithGoogle,
                        onTap: () => _handleSocialLogin(OAuthProvider.google),
                      ),
                      const SizedBox(width: 16),
                      _socialCircle(
                        icon: const FaIcon(FontAwesomeIcons.apple, size: 22, color: Colors.white),
                        tooltip: l10n.continueWithApple,
                        onTap: () => _handleSocialLogin(OAuthProvider.apple),
                      ),
                      const SizedBox(width: 16),
                      _socialCircle(
                        icon: const FaIcon(FontAwesomeIcons.facebookF, size: 18, color: Colors.white),
                        tooltip: l10n.continueWithFacebook,
                        onTap: () => _handleSocialLogin(OAuthProvider.facebook),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${l10n.noAccount}  ',
                        style: TextStyle(color: kDark.withOpacity(0.5), fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: Text(l10n.signup,
                          style: const TextStyle(color: kGold, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({String? label, String? hint, Widget? suffix}) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: kDark.withOpacity(0.55), fontSize: 14),
    floatingLabelStyle: const TextStyle(color: kGold, fontSize: 13, fontWeight: FontWeight.w500),
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

  Widget _socialCircle({
    required Widget icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x0AFFFFFF),
                border: Border.all(color: kGlassBorder, width: 0.8),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
