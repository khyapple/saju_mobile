import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';

/// 개인정보 처리방침 / 서비스 이용약관 바텀시트에서 표시할 문서 종류
enum PolicyType { privacy, terms }

/// 약관 전문 바텀시트. `showModalBottomSheet`의 builder에서 사용하세요.
class PolicySheet extends StatelessWidget {
  final PolicyType type;
  const PolicySheet({super.key, required this.type});

  /// 편의 메서드: bottom sheet로 열기.
  static Future<void> show(BuildContext context, PolicyType type) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PolicySheet(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPrivacy = type == PolicyType.privacy;
    final isEn = l10n.locale.languageCode == 'en';
    final title = isPrivacy ? l10n.privacyPolicy : l10n.termsOfService;
    final content = isPrivacy
        ? (isEn ? _privacyContentEn : _privacyContentKo)
        : (isEn ? _termsContentEn : _termsContentKo);

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

  static const _privacyContentKo = '''
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

  static const _privacyContentEn = '''
Last updated: January 1, 2025

The Saju app (the "Company") values your privacy and complies with the Personal Information Protection Act and related regulations.

■ Information We Collect
- Required: email address, password (stored encrypted)
- Optional: name, date of birth, time of birth, gender

■ Purpose of Collection and Use
- Providing services and managing membership
- Delivering Saju analysis and AI readings
- Improving the service and statistical analysis

■ Retention Period
- Retained until the account is deleted
- Retained for the period required by applicable law, where longer retention is mandated

■ Disclosure to Third Parties
The Company does not provide personal information to third parties without your consent, except when required by law or when requested by investigative authorities under legal procedures.

■ Processing Entrustment
For service delivery, personal information is entrusted as follows:
- Supabase Inc.: database and authentication services
- Anthropic Inc.: AI analysis services (no personally identifying information is shared)

■ Your Rights
You may at any time request access to, correction of, deletion of, or suspension of processing of your personal information.

■ Privacy Officer
Email: privacy@saju-app.com

■ Notice of Changes
Any changes to this policy will be announced in-app in advance.''';

  static const _termsContentKo = '''
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

  static const _termsContentEn = '''
Last updated: January 1, 2025

Welcome to the Saju app Terms of Service.

■ Article 1 (Purpose)
These Terms govern the conditions and procedures for using the Saju app (the "Service"), and the rights, obligations, and responsibilities of the Company and users.

■ Article 2 (Service Description)
- AI-based Saju reading service
- Life-event logging and fortune analysis
- Compatibility analysis
- Other additional services provided by the Company

■ Article 3 (Registration and Use)
- Users may use the Service by agreeing to these Terms and completing registration.
- Users under 14 years of age are not permitted to use the Service.
- Registering using another person's information is prohibited.

■ Article 4 (Restrictions on Use)
Use of the Service may be restricted in the following cases:
- Defaming others or causing harm to them
- Interfering with the operation of the Service
- Any other act that violates applicable law

■ Article 5 (Paid Services)
- Payments follow the in-app guidance.
- Refunds are handled in accordance with applicable law and the Company's refund policy.

■ Article 6 (Disclaimer)
- Saju readings provided by the Service are for reference only and should not be the sole basis for important decisions.
- The Company is not liable for service interruptions caused by force majeure, system failure, or other causes beyond its control.

■ Article 7 (Changes to Terms)
The Company may change these Terms when necessary, and will announce any changes in-app in advance.

■ Contact
Email: support@saju-app.com''';
}
