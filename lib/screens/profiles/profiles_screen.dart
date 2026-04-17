import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profiles_provider.dart';
import '../../models/profile.dart';
import '../../widgets/dancheong_bar.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  // 그리드 컨테이너의 위치/크기를 구하기 위한 키
  final GlobalKey _gridKey = GlobalKey();

  // 드래그 상태
  Profile? _draggingProfile;
  int _hoverIndex = 0;
  OverlayEntry? _overlayEntry;
  final ValueNotifier<Offset> _overlayPos = ValueNotifier(Offset.zero);
  double _cardW = 0;
  double _cardH = 0;
  Offset _fingerOnCard = Offset.zero; // 카드 내 손가락 누른 위치 오프셋

  bool get _isDragging => _draggingProfile != null;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilesProvider>().loadProfiles();
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayPos.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── 그리드 RenderBox 가져오기 ─────────────────
  RenderBox? get _gridBox =>
      _gridKey.currentContext?.findRenderObject() as RenderBox?;

  // ── 글로벌 위치 → 그리드 셀 인덱스 ──────────
  int? _indexAt(Offset globalPos, int count) {
    final box = _gridBox;
    if (box == null) return null;
    final local = box.globalToLocal(globalPos);
    final colW = (box.size.width - 12) / 2; // crossAxisSpacing=12
    final colH = colW / 0.80;               // childAspectRatio=0.80
    final col = (local.dx / (colW + 12)).floor().clamp(0, 1);
    final row = (local.dy / (colH + 12)).floor().clamp(0, (count - 1 + 1) ~/ 2);
    final idx = (row * 2 + col).clamp(0, count - 1);
    return idx;
  }

  // ── 드래그 시작 ──────────────────────────────
  void _startDrag(LongPressStartDetails d, List<Profile> profiles) {
    final box = _gridBox;
    if (box == null) return;

    final tapIndex = _indexAt(d.globalPosition, profiles.length);
    if (tapIndex == null || tapIndex >= profiles.length) return;

    final colW = (box.size.width - 12) / 2;
    final colH = colW / 0.80;
    final col = tapIndex % 2;
    final row = tapIndex ~/ 2;
    final gridGlobal = box.localToGlobal(Offset.zero);
    final cardTopLeft = Offset(
      gridGlobal.dx + col * (colW + 12),
      gridGlobal.dy + row * (colH + 12),
    );

    _cardW = colW;
    _cardH = colH;
    _fingerOnCard = d.globalPosition - cardTopLeft;

    final profile = profiles[tapIndex];
    HapticFeedback.mediumImpact();

    _overlayPos.value = cardTopLeft;
    _overlayEntry = OverlayEntry(
      builder: (_) => ValueListenableBuilder<Offset>(
        valueListenable: _overlayPos,
        builder: (_, pos, __) => Positioned(
          left: pos.dx,
          top: pos.dy,
          width: _cardW,
          height: _cardH,
          child: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.07,
              child: Opacity(
                opacity: 0.9,
                child: _ProfileCard(profile: profile),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _draggingProfile = profile;
      _hoverIndex = tapIndex;
    });
  }

  // ── 드래그 이동 ──────────────────────────────
  void _moveDrag(LongPressMoveUpdateDetails d, int profileCount) {
    if (!_isDragging) return;

    // 오버레이(떠다니는 카드)를 손가락 따라 이동
    _overlayPos.value = d.globalPosition - _fingerOnCard;

    // 어느 셀 위인지 계산해서 hoverIndex 업데이트
    final newIdx = _indexAt(d.globalPosition, profileCount);
    if (newIdx != null && newIdx != _hoverIndex) {
      HapticFeedback.selectionClick();
      setState(() => _hoverIndex = newIdx);
    }
  }

  // ── 드래그 종료 ──────────────────────────────
  void _endDrag(List<Profile> profiles) {
    if (!_isDragging) return;
    final dragging = _draggingProfile!;
    final without = profiles.where((p) => p.id != dragging.id).toList();
    without.insert(_hoverIndex.clamp(0, without.length), dragging);

    _overlayEntry?.remove();
    _overlayEntry = null;

    setState(() => _draggingProfile = null);
    context.read<ProfilesProvider>().reorderProfiles(without);
  }

  void _cancelDrag() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _draggingProfile = null);
  }

  // ── 드래그 중 그리드에 표시할 리스트 ────────
  List<Profile?> _displayList(List<Profile> profiles) {
    if (!_isDragging) return profiles;
    final without = profiles
        .where((p) => p.id != _draggingProfile!.id)
        .cast<Profile?>()
        .toList();
    without.insert(_hoverIndex.clamp(0, without.length), null);
    return without;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profilesProvider = context.watch<ProfilesProvider>();
    final profiles = profilesProvider.profiles;
    final display = _displayList(profiles);

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: _isDragging ? null : _buildDrawer(auth),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isDragging)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: kDark),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
        ],
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
            child: RefreshIndicator(
              color: kGold,
              backgroundColor: kCosmicNavy,
              onRefresh: _isDragging ? () async {} : () => profilesProvider.loadProfiles(),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                child: CustomScrollView(
                physics: _isDragging
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: DancheongBar()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.person, color: kGold, size: 30),
                                Image.asset('assets/images/profile_frame.png',
                                    width: 56, height: 56, fit: BoxFit.contain),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '안녕하세요, ${auth.displayName}님',
                                style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600, color: kDark,
                                ),
                              ),
                              Text(
                                _isDragging ? '놓을 위치로 드래그하세요' : '나의 사주 프로필',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isDragging
                                      ? kGold.withOpacity(0.8)
                                      : kDark.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: DancheongBar(),
                    ),
                  ),

                  // ── 로딩 ────────────────────────────────
                  if (profilesProvider.loading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.80,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const ProfileCardSkeleton(),
                          childCount: 4,
                        ),
                      ),
                    )

                  // ── 에러 ────────────────────────────────
                  else if (profilesProvider.error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  color: kDark.withOpacity(0.3), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                profilesProvider.error!,
                                style: TextStyle(color: kDark.withOpacity(0.5)),
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: profilesProvider.loadProfiles,
                                child: const Text('다시 시도',
                                    style: TextStyle(color: kGold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  // ── 데이터 ──────────────────────────────
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        // GestureDetector를 그리드 전체에 씌워서
                        // setState로 그리드가 재빌드돼도 제스처가 끊기지 않는다
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPressStart: (d) => _startDrag(d, profiles),
                          onLongPressMoveUpdate: (d) =>
                              _moveDrag(d, profiles.length),
                          onLongPressEnd: (_) => _endDrag(profiles),
                          onLongPressCancel: _cancelDrag,
                          child: Container(
                            key: _gridKey,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.80,
                              ),
                              itemCount: _isDragging
                                  ? display.length          // placeholder 포함, 추가버튼 없음
                                  : profiles.length + 1,    // 프로필 + 추가버튼
                              itemBuilder: (context, index) {
                                // 드래그 중
                                if (_isDragging) {
                                  final item = display[index];
                                  if (item == null) return const _DropPlaceholder();
                                  return _ProfileCard(profile: item);
                                }
                                // 일반 모드 - 추가 버튼
                                if (index == profiles.length) {
                                  return GestureDetector(
                                    onTap: () => context.push('/profiles/new'),
                                    child: const _AddProfileCard(),
                                  );
                                }
                                // 일반 모드 - 프로필 카드 (탭으로 이동)
                                final profile = profiles[index];
                                return GestureDetector(
                                  onTap: () =>
                                      context.push('/profiles/${profile.id}'),
                                  child: _ProfileCard(profile: profile),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ), // CustomScrollView
              ), // ScrollConfiguration
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthProvider auth) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRect(
        child: ColoredBox(
          color: kCosmicNavy.withOpacity(0.25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                // 베이스 그라데이션
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.01),
                          kCosmicNavy.withOpacity(0.10),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // 대각선 광택
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.25, 0.28, 1.0],
                        colors: [
                          Colors.white.withOpacity(0.04),
                          Colors.white.withOpacity(0.02),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 우측 엣지 하이라이트 (사이드바는 오른쪽이 열린 면)
                Positioned(
                  top: 0, right: 0, bottom: 0,
                  child: Container(
                    width: 0.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 콘텐츠
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      Divider(color: kGlassBorder, height: 1),
                      const SizedBox(height: 48),
                      ListTile(
                        leading: Image.asset('assets/images/menu_icon.png', width: 24, height: 24),
                        title: const Text('궁합 분석', style: TextStyle(color: kDark)),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/compatibility');
                        },
                      ),
                      ListTile(
                        leading: Image.asset('assets/images/menu_icon.png', width: 24, height: 24),
                        title: const Text('환경 설정', style: TextStyle(color: kDark)),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/account');
                        },
                      ),
                      ListTile(
                        leading: Image.asset('assets/images/menu_icon.png', width: 24, height: 24),
                        title: const Text('마이페이지', style: TextStyle(color: kDark)),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/account');
                        },
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await auth.signOut();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '로그아웃',
                                  style: TextStyle(
                                    color: kErrorColor.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.logout,
                                  color: kErrorColor.withOpacity(0.7),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ), // Padding
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 드롭 플레이스홀더 ─────────────────────────────────────
class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kGold.withOpacity(0.06),
        border: Border.all(
          color: kGold.withOpacity(0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
    );
  }
}

// ── 프로필 카드 ───────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final Profile profile;

  const _ProfileCard({required this.profile});

  static const _branchEmojiMap = {
    '자': '🐭', '축': '🐮', '인': '🐯', '묘': '🐰',
    '진': '🐲', '사': '🐍', '오': '🐴', '미': '🐑',
    '신': '🐵', '유': '🐔', '술': '🐶', '해': '🐷',
  };

  static String _zodiacEmoji(Profile profile) {
    // 일주(日柱)의 지지(地支) 글자로 동물 결정
    final chart = profile.chartData;
    if (chart != null) {
      final dayPillar = chart['dayPillar'] as Map<String, dynamic>?;
      final branch = (dayPillar?['branch'] as Map<String, dynamic>?)?['char'] as String?;
      if (branch != null) return _branchEmojiMap[branch] ?? '🐾';
    }
    return '🐾';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = profile.isOwner;

    // 반사광을 위한 그림자는 ClipRRect 바깥에 둬야 보임
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: kCosmicNavy,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
            children: [
              // ① 베이스 유리 몸통
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.07),
                      Colors.white.withOpacity(0.02),
                      kCosmicNavy.withOpacity(0.25),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ② 대각선 광택
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.38, 0.42, 1.0],
                      colors: [
                        Colors.white.withOpacity(0.04),
                        Colors.white.withOpacity(0.02),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ③ 좌측+모서리+상단 엣지 하이라이트 (연속 곡선)
              Positioned.fill(
                child: CustomPaint(painter: _GlassEdgePainter()),
              ),

              // ④ 콘텐츠
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    kGold.withOpacity(0.15),
                    kGold.withOpacity(0.05),
                  ]),
                  border: Border.all(color: kGold.withOpacity(0.2)),
                ),
                child: Text(
                  _zodiacEmoji(profile),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (isOwner)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      kDancheongRed,
                      kDancheongRed.withOpacity(0.7)
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: kDancheongRed.withOpacity(0.3), blurRadius: 8)
                    ],
                  ),
                  child: const Text('나의 사주',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                )
              else if (profile.relationship != null &&
                  profile.relationship!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGlassBorder),
                  ),
                  child: Text(
                    profile.relationship!,
                    style: TextStyle(
                        fontSize: 10,
                        color: kDark.withOpacity(0.5),
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            profile.name,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            profile.displayBirthDate,
            style: TextStyle(
              fontSize: 11,
              color: isOwner ? kGold : kDark.withOpacity(0.4),
              fontWeight: isOwner ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (profile.displayGender.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(profile.displayGender,
                style: TextStyle(fontSize: 11, color: kDark.withOpacity(0.35))),
          ],
              ],
                ), // Column
              ), // Padding  ⑥
            ], // Stack children
          ), // Stack
          ), // BackdropFilter
        ), // ColoredBox
      ), // ClipRRect
    ); // Container (shadow)
  }
}

// ── 프로필 추가 카드 ──────────────────────────────────────
class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: kCosmicNavy,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
            children: [
              // 베이스
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.07),
                      Colors.white.withOpacity(0.02),
                      kCosmicNavy.withOpacity(0.25),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // 대각선 광택
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.38, 0.42, 1.0],
                      colors: [
                        Colors.white.withOpacity(0.04),
                        Colors.white.withOpacity(0.02),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // 좌측+모서리+상단 엣지 하이라이트 (연속 곡선)
              Positioned.fill(
                child: CustomPaint(painter: _GlassEdgePainter()),
              ),
              // 콘텐츠
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kGold.withOpacity(0.35)),
                      gradient: RadialGradient(colors: [
                        kGold.withOpacity(0.10),
                        Colors.transparent,
                      ]),
                    ),
                    child: const Icon(Icons.add, color: kGold, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '프로필 추가',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kDark.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ],
          ), // Stack
          ), // BackdropFilter
        ), // ColoredBox
      ), // ClipRRect
    ); // Container (shadow)
  }
}

// ── 유리 엣지 하이라이트 페인터 ──────────────────────────
// 왼쪽 세로선 → 좌상단 모서리 호 → 상단 가로선을 하나의 연속된 선으로 그림
class _GlassEdgePainter extends CustomPainter {
  static const double _r = 16.0; // card border radius

  @override
  void paint(Canvas canvas, Size size) {
    // ① 왼쪽 세로 엣지: 하단(투명) → 상단(밝음)
    canvas.drawLine(
      Offset(0.5, size.height),
      const Offset(0.5, _r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 1, size.height)),
    );

    // ② 좌상단 모서리 호: 두 선을 자연스럽게 연결
    final arcPath = Path()
      ..moveTo(0.5, _r)
      ..arcToPoint(
        const Offset(_r, 0.5),
        radius: const Radius.circular(_r),
        clockwise: true,
      );
    canvas.drawPath(
      arcPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.5),
    );

    // ③ 상단 가로 엣지: 좌(밝음) → 우(투명)
    canvas.drawLine(
      const Offset(_r, 0.5),
      Offset(size.width, 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 1)),
    );
  }

  @override
  bool shouldRepaint(_GlassEdgePainter old) => false;
}
