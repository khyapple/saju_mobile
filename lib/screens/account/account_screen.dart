import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profiles_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _subscription;
  bool _loadingSub = true;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await _api.getSubscription();
      setState(() => _subscription = sub);
    } catch (_) {
    } finally {
      setState(() => _loadingSub = false);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        title: Text(l10n.logout, style: const TextStyle(color: kDark)),
        content: Text(l10n.logoutConfirm,
          style: const TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout, style: const TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      context.go('/login');
    }
  }

  void _openOwnerProfile() {
    final l10n = AppLocalizations.of(context);
    final profiles = context.read<ProfilesProvider>().profiles;
    final owner = profiles.where((p) => p.isOwner).cast<dynamic>().firstOrNull;
    if (owner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noProfiles)),
      );
      return;
    }
    context.push('/profiles/${owner.id}');
  }

  InputDecoration _fieldDeco(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: kTextMuted, fontSize: 13),
        hintStyle: TextStyle(color: kTextMuted.withOpacity(0.6), fontSize: 13),
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGold),
        ),
      );

  Future<void> _showChangeEmailDialog() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final currentPw = TextEditingController();
    final newEmail = TextEditingController();
    String? errorText;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          backgroundColor: kCosmicNavy.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.changeId,
            style: const TextStyle(color: kDark, fontSize: 17, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.currentEmail}: ${auth.email}',
                style: const TextStyle(fontSize: 12, color: kTextMuted)),
              const SizedBox(height: 14),
              TextField(
                controller: currentPw,
                autofocus: true,
                obscureText: true,
                style: const TextStyle(color: kDark, fontSize: 14),
                decoration: _fieldDeco(l10n.currentPassword, l10n.currentPasswordHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newEmail,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: kDark, fontSize: 14),
                decoration: _fieldDeco(l10n.newEmail, l10n.newEmailHint),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(errorText!, style: const TextStyle(color: kErrorColor, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
            ),
            TextButton(
              onPressed: loading ? null : () async {
                final cp = currentPw.text;
                final v = newEmail.text.trim();
                if (cp.isEmpty) {
                  setSheet(() => errorText = l10n.currentPasswordRequired);
                  return;
                }
                if (v.isEmpty) {
                  setSheet(() => errorText = l10n.emailRequired);
                  return;
                }
                final emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRe.hasMatch(v)) {
                  setSheet(() => errorText = l10n.invalidEmail);
                  return;
                }
                if (v == auth.email) {
                  setSheet(() => errorText = l10n.sameAsCurrentEmail);
                  return;
                }
                setSheet(() {
                  errorText = null;
                  loading = true;
                });
                try {
                  await auth.verifyPassword(cp);
                } catch (_) {
                  setSheet(() {
                    loading = false;
                    errorText = l10n.currentPasswordWrong;
                  });
                  return;
                }
                try {
                  await auth.updateEmail(v);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.emailChangeConfirmSent)),
                  );
                } catch (e) {
                  setSheet(() {
                    loading = false;
                    errorText = '${l10n.emailChangeFailed} ($e)';
                  });
                }
              },
              child: loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: kGold, strokeWidth: 2))
                  : Text(l10n.save, style: const TextStyle(color: kGold, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final currentPw = TextEditingController();
    final pw = TextEditingController();
    final pwConfirm = TextEditingController();
    String? errorText;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          backgroundColor: kCosmicNavy.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.changePassword,
            style: const TextStyle(color: kDark, fontSize: 17, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: currentPw,
                autofocus: true,
                obscureText: true,
                style: const TextStyle(color: kDark, fontSize: 14),
                decoration: _fieldDeco(l10n.currentPassword, l10n.currentPasswordHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pw,
                obscureText: true,
                style: const TextStyle(color: kDark, fontSize: 14),
                decoration: _fieldDeco(l10n.newPassword, l10n.newPasswordHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwConfirm,
                obscureText: true,
                style: const TextStyle(color: kDark, fontSize: 14),
                decoration: _fieldDeco(l10n.confirmNewPassword, l10n.passwordConfirmHint),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(errorText!, style: const TextStyle(color: kErrorColor, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
            ),
            TextButton(
              onPressed: loading ? null : () async {
                final cp = currentPw.text;
                final a = pw.text;
                final b = pwConfirm.text;
                if (cp.isEmpty) {
                  setSheet(() => errorText = l10n.currentPasswordRequired);
                  return;
                }
                if (a.length < 8) {
                  setSheet(() => errorText = l10n.passwordTooShort);
                  return;
                }
                if (a != b) {
                  setSheet(() => errorText = l10n.passwordMismatch);
                  return;
                }
                setSheet(() {
                  errorText = null;
                  loading = true;
                });
                try {
                  await auth.verifyPassword(cp);
                } catch (_) {
                  setSheet(() {
                    loading = false;
                    errorText = l10n.currentPasswordWrong;
                  });
                  return;
                }
                try {
                  await auth.updatePassword(a);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.passwordChangeSuccess)),
                  );
                } catch (e) {
                  setSheet(() {
                    loading = false;
                    errorText = '${l10n.passwordChangeFailed} ($e)';
                  });
                }
              },
              child: loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: kGold, strokeWidth: 2))
                  : Text(l10n.save, style: const TextStyle(color: kGold, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final plan = _subscription?['plan'] as String? ?? 'free';
    final tokens = _subscription?['tokensRemaining'] as int? ?? 0;
    final tokensLimit = _subscription?['tokensLimit'] as int?;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.myPage,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // 프로필 카드
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: kGold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            auth.displayName.isNotEmpty ? auth.displayName[0] : '?',
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700, color: kGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.displayName,
                              style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700, color: kDark)),
                            const SizedBox(height: 3),
                            Text(auth.email,
                              style: const TextStyle(fontSize: 13, color: kTextMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _menuItem(icon: Icons.person_outline, label: l10n.editProfile, onTap: _openOwnerProfile),
                _menuItem(icon: Icons.alternate_email, label: l10n.changeId, onTap: _showChangeEmailDialog),
                _menuItem(icon: Icons.lock_outline, label: l10n.changePassword, onTap: _showChangePasswordDialog),
                const SizedBox(height: 16),
                // 플랜 + 토큰 사용량 카드
                GlassCard(
                  fillColor: kGold.withOpacity(0.08),
                  borderColor: kGold.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  child: _loadingSub
                      ? const Center(
                          child: CircularProgressIndicator(color: kGold, strokeWidth: 2))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: kGold, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _planLabel(l10n, plan),
                                  style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: kDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.tokenUsage,
                                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
                                Text(
                                  tokensLimit != null && tokensLimit > 0
                                      ? l10n.tokenUsageOf(tokens, tokensLimit)
                                      : l10n.tokensRemaining(tokens),
                                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
                              ],
                            ),
                            if (tokensLimit != null && tokensLimit > 0) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: tokens / tokensLimit,
                                  backgroundColor: kGlassBorder,
                                  valueColor: const AlwaysStoppedAnimation<Color>(kGold),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.auto_awesome, size: 18, color: kInk),
                                label: Text(
                                  l10n.upgrade,
                                  style: const TextStyle(
                                    color: kInk, fontSize: 15, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kGold,
                                  foregroundColor: kInk,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                    ],
                  ),
                ),
              ),
              // 로그아웃 고정 하단
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _menuItem(
                  icon: Icons.logout,
                  label: l10n.logout,
                  onTap: _signOut,
                  color: kErrorColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _planLabel(AppLocalizations l10n, String plan) {
    switch (plan.toLowerCase()) {
      case 'basic': return l10n.planBasic;
      case 'pro': return l10n.planPro;
      case 'ultimate': return l10n.planUltimate;
      default: return l10n.planFree;
    }
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGlassBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color ?? kTextMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                      style: TextStyle(
                        fontSize: 15,
                        color: color ?? kDark,
                        fontWeight: FontWeight.w400,
                      )),
                  ),
                  Icon(Icons.chevron_right,
                    size: 18, color: color ?? kTextMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
