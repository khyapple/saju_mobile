import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _signupSuccess = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // 웹과 동일한 비밀번호 강도 계산 (0~4)
  int get _passwordStrength {
    final pw = _passwordCtrl.text;
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[a-z]')) && pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[^a-zA-Z0-9]'))) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return const Color(0xFFB5413B);
      case 2: return const Color(0xFFC97B49);
      case 3: return kGold;
      default: return kSuccessColor;
    }
  }

  String _strengthLabel(AppLocalizations l10n) {
    switch (_passwordStrength) {
      case 1: return l10n.passwordWeak;
      case 2: return l10n.passwordFair;
      case 3: return l10n.passwordStrong;
      default: return l10n.passwordVeryStrong;
    }
  }

  Future<void> _signup() async {
    final l10n = AppLocalizations.of(context);
    if (!_agreeTerms) {
      setState(() => _error = l10n.termsRequired);
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.nameRequired);
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = l10n.passwordMismatch);
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'full_name': _nameCtrl.text.trim(),
          'display_name': _nameCtrl.text.trim(),
          'onboarding_step': 'welcome',
        },
      );

      if (!mounted) return;

      // 세션이 null이면 이메일 인증 필요 (웹과 동일한 처리)
      if (response.session == null) {
        setState(() { _signupSuccess = true; _loading = false; });
        return;
      }

      context.go('/onboarding');
    } on AuthException catch (e) {
      final String msg;
      if (e.message.contains('already registered') || e.message.contains('User already registered')) {
        msg = l10n.emailAlreadyUsed;
      } else if (e.message.contains('rate limit') || e.message.contains('email rate')) {
        msg = l10n.emailRateLimit;
      } else {
        msg = l10n.signupFailed;
      }
      setState(() => _error = msg);
    } catch (_) {
      setState(() => _error = l10n.signupFailed);
    } finally {
      if (mounted && !_signupSuccess) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    if (_signupSuccess) return _emailConfirmScreen();
    return _formScreen();
  }

  // 이메일 인증 안내 화면 (웹과 동일)
  Widget _emailConfirmScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kGold.withOpacity(0.25), width: 2),
                    ),
                    child: const Icon(Icons.mail_outline, color: kGold, size: 36),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    borderRadius: 20,
                    child: Column(
                      children: [
                        Text(
                          l10n.checkYourEmail,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.confirmLinkSent,
                          style: const TextStyle(fontSize: 13, color: kTextMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailCtrl.text.trim(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(width: 60, height: 0.5, color: kGold.withOpacity(0.25)),
                        const SizedBox(height: 16),
                        Text(
                          l10n.confirmLinkDesc,
                          style: const TextStyle(fontSize: 12, color: kTextMuted, height: 1.6),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.checkSpam,
                          style: const TextStyle(fontSize: 11, color: kTextMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${l10n.alreadyConfirmed}  ', style: const TextStyle(fontSize: 12, color: kTextMuted)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          l10n.login,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGold),
                        ),
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

  Widget _formScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.signup,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kDark)),
                const SizedBox(height: 6),
                Text(l10n.startAiAnalysis,
                  style: const TextStyle(fontSize: 14, color: kTextMuted)),
                const SizedBox(height: 28),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(controller: _nameCtrl, label: l10n.name, hint: l10n.nameHint),
                      const SizedBox(height: 16),
                      _field(
                        controller: _emailCtrl,
                        label: l10n.email,
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 + 강도 바
                      _labelText(l10n.password),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePass,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 15, color: kDark),
                        decoration: _inputDeco(
                          hint: l10n.passwordMinLength,
                          suffix: _eyeIcon(_obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
                        ),
                      ),
                      if (_passwordCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(4, (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                                height: 3,
                                decoration: BoxDecoration(
                                  color: i < _passwordStrength ? _strengthColor : const Color(0x08FFFFFF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )),
                            if (_passwordStrength > 0) ...[
                              const SizedBox(width: 8),
                              Text(_strengthLabel(l10n), style: TextStyle(fontSize: 11, color: _strengthColor)),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 비밀번호 확인
                      _labelText(l10n.passwordConfirm),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 15, color: kDark),
                        decoration: _inputDeco(
                          hint: l10n.passwordConfirmHint,
                          suffix: _eyeIcon(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                        ),
                      ),
                      if (_confirmCtrl.text.isNotEmpty && _confirmCtrl.text != _passwordCtrl.text) ...[
                        const SizedBox(height: 4),
                        Text(l10n.passwordMismatch,
                          style: const TextStyle(fontSize: 10, color: kErrorColor)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 약관 동의
                GestureDetector(
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _agreeTerms ? kGold : Colors.transparent,
                          border: Border.all(color: _agreeTerms ? kGold : kGlassBorder, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _agreeTerms
                            ? const Icon(Icons.check, color: kInk, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.agreeToTerms,
                          style: const TextStyle(fontSize: 13, color: kTextMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
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
                const SizedBox(height: 28),

                PrimaryButton(
                  text: l10n.signup,
                  onPressed: _agreeTerms ? _signup : null,
                  loading: _loading,
                ),
                const SizedBox(height: 20),

                // 구분선
                Row(
                  children: [
                    Expanded(child: Container(height: 0.5, color: kGlassBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(l10n.orContinueWith, style: const TextStyle(fontSize: 11, color: kTextMuted)),
                    ),
                    Expanded(child: Container(height: 0.5, color: kGlassBorder)),
                  ],
                ),
                const SizedBox(height: 16),

                // 소셜 로그인 — glass-styled
                _socialBtn(
                  label: l10n.continueWithGoogle,
                  icon: const Text('G', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                  onTap: () => _handleSocialLogin(OAuthProvider.google),
                ),
                const SizedBox(height: 10),
                _socialBtn(
                  label: l10n.continueWithApple,
                  icon: const Text('', style: TextStyle(fontSize: 16, color: Colors.white)),
                  bgOverride: Colors.black.withOpacity(0.6),
                  onTap: () => _handleSocialLogin(OAuthProvider.apple),
                ),
                const SizedBox(height: 10),
                _socialBtn(
                  label: l10n.continueWithFacebook,
                  icon: const Text('f', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  bgOverride: const Color(0xFF1877F2).withOpacity(0.7),
                  onTap: () => _handleSocialLogin(OAuthProvider.facebook),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${l10n.noAccount}  ',
                      style: const TextStyle(color: kTextMuted, fontSize: 14)),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(l10n.login,
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
        _labelText(label),
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

  Widget _labelText(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark),
  );

  InputDecoration _inputDeco({required String hint, Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
    filled: true,
    fillColor: const Color(0x08FFFFFF),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGlassBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGlassBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGold, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _eyeIcon(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: kTextMuted, size: 20),
    onPressed: onTap,
  );

  Widget _socialBtn({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
    Color? bgOverride,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: bgOverride ?? const Color(0x0AFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: kGlassBorder),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kDark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
