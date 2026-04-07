import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/profiles_provider.dart';
import '../../models/profile.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  Profile? _profileA;
  Profile? _profileB;
  bool _loading = false;
  String? _error;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilesProvider>().loadProfiles();
    });
  }

  Future<void> _startAnalysis() async {
    if (_profileA == null || _profileB == null) return;
    if (_profileA!.id == _profileB!.id) {
      setState(() => _error = '서로 다른 프로필을 선택해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final session = await _api.createChatSession(
        _profileA!.id,
        compatibilityProfileId: _profileB!.id,
      );
      final sessionId = session['session']?['id'] as String? ?? session['id'] as String? ?? '';
      if (mounted) {
        context.push(
          '/profiles/${_profileA!.id}/consultation',
          extra: {'sessionId': sessionId, 'compatibilityProfileId': _profileB!.id},
        );
      }
    } catch (e) {
      setState(() => _error = '궁합 분석을 시작할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesProvider = context.watch<ProfilesProvider>();
    final profiles = profilesProvider.profiles;

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
        title: const Text(
          '궁합 분석',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: profilesProvider.loading
              ? const Center(child: CircularProgressIndicator(color: kGold))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header description — glass-styled with gold accent
                      GlassCard(
                        fillColor: kGold.withOpacity(0.08),
                        borderColor: kGold.withOpacity(0.3),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: kGold, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '두 프로필을 선택하여 사주 궁합을 분석합니다',
                                style: TextStyle(fontSize: 13, color: kTextMuted, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile A selector
                      const Text('첫 번째 프로필',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
                      const SizedBox(height: 10),
                      if (profiles.isEmpty)
                        const Text('프로필이 없습니다.',
                          style: TextStyle(color: kTextMuted))
                      else
                        ...profiles.map((p) => _profileTile(
                          p,
                          selected: _profileA?.id == p.id,
                          onTap: () => setState(() {
                            _profileA = _profileA?.id == p.id ? null : p;
                            _error = null;
                          }),
                        )),

                      const SizedBox(height: 24),

                      // Profile B selector
                      const Text('두 번째 프로필',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
                      const SizedBox(height: 10),
                      if (profiles.isEmpty)
                        const Text('프로필이 없습니다.',
                          style: TextStyle(color: kTextMuted))
                      else
                        ...profiles.map((p) => _profileTile(
                          p,
                          selected: _profileB?.id == p.id,
                          onTap: () => setState(() {
                            _profileB = _profileB?.id == p.id ? null : p;
                            _error = null;
                          }),
                        )),

                      const SizedBox(height: 24),

                      // Selected pair preview
                      if (_profileA != null && _profileB != null) ...[
                        _pairPreview(),
                        const SizedBox(height: 24),
                      ],

                      // Error
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kErrorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kErrorColor.withOpacity(0.3)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: kErrorColor, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Start button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_profileA != null && _profileB != null && !_loading)
                              ? _startAnalysis
                              : null,
                          icon: _loading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(color: kInk, strokeWidth: 2))
                              : const Icon(Icons.favorite, size: 18),
                          label: const Text('궁합 분석 시작',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGold,
                            foregroundColor: kInk,
                            disabledBackgroundColor: kGold.withOpacity(0.3),
                            disabledForegroundColor: kInk.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _profileTile(Profile profile, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? kGold.withOpacity(0.12) : const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? kGold.withOpacity(0.6) : kGlassBorder,
                  width: selected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: kGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: kGold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(profile.name,
                              style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600, color: kDark)),
                            if (profile.isOwner) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('나',
                                  style: TextStyle(fontSize: 10, color: kGold, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        Text(profile.displayBirthDate,
                          style: const TextStyle(fontSize: 12, color: kTextMuted)),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: kGold, size: 20)
                  else
                    Icon(Icons.circle_outlined, color: kGlassBorder, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pairPreview() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: kGold.withOpacity(0.3),
      child: Row(
        children: [
          Expanded(child: _miniProfileBadge(_profileA!)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Icon(Icons.favorite, color: kGold, size: 20),
                const SizedBox(height: 4),
                const Text('VS',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: kTextMuted, letterSpacing: 2)),
              ],
            ),
          ),
          Expanded(child: _miniProfileBadge(_profileB!)),
        ],
      ),
    );
  }

  Widget _miniProfileBadge(Profile profile) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: kGold.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: kGold.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              profile.name.isNotEmpty ? profile.name[0] : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kGold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(profile.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(profile.displayGender,
          style: const TextStyle(fontSize: 11, color: kTextMuted)),
      ],
    );
  }
}
