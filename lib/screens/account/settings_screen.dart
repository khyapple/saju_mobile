import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/dancheong_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
      ),
      body: CosmicBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DancheongBar(height: 16),
                  const SizedBox(height: 20),
                  _sectionLabel(l10n.settings),
                  _menuItem(
                    icon: Icons.notifications_outlined,
                    label: l10n.notificationSettings,
                    onTap: () => _showNotificationsSheet(context),
                  ),
                  _menuItem(
                    icon: Icons.language,
                    label: l10n.languageSettings,
                    onTap: () => _showLanguageSheet(context),
                    trailing: Consumer<LocaleProvider>(
                      builder: (_, lp, __) => Text(
                        lp.locale.languageCode == 'ko' ? '한국어' : 'English',
                        style: const TextStyle(fontSize: 13, color: kTextMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel(l10n.support),
                  _menuItem(
                    icon: Icons.help_outline,
                    label: l10n.help,
                    onTap: () => _showHelpSheet(context),
                  ),
                  _menuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.privacyPolicy,
                    onTap: () => _showPolicySheet(context, _PolicyType.privacy),
                  ),
                  _menuItem(
                    icon: Icons.description_outlined,
                    label: l10n.termsOfService,
                    onTap: () => _showPolicySheet(context, _PolicyType.terms),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: kCosmicNavy.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: kGlassBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.languageSettings,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
            const SizedBox(height: 20),
            _languageOption(
              context: context,
              provider: localeProvider,
              code: 'ko',
              label: '한국어',
              sublabel: 'Korean',
            ),
            const SizedBox(height: 10),
            _languageOption(
              context: context,
              provider: localeProvider,
              code: 'en',
              label: 'English',
              sublabel: '영어',
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption({
    required BuildContext context,
    required LocaleProvider provider,
    required String code,
    required String label,
    required String sublabel,
  }) {
    final selected = provider.locale.languageCode == code;
    return GestureDetector(
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kGold.withOpacity(0.15) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kGold.withOpacity(0.6) : kGlassBorder,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? kGold : kDark,
                    )),
                  Text(sublabel,
                    style: const TextStyle(fontSize: 12, color: kTextMuted)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: kGold, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPolicySheet(BuildContext context, _PolicyType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PolicySheet(type: type),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HelpSheet(),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NotificationsSheet(),
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
    Widget? trailing,
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
                  Icon(icon, size: 20, color: kTextMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                      style: const TextStyle(fontSize: 15, color: kDark, fontWeight: FontWeight.w400)),
                  ),
                  if (trailing != null) ...[trailing, const SizedBox(width: 4)],
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

enum _PolicyType { privacy, terms }

class _PolicySheet extends StatelessWidget {
  final _PolicyType type;
  const _PolicySheet({required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPrivacy = type == _PolicyType.privacy;
    final title = isPrivacy ? l10n.privacyPolicy : l10n.termsOfService;
    final content = isPrivacy ? _privacyContent : _termsContent;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: kGlassBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                    IconButton(
                      icon: const Icon(Icons.close, color: kTextMuted, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: kGlassBorder, height: 1),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13, color: kTextMuted, height: 1.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _privacyContent = '''
최종 수정일: 2025년 1월 1일

사주 앱(이하 "회사")은 이용자의 개인정보를 중요하게 생각하며, 「개인정보 보호법」 및 관련 법령을 준수합니다.

■ 수집하는 개인정보 항목
- 필수: 이메일 주소, 비밀번호(암호화 저장)
- 선택: 이름, 생년월일, 출생시간, 성별

■ 개인정보 수집 및 이용 목적
- 서비스 제공 및 회원 관리
- 사주 분석 및 AI 해석 서비스 제공
- 서비스 개선 및 통계 분석

■ 개인정보 보유 및 이용 기간
- 회원 탈퇴 시까지 보유
- 관련 법령에 따라 일정 기간 보존이 필요한 경우 해당 기간 동안 보관

■ 개인정보의 제3자 제공
회사는 이용자의 동의 없이 개인정보를 제3자에게 제공하지 않습니다. 다만, 법령에 의거하거나 수사 목적으로 관계기관의 요청이 있는 경우는 예외로 합니다.

■ 개인정보 처리 위탁
회사는 서비스 제공을 위해 아래와 같이 개인정보를 위탁합니다.
- Supabase Inc.: 데이터베이스 및 인증 서비스
- Anthropic Inc.: AI 분석 서비스(개인 식별 정보 미포함)

■ 이용자의 권리
이용자는 언제든지 자신의 개인정보를 조회, 수정, 삭제, 처리 정지를 요청할 수 있습니다.

■ 개인정보 보호책임자
이메일: privacy@saju-app.com

■ 고지 의무
본 방침이 변경되는 경우 앱 내 공지를 통해 사전 안내드립니다.''';

  static const _termsContent = '''
최종 수정일: 2025년 1월 1일

사주 앱 서비스 이용약관에 오신 것을 환영합니다.

■ 제1조 (목적)
본 약관은 사주 앱(이하 "서비스")의 이용 조건 및 절차, 회사와 이용자의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

■ 제2조 (서비스 내용)
- AI 기반 사주 해석 서비스
- 생활 이벤트 기록 및 운세 분석
- 궁합 분석 서비스
- 기타 회사가 정하는 부가 서비스

■ 제3조 (회원가입 및 이용)
- 이용자는 약관에 동의하고 회원가입 절차를 완료함으로써 서비스를 이용할 수 있습니다.
- 만 14세 미만은 서비스를 이용할 수 없습니다.
- 타인의 정보를 도용하여 가입하는 행위는 금지됩니다.

■ 제4조 (서비스 이용 제한)
다음에 해당하는 경우 서비스 이용이 제한될 수 있습니다.
- 타인의 명예를 훼손하거나 불이익을 주는 행위
- 서비스 운영을 방해하는 행위
- 기타 관련 법령에 위반되는 행위

■ 제5조 (유료 서비스)
- 유료 서비스 결제는 앱 내 안내에 따릅니다.
- 환불은 관련 법령 및 회사 환불 정책에 따릅니다.

■ 제6조 (면책사항)
- 서비스에서 제공하는 사주 해석은 참고용이며, 중요한 결정의 유일한 근거로 삼지 않을 것을 권장합니다.
- 천재지변, 시스템 장애 등 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.

■ 제7조 (약관 변경)
회사는 필요한 경우 약관을 변경할 수 있으며, 변경 시 앱 내 공지를 통해 사전 안내드립니다.

■ 문의
이메일: support@saju-app.com''';
}

class _HelpSection {
  final String title;
  final String body;
  const _HelpSection(this.title, this.body);
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEn = l10n.locale.languageCode == 'en';
    final categories = [
      (l10n.helpCategoryTheory, isEn ? _theoryEn : _theoryKo),
      (l10n.helpCategoryUsage, isEn ? _usageEn : _usageKo),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: kGlassBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.howToReadSaju,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                    IconButton(
                      icon: const Icon(Icons.close, color: kTextMuted, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: kGlassBorder, height: 1),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < categories.length; c++) ...[
                    if (c > 0) ...[
                      const SizedBox(height: 28),
                      Container(height: 1, color: kGlassBorder),
                      const SizedBox(height: 22),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kGold.withOpacity(0.35), width: 0.5),
                      ),
                      child: Text(
                        categories[c].$1,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: kGold, letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < categories[c].$2.length; i++) ...[
                      if (i > 0) const SizedBox(height: 22),
                      Text(
                        categories[c].$2[i].title,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: kDark, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categories[c].$2[i].body,
                        style: const TextStyle(
                          fontSize: 13, color: kTextMuted, height: 1.8),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _theoryKo = <_HelpSection>[
    _HelpSection(
      '사주(四柱)란?',
      '사주는 태어난 연·월·일·시를 각각 두 글자씩 조합해 만든 여덟 글자의 명식(命式)이에요. 이 여덟 글자로 타고난 성격과 기질, 인생의 큰 흐름을 읽는 동양의 전통 명리학입니다.',
    ),
    _HelpSection(
      '사주표의 네 기둥',
      '사주표는 네 개의 기둥(四柱)으로 이루어져 있어요.\n'
      '• 연주(年柱): 태어난 해 — 어린 시절 환경, 조상과의 인연\n'
      '• 월주(月柱): 태어난 달 — 부모·형제, 20~40대 사회생활\n'
      '• 일주(日柱): 태어난 날 — 나 자신과 배우자와의 관계\n'
      '• 시주(時柱): 태어난 시간 — 자식과 노년기의 흐름\n\n'
      '각 기둥은 위쪽에 천간(天干), 아래쪽에 지지(地支) 한 글자씩, 총 두 글자로 구성돼요.',
    ),
    _HelpSection(
      '오행(五行)',
      '우주의 기운을 목(木)·화(火)·토(土)·금(金)·수(水) 다섯 가지로 나눈 것으로, 각 글자가 어떤 오행에 속하는지에 따라 성격과 기운이 결정돼요.\n'
      '• 목(木): 성장 · 창의 · 인자\n'
      '• 화(火): 열정 · 예의 · 지혜\n'
      '• 토(土): 신용 · 안정 · 포용\n'
      '• 금(金): 의리 · 결단 · 정의\n'
      '• 수(水): 지혜 · 유연 · 지모',
    ),
    _HelpSection(
      '십성(十星)',
      '일주의 천간(=나)을 기준으로 다른 글자들과의 관계를 10가지로 나눈 개념이에요. 비견·겁재(같은 기운), 식신·상관(내가 키우는 기운), 편재·정재(내가 다스리는 재물), 편관·정관(나를 이끄는 기운), 편인·정인(나를 키우는 기운)이 각각 재물·직업·인간관계·명예 등을 나타냅니다.',
    ),
    _HelpSection(
      '12운성',
      '내 기운이 각 지지에서 얼마나 강한지를 12단계로 표현해요. 장생(태어남) → 목욕 → 관대 → 건록 → 제왕(전성기) → 쇠 → 병 → 사 → 묘 → 절 → 태 → 양의 순환으로, 사람의 일생에 비유한 에너지 흐름이에요.',
    ),
    _HelpSection(
      '대운(大運)',
      '10년 단위로 바뀌는 큰 운의 흐름이에요. 인생의 어느 시기에 어떤 오행·십성의 기운이 들어오는지 보여주며, 사주 원국과 맞물려 운의 방향을 결정합니다.',
    ),
    _HelpSection(
      '앱 사용 팁',
      '• 사주 탭의 글자를 탭하면 각 글자의 뜻과 설명을 볼 수 있어요.\n'
      '• 오행 분포 카드에서 내 기운이 어느 방향에 쏠려 있는지 확인하세요.\n'
      '• 해석 탭의 "해석 생성"을 누르면 Claude AI가 사주 전체를 분석해드려요.\n'
      '• 이벤트 탭에 인생의 주요 사건을 기록하면 AI 해석이 더 정확해집니다.\n'
      '• AI 상담 버튼으로 언제든 내 사주에 대해 질문할 수 있어요.',
    ),
    _HelpSection(
      '참고',
      '사주 해석은 인생의 힌트이자 참고 자료예요. 중요한 결정을 내릴 때는 사주뿐만 아니라 현실적인 조건과 자신의 판단을 함께 고려해주세요.',
    ),
  ];

  static const _usageKo = <_HelpSection>[
    _HelpSection(
      '홈 화면',
      '• 상단의 프로필 카드를 탭하면 해당 사주의 상세 분석으로 이동해요.\n'
      '• 카드를 길게 눌러 드래그하면 순서를 바꿀 수 있어요.\n'
      '• "+ 프로필 추가" 버튼으로 가족·친구의 사주를 등록할 수 있습니다.\n'
      '• 좌측 상단 메뉴 버튼(☰)으로 사이드바를 열어 궁합·상담·마이페이지로 이동하세요.',
    ),
    _HelpSection(
      '프로필 상세 — 사주 탭',
      '• 화면 상단의 정보 카드에서 생년월일, 띠, 일주를 확인할 수 있어요.\n'
      '• 사주표의 각 글자(천간·지지·십성·지장간·12운성)를 탭하면 뜻과 설명 모달이 열립니다.\n'
      '• 행/열 라벨(천간·지지·시주·일주 등)을 탭해도 개념 설명을 볼 수 있어요.\n'
      '• 오행 분포 카드에서 내 기운(목·화·토·금·수)의 균형을 확인하세요.\n'
      '• 대운 타임라인을 좌우로 스크롤하면 10년 단위 운의 흐름과 현재 대운이 빨간 "현재" 뱃지로 표시돼요.',
    ),
    _HelpSection(
      '프로필 상세 — 해석 탭',
      '• "해석 생성" 버튼을 누르면 Claude AI가 성격·직업·건강·재물·인간관계 등을 섹션별로 분석해드려요.\n'
      '• 생성에는 토큰이 소모되며 보통 1~2분 정도 걸립니다.\n'
      '• 한 번 생성한 해석은 계속 다시 볼 수 있고, 필요하면 재생성할 수도 있어요.',
    ),
    _HelpSection(
      '프로필 상세 — 이벤트 탭',
      '• 우측 하단 + 버튼으로 인생의 주요 사건(결혼·이직·사고·이사 등)을 기록하세요.\n'
      '• 연도·월, 제목, 내용, 영향도(매우 긍정 ~ 매우 부정)를 입력합니다.\n'
      '• 등록한 이벤트를 탭하면 상세 보기가 열리고, 거기서 수정·삭제가 가능해요.\n'
      '• 이벤트가 많을수록 AI 해석이 실제 인생 흐름에 맞춰 더 정확해집니다.',
    ),
    _HelpSection(
      'AI 사주상담',
      '• 프로필 상세 화면 하단의 "AI 사주상담" 버튼을 눌러 대화를 시작하세요.\n'
      '• 추천 질문(올해 운세, 직업 적성, 연애운)을 탭하면 빠르게 시작할 수 있어요.\n'
      '• 상단의 채팅 기록에서 이전 대화를 다시 열 수 있습니다.\n'
      '• 새 채팅은 + 버튼으로 시작하며, 각 메시지마다 토큰이 소모돼요.',
    ),
    _HelpSection(
      '궁합 분석',
      '• 사이드바의 "궁합 분석"으로 이동해 두 개의 프로필을 선택하세요.\n'
      '• 궁합 유형(연애·결혼·사업·우정)에 따라 해석 관점이 달라져요.\n'
      '• "궁합 분석 시작"을 누르면 AI가 두 사주의 조합을 분석합니다.\n'
      '• 결과는 분석 기록에 저장되어 언제든 다시 열 수 있어요.',
    ),
    _HelpSection(
      '마이페이지 · 설정',
      '• 마이페이지에서 내 이름, 이메일, 플랜, 토큰 잔량을 확인할 수 있어요.\n'
      '• "업그레이드" 버튼으로 유료 플랜을 구독하면 토큰을 더 많이 받을 수 있어요.\n'
      '• 설정에서 알림 설정과 언어(한국어/English)를 변경할 수 있습니다.\n'
      '• 개인정보 처리방침과 이용약관도 설정 화면에서 확인할 수 있어요.',
    ),
  ];

  static const _theoryEn = <_HelpSection>[
    _HelpSection(
      'What is Saju?',
      'Saju is an eight-character chart built from the year, month, day, and hour of your birth — two characters per pillar. In East Asian fortune-telling, these eight characters reveal your innate personality, temperament, and the broad flow of your life.',
    ),
    _HelpSection(
      'The Four Pillars',
      'Your chart has four pillars (四柱):\n'
      '• Year Pillar (年柱): birth year — childhood environment and ancestral ties\n'
      '• Month Pillar (月柱): birth month — parents, siblings, life in your 20s–40s\n'
      '• Day Pillar (日柱): birth day — yourself and your bond with a spouse\n'
      '• Hour Pillar (時柱): birth hour — children and later years\n\n'
      'Each pillar holds one Heavenly Stem (天干) on top and one Earthly Branch (地支) below.',
    ),
    _HelpSection(
      'Five Elements (五行)',
      'The universe\'s energies are divided into Wood, Fire, Earth, Metal, and Water. Each character in the chart belongs to one of them, shaping your nature.\n'
      '• Wood: Growth · Creativity · Benevolence\n'
      '• Fire: Passion · Etiquette · Wisdom\n'
      '• Earth: Trust · Stability · Tolerance\n'
      '• Metal: Loyalty · Resolve · Justice\n'
      '• Water: Wisdom · Flexibility · Insight',
    ),
    _HelpSection(
      'Ten Gods (十星)',
      'Using the Day Master (the top character of the Day Pillar — "you") as reference, the other characters are grouped into ten relationships: Bi Jian / Jie Cai (same energy), Shi Shen / Shang Guan (energy you nurture), Pian Cai / Zheng Cai (wealth you govern), Pian Guan / Zheng Guan (energy guiding you), and Pian Yin / Zheng Yin (energy raising you). Each maps to wealth, career, relationships, or honor.',
    ),
    _HelpSection(
      'Twelve Fortune Stages',
      'Shows how strong your energy is at each Branch through 12 stages: Chang Sheng (birth) → Mu Yu → Guan Dai → Jian Lu → Di Wang (prime) → Shuai → Bing → Si → Mu → Jue → Tai → Yang. It is the flow of energy compared to a human life.',
    ),
    _HelpSection(
      'Major Luck (大運)',
      'A 10-year cycle of overarching fortune. It reveals which elemental and ten-god energies enter your life at each stage, and how they interact with your natal chart to steer the direction of your luck.',
    ),
    _HelpSection(
      'Tips for Using the App',
      '• Tap any character on the Saju tab to see its meaning and description.\n'
      '• Check the Five Elements card to see where your energy is concentrated.\n'
      '• Tap "Generate Reading" on the Reading tab and Claude AI will analyze your full chart.\n'
      '• Recording important life events on the Events tab makes AI readings more accurate.\n'
      '• Use the AI Consultation button any time to ask questions about your chart.',
    ),
    _HelpSection(
      'A Note',
      'Saju readings are hints and references for life, not the final word. When making important decisions, weigh your chart alongside real-world circumstances and your own judgment.',
    ),
  ];

  static const _usageEn = <_HelpSection>[
    _HelpSection(
      'Home Screen',
      '• Tap a profile card at the top to open its detailed Saju analysis.\n'
      '• Long-press and drag a card to change its order.\n'
      '• Use "+ Add Profile" to register charts for family or friends.\n'
      '• Open the sidebar with the menu button (☰) at the top-left to reach Compatibility, Consultation, and My Page.',
    ),
    _HelpSection(
      'Profile Detail — Saju Tab',
      '• The info card at the top shows date of birth, zodiac animal, and Day Pillar.\n'
      '• Tap any character in the chart (Stems, Branches, Ten Gods, Hidden Stems, 12 Stages) to open a meaning modal.\n'
      '• You can also tap row/column labels (Stem, Branch, Hour, Day, etc.) to see the concept explained.\n'
      '• The Five Elements card shows how your Wood/Fire/Earth/Metal/Water energies balance out.\n'
      '• Scroll the Major Luck timeline horizontally to see 10-year cycles; the current cycle is marked with a red "Current" badge.',
    ),
    _HelpSection(
      'Profile Detail — Reading Tab',
      '• Tap "Generate Reading" and Claude AI will analyze your personality, career, health, wealth, and relationships section by section.\n'
      '• Generation uses tokens and usually takes 1–2 minutes.\n'
      '• Once generated, the reading stays available and can be regenerated when you want a fresh take.',
    ),
    _HelpSection(
      'Profile Detail — Events Tab',
      '• Use the + button at the bottom-right to record major life events (marriage, new job, accident, moving, etc.).\n'
      '• Enter year/month, title, description, and impact (Very Positive to Very Negative).\n'
      '• Tap an event to open details — you can edit or delete it from there.\n'
      '• The more events you record, the more accurately the AI reading can match the actual flow of your life.',
    ),
    _HelpSection(
      'AI Consultation',
      '• Tap the "AI Consultation" button at the bottom of the profile detail to start a chat.\n'
      '• Tap a suggested question (this year\'s fortune, career fit, love outlook) for a quick start.\n'
      '• Open past chats from the list at the top.\n'
      '• Start a new chat with the + button. Each message consumes tokens.',
    ),
    _HelpSection(
      'Compatibility',
      '• Open "Compatibility" from the sidebar and pick two profiles.\n'
      '• Choose a type (Romance, Marriage, Business, Friendship) — each gives a different angle of reading.\n'
      '• Tap "Start Analysis" and the AI will analyze how the two charts work together.\n'
      '• Results are saved to your history and can be reopened any time.',
    ),
    _HelpSection(
      'My Page · Settings',
      '• My Page shows your name, email, plan, and remaining tokens.\n'
      '• Tap "Upgrade" to subscribe to a paid plan for more tokens.\n'
      '• In Settings, adjust notifications and language (Korean / English).\n'
      '• You can also review the Privacy Policy and Terms of Service from Settings.',
    ),
  ];
}

/// 알림 채널 / Notification delivery channel
enum _NotifChannel { off, push, email, both }

extension on _NotifChannel {
  String get storageKey => switch (this) {
        _NotifChannel.off => 'off',
        _NotifChannel.push => 'push',
        _NotifChannel.email => 'email',
        _NotifChannel.both => 'both',
      };

  String get label => switch (this) {
        _NotifChannel.off => '끄기',
        _NotifChannel.push => '푸시',
        _NotifChannel.email => '이메일',
        _NotifChannel.both => '모두',
      };

  IconData get icon => switch (this) {
        _NotifChannel.off => Icons.notifications_off_outlined,
        _NotifChannel.push => Icons.notifications_active_outlined,
        _NotifChannel.email => Icons.mail_outline,
        _NotifChannel.both => Icons.all_inclusive,
      };
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  static const _eventKey = 'notif.event_channel';
  static const _fortuneKey = 'notif.fortune_channel';

  _NotifChannel _event = _NotifChannel.push;
  _NotifChannel _fortune = _NotifChannel.push;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _event = _NotifChannelExt.fromStorage(prefs.getString(_eventKey));
      _fortune = _NotifChannelExt.fromStorage(prefs.getString(_fortuneKey));
      _loading = false;
    });
  }

  Future<void> _setEvent(_NotifChannel v) async {
    setState(() => _event = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventKey, v.storageKey);
  }

  Future<void> _setFortune(_NotifChannel v) async {
    setState(() => _fortune = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fortuneKey, v.storageKey);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kGlassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '알림 설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: kGold)),
              )
            else ...[
              _ReminderCard(
                icon: Icons.edit_note,
                time: '오후 8:00',
                title: '오늘 하루 어땠나요?',
                subtitle: '저녁 8시에 오늘의 이벤트를 작성하도록 알려드려요.',
                current: _event,
                onChanged: _setEvent,
              ),
              const SizedBox(height: 12),
              _ReminderCard(
                icon: Icons.wb_sunny_outlined,
                time: '오전 9:30',
                title: '오늘의 운세',
                subtitle: '아침 9시 30분에 오늘의 운세를 알려드려요.',
                current: _fortune,
                onChanged: _setFortune,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _NotifChannelExt on _NotifChannel {
  static _NotifChannel fromStorage(String? v) {
    switch (v) {
      case 'push': return _NotifChannel.push;
      case 'email': return _NotifChannel.email;
      case 'both': return _NotifChannel.both;
      default: return _NotifChannel.off;
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final String time;
  final String title;
  final String subtitle;
  final _NotifChannel current;
  final ValueChanged<_NotifChannel> onChanged;

  const _ReminderCard({
    required this.icon,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGlassBorder, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: kGold.withOpacity(0.3), width: 0.6),
                ),
                child: Icon(icon, size: 16, color: kGold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: kTextMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _NotifChannel.values
                .map((c) => _ChannelChip(
                      channel: c,
                      selected: current == c,
                      onTap: () => onChanged(c),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final _NotifChannel channel;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelChip({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOff = channel == _NotifChannel.off;
    final activeColor = isOff ? kErrorColor : kGold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.14) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.6) : kGlassBorder,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              channel.icon,
              size: 14,
              color: selected ? activeColor : kTextMuted,
            ),
            const SizedBox(width: 6),
            Text(
              channel.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? activeColor : kDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
