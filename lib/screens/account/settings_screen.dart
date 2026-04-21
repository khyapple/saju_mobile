import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../widgets/cosmic_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('환경 설정',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
      ),
      body: CosmicBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('설정'),
                  _menuItem(icon: Icons.notifications_outlined, label: '알림 설정', onTap: () {}),
                  _menuItem(icon: Icons.language, label: '언어 설정', onTap: () {}),
                  const SizedBox(height: 16),
                  _sectionLabel('지원'),
                  _menuItem(icon: Icons.help_outline, label: '도움말', onTap: () {}),
                  _menuItem(icon: Icons.privacy_tip_outlined, label: '개인정보 처리방침', onTap: () {}),
                  _menuItem(icon: Icons.description_outlined, label: '서비스 이용약관', onTap: () {}),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kDark.withOpacity(0.4),
          letterSpacing: 0.5,
        )),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
                  Icon(icon, size: 20, color: kTextMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                      style: const TextStyle(fontSize: 15, color: kDark, fontWeight: FontWeight.w400)),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: kTextMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
