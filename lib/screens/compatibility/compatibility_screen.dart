import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/profiles_provider.dart';
import '../../models/profile.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

// 분석 기록 모델
class _AnalysisRecord {
  final String profileAName;
  final String profileBName;
  final String compatLabel;
  final int compatIndex;
  final String result;
  final DateTime createdAt;

  _AnalysisRecord({
    required this.profileAName,
    required this.profileBName,
    required this.compatLabel,
    required this.compatIndex,
    required this.result,
    required this.createdAt,
  });

  String get title => '${profileAName} & ${profileBName}';
  String get subtitle => '$compatLabel 궁합';
}

// 궁합 유형 정의
class _CompatType {
  final String label;
  final String prompt;
  final IconData icon;
  const _CompatType({required this.label, required this.prompt, required this.icon});
}

const _compatTypes = [
  _CompatType(label: '연애', prompt: '두 사람의 연애궁합을 사주를 기반으로 상세히 분석해주세요.', icon: Icons.favorite_outline),
  _CompatType(label: '결혼', prompt: '두 사람의 결혼궁합을 사주를 기반으로 상세히 분석해주세요.', icon: Icons.diamond_outlined),
  _CompatType(label: '사업', prompt: '두 사람의 사업궁합을 사주를 기반으로 상세히 분석해주세요.', icon: Icons.handshake_outlined),
  _CompatType(label: '우정', prompt: '두 사람의 우정궁합을 사주를 기반으로 상세히 분석해주세요.', icon: Icons.people_outline),
];

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  Profile? _profileA;
  Profile? _profileB;
  int _selectedTypeIndex = 0;
  bool _loading = false;
  String? _error;
  String? _result;
  int? _tokensRemaining;

  bool get _hasTokens => _tokensRemaining != null && _tokensRemaining! > 0;

  final List<_AnalysisRecord> _history = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _api = ApiService();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilesProvider>().loadProfiles();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _buildChartContext(Map<String, dynamic> profile) {
    final chart = (profile['chartData'] ?? profile['chart_data']) as Map<String, dynamic>?;
    final name = profile['name'] as String? ?? '';
    final by = (profile['birthYear'] as num?)?.toInt();
    final bm = (profile['birthMonth'] as num?)?.toInt();
    final bd = (profile['birthDay'] as num?)?.toInt();
    final bh = (profile['birthHour'] as num?)?.toInt();
    final gender = profile['gender'] as String? ?? '';

    if (chart == null) {
      return '### $name\n- 생년월일: $by/$bm/$bd\n- 성별: $gender\n';
    }

    final lines = <String>[
      '### $name 사주 데이터',
      '- 생년월일: $by/$bm/$bd${bh != null ? " ${bh}시" : ""}',
      '- 성별: ${gender == "male" ? "남성" : "여성"}',
      '',
      '#### 명식',
    ];

    String pillarText(Map<String, dynamic>? p) {
      if (p == null) return '';
      return '${p['fullChar'] ?? ''} (${p['fullHanja'] ?? ''})';
    }

    final yearP = chart['yearPillar'] as Map<String, dynamic>?;
    final monthP = chart['monthPillar'] as Map<String, dynamic>?;
    final dayP = chart['dayPillar'] as Map<String, dynamic>?;
    final hourP = chart['hourPillar'] as Map<String, dynamic>?;

    if (yearP != null) lines.add('- 연주: ${pillarText(yearP)}');
    if (monthP != null) lines.add('- 월주: ${pillarText(monthP)}');
    if (dayP != null) lines.add('- 일주: ${pillarText(dayP)}');
    if (hourP != null) lines.add('- 시주: ${pillarText(hourP)}');

    final five = chart['fiveElements'] as Map<String, dynamic>?;
    if (five != null) {
      lines.addAll([
        '',
        '#### 오행',
        '- 목:${five["목"]}, 화:${five["화"]}, 토:${five["토"]}, 금:${five["금"]}, 수:${five["수"]}',
      ]);
    }

    return lines.join('\n');
  }

  Future<void> _startAnalysis() async {
    if (_profileA == null || _profileB == null) return;
    if (_profileA!.id == _profileB!.id) {
      setState(() => _error = '서로 다른 프로필을 선택해주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      // 두 프로필 병렬 로드
      final profileResults = await Future.wait([
        _api.getProfile(_profileA!.id),
        _api.getProfile(_profileB!.id),
      ]);
      final profileAFull = profileResults[0];
      final profileBFull = profileResults[1];

      // 구독 정보 (실패해도 계속 진행)
      try {
        final sub = await _api.getSubscription();
        if (mounted) {
          setState(() {
            _tokensRemaining = (sub['remaining'] as num?)?.toInt();
          });
        }
      } catch (_) {}

      final chartContext =
          '## ${_profileA!.name} 사주\n${_buildChartContext(profileAFull)}\n\n'
          '## ${_profileB!.name} 사주\n${_buildChartContext(profileBFull)}';

      // 채팅 세션 생성
      final session = await _api.createChatSession(
        _profileA!.id,
        compatibilityProfileId: _profileB!.id,
      );
      final sessionId =
          session['session']?['id'] as String? ?? session['id'] as String? ?? '';

      final compatType = _compatTypes[_selectedTypeIndex];

      // 메시지 전송 (스트리밍 응답 수집)
      final response = await _api.sendMessage(
        sessionId,
        compatType.prompt,
        chartContext: chartContext,
        interpretation: '',
        history: [],
      );

      if (mounted) {
        setState(() {
          _result = response;
          _history.insert(0, _AnalysisRecord(
            profileAName: _profileA!.name,
            profileBName: _profileB!.name,
            compatLabel: compatType.label,
            compatIndex: _selectedTypeIndex,
            result: response,
            createdAt: DateTime.now(),
          ));
        });
        // 분석 결과로 스크롤
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = '궁합 분석을 시작할 수 없습니다.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfileModal(bool isA) {
    final profiles = context.read<ProfilesProvider>().profiles;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfilePickerModal(
        profiles: profiles,
        selectedId: isA ? _profileA?.id : _profileB?.id,
        excludeId: isA ? _profileB?.id : _profileA?.id,
        onSelected: (p) {
          setState(() {
            if (isA) {
              _profileA = p;
            } else {
              _profileB = p;
            }
            _error = null;
            _result = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilesProvider = context.watch<ProfilesProvider>();
    final compatType = _compatTypes[_selectedTypeIndex];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      endDrawer: _HistoryDrawer(
        history: _history,
        onSelect: (record) {
          setState(() {
            _result = record.result;
            _selectedTypeIndex = record.compatIndex;
          });
          _scaffoldKey.currentState?.closeEndDrawer();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.animateTo(
                _scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            }
          });
        },
      ),
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
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.history, color: kDark),
                if (_history.isNotEmpty)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: kGold, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: CosmicBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: profilesProvider.loading
                ? const Center(child: CircularProgressIndicator(color: kGold))
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 프로필 선택 박스 2개 ──────────────────────
                        Row(
                          children: [
                            Expanded(child: _ProfileBox(
                              profile: _profileA,
                              label: '첫 번째',
                              onTap: () => _openProfileModal(true),
                            )),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('&',
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700,
                                  color: kGold)),
                            ),
                            Expanded(child: _ProfileBox(
                              profile: _profileB,
                              label: '두 번째',
                              onTap: () => _openProfileModal(false),
                            )),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── 궁합 유형 선택 ────────────────────────────
                        const Text('궁합 유형',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: kTextMuted, letterSpacing: 0.3)),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(_compatTypes.length, (i) {
                            final selected = i == _selectedTypeIndex;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: i < _compatTypes.length - 1 ? 8 : 0),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedTypeIndex = i;
                                    _result = null;
                                    _error = null;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? kGold.withOpacity(0.15)
                                          : const Color(0x0AFFFFFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected ? kGold.withOpacity(0.6) : kGlassBorder,
                                        width: selected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(_compatTypes[i].icon,
                                          size: 20,
                                          color: selected ? kGold : kTextMuted),
                                        const SizedBox(height: 4),
                                        Text(_compatTypes[i].label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                            color: selected ? kGold : kTextMuted,
                                          )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 28),

                        // ── 에러 ──────────────────────────────────────
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kErrorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kErrorColor.withOpacity(0.3)),
                            ),
                            child: Text(_error!,
                              style: const TextStyle(color: kErrorColor, fontSize: 13)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── 분석 시작 버튼 ─────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_profileA != null && _profileB != null && !_loading)
                                ? _startAnalysis
                                : null,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(color: kInk, strokeWidth: 2))
                                : Icon(compatType.icon, size: 18),
                            label: Text(
                              _loading ? '분석 중...' : '${compatType.label}궁합 분석 시작',
                              style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: kInk,
                              disabledBackgroundColor: kGold.withOpacity(0.3),
                              disabledForegroundColor: kInk.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        // ── 분석 결과 ─────────────────────────────────
                        if (_result != null) ...[
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1228),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kGold.withOpacity(0.25), width: 0.5),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: kGold, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_profileA!.name}님과 ${_profileB!.name}님의 '
                                        '${compatType.label} 궁합 분석',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: kGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Color(0x33FFFFFF), height: 1),
                                const SizedBox(height: 16),
                                _BlurredResult(content: _result!),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _markdownBody(String data) {
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: kDark, height: 1.7),
        h1: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kGold),
        h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kGold),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: kDark),
        listBullet: const TextStyle(fontSize: 14, color: kTextMuted),
      ),
    );
  }
}

// ── 블러 페이드아웃 결과 위젯 ────────────────────────────────────
class _BlurredResult extends StatelessWidget {
  final String content;
  // 4줄 분량: 줄높이 1.7 × 14px × 4줄 + 여유 = 약 110px
  static const double _previewHeight = 110.0;

  const _BlurredResult({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 미리보기 (4줄) + 그라데이션 오버레이
        Stack(
          children: [
            ClipRect(
              child: SizedBox(
                height: _previewHeight,
                width: double.infinity,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: double.infinity,
                  child: MarkdownBody(
                    data: content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, color: kDark, height: 1.7),
                      h1: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kGold),
                      h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kGold),
                      h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
                      strong: const TextStyle(fontWeight: FontWeight.w700, color: kDark),
                      listBullet: const TextStyle(fontSize: 14, color: kTextMuted),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      const Color(0x000E1228),
                      const Color(0xCC0E1228),
                      const Color(0xFF0E1228),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 12,
              left: 0, right: 0,
              child: Icon(Icons.lock, color: kGold, size: 36),
            ),
          ],
        ),
        // CTA 영역 — 잠금 버튼
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0E1228),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 토큰 구매 페이지로 이동
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    '토큰 추가하고 분석 전체 보기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: kInk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 일주 헬퍼 ────────────────────────────────────────────────────
const _branchEmojiMap = {
  '자': '🐭', '축': '🐮', '인': '🐯', '묘': '🐰',
  '진': '🐲', '사': '🐍', '오': '🐴', '미': '🐑',
  '신': '🐵', '유': '🐔', '술': '🐶', '해': '🐷',
};

String _zodiacEmoji(Profile profile) {
  try {
    final chart = profile.chartData;
    if (chart != null) {
      final branch = (chart['dayPillar']?['branch'] as Map<String, dynamic>?)?['char'] as String?;
      if (branch != null) return _branchEmojiMap[branch] ?? '🐾';
    }
  } catch (_) {}
  return '🐾';
}

Color _dayPillarColor(Profile profile) {
  try {
    final stem = (profile.chartData?['dayPillar']?['stem'] as Map<String, dynamic>?)?['char'] as String?;
    switch (stem) {
      case '갑': case '을': return kWoodColor;
      case '병': case '정': return kFireColor;
      case '무': case '기': return kEarthColor;
      case '경': case '신': return kMetalColor;
      case '임': case '계': return kWaterColor;
    }
  } catch (_) {}
  return kGold;
}

// ── 프로필 선택 박스 ──────────────────────────────────────────────
class _ProfileBox extends StatelessWidget {
  final Profile? profile;
  final String label;
  final VoidCallback onTap;

  const _ProfileBox({
    required this.profile,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfile = profile != null;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 130,
            decoration: BoxDecoration(
              color: hasProfile
                  ? kGold.withOpacity(0.10)
                  : const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasProfile ? kGold.withOpacity(0.5) : kGlassBorder,
                width: hasProfile ? 1.5 : 1.0,
              ),
            ),
            child: hasProfile
                ? _SelectedProfile(profile: profile!)
                : _EmptySlot(label: label),
          ),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String label;
  const _EmptySlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: kGlassBorder.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: kGlassBorder, width: 1.5),
          ),
          child: const Icon(Icons.add, color: kTextMuted, size: 22),
        ),
        const SizedBox(height: 10),
        Text(label,
          style: const TextStyle(
            fontSize: 12, color: kTextMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        const Text('프로필 선택',
          style: TextStyle(fontSize: 11, color: kTextMuted)),
      ],
    );
  }
}

class _SelectedProfile extends StatelessWidget {
  final Profile profile;
  const _SelectedProfile({required this.profile});

  @override
  Widget build(BuildContext context) {
    final color = _dayPillarColor(profile);
    final emoji = _zodiacEmoji(profile);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.6), width: 1.5),
              ),
              child: Center(
                child: Text(emoji,
                  style: const TextStyle(fontSize: 22)),
              ),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: kGold, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 10, color: kInk),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(profile.name,
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: kDark),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(profile.displayBirthDate,
          style: const TextStyle(fontSize: 10, color: kTextMuted),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('탭하여 변경',
          style: TextStyle(fontSize: 10, color: kTextMuted.withOpacity(0.6))),
      ],
    );
  }
}

// ── 프로필 선택 모달 ─────────────────────────────────────────────
class _ProfilePickerModal extends StatelessWidget {
  final List<Profile> profiles;
  final String? selectedId;
  final String? excludeId;
  final ValueChanged<Profile> onSelected;

  const _ProfilePickerModal({
    required this.profiles,
    required this.selectedId,
    required this.excludeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final available = profiles.where((p) => p.id != excludeId).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: kGlassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('프로필 선택',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
              const SizedBox(height: 16),
              if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: const [
                      Icon(Icons.person_off_outlined, color: kTextMuted, size: 36),
                      SizedBox(height: 12),
                      Text('선택 가능한 프로필이 없습니다.',
                        style: TextStyle(color: kTextMuted, fontSize: 14)),
                    ],
                  ),
                )
              else
                ...available.map((p) => _ProfilePickerTile(
                  profile: p,
                  selected: p.id == selectedId,
                  onTap: () {
                    onSelected(p);
                    Navigator.of(context).pop();
                  },
                )),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePickerTile extends StatelessWidget {
  final Profile profile;
  final bool selected;
  final VoidCallback onTap;

  const _ProfilePickerTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                color: _dayPillarColor(profile).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _dayPillarColor(profile).withOpacity(0.4)),
              ),
              child: Center(
                child: Text(_zodiacEmoji(profile),
                  style: const TextStyle(fontSize: 18)),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('나',
                            style: TextStyle(
                              fontSize: 10, color: kGold,
                              fontWeight: FontWeight.w700)),
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
              const Icon(Icons.circle_outlined, color: kGlassBorder, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 분석 기록 사이드바 ─────────────────────────────────────────────
class _HistoryDrawer extends StatelessWidget {
  final List<_AnalysisRecord> history;
  final ValueChanged<_AnalysisRecord> onSelect;

  const _HistoryDrawer({required this.history, required this.onSelect});

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.78,
          decoration: const BoxDecoration(
            color: Color(0xF0060611),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            border: Border(
              left: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: kGold, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('분석 기록',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: kTextMuted, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0x33FFFFFF), height: 1),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border, color: kTextMuted, size: 36),
                          SizedBox(height: 12),
                          Text('분석 기록이 없어요',
                            style: TextStyle(color: kTextMuted, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('궁합을 분석하면 여기에 저장돼요',
                            style: TextStyle(color: kTextMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: history.length,
                      itemBuilder: (_, i) {
                        final rec = history[i];
                        return GestureDetector(
                          onTap: () => onSelect(rec),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x0AFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x1AFFFFFF), width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: kGold.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kGold.withOpacity(0.3)),
                                  ),
                                  child: const Icon(
                                    Icons.favorite, color: kGold, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rec.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kDark),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(rec.subtitle,
                                        style: const TextStyle(
                                          fontSize: 11, color: kTextMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_timeLabel(rec.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10, color: kTextMuted)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
