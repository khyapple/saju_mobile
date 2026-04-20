import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        title: const Text('로그아웃', style: TextStyle(color: kDark)),
        content: const Text('정말 로그아웃하시겠습니까?',
          style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('마이페이지',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
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
                _menuItem(icon: Icons.person_outline, label: '프로필 수정', onTap: () {}),
                _menuItem(icon: Icons.alternate_email, label: '아이디 변경', onTap: () {}),
                _menuItem(icon: Icons.lock_outline, label: '비밀번호 변경', onTap: () {}),
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
                                  _planLabel(plan),
                                  style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: kDark),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('업그레이드',
                                    style: TextStyle(color: kGold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('토큰 사용량',
                                  style: TextStyle(fontSize: 12, color: kTextMuted)),
                                Text(
                                  tokensLimit != null && tokensLimit > 0
                                      ? '$tokens / $tokensLimit'
                                      : '$tokens개 남음',
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
                  label: '로그아웃',
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

  String _planLabel(String plan) {
    switch (plan.toLowerCase()) {
      case 'basic': return 'Basic 플랜';
      case 'pro': return 'Pro 플랜';
      case 'ultimate': return 'Ultimate 플랜';
      default: return '무료 플랜';
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
        margin: const EdgeInsets.only(bottom: 2),
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
