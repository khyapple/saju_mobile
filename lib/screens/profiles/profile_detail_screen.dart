import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/saju_chart_widget.dart';
import '../../widgets/five_elements_widget.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/dancheong_bar.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String profileId;

  const ProfileDetailScreen({super.key, required this.profileId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _generating = false; // interpretation in progress

  final ApiService _api = ApiService();

  // Expanded state for interpretation sections
  final Set<int> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getProfile(widget.profileId);
      setState(() => _profile = data);
    } catch (e) {
      setState(() => _error = '프로필을 불러올 수 없습니다.');
    } finally {
      setState(() => _loading = false);
    }
  }

  static const _branchEmojiMap = {
    '자': '🐭', '축': '🐮', '인': '🐯', '묘': '🐰',
    '진': '🐲', '사': '🐍', '오': '🐴', '미': '🐑',
    '신': '🐵', '유': '🐔', '술': '🐶', '해': '🐷',
  };

  static String _zodiacEmoji(Map<String, dynamic>? chartData) {
    // 일주(日柱)의 지지(地支) 글자로 동물 결정
    if (chartData != null) {
      final dayPillar = chartData['dayPillar'] as Map<String, dynamic>?;
      final branch = (dayPillar?['branch'] as Map<String, dynamic>?)?['char'] as String?;
      if (branch != null) return _branchEmojiMap[branch] ?? '🐾';
    }
    return '🐾';
  }

  bool _hasAnyInterpretation(Map<String, dynamic> data) {
    final sections = data['interpretationSections'];
    if (sections is List && sections.isNotEmpty) return true;
    final interp = data['interpretation'];
    if (interp is Map) {
      final content = interp['content'] as String?;
      if (content != null && content.isNotEmpty) return true;
    }
    if (interp is String && interp.isNotEmpty) return true;
    return false;
  }

  Future<void> _generateInterpretation() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      // Await SSE stream — server saves interpretation to DB when done
      await _api.triggerInterpretation(widget.profileId);
      // Refresh profile to show new interpretation
      if (mounted) await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해석 생성에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(
        profile: _profile!,
        profileId: widget.profileId,
        onSaved: _loadProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                border: Border(
                  bottom: BorderSide(color: kGlassBorder, width: 0.5),
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _profile?['name'] as String? ?? '프로필',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kDark),
              tooltip: '프로필 수정',
              onPressed: _showEditSheet,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: kGold,
                unselectedLabelColor: kTextMuted,
                indicatorColor: kDancheongRed,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: const [
                  Tab(text: '사주'),
                  Tab(text: '해석'),
                  Tab(text: '이벤트'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: CosmicBackground(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _error != null
              ? _errorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _chartTab(),
                    _interpretationTab(),
                    _eventsTab(),
                  ],
                ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFDD835), kGold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withOpacity(0.22),
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.push('/profiles/${widget.profileId}/consultation'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: kInk, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'AI 사주상담',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _errorView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: kTextMuted, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: kTextMuted)),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loadProfile,
          child: const Text('다시 시도', style: TextStyle(color: kGold)),
        ),
      ],
    ),
  );

  Widget _chartTab() {
    final chart = _profile?['chart_data'] as Map<String, dynamic>?;
    if (chart == null) {
      return const Center(
        child: Text('차트 데이터가 없습니다.', style: TextStyle(color: kTextMuted)),
      );
    }
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Extra top padding for app bar
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 52),
          _infoCard(),
          const SizedBox(height: 16),
          SajuChartWidget(chartData: chart),
          const SizedBox(height: 16),
          _elementsDescription(chart),
          const SizedBox(height: 16),
          _luckTimeline(chart),
          const SizedBox(height: 100),
        ],
      ),
    ), // SingleChildScrollView
  ); // ScrollConfiguration
  }

  // 태어난 해의 한국식 이름 계산 (e.g. "갑술년 · 흰개띠")
  // 일주 천간 → 오행 색
  static Color _dayPillarColor(Map<String, dynamic>? chartData) {
    final day = chartData?['dayPillar'] as Map<String, dynamic>?;
    final stem = (day?['stem'] as Map<String, dynamic>?)?['char'] as String?;
    switch (stem) {
      case '갑': case '을': return kWoodColor;
      case '병': case '정': return kFireColor;
      case '무': case '기': return kEarthColor;
      case '경': case '신': return kMetalColor;
      case '임': case '계': return kWaterColor;
      default: return kDancheongRed;
    }
  }

  // 일주(日柱) 천간+지지 → "갑술일주 · 푸른 개" 형식
  static String? _dayPillarLabel(Map<String, dynamic>? chartData) {
    if (chartData == null) return null;
    final day = chartData['dayPillar'] as Map<String, dynamic>?;
    if (day == null) return null;
    final stemChar   = (day['stem']   as Map<String, dynamic>?)?['char'] as String?;
    final branchChar = (day['branch'] as Map<String, dynamic>?)?['char'] as String?;
    if (stemChar == null || branchChar == null) return null;
    const colorMap = {
      '갑': '푸른', '을': '푸른',
      '병': '붉은', '정': '붉은',
      '무': '노란', '기': '노란',
      '경': '흰',   '신': '흰',
      '임': '검은', '계': '검은',
    };
    const animalMap = {
      '자': '쥐', '축': '소', '인': '호랑이', '묘': '토끼',
      '진': '용', '사': '뱀', '오': '말',     '미': '양',
      '신': '원숭이', '유': '닭', '술': '개', '해': '돼지',
    };
    final color  = colorMap[stemChar] ?? '';
    final animal = animalMap[branchChar];
    if (animal == null) return null;
    return '$stemChar${branchChar}일주 · $color $animal';
  }

  // birthHour 문자열 → 시진 표시 (e.g. "자시 (23:00~01:00)")
  static String? _hourDisplay(String? birthHour, String? precision) {
    if (precision == 'unknown' || birthHour == null) return null;
    const hours = [
      ('자시', '23:00~01:00', '23'),
      ('축시', '01:00~03:00', '01'),
      ('인시', '03:00~05:00', '03'),
      ('묘시', '05:00~07:00', '05'),
      ('진시', '07:00~09:00', '07'),
      ('사시', '09:00~11:00', '09'),
      ('오시', '11:00~13:00', '11'),
      ('미시', '13:00~15:00', '13'),
      ('신시', '15:00~17:00', '15'),
      ('유시', '17:00~19:00', '17'),
      ('술시', '19:00~21:00', '19'),
      ('해시', '21:00~23:00', '21'),
    ];
    final padded = birthHour.padLeft(2, '0');
    for (final h in hours) {
      if (h.$3 == padded) return '${h.$2} (${h.$1})';
    }
    return null;
  }

  Widget _infoCard() {
    final p = _profile ?? const <String, dynamic>{};
    final name = (p['name'] as String?) ?? '';
    // birth_date 우선, 없으면 birthYear/Month/Day로 조립 (num→int 안전 캐스트)
    String birthDate = (p['birth_date'] as String?) ?? '';
    if (birthDate.isEmpty) {
      final by = (p['birthYear'] as num?)?.toInt();
      final bm = (p['birthMonth'] as num?)?.toInt();
      final bd = (p['birthDay'] as num?)?.toInt();
      if (by != null && bm != null && bd != null) {
        birthDate = '$by-${bm.toString().padLeft(2, '0')}-${bd.toString().padLeft(2, '0')}';
      }
    }
    final gender = p['gender'] as String?;
    final calendarType =
        (p['calendar_type'] as String?) ?? (p['calendarType'] as String?);
    final relationship = p['relationship'] as String?;
    final birthHour = (p['birthHour'] ?? p['birth_hour'])?.toString();
    final birthHourPrecision = (p['birthTimeType'] ?? p['birth_time_type'] ?? p['birth_hour_precision']) as String?;
    final chartData = (p['chartData'] ?? p['chart_data']) as Map<String, dynamic>?;
    final pillarColor = _dayPillarColor(chartData);
    final dayPillarLabel = _dayPillarLabel(chartData);
    final hourDisplay = _hourDisplay(birthHour, birthHourPrecision);
    debugPrint('=== _infoCard: name=$name, birthDate=$birthDate, gender=$gender, calendarType=$calendarType');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: kGlassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kGlassBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 좌측 액센트 strip (일주 오행 색)
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: pillarColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              pillarColor.withOpacity(0.20),
                              pillarColor.withOpacity(0.06),
                            ]),
                            border: Border.all(color: pillarColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            _zodiacEmoji(chartData),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 이름 + 관계 뱃지
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                                  if (relationship != null && relationship.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: kSecondaryGold.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: kSecondaryGold.withOpacity(0.4), width: 0.5),
                                      ),
                                      child: Text(
                                        relationship,
                                        style: const TextStyle(fontSize: 11, color: kSecondaryGold, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              // 양력/음력 · 생년월일 · 성별
                              Text(
                                [
                                  if (calendarType != null) calendarType == 'solar' ? '양력' : '음력',
                                  if (birthDate.isNotEmpty) _formatDate(birthDate),
                                  if (gender != null) gender == 'male' ? '남성' : '여성',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 12, color: kTextMuted),
                              ),
                              if (hourDisplay != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 12, color: kTextMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      hourDisplay,
                                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                                    ),
                                  ],
                                ),
                              ],
                              if (dayPillarLabel != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  dayPillarLabel,
                                  style: const TextStyle(fontSize: 12, color: kTextMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // ClipRRect
    ); // _infoCard return
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[0]}년 ${parts[1]}월 ${parts[2]}일';
  }

  // 십성(十星) 계산
  static String _tenGod(String dayMaster, String target) {
    const el = {
      '갑': 'wood', '을': 'wood', '병': 'fire', '정': 'fire',
      '무': 'earth', '기': 'earth', '경': 'metal', '신': 'metal',
      '임': 'water', '계': 'water',
    };
    const yang = {'갑', '병', '무', '경', '임'};
    const gen = {'wood':'fire','fire':'earth','earth':'metal','metal':'water','water':'wood'};
    const ctrl = {'wood':'earth','earth':'water','water':'fire','fire':'metal','metal':'wood'};

    final dmEl = el[dayMaster]; final tEl = el[target];
    if (dmEl == null || tEl == null) return '';
    final same = yang.contains(dayMaster) == yang.contains(target);

    if (dmEl == tEl)         return same ? '비견' : '겁재';
    if (gen[dmEl] == tEl)    return same ? '식신' : '상관';
    if (ctrl[dmEl] == tEl)   return same ? '편재' : '정재';
    if (ctrl[tEl] == dmEl)   return same ? '편관' : '정관';
    if (gen[tEl] == dmEl)    return same ? '편인' : '정인';
    return '';
  }

  // 천간/지지 → 오행 색
  static Color _elementColorOf(String char) {
    const stemEl = {
      '갑':'wood','을':'wood','병':'fire','정':'fire',
      '무':'earth','기':'earth','경':'metal','신':'metal','임':'water','계':'water',
    };
    const branchEl = {
      '자':'water','축':'earth','인':'wood','묘':'wood','진':'earth','사':'fire',
      '오':'fire','미':'earth','신':'metal','유':'metal','술':'earth','해':'water',
    };
    switch (stemEl[char] ?? branchEl[char]) {
      case 'wood':  return kWoodColor;
      case 'fire':  return kFireColor;
      case 'earth': return kEarthColor;
      case 'metal': return kMetalColor;
      case 'water': return kWaterColor;
      default:      return kGlassBorder;
    }
  }

  // 지지 → 본기(本氣) 천간 (십성 계산용)
  static const _branchMainStem = {
    '자':'계', '축':'기', '인':'갑', '묘':'을',
    '진':'무', '사':'병', '오':'정', '미':'기',
    '신':'경', '유':'신', '술':'무', '해':'임',
  };

  Widget _luckTimeline(Map<String, dynamic> chart) {
    final luck = chart['majorLuck'] as List<dynamic>?;
    if (luck == null || luck.isEmpty) return const SizedBox.shrink();

    // 일간(日干) 추출
    final dayMaster = (chart['dayPillar']?['stem'] as Map<String, dynamic>?)?['char'] as String? ?? '';

    final birthYear = _profile?['birthYear'] as int?;
    final currentAge = birthYear != null ? DateTime.now().year - birthYear : null;

    // Find current period index
    int currentIndex = -1;
    if (currentAge != null) {
      for (int i = luck.length - 1; i >= 0; i--) {
        final period = luck[i] as Map<String, dynamic>;
        final startAge = period['startAge'] as int? ?? 0;
        if (currentAge >= startAge) {
          currentIndex = i;
          break;
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kGlassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('대운',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: luck.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final period = luck[i] as Map<String, dynamic>;
                    final age = period['startAge'] as int? ?? 0;
                    final stemInfo = period['stem'] as Map<String, dynamic>?;
                    final branchInfo = period['branch'] as Map<String, dynamic>?;
                    final stem = stemInfo?['char'] as String? ?? '';
                    final branch = branchInfo?['char'] as String? ?? '';
                    final isCurrent = i == currentIndex;

                    final stemGod    = dayMaster.isNotEmpty && stem.isNotEmpty ? _tenGod(dayMaster, stem) : '';
                    final branchMain = _branchMainStem[branch] ?? '';
                    final branchGod  = dayMaster.isNotEmpty && branchMain.isNotEmpty ? _tenGod(dayMaster, branchMain) : '';
                    final stemColor   = _elementColorOf(stem);
                    final branchColor = _elementColorOf(branch);
                    final isWaterStem   = stemColor == kWaterColor;
                    final isWaterBranch = branchColor == kWaterColor;

                    Widget charCard(String char, Color color, bool isWater) => Container(
                      width: 40,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent ? kGold.withOpacity(0.45) : Colors.white.withOpacity(0.12),
                        ),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 3))],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(isWater ? 0.55 : 0.40),
                            color.withOpacity(isWater ? 0.40 : 0.22),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(char, style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
                        )),
                      ),
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            // 나이
                            Text('$age세', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: isCurrent ? kGold : Colors.white54,
                            )),
                            const SizedBox(height: 5),
                            // 천간 십성
                            if (stemGod.isNotEmpty)
                              Text(stemGod, style: const TextStyle(fontSize: 9, color: Colors.white54)),
                            const SizedBox(height: 2),
                            // 천간 카드
                            charCard(stem, stemColor, isWaterStem),
                            const SizedBox(height: 4),
                            // 지지 카드
                            charCard(branch, branchColor, isWaterBranch),
                            const SizedBox(height: 2),
                            // 지지 십성
                            if (branchGod.isNotEmpty)
                              Text(branchGod, style: const TextStyle(fontSize: 9, color: Colors.white54)),
                          ],
                        ),
                        if (isCurrent)
                          Positioned(
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kDancheongRed,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(color: kDancheongRed.withOpacity(0.4), blurRadius: 6)],
                              ),
                              child: const Text('현재',
                                style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    );

                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEventSheet(
        profileId: widget.profileId,
        onAdded: _loadProfile,
      ),
    );
  }

  void _showEditEventSheet(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEventSheet(
        profileId: widget.profileId,
        onAdded: _loadProfile,
        existingEvent: event,
      ),
    );
  }

  // ─── 이벤트 상세 보기 ─────────────────────────────────────
  Color _impactColor(String impact) {
    switch (impact) {
      case 'very_positive': return const Color(0xFF4CAF50);
      case 'positive': return const Color(0xFF81C784);
      case 'negative': return const Color(0xFFE57373);
      case 'very_negative': return kErrorColor;
      default: return kTextMuted;
    }
  }

  String _impactLabel(String impact) {
    switch (impact) {
      case 'very_positive': return '매우 긍정';
      case 'positive': return '긍정';
      case 'negative': return '부정';
      case 'very_negative': return '매우 부정';
      default: return '중립';
    }
  }

  void _showEventDetailSheet(Map<String, dynamic> event) {
    final year = (event['eventYear'] as num?)?.toInt();
    final month = (event['eventMonth'] as num?)?.toInt();
    final desc = event['description'] as String? ?? '';
    final impact = event['impact'] as String? ?? '';
    final category = event['category'] as String?;
    final eventId = event['id'] as String?;
    final createdAt = event['createdAt'] as String?;
    final impactColor = _impactColor(impact);
    final impactLabel = _impactLabel(impact);
    final dateText = month != null ? '$year년 $month월' : '$year년';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: kDark.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('이벤트 상세',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 날짜
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGlassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: kGold, size: 14),
                  const SizedBox(width: 8),
                  Text(dateText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 내용
            const Text('내용',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMuted)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGlassBorder),
              ),
              child: Text(desc,
                style: const TextStyle(fontSize: 14, color: kDark, height: 1.6)),
            ),
            const SizedBox(height: 16),
            // 영향도
            const Text('영향도',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMuted)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: impactColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: impactColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, color: impactColor, size: 14),
                  const SizedBox(width: 8),
                  Text(impactLabel,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: impactColor)),
                ],
              ),
            ),
            if (category != null && category.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('카테고리',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMuted)),
              const SizedBox(height: 6),
              Text(category,
                style: const TextStyle(fontSize: 14, color: kDark)),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 16),
              Text('등록일: ${_formatCreatedAt(createdAt)}',
                style: TextStyle(fontSize: 11, color: kDark.withOpacity(0.4))),
            ],
            const SizedBox(height: 24),
            // 수정/삭제 버튼
            if (eventId != null && eventId.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditEventSheet(event);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18, color: kInk),
                      label: const Text('수정',
                        style: TextStyle(color: kInk, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _confirmDeleteEvent(eventId);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18, color: kErrorColor),
                      label: const Text('삭제',
                        style: TextStyle(color: kErrorColor, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kErrorColor.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatCreatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _confirmDeleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('이벤트 삭제', style: TextStyle(color: kDark)),
        content: const Text('이 이벤트를 삭제하시겠습니까?',
          style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: kErrorColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteEvent(widget.profileId, eventId);
      await _loadProfile();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이벤트 삭제에 실패했습니다.')),
        );
      }
    }
  }

  Widget _eventsTab() {
    final events = _profile?['events'] as List<dynamic>? ?? [];
    debugPrint('=== _eventsTab: events count=${events.length}, raw=${events.isNotEmpty ? events.first : "empty"}');

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_note_outlined, color: kTextMuted, size: 40),
              const SizedBox(height: 16),
              const Text(
                '생활 이벤트를 기록해보세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark),
              ),
              const SizedBox(height: 8),
              const Text(
                '중요한 사건을 기록하면\nAI 해석의 정확도가 높아집니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kTextMuted),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: '이벤트 추가',
                onPressed: _showAddEventSheet,
                width: 200,
              ),
            ],
          ),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 52;
    const addBarHeight = 56.0;
    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.fromLTRB(20, topPadding + addBarHeight + 56, 20, 100),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final event = events[i] as Map<String, dynamic>;
            final year = (event['eventYear'] as num?)?.toInt();
            final month = (event['eventMonth'] as num?)?.toInt();
            final desc = event['description'] as String? ?? '';
            final impact = event['impact'] as String? ?? '';
            final category = event['category'] as String?;
            final impactColor = _impactColor(impact);

            final title = event['title'] as String? ?? '';
            return GestureDetector(
              onTap: () => _showEventDetailSheet(event),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kGlassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGlassBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 날짜 뱃지 (흰색 반투명)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x30FFFFFF)),
                          ),
                          child: Text(
                            month != null ? '$year.$month' : '$year',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 영향도 뱃지 (색 구분)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: impactColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _impactLabel(impact),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: impactColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 제목
                        Expanded(
                          child: Text(
                            title.isNotEmpty ? title : desc,
                            style: const TextStyle(fontSize: 14, color: kDark, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: kDark.withOpacity(0.3), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // 상단 고정 "이벤트 추가" 버튼
        Positioned(
          top: topPadding + 20,
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: _showAddEventSheet,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kGold.withOpacity(0.25),
                        kGold.withOpacity(0.10),
                        kDancheongRed.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(color: kGold.withOpacity(0.5), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kGold.withOpacity(0.15),
                          border: Border.all(color: kGold.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.add, color: kGold, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '중요한 사건을 기록해보세요',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kGold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            '사주 풀이가 더 정확해 집니다',
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: kGold.withOpacity(0.5), size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _elementsDescription(Map<String, dynamic> chart) {
    // 기둥 데이터에서 직접 오행 수량 계산
    const stemElementMap = {
      '갑': 'wood', '을': 'wood',
      '병': 'fire', '정': 'fire',
      '무': 'earth', '기': 'earth',
      '경': 'metal', '신': 'metal',
      '임': 'water', '계': 'water',
    };
    const branchElementMap = {
      '자': 'water', '축': 'earth',
      '인': 'wood', '묘': 'wood',
      '진': 'earth', '사': 'fire',
      '오': 'fire', '미': 'earth',
      '신': 'metal', '유': 'metal',
      '술': 'earth', '해': 'water',
    };

    final counts = <String, int>{'wood': 0, 'fire': 0, 'earth': 0, 'metal': 0, 'water': 0};
    for (final key in ['yearPillar', 'monthPillar', 'dayPillar', 'hourPillar']) {
      final pillar = chart[key] as Map<String, dynamic>?;
      if (pillar == null) continue;
      final stemChar = (pillar['stem'] as Map?)?['char'] as String?;
      final branchChar = (pillar['branch'] as Map?)?['char'] as String?;
      if (stemChar != null && stemElementMap.containsKey(stemChar)) {
        final el = stemElementMap[stemChar]!;
        counts[el] = (counts[el] ?? 0) + 1;
      }
      if (branchChar != null && branchElementMap.containsKey(branchChar)) {
        final el = branchElementMap[branchChar]!;
        counts[el] = (counts[el] ?? 0) + 1;
      }
    }

    final elements = [
      ('木', 'wood', kWoodColor,  ['성장', '창의', '인자']),
      ('火', 'fire', kFireColor,  ['열정', '예의', '지혜']),
      ('土', 'earth', kEarthColor, ['신용', '안정', '포용']),
      ('金', 'metal', kMetalColor, ['의리', '결단', '정의']),
      ('水', 'water', kWaterColor, ['지혜', '유연', '지모']),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kGlassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kGlassBorder),
          ),
          child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('오행 분포',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        ...elements.map((e) {
          final count = counts[e.$2] ?? 0;
          final isWater = e.$2 == 'water';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: kWaterColor.withOpacity(0.45),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.07),
                                  Colors.white.withOpacity(0.02),
                                  kWaterColor.withOpacity(0.15),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0.0, 0.38, 0.42, 1.0],
                                colors: [
                                  Colors.white.withOpacity(0.06),
                                  Colors.white.withOpacity(0.02),
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 한자 색 박스
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: e.$3.withOpacity(isWater ? 0.55 : 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isWater ? Colors.grey.withOpacity(0.5) : e.$3.withOpacity(0.3), width: 0.5),
                                ),
                                child: Center(
                                  child: Text(
                                    e.$1,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 뱃지
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: e.$4.map((kw) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      kw,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 수량 맨 오른쪽
                              Text(
                                '$count개',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
          ),
        ),
      ),
    );
  }

  Widget _interpretationTab() {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    // Check for interpretation sections
    final rawSections = profile['interpretationSections'];
    final sections = rawSections is List ? rawSections : null;

    // Check for raw interpretation text
    final interpretation = profile['interpretation'];
    final rawText = interpretation is Map
        ? interpretation['content'] as String?
        : interpretation as String?;

    final hasInterpretation = (sections != null && sections.isNotEmpty) ||
        (rawText != null && rawText.isNotEmpty);

    // Show generating banner if no interpretation yet
    if (!hasInterpretation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _generating
              ? _generatingBanner()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: kDancheongRed, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'AI 해석을 생성해보세요',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Claude AI가 당신의 사주를 상세히 분석합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kTextMuted),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: '해석 생성',
                      onPressed: _generateInterpretation,
                      loading: _generating,
                      width: 200,
                    ),
                  ],
                ),
        ),
      );
    }

    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 52;
    // Show section-based display if sections available
    if (sections != null && sections.isNotEmpty) {
      return Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < sections.length; i++)
                  _sectionCard(i, sections[i] as Map<String, dynamic>),
              ],
            ),
          ),
        ],
      );
    }

    // Fallback: raw markdown text
    return Markdown(
      data: rawText!,
      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 80),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: kDark, height: 1.7),
        h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kDark),
        h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kDark),
        h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kSecondaryGold),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: kDark),
        blockquoteDecoration: BoxDecoration(
          color: kGold.withOpacity(0.08),
          border: const Border(left: BorderSide(color: kGold, width: 3)),
        ),
      ),
    );
  }

  Widget _generatingBanner() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(color: kGold, strokeWidth: 2.5),
        ),
        const SizedBox(height: 20),
        const Text(
          '해석 생성 중...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'AI가 사주를 분석하고 있습니다\n잠시만 기다려주세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: kTextMuted, height: 1.6),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kDancheongBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDancheongBlue.withOpacity(0.4)),
              ),
              child: const Text(
                '보통 1~2분 소요됩니다',
                style: TextStyle(fontSize: 12, color: kDancheongBlue),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _sectionBorderColors = [kDancheongBlue, kDancheongRed, kDancheongYellow];

  Widget _sectionCard(int index, Map<String, dynamic> section) {
    final title = section['title'] as String? ?? '';
    final summary = section['summary'] as String? ?? '';
    final content = section['content'] as String? ?? '';
    final isExpanded = _expandedSections.contains(index);
    final borderColor = _sectionBorderColors[index % _sectionBorderColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: kGlassFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGlassBorder),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Image.asset('assets/images/tab_selected.png', width: 14, height: 14, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 6),
                      Text(title,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: kGold)),
                    ],
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(summary,
                      style: const TextStyle(fontSize: 13, color: kTextMuted, height: 1.5)),
                  ],
                ],
              ),
            ),
            // Expand button
            if (content.isNotEmpty)
              InkWell(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedSections.remove(index);
                  } else {
                    _expandedSections.add(index);
                  }
                }),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18, color: kGold,
                    ),
                  ),
                ),
              ),
            // Expanded content
            if (isExpanded && content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(content,
                        style: const TextStyle(fontSize: 13, color: kDark, height: 1.7)),
                    ),
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
        ),
      ),
    );
  }
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String profileId;
  final VoidCallback onSaved;

  const _EditProfileSheet({
    required this.profile,
    required this.profileId,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _relationshipCtrl;
  DateTime? _birthDate;
  late String _gender;
  late String _calendarType;
  late String _birthHourPrecision;
  String? _birthHour;
  bool _loading = false;
  String? _error;

  final ApiService _api = ApiService();

  static const _hours = [
    ('자시', '23~01시', '23'), ('축시', '01~03시', '01'), ('인시', '03~05시', '03'),
    ('묘시', '05~07시', '05'), ('진시', '07~09시', '07'), ('사시', '09~11시', '09'),
    ('오시', '11~13시', '11'), ('미시', '13~15시', '13'), ('신시', '15~17시', '15'),
    ('유시', '17~19시', '17'), ('술시', '19~21시', '19'), ('해시', '21~23시', '21'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile['name'] as String? ?? '');
    _relationshipCtrl = TextEditingController(
        text: widget.profile['relationship'] as String? ?? '');
    _gender = widget.profile['gender'] as String? ?? 'male';
    _calendarType = widget.profile['calendar_type'] as String? ?? 'solar';
    _birthHourPrecision = widget.profile['birth_time_type'] as String? ?? 'unknown';
    final bh = widget.profile['birthHour'];
    _birthHour = bh?.toString();

    final birthDate = widget.profile['birth_date'] as String?;
    if (birthDate != null) {
      try {
        _birthDate = DateTime.parse(birthDate);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kGold, onPrimary: kDark),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '이름을 입력해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'gender': _gender,
        'calendarType': _calendarType,
        'birthTimeType': _birthHourPrecision,
        if (_birthHour != null && _birthHourPrecision != 'unknown')
          'birthHour': int.tryParse(_birthHour!),
        if (_relationshipCtrl.text.trim().isNotEmpty)
          'relationship': _relationshipCtrl.text.trim(),
      };

      if (_birthDate != null) {
        updates['birthYear'] = _birthDate!.year;
        updates['birthMonth'] = _birthDate!.month;
        updates['birthDay'] = _birthDate!.day;
      }

      await _api.updateProfile(widget.profileId, updates);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '프로필 수정에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        title: const Text('프로필 삭제', style: TextStyle(color: kDark)),
        content: const Text('이 프로필을 삭제하시겠습니까?\n삭제된 프로필은 복구할 수 없습니다.',
          style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _api.deleteProfile(widget.profileId);
      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.pop(context); // go back to profiles list
      }
    } catch (e) {
      setState(() => _error = '프로필 삭제에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('프로필 수정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('이름'),
            const SizedBox(height: 6),
            _field(controller: _nameCtrl, hint: '홍길동'),
            const SizedBox(height: 16),
            _label('관계'),
            const SizedBox(height: 6),
            _field(controller: _relationshipCtrl, hint: '예) 친구, 배우자, 부모님 (선택사항)'),
            const SizedBox(height: 16),
            _label('생년월일'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGlassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthDate == null
                            ? '날짜를 선택하세요'
                            : '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일',
                        style: TextStyle(
                          fontSize: 15,
                          color: _birthDate == null ? kTextMuted : kDark),
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: kTextMuted, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label('성별'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _chip('남성', 'male', _gender, (v) => setState(() => _gender = v))),
              const SizedBox(width: 12),
              Expanded(child: _chip('여성', 'female', _gender, (v) => setState(() => _gender = v))),
            ]),
            const SizedBox(height: 16),
            _label('달력 종류'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _chip('양력', 'solar', _calendarType, (v) => setState(() => _calendarType = v))),
              const SizedBox(width: 12),
              Expanded(child: _chip('음력', 'lunar', _calendarType, (v) => setState(() => _calendarType = v))),
            ]),
            const SizedBox(height: 16),
            _label('태어난 시간'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _chip('정확히', 'exact', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
              const SizedBox(width: 8),
              Expanded(child: _chip('대략', 'rough', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
              const SizedBox(width: 8),
              Expanded(child: _chip('모름', 'unknown', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
            ]),
            if (_birthHourPrecision == 'exact') ...[
              const SizedBox(height: 12),
              // 1행: 자시~사시 (6개)
              Row(children: List.generate(6, (i) {
                final h = _hours[i];
                final selected = _birthHour == h.$3;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _birthHour = h.$3),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? kGold : const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? kGold : kGlassBorder),
                    ),
                    child: Column(children: [
                      Text(h.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? kInk : kDark)),
                      Text(h.$2, style: TextStyle(fontSize: 8,
                        color: selected ? kInk.withOpacity(0.6) : kTextMuted)),
                    ]),
                  ),
                ));
              })),
              const SizedBox(height: 6),
              // 2행: 오시~해시 (6개)
              Row(children: List.generate(6, (i) {
                final h = _hours[i + 6];
                final selected = _birthHour == h.$3;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _birthHour = h.$3),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? kGold : const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? kGold : kGlassBorder),
                    ),
                    child: Column(children: [
                      Text(h.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? kInk : kDark)),
                      Text(h.$2, style: TextStyle(fontSize: 8,
                        color: selected ? kInk.withOpacity(0.6) : kTextMuted)),
                    ]),
                  ),
                ));
              })),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kErrorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kErrorColor.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: kErrorColor, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kInk,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: kInk, strokeWidth: 2))
                    : const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _loading ? null : _delete,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: kErrorColor.withOpacity(0.3)),
                  ),
                ),
                child: const Text('프로필 삭제',
                  style: TextStyle(fontSize: 14, color: kErrorColor, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark));

  Widget _field({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, color: kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
        filled: true, fillColor: const Color(0x0AFFFFFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kGlassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kGlassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGold, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _chip(String label, String value, String current, void Function(String) onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kGold : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kGold : kGlassBorder),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: selected ? kInk : kTextMuted)),
        ),
      ),
    );
  }
}

// ─── Add Event Bottom Sheet (inline) ─────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final String profileId;
  final VoidCallback onAdded;
  /// 있으면 수정 모드, 없으면 추가 모드
  final Map<String, dynamic>? existingEvent;

  const _AddEventSheet({
    required this.profileId,
    required this.onAdded,
    this.existingEvent,
  });

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _year = DateTime.now().year;
  int? _month;
  String _impact = 'neutral';
  bool _loading = false;
  String? _error;

  final ApiService _api = ApiService();

  bool get _isEditMode => widget.existingEvent != null;

  static const _impacts = [
    ('very_positive', '매우긍정', Color(0xFF4CAF50)),
    ('positive', '긍정', Color(0xFF81C784)),
    ('neutral', '중립', Color(0xFF8B87A0)),
    ('negative', '부정', Color(0xFFE57373)),
    ('very_negative', '매우부정', Color(0xFFC8393A)),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingEvent;
    if (e != null) {
      _titleCtrl.text = (e['title'] as String?) ?? '';
      _descCtrl.text = (e['description'] as String?) ?? '';
      _year = (e['eventYear'] as num?)?.toInt() ?? DateTime.now().year;
      _month = (e['eventMonth'] as num?)?.toInt();
      _impact = (e['impact'] as String?) ?? 'neutral';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _error = '내용을 입력해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isEditMode) {
        final eventId = widget.existingEvent!['id'] as String;
        await _api.updateEvent(
          widget.profileId,
          eventId: eventId,
          eventYear: _year,
          eventMonth: _month,
          description: _descCtrl.text.trim(),
          impact: _impact,
          title: _titleCtrl.text.trim(),
        );
        widget.onAdded();
        if (mounted) Navigator.pop(context);
        return;
      }
      await _api.addEvent(
        widget.profileId,
        eventYear: _year,
        description: _descCtrl.text.trim(),
        impact: _impact,
        eventMonth: _month,
        title: _titleCtrl.text.trim(),
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '이벤트 추가에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditMode ? '이벤트 수정' : '이벤트 추가',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('제목',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, color: kDark),
              decoration: InputDecoration(
                hintText: '이벤트 제목을 입력해주세요',
                hintStyle: const TextStyle(color: kTextMuted, fontSize: 13),
                filled: true, fillColor: const Color(0x0AFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGlassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGlassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kGold, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            const Text('연도',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.remove_circle_outline, color: kGold),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGlassBorder),
                    ),
                    child: Center(
                      child: Text('$_year년',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (_year < DateTime.now().year) _year++;
                  }),
                  icon: const Icon(Icons.add_circle_outline, color: kGold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('월 (선택사항)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Row(children: [
              for (int m = 1; m <= 6; m++) Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _monthChip(m, '$m월'),
              )),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              for (int m = 7; m <= 12; m++) Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _monthChip(m, '$m월'),
              )),
            ]),
            const SizedBox(height: 6),
            _monthChip(null, '전체'),
            const SizedBox(height: 16),
            const Text('내용',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: kDark),
              decoration: InputDecoration(
                hintText: '어떤 일이 있었나요?',
                hintStyle: const TextStyle(color: kTextMuted, fontSize: 13),
                filled: true, fillColor: const Color(0x0AFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGlassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGlassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kGold, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            const Text('영향도',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Row(
              children: _impacts.map((item) {
                final selected = _impact == item.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _impact = item.$1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? kGold : const Color(0x0AFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? kGold : kGlassBorder,
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selected ? Icons.check_circle : Icons.circle_outlined,
                            size: 14, color: selected ? kInk : kTextMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(item.$2,
                            style: TextStyle(fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                              color: selected ? kInk : kTextMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kErrorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kErrorColor.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: kErrorColor, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kInk,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: kInk, strokeWidth: 2))
                    : Text(_isEditMode ? '수정' : '추가',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthChip(int? month, String label) {
    final selected = _month == month;
    return GestureDetector(
      onTap: () => setState(() => _month = month),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kGold : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? kGold : kGlassBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(fontSize: 12,
              color: selected ? kInk : kTextMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        ),
      ),
    );
  }
}
