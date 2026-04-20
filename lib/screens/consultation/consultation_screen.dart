import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../models/chat_message.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class ConsultationScreen extends StatefulWidget {
  final String profileId;

  const ConsultationScreen({super.key, required this.profileId});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final ApiService _api = ApiService();

  List<ChatMessage> _messages = [];
  String? _sessionId;
  bool _loading = false;
  bool _sending = false;
  String? _error;

  // Chart 컨텍스트 (LLM 입력에 필요)
  String _chartContext = '';
  String _interpretation = '';

  // Chat history for sidebar
  List<Map<String, dynamic>> _chatSessions = [];

  // 크래딧 정보
  int? _tokensRemaining;
  int? _tokensLimit;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  /// chartData 맵 → LLM이 읽을 수 있는 텍스트로 직렬화
  String _buildChartContext(Map<String, dynamic> profile) {
    final chart = (profile['chart_data'] ?? profile['chartData']) as Map<String, dynamic>?;
    final name = profile['name'] as String? ?? '';
    final by = (profile['birthYear'] as num?)?.toInt();
    final bm = (profile['birthMonth'] as num?)?.toInt();
    final bd = (profile['birthDay'] as num?)?.toInt();
    final bh = (profile['birthHour'] as num?)?.toInt();
    final gender = profile['gender'] as String? ?? '';

    if (chart == null) {
      return '### $name\n- Birth: $by/$bm/$bd\n- Gender: $gender';
    }

    final lines = <String>[
      '### $name 사주 데이터',
      '- 생년월일: $by/$bm/$bd${bh != null ? " ${bh}시" : ""}',
      '- 성별: ${gender == "male" ? "남성" : "여성"}',
      '',
      '### 명식 (Birth Chart)',
    ];

    final yearP = chart['yearPillar'] as Map<String, dynamic>?;
    final monthP = chart['monthPillar'] as Map<String, dynamic>?;
    final dayP = chart['dayPillar'] as Map<String, dynamic>?;
    final hourP = chart['hourPillar'] as Map<String, dynamic>?;

    String pillarText(Map<String, dynamic>? p) {
      if (p == null) return '';
      final ch = p['fullChar'] ?? '';
      final ha = p['fullHanja'] ?? '';
      return '$ch ($ha)';
    }

    if (yearP != null) lines.add('- 연주: ${pillarText(yearP)}');
    if (monthP != null) lines.add('- 월주: ${pillarText(monthP)}');
    if (dayP != null) {
      final stem = (dayP['stem'] as Map<String, dynamic>?)?['char'] ?? '';
      final element = (dayP['stem'] as Map<String, dynamic>?)?['element'] ?? '';
      lines.add('- 일주: ${pillarText(dayP)} ← 일간(Day Master): $stem ($element)');
    }
    if (hourP != null) lines.add('- 시주: ${pillarText(hourP)}');

    final five = chart['fiveElements'] as Map<String, dynamic>?;
    if (five != null) {
      lines.add('');
      lines.add('### 오행 분포');
      lines.add('- 목:${five["목"]}, 화:${five["화"]}, 토:${five["토"]}, 금:${five["금"]}, 수:${five["수"]}');
      if (five['dominant'] != null) lines.add('- 가장 강한 오행: ${five["dominant"]}, 가장 약한 오행: ${five["weakest"]}');
    }

    final majorLuck = chart['majorLuck'] as List<dynamic>?;
    if (majorLuck != null && majorLuck.isNotEmpty) {
      lines.add('');
      lines.add('### 대운');
      for (final m in majorLuck) {
        final ml = m as Map<String, dynamic>;
        final start = ml['startAge'];
        final end = ml['endAge'];
        final ch = ml['fullChar'] ?? '';
        lines.add('- $start~$end세: $ch');
      }
    }

    return lines.join('\n');
  }

  /// 프로필 fetch → chartContext + interpretation 저장
  Future<void> _loadProfileContext() async {
    try {
      final profile = await _api.getProfile(widget.profileId);
      _chartContext = _buildChartContext(profile);
      final interp = profile['interpretation'];
      if (interp is String) {
        _interpretation = interp;
      } else if (interp is Map) {
        _interpretation = (interp['content'] as String?) ?? '';
      } else {
        _interpretation = '';
      }
      debugPrint('=== chart context loaded: ${_chartContext.length} chars, interp: ${_interpretation.length} chars');
    } catch (e) {
      debugPrint('=== load profile context failed: $e');
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    setState(() => _loading = true);
    try {
      // 프로필 컨텍스트 + 세션 목록 + 구독 정보를 병렬 로드
      await Future.wait([
        _loadProfileContext(),
        _refreshChatSessions(),
        _loadCredits(),
      ]);
      // 기존 세션이 있으면 가장 최근 것 자동 로드 (이어 채팅)
      if (_chatSessions.isNotEmpty) {
        final mostRecent = _chatSessions.first;
        final id = mostRecent['id'] as String?;
        if (id != null) {
          _sessionId = id;
          try {
            final history = await _api.getChatHistory(id);
            setState(() => _messages = history);
          } catch (_) {
            // history 로드 실패해도 빈 채팅으로 계속 진행
          }
        }
      }
      // 세션이 하나도 없으면 _sessionId == null로 두고, 첫 메시지 전송 시 생성
      debugPrint('=== chat init done: sessionId=$_sessionId, sessions=${_chatSessions.length}');
    } catch (e) {
      debugPrint('=== chat init failed: $e');
      setState(() => _error = '채팅을 시작할 수 없습니다.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCredits() async {
    try {
      final sub = await _api.getSubscription();
      if (mounted) {
        setState(() {
          _tokensRemaining = (sub['tokensRemaining'] as num?)?.toInt();
          _tokensLimit = (sub['tokensLimit'] as num?)?.toInt();
        });
      }
    } catch (e) {
      debugPrint('=== load credits failed: $e');
    }
  }

  Future<void> _refreshChatSessions() async {
    try {
      final list = await _api.getChatSessions(widget.profileId);
      if (mounted) setState(() => _chatSessions = list);
    } catch (e) {
      debugPrint('=== load chat sessions failed: $e');
    }
  }

  Future<void> _loadSession(String sessionId) async {
    setState(() { _loading = true; _sessionId = sessionId; _error = null; });
    try {
      final history = await _api.getChatHistory(sessionId);
      setState(() => _messages = history);
    } catch (e) {
      setState(() => _error = '채팅 기록을 불러올 수 없습니다.');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 새 채팅 시작 — 세션은 첫 메시지 보낼 때 lazy 생성
  void _startNewSession() {
    setState(() {
      _sessionId = null;
      _messages = [];
      _error = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    debugPrint('=== _sendMessage called: text=${text.length} chars, sessionId=$_sessionId, sending=$_sending');
    if (text.isEmpty || _sending) {
      debugPrint('=== _sendMessage early return');
      return;
    }

    _messageCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _sending = true;
    });
    _scrollToBottom();

    // 세션이 없으면 첫 메시지 시점에 lazy 생성
    if (_sessionId == null) {
      try {
        final raw = await _api.createChatSession(widget.profileId);
        final session = (raw['session'] as Map<String, dynamic>?) ?? raw;
        _sessionId = session['id'] as String?;
        debugPrint('=== chat session lazy-created: $_sessionId');
      } catch (e) {
        debugPrint('=== lazy session creation failed: $e');
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: '채팅 세션을 시작할 수 없습니다: $e',
          ));
          _sending = false;
        });
        return;
      }
    }

    // 직전 메시지 중 새로 추가한 user 메시지는 제외하고 history 전송
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    try {
      debugPrint('=== sendMessage: posting to /api/chat ...');
      final reply = await _api.sendMessage(
        _sessionId!,
        text,
        chartContext: _chartContext,
        interpretation: _interpretation,
        history: history,
      );
      debugPrint('=== sendMessage: received reply, length=${reply.length}');
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });
      // 첫 답장 후 세션 목록 새로고침 (제목/정렬 갱신)
      _refreshChatSessions();
    } catch (e, stack) {
      debugPrint('=== sendMessage exception: $e');
      debugPrint('=== stack: $stack');
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: '오류: $e',
        ));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color get _creditColor {
    if (_tokensRemaining == null || _tokensLimit == null || _tokensLimit! == 0) {
      return kGoldLight;
    }
    final ratio = _tokensRemaining! / _tokensLimit!;
    if (ratio <= 0.1) return kAccentRed;
    if (ratio <= 0.3) return const Color(0xFFFF9500);
    return kGoldLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      endDrawer: _chatHistoryDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI 상담',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kDark,
              ),
            ),
            if (_tokensRemaining != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _creditColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _creditColor.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: _creditColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 10, color: _creditColor),
                    const SizedBox(width: 3),
                    Text(
                      '$_tokensRemaining 크래딧',
                      style: TextStyle(
                        fontSize: 10,
                        color: _creditColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.history, color: kDark),
              tooltip: '채팅 기록',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: CosmicBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGold))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: kTextMuted.withOpacity(0.7), size: 40),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(color: kTextMuted)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _initSession,
                          child: const Text('다시 시도',
                              style: TextStyle(color: kGold)),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _messages.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  MediaQuery.of(context).padding.top +
                                      kToolbarHeight +
                                      16,
                                  16,
                                  8,
                                ),
                                itemCount:
                                    _messages.length + (_sending ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_sending &&
                                      index == _messages.length) {
                                    return _typingBubble();
                                  }
                                  return _messageBubble(_messages[index]);
                                },
                              ),
                      ),
                      _inputBar(),
                    ],
                  ),
      ),
    );
  }

  Widget _chatHistoryDrawer() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Drawer(
          backgroundColor: kCosmicNavy.withOpacity(0.85),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '채팅 기록',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: kGold),
                        tooltip: '새 채팅',
                        onPressed: () {
                          Navigator.pop(context);
                          _startNewSession();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: kGlassBorder, height: 1),
                // Current session indicator
                if (_sessionId != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble,
                            color: kGold, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _messages.isNotEmpty
                                ? _messages.first.content.length > 30
                                    ? '${_messages.first.content.substring(0, 30)}...'
                                    : _messages.first.content
                                : '현재 대화',
                            style:
                                const TextStyle(fontSize: 13, color: kDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('현재',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _chatSessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.forum_outlined,
                                    color: kTextMuted.withOpacity(0.4), size: 40),
                                const SizedBox(height: 12),
                                const Text(
                                  '아직 다른 채팅 기록이 없어요\n상단 + 버튼으로 새 채팅을 시작하세요',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: kTextMuted,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          itemCount: _chatSessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final s = _chatSessions[i];
                            final id = s['id'] as String? ?? '';
                            final title = (s['title'] as String?) ?? '대화';
                            final count = (s['messageCount'] as num?)?.toInt() ?? 0;
                            final updatedAt = s['updatedAt'] as String?;
                            final isCurrent = id == _sessionId;
                            // 현재 세션은 위쪽 indicator에서 보여주므로 리스트에서 제외
                            if (isCurrent) return const SizedBox.shrink();
                            return _ChatSessionTile(
                              title: title,
                              messageCount: count,
                              updatedAt: updatedAt,
                              onTap: () {
                                Navigator.pop(context);
                                _loadSession(id);
                              },
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
          left: 32,
          right: 32,
          bottom: 32,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kGold.withOpacity(0.25),
                      kGold.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Image.asset('assets/images/logo.png', height: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI 사주 상담',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kDark),
              ),
              const SizedBox(height: 8),
              Text(
                '사주에 대해 궁금한 것을\n무엇이든 물어보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: kDark.withOpacity(0.7),
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              ...[
                '올해 운세가 어떤가요?',
                '적성에 맞는 직업은?',
                '연애운을 알려주세요',
              ].map((q) => GestureDetector(
                    onTap: () {
                      _messageCtrl.text = q;
                      _sendMessage();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x0AFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kGlassBorder),
                          ),
                          child: Text(q,
                              style: const TextStyle(
                                  fontSize: 13, color: kDark)),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _commandAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            kGold.withOpacity(0.35),
            kGold.withOpacity(0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
          radius: 1.2,
        ),
      ),
      child: const Center(
        child: Text('命',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kGoldLight)),
      ),
    );
  }

  Widget _messageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _commandAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: isUser
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kGold,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(msg.content,
                        style: const TextStyle(
                            fontSize: 14, color: kInk, height: 1.5)),
                  )
                : ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x0AFFFFFF),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(color: kGlassBorder),
                        ),
                        child: MarkdownBody(
                          data: msg.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                fontSize: 14, color: kDark, height: 1.6),
                            strong: const TextStyle(
                                fontWeight: FontWeight.w700, color: kDark),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _commandAvatar(),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(color: kGlassBorder),
                ),
                child: SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    color: kGold,
                    backgroundColor: kGlassFill,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: kCosmicNavy.withOpacity(0.7),
        border: Border(top: BorderSide(color: kGlassBorder)),
      ),
      child: Row(
        children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 14, color: kDark),
                  decoration: InputDecoration(
                    hintText: '질문을 입력하세요...',
                    hintStyle: TextStyle(
                        color: kDark.withOpacity(0.4), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0x08FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: kGlassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: kGlassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: kGold, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                debugPrint('=== send button tapped');
                _sendMessage();
              },
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending ? kGlassFill : kGold,
                  shape: BoxShape.circle,
                  boxShadow: _sending
                      ? []
                      : [
                          BoxShadow(
                            color: kGoldGlow,
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: _sending ? kTextMuted : kInk,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 채팅 세션 리스트 타일 (드로어용)
class _ChatSessionTile extends StatelessWidget {
  final String title;
  final int messageCount;
  final String? updatedAt;
  final VoidCallback onTap;

  const _ChatSessionTile({
    required this.title,
    required this.messageCount,
    required this.updatedAt,
    required this.onTap,
  });

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '방금';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.year}.${dt.month.toString().padLeft(2, "0")}.${dt.day.toString().padLeft(2, "0")}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGlassBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                color: kDark.withOpacity(0.6), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$messageCount개 메시지',
                          style: TextStyle(
                            fontSize: 10,
                            color: kDark.withOpacity(0.4),
                          ),
                        ),
                        if (updatedAt != null) ...[
                          Text(' · ',
                            style: TextStyle(
                              fontSize: 10,
                              color: kDark.withOpacity(0.3),
                            )),
                          Text(
                            _formatDate(updatedAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: kDark.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                color: kDark.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
