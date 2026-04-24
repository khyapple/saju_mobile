import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)
        ?? const AppLocalizations(Locale('ko'));
  }

  static const delegate = _AppLocalizationsDelegate();

  String _t(String key) =>
      (_strings[locale.languageCode] ?? _strings['ko']!)[key] ?? _strings['ko']![key] ?? key;

  // ─── App ──────────────────────────────────────────────────────
  String get appTitle => _t('appTitle');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get save => _t('save');
  String get add => _t('add');
  String get edit => _t('edit');
  String get confirm => _t('confirm');
  String get retry => _t('retry');
  String get close => _t('close');
  String get done => _t('done');
  String get unknown => _t('unknown');
  String get optional => _t('optional');
  String get current => _t('current');
  String get justNow => _t('justNow');
  String minutesAgo(int n) => _t('minutesAgo').replaceAll('{n}', '$n');
  String hoursAgo(int n) => _t('hoursAgo').replaceAll('{n}', '$n');
  String daysAgo(int n) => _t('daysAgo').replaceAll('{n}', '$n');

  // ─── Auth ─────────────────────────────────────────────────────
  String get login => _t('login');
  String get logout => _t('logout');
  String get logoutConfirm => _t('logoutConfirm');
  String get signup => _t('signup');
  String get next => _t('next');
  String get email => _t('email');
  String get password => _t('password');
  String get passwordHint => _t('passwordHint');
  String get passwordConfirm => _t('passwordConfirm');
  String get passwordConfirmHint => _t('passwordConfirmHint');
  String get passwordMismatch => _t('passwordMismatch');
  String get forgotPassword => _t('forgotPassword');
  String get forgotPasswordDesc => _t('forgotPasswordDesc');
  String get send => _t('send');
  String get name => _t('name');
  String get nameHint => _t('nameHint');
  String get nameRequired => _t('nameRequired');
  String get orContinueWith => _t('orContinueWith');
  String get continueWithGoogle => _t('continueWithGoogle');
  String get continueWithApple => _t('continueWithApple');
  String get continueWithFacebook => _t('continueWithFacebook');
  String get noAccount => _t('noAccount');
  String get hasAccount => _t('hasAccount');
  String get aiSajuAnalysis => _t('aiSajuAnalysis');
  String get startAiAnalysis => _t('startAiAnalysis');
  String get checkYourEmail => _t('checkYourEmail');
  String get confirmLinkSent => _t('confirmLinkSent');
  String get confirmLinkDesc => _t('confirmLinkDesc');
  String get checkSpam => _t('checkSpam');
  String get alreadyConfirmed => _t('alreadyConfirmed');
  String get passwordWeak => _t('passwordWeak');
  String get passwordFair => _t('passwordFair');
  String get passwordStrong => _t('passwordStrong');
  String get passwordVeryStrong => _t('passwordVeryStrong');
  String get passwordMinLength => _t('passwordMinLength');
  String get passwordTooShort => _t('passwordTooShort');
  String get passwordRequired => _t('passwordRequired');
  String get passwordConfirmRequired => _t('passwordConfirmRequired');
  String get checkDuplicate => _t('checkDuplicate');
  String get checkingEmail => _t('checkingEmail');
  String get emailAvailable => _t('emailAvailable');
  String get checkEmailFirst => _t('checkEmailFirst');
  String get emailCheckUnavailable => _t('emailCheckUnavailable');
  String get agreeToTerms => _t('agreeToTerms');
  /// RichText template for agree-to-terms with {terms} and {privacy} placeholders.
  /// ko: "{terms} 및 {privacy}에 동의합니다"
  /// en: "I agree to the {terms} and {privacy}"
  String get agreeToTermsTemplate => _t('agreeToTermsTemplate');
  String get termsRequired => _t('termsRequired');
  String get emailAlreadyUsed => _t('emailAlreadyUsed');
  String get emailRateLimit => _t('emailRateLimit');
  String get signupFailed => _t('signupFailed');
  String get loginFailed => _t('loginFailed');
  String get socialLoginFailed => _t('socialLoginFailed');
  String get resetEmailSent => _t('resetEmailSent');
  String get resetEmailFailed => _t('resetEmailFailed');

  // ─── Account / Settings ───────────────────────────────────────
  String get myPage => _t('myPage');
  String get editProfile => _t('editProfile');
  String get changeId => _t('changeId');
  String get changePassword => _t('changePassword');
  String get currentEmail => _t('currentEmail');
  String get newEmail => _t('newEmail');
  String get newEmailHint => _t('newEmailHint');
  String get newPassword => _t('newPassword');
  String get newPasswordHint => _t('newPasswordHint');
  String get confirmNewPassword => _t('confirmNewPassword');
  String get emailChangeConfirmSent => _t('emailChangeConfirmSent');
  String get passwordChangeSuccess => _t('passwordChangeSuccess');
  String get emailChangeFailed => _t('emailChangeFailed');
  String get passwordChangeFailed => _t('passwordChangeFailed');
  String get emailRequired => _t('emailRequired');
  String get invalidEmail => _t('invalidEmail');
  String get sameAsCurrentEmail => _t('sameAsCurrentEmail');
  String get currentPassword => _t('currentPassword');
  String get currentPasswordHint => _t('currentPasswordHint');
  String get currentPasswordRequired => _t('currentPasswordRequired');
  String get currentPasswordWrong => _t('currentPasswordWrong');
  String get upgrade => _t('upgrade');
  String get tokenUsage => _t('tokenUsage');
  String tokensRemaining(int n) => _t('tokensRemaining').replaceAll('{n}', '$n');
  String tokenUsageOf(int used, int total) =>
      _t('tokenUsageOf').replaceAll('{used}', '$used').replaceAll('{total}', '$total');
  String get planFree => _t('planFree');
  String get planBasic => _t('planBasic');
  String get planPro => _t('planPro');
  String get planUltimate => _t('planUltimate');
  String get planPlus => _t('planPlus');
  String get selectPlan => _t('selectPlan');
  String get currentPlanBadge => _t('currentPlanBadge');
  String get selectThisPlan => _t('selectThisPlan');
  String get priceFreeLabel => _t('priceFreeLabel');
  String pricePerMonth(String price) => _t('pricePerMonth').replaceAll('{price}', price);
  List<String> planFeatures(String plan) {
    final isKo = locale.languageCode == 'ko';
    switch (plan) {
      case 'basic':
        return isKo
            ? ['AI 사주 상담 해금', '프로필 5개 저장', '월 100,000 토큰', '궁합 분석 기본']
            : ['Unlock AI Saju consultation', 'Store up to 5 profiles', '100,000 tokens/month', 'Basic compatibility analysis'];
      case 'plus':
        return isKo
            ? ['무제한 AI 사주 상담', '프로필 무제한', '무제한 토큰', '심화 궁합 분석', '이벤트 타로 해석', '우선 고객 지원']
            : ['Unlimited AI consultation', 'Unlimited profiles', 'Unlimited tokens', 'Advanced compatibility', 'Event tarot reading', 'Priority support'];
      default:
        return isKo
            ? ['기본 사주 분석', '프로필 1개 저장', '월 10,000 토큰']
            : ['Basic Saju analysis', '1 profile slot', '10,000 tokens/month'];
    }
  }
  String get settings => _t('settings');
  String get notificationSettings => _t('notificationSettings');
  String get languageSettings => _t('languageSettings');
  String get support => _t('support');
  String get help => _t('help');
  String get howToReadSaju => _t('howToReadSaju');
  String get helpCategoryTheory => _t('helpCategoryTheory');
  String get helpCategoryUsage => _t('helpCategoryUsage');
  String get privacyPolicy => _t('privacyPolicy');
  String get termsOfService => _t('termsOfService');

  // ─── Notifications Sheet ──────────────────────────────────────
  String get notifReminderEventTime => _t('notifReminderEventTime');
  String get notifReminderEventTitle => _t('notifReminderEventTitle');
  String get notifReminderEventSubtitle => _t('notifReminderEventSubtitle');
  String get notifReminderFortuneTime => _t('notifReminderFortuneTime');
  String get notifReminderFortuneTitle => _t('notifReminderFortuneTitle');
  String get notifReminderFortuneSubtitle => _t('notifReminderFortuneSubtitle');
  String get notifChannelOff => _t('notifChannelOff');
  String get notifChannelPush => _t('notifChannelPush');
  String get notifChannelEmail => _t('notifChannelEmail');
  String get notifChannelBoth => _t('notifChannelBoth');

  // ─── Birth hours & date formatting ─────────────────────────────

  /// 12 Earthly-Branch hours as (name, shortRange, value).
  /// e.g. Korean: ('자시', '23~01시', '23'); English: ('Rat', '23:00–01:00', '23').
  List<(String, String, String)> get birthHourList =>
      locale.languageCode == 'en' ? _birthHoursEn : _birthHoursKo;

  /// Long-form range like '23:00~01:00' (ko) or '23:00–01:00' (en).
  String _hourRangeLong(String value) {
    final i = int.tryParse(value);
    if (i == null) return '';
    final end = (i + 2) % 24;
    String pad(int v) => v.toString().padLeft(2, '0');
    final dash = locale.languageCode == 'en' ? '–' : '~';
    return '${pad(i)}:00$dash${pad(end)}:00';
  }

  /// Display like "자시 (23:00~01:00)" (ko) or "Rat (23:00–01:00)" (en).
  /// Returns null if no matching hour is found.
  String? birthHourDisplay(String? hourValue) {
    if (hourValue == null) return null;
    final padded = hourValue.padLeft(2, '0');
    for (final h in birthHourList) {
      if (h.$3 == padded) return '${h.$1} (${_hourRangeLong(padded)})';
    }
    return null;
  }

  /// Format (year, month, day) — "1990년 5월 12일" (ko) / "May 12, 1990" (en).
  String formatBirthDate(int year, int month, int day) {
    if (locale.languageCode == 'en') {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final m = (month >= 1 && month <= 12) ? months[month - 1] : '$month';
      return '$m $day, $year';
    }
    return '$year년 $month월 $day일';
  }

  /// Same as [formatBirthDate] but takes an ISO `YYYY-MM-DD` string.
  String formatBirthDateIso(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return iso;
    return formatBirthDate(y, m, d);
  }

  /// "19시생" (ko) / "Born at 19:00" (en).
  String bornAtHour(String hour) {
    if (locale.languageCode == 'en') return 'Born at $hour:00';
    return '$hour시생';
  }

  /// Empty date placeholder, e.g. when birth date is missing.
  String get noBirthDate => _t('noBirthDate');

  // ─── Onboarding ───────────────────────────────────────────────
  String get onboardingTagline => _t('onboardingTagline');
  String get onboardingFeatureCalcTitle => _t('onboardingFeatureCalcTitle');
  String get onboardingFeatureCalcDesc => _t('onboardingFeatureCalcDesc');
  String get onboardingFeatureAiTitle => _t('onboardingFeatureAiTitle');
  String get onboardingFeatureAiDesc => _t('onboardingFeatureAiDesc');
  String get onboardingFeatureElementsTitle => _t('onboardingFeatureElementsTitle');
  String get onboardingFeatureElementsDesc => _t('onboardingFeatureElementsDesc');
  String get getStarted => _t('getStarted');
  String get basicInfo => _t('basicInfo');
  String get basicInfoDesc => _t('basicInfoDesc');
  String get knowExactly => _t('knowExactly');
  String get knowRoughly => _t('knowRoughly');
  String get startAnalysisAction => _t('startAnalysisAction');

  // ─── Profiles ─────────────────────────────────────────────────
  String helloUser(String name) => _t('helloUser').replaceAll('{name}', name);
  String get mySajuProfile => _t('mySajuProfile');
  String get addProfile => _t('addProfile');
  String get profileDetail => _t('profileDetail');
  String get loadProfileFailed => _t('loadProfileFailed');
  String get noChartData => _t('noChartData');
  String get dragToReorder => _t('dragToReorder');
  String get mySaju => _t('mySaju');
  String get timeUnknown => _t('timeUnknown');
  String get birthHour => _t('birthHour');
  String get birthDate => _t('birthDate');
  String get selectBirthDate => _t('selectBirthDate');
  String get gender => _t('gender');
  String get male => _t('male');
  String get female => _t('female');
  String get calendarType => _t('calendarType');
  String get solar => _t('solar');
  String get lunar => _t('lunar');
  String get relationship => _t('relationship');
  String get relationshipHint => _t('relationshipHint');
  String get addProfileDesc => _t('addProfileDesc');
  String get birthDateRequired => _t('birthDateRequired');
  String get createProfileFailed => _t('createProfileFailed');
  String get selectDate => _t('selectDate');
  String get year => _t('year');
  String get month => _t('month');
  String get day => _t('day');
  String get exactly => _t('exactly');
  String get approximately => _t('approximately');
  String get deleteProfile => _t('deleteProfile');
  String get deleteProfileConfirm => _t('deleteProfileConfirm');
  String get editProfileFailed => _t('editProfileFailed');
  String get deleteProfileFailed => _t('deleteProfileFailed');

  // ─── Profile Detail Tabs ──────────────────────────────────────
  String get tabSaju => _t('tabSaju');
  String get tabInterpretation => _t('tabInterpretation');
  String get tabEvents => _t('tabEvents');
  String get aiConsultation => _t('aiConsultation');
  String get majorLuckPeriods => _t('majorLuckPeriods');
  String get age => _t('age');
  String get generatingInterpretation => _t('generatingInterpretation');
  String get aiAnalyzingDesc => _t('aiAnalyzingDesc');
  String get aiAnalyzingWait => _t('aiAnalyzingWait');
  String get generateInterpretation => _t('generateInterpretation');
  String get generateInterpretationDesc => _t('generateInterpretationDesc');
  String get addTokensToSee => _t('addTokensToSee');
  String get fiveElements => _t('fiveElements');
  String elementCount(int n) => _t('elementCount').replaceAll('{n}', '$n');
  String get kwGrowth => _t('kwGrowth');
  String get kwCreativity => _t('kwCreativity');
  String get kwBenevolence => _t('kwBenevolence');
  String get kwPassion => _t('kwPassion');
  String get kwEtiquette => _t('kwEtiquette');
  String get kwWisdom => _t('kwWisdom');
  String get kwTrust => _t('kwTrust');
  String get kwStability => _t('kwStability');
  String get kwTolerance => _t('kwTolerance');
  String get kwLoyalty => _t('kwLoyalty');
  String get kwDecisiveness => _t('kwDecisiveness');
  String get kwJustice => _t('kwJustice');
  String get kwFlexibility => _t('kwFlexibility');
  String get kwStrategy => _t('kwStrategy');

  // ─── Life Events ──────────────────────────────────────────────
  String get lifeEvents => _t('lifeEvents');
  String get loadEventsFailed => _t('loadEventsFailed');
  String get noEventsRecorded => _t('noEventsRecorded');
  String get noEventsDesc => _t('noEventsDesc');
  String get addEvent => _t('addEvent');
  String get editEvent => _t('editEvent');
  String get deleteEvent => _t('deleteEvent');
  String get deleteEventConfirm => _t('deleteEventConfirm');
  String get deleteEventFailed => _t('deleteEventFailed');
  String get addEventFailed => _t('addEventFailed');
  String get updateEventFailed => _t('updateEventFailed');
  String get eventTitle => _t('eventTitle');
  String get eventTitleHint => _t('eventTitleHint');
  String get eventTitleRequired => _t('eventTitleRequired');
  String get eventContent => _t('eventContent');
  String get eventContentHint => _t('eventContentHint');
  String get eventContentRequired => _t('eventContentRequired');
  String get eventYear => _t('eventYear');
  String get eventMonth => _t('eventMonth');
  String get eventMonthOptional => _t('eventMonthOptional');
  String get allMonths => _t('allMonths');
  String get impact => _t('impact');
  String get impactVeryPositive => _t('impactVeryPositive');
  String get impactPositive => _t('impactPositive');
  String get impactNeutral => _t('impactNeutral');
  String get impactNegative => _t('impactNegative');
  String get impactVeryNegative => _t('impactVeryNegative');
  String get recordLifeEvents => _t('recordLifeEvents');
  String get recordLifeEventsDesc => _t('recordLifeEventsDesc');

  // ─── Consultation ─────────────────────────────────────────────
  String get aiConsultationTitle => _t('aiConsultationTitle');
  String get credit => _t('credit');
  String get chatHistory => _t('chatHistory');
  String get noChatHistory => _t('noChatHistory');
  String get currentConversation => _t('currentConversation');
  String get chatInputHint => _t('chatInputHint');
  String get chatStartFailed => _t('chatStartFailed');
  String get cannotLoadHistory => _t('cannotLoadHistory');
  String get suggestFortune => _t('suggestFortune');
  String get suggestCareer => _t('suggestCareer');
  String get suggestLove => _t('suggestLove');
  String get chatEmptyHint => _t('chatEmptyHint');
  String messagesCount(int n) => _t('messagesCount').replaceAll('{n}', '$n');
  String get conversation => _t('conversation');
  String get newChat => _t('newChat');
  String get renameChat => _t('renameChat');
  String get deleteChat => _t('deleteChat');
  String deleteChatConfirm(String title) =>
      _t('deleteChatConfirm').replaceAll('{title}', title);
  String get pin => _t('pin');
  String get unpin => _t('unpin');
  String get chatPinned => _t('chatPinned');
  String get chatUnpinned => _t('chatUnpinned');
  String get pinFailedPrefix => _t('pinFailedPrefix');
  String get renameFailedPrefix => _t('renameFailedPrefix');
  String get nameChangedOk => _t('nameChangedOk');
  String get deleteChatFailedPrefix => _t('deleteChatFailedPrefix');
  String get chatDeletedOk => _t('chatDeletedOk');
  String get sessionStartFailedPrefix => _t('sessionStartFailedPrefix');
  String get errorPrefix => _t('errorPrefix');
  String creditsCount(int n) => _t('creditsCount').replaceAll('{n}', '$n');

  // ─── Compatibility ────────────────────────────────────────────
  String get compatibilityTitle => _t('compatibilityTitle');
  String get first => _t('first');
  String get second => _t('second');
  String get compatibilityType => _t('compatibilityType');
  String get typeLove => _t('typeLove');
  String get typeMarriage => _t('typeMarriage');
  String get typeFamily => _t('typeFamily');
  String get typeBusiness => _t('typeBusiness');
  String get typeFriendship => _t('typeFriendship');
  String startCompatAnalysis(String type) =>
      _t('startCompatAnalysis').replaceAll('{type}', type);
  String compatSubtitleOf(String type) =>
      _t('compatSubtitleOf').replaceAll('{type}', type);
  String get compatStartFailedPrefix => _t('compatStartFailedPrefix');
  String get compatPromptLove => _t('compatPromptLove');
  String get compatPromptMarriage => _t('compatPromptMarriage');
  String get compatPromptFamily => _t('compatPromptFamily');
  String get compatPromptBusiness => _t('compatPromptBusiness');
  String get compatPromptFriendship => _t('compatPromptFriendship');
  String get selectDifferentProfiles => _t('selectDifferentProfiles');
  String get analyzing => _t('analyzing');
  String get startAnalysis => _t('startAnalysis');
  String get noProfiles => _t('noProfiles');
  String get selectProfile => _t('selectProfile');
  String get analysisHistory => _t('analysisHistory');
  String get noAnalysisHistory => _t('noAnalysisHistory');
  String get noAnalysisHistoryDesc => _t('noAnalysisHistoryDesc');
  String get tapToChange => _t('tapToChange');
  String get remainingTokens => _t('remainingTokens');
  String get addTokens => _t('addTokens');
  String get me => _t('me');
  String compatibilityWith(String a, String b, String type) => _t('compatibilityWith')
      .replaceAll('{a}', a).replaceAll('{b}', b).replaceAll('{type}', type);
}

// ─── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ko', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ─── Birth Hour Tables ────────────────────────────────────────────────────────

const _birthHoursKo = <(String, String, String)>[
  ('자시', '23~01시', '23'),
  ('축시', '01~03시', '01'),
  ('인시', '03~05시', '03'),
  ('묘시', '05~07시', '05'),
  ('진시', '07~09시', '07'),
  ('사시', '09~11시', '09'),
  ('오시', '11~13시', '11'),
  ('미시', '13~15시', '13'),
  ('신시', '15~17시', '15'),
  ('유시', '17~19시', '17'),
  ('술시', '19~21시', '19'),
  ('해시', '21~23시', '21'),
];

const _birthHoursEn = <(String, String, String)>[
  ('Rat', '23–01', '23'),
  ('Ox', '01–03', '01'),
  ('Tiger', '03–05', '03'),
  ('Rabbit', '05–07', '05'),
  ('Dragon', '07–09', '07'),
  ('Snake', '09–11', '09'),
  ('Horse', '11–13', '11'),
  ('Goat', '13–15', '13'),
  ('Monkey', '15–17', '15'),
  ('Rooster', '17–19', '17'),
  ('Dog', '19–21', '19'),
  ('Pig', '21–23', '21'),
];

// ─── String Tables ────────────────────────────────────────────────────────────

const _strings = <String, Map<String, String>>{
  'ko': {
    // App
    'appTitle': '사주',
    'cancel': '취소',
    'delete': '삭제',
    'save': '저장',
    'add': '추가',
    'edit': '수정',
    'confirm': '확인',
    'retry': '다시 시도',
    'close': '닫기',
    'done': '선택 완료',
    'unknown': '모름',
    'optional': '선택사항',
    'current': '현재',
    'justNow': '방금 전',
    'minutesAgo': '{n}분 전',
    'hoursAgo': '{n}시간 전',
    'daysAgo': '{n}일 전',
    // Auth
    'login': '로그인',
    'logout': '로그아웃',
    'logoutConfirm': '정말 로그아웃하시겠습니까?',
    'signup': '회원가입',
    'next': '다음',
    'email': '이메일',
    'password': '비밀번호',
    'passwordHint': '최소 8자 이상',
    'passwordConfirm': '비밀번호 확인',
    'passwordConfirmHint': '비밀번호를 다시 입력하세요',
    'passwordMismatch': '비밀번호가 일치하지 않습니다',
    'forgotPassword': '비밀번호 찾기',
    'forgotPasswordDesc': '가입한 이메일로 재설정 링크를 보내드립니다.',
    'send': '전송',
    'name': '이름',
    'nameHint': '홍길동',
    'nameRequired': '이름을 입력해주세요.',
    'orContinueWith': '또는',
    'continueWithGoogle': 'Google로 계속하기',
    'continueWithApple': 'Apple로 계속하기',
    'continueWithFacebook': 'Facebook으로 계속하기',
    'noAccount': '계정이 없으신가요?',
    'hasAccount': '계정이 있으신가요?',
    'aiSajuAnalysis': 'AI 사주 분석',
    'startAiAnalysis': 'AI 사주 분석을 시작해보세요',
    'checkYourEmail': '이메일을 확인해주세요',
    'confirmLinkSent': '확인 링크를 보냈습니다',
    'confirmLinkDesc': '이메일의 확인 링크를 클릭해\n가입을 완료해주세요.',
    'checkSpam': '이메일이 보이지 않으면 스팸함을 확인해주세요.',
    'alreadyConfirmed': '이미 확인하셨나요?',
    'passwordWeak': '약함',
    'passwordFair': '보통',
    'passwordStrong': '강함',
    'passwordVeryStrong': '매우 강함',
    'passwordMinLength': '최소 8자 이상',
    'passwordTooShort': '비밀번호는 8자 이상이어야 합니다.',
    'passwordRequired': '비밀번호를 입력해주세요.',
    'passwordConfirmRequired': '비밀번호 확인을 입력해주세요.',
    'checkDuplicate': '중복확인',
    'checkingEmail': '확인 중...',
    'emailAvailable': '사용 가능한 이메일입니다',
    'checkEmailFirst': '이메일 중복확인을 해주세요.',
    'emailCheckUnavailable': '이메일 확인 기능을 사용할 수 없습니다. 가입 시 확인됩니다.',
    'agreeToTerms': '서비스 이용약관 및 개인정보 처리방침에 동의합니다',
    'agreeToTermsTemplate': '{terms} 및 {privacy}에 동의합니다',
    'termsRequired': '서비스 이용약관에 동의해주세요.',
    'emailAlreadyUsed': '이미 가입된 이메일입니다.',
    'emailRateLimit': '이메일 발송 한도를 초과했습니다. 잠시 후 다시 시도해주세요.',
    'signupFailed': '회원가입에 실패했습니다. 다시 시도해주세요.',
    'loginFailed': '이메일 또는 비밀번호를 확인해주세요.',
    'socialLoginFailed': '소셜 로그인에 실패했습니다.',
    'resetEmailSent': '비밀번호 재설정 이메일을 보냈습니다. 스팸함도 확인해주세요.',
    'resetEmailFailed': '이메일 전송에 실패했습니다.',
    // Account / Settings
    'myPage': '마이페이지',
    'editProfile': '프로필 수정',
    'changeId': '아이디 변경',
    'changePassword': '비밀번호 변경',
    'currentEmail': '현재 이메일',
    'newEmail': '새 이메일',
    'newEmailHint': '새 이메일을 입력하세요',
    'newPassword': '새 비밀번호',
    'newPasswordHint': '최소 8자 이상',
    'confirmNewPassword': '새 비밀번호 확인',
    'emailChangeConfirmSent': '새 이메일로 확인 링크를 보냈습니다. 메일함을 확인해주세요.',
    'passwordChangeSuccess': '비밀번호가 변경되었습니다.',
    'emailChangeFailed': '이메일 변경에 실패했습니다.',
    'passwordChangeFailed': '비밀번호 변경에 실패했습니다.',
    'emailRequired': '이메일을 입력해주세요.',
    'invalidEmail': '올바른 이메일 형식이 아닙니다.',
    'sameAsCurrentEmail': '현재 이메일과 같습니다.',
    'currentPassword': '현재 비밀번호',
    'currentPasswordHint': '본인 확인을 위해 입력해주세요',
    'currentPasswordRequired': '현재 비밀번호를 입력해주세요.',
    'currentPasswordWrong': '현재 비밀번호가 올바르지 않습니다.',
    'upgrade': '업그레이드',
    'tokenUsage': '토큰 사용량',
    'tokensRemaining': '{n}개 남음',
    'tokenUsageOf': '{used} / {total}',
    'planFree': '무료 플랜',
    'planBasic': '기본 플랜',
    'planPro': 'Pro 플랜',
    'planUltimate': 'Ultimate 플랜',
    'planPlus': '플러스 플랜',
    'selectPlan': '플랜 선택',
    'currentPlanBadge': '현재 이용 중',
    'selectThisPlan': '이 플랜 선택',
    'priceFreeLabel': '무료',
    'pricePerMonth': '₩{price}/월',
    'settings': '설정',
    'notificationSettings': '알림 설정',
    'languageSettings': '언어 설정',
    'support': '지원',
    'help': '도움말',
    'howToReadSaju': '사주 보는 법',
    'helpCategoryTheory': '사주 이해하기',
    'helpCategoryUsage': '앱 사용법',
    'privacyPolicy': '개인정보 처리방침',
    'termsOfService': '서비스 이용약관',
    // Notifications
    'notifReminderEventTime': '오후 8:00',
    'notifReminderEventTitle': '오늘 하루 어땠나요?',
    'notifReminderEventSubtitle': '저녁 8시에 오늘의 이벤트를 작성하도록 알려드려요.',
    'notifReminderFortuneTime': '오전 9:30',
    'notifReminderFortuneTitle': '오늘의 운세',
    'notifReminderFortuneSubtitle': '아침 9시 30분에 오늘의 운세를 알려드려요.',
    'notifChannelOff': '끄기',
    'notifChannelPush': '푸시',
    'notifChannelEmail': '이메일',
    'notifChannelBoth': '모두',
    // Onboarding
    'onboardingTagline': 'AI가 당신의 사주를 분석해\n삶의 흐름을 알려드립니다.',
    'onboardingFeatureCalcTitle': '정확한 사주 계산',
    'onboardingFeatureCalcDesc': '만세력 기반 정밀 계산',
    'onboardingFeatureAiTitle': 'AI 해석',
    'onboardingFeatureAiDesc': '클로드 AI가 상세히 분석',
    'onboardingFeatureElementsTitle': '오행 분석',
    'onboardingFeatureElementsDesc': '목화토금수 균형 파악',
    'getStarted': '시작하기',
    'basicInfo': '기본 정보 입력',
    'basicInfoDesc': '사주분석을 위해 기본 정보를 입력해주세요.',
    'knowExactly': '정확히 앎',
    'knowRoughly': '대략 앎',
    'startAnalysisAction': '분석 시작',
    'noBirthDate': '날짜 미입력',
    // Profiles
    'helloUser': '안녕하세요, {name}님',
    'mySajuProfile': '나의 사주 프로필 →',
    'addProfile': '프로필 추가',
    'profileDetail': '프로필',
    'loadProfileFailed': '프로필을 불러올 수 없습니다.',
    'noChartData': '차트 데이터가 없습니다.',
    'dragToReorder': '놓을 위치로 드래그하세요',
    'mySaju': '나의 사주',
    'timeUnknown': '시간 미상',
    'birthHour': '태어난 시간',
    'birthDate': '생년월일',
    'selectBirthDate': '생년월일 선택',
    'gender': '성별',
    'male': '남성',
    'female': '여성',
    'calendarType': '달력 종류',
    'solar': '양력',
    'lunar': '음력',
    'relationship': '관계',
    'relationshipHint': '예) 친구, 배우자, 부모님 (선택사항)',
    'addProfileDesc': '지인의 사주를 분석하려면 기본 정보를 입력하세요',
    'birthDateRequired': '생년월일을 선택해주세요.',
    'createProfileFailed': '프로필 생성에 실패했습니다.',
    'selectDate': '날짜를 선택하세요',
    'year': '년',
    'month': '월',
    'day': '일',
    'exactly': '정확히',
    'approximately': '대략',
    'deleteProfile': '프로필 삭제',
    'deleteProfileConfirm': '이 프로필을 삭제하시겠습니까?\n삭제된 프로필은 복구할 수 없습니다.',
    'editProfileFailed': '프로필 수정에 실패했습니다.',
    'deleteProfileFailed': '프로필 삭제에 실패했습니다.',
    // Profile detail tabs
    'tabSaju': '사주',
    'tabInterpretation': '해석',
    'tabEvents': '이벤트',
    'aiConsultation': 'AI 사주상담',
    'majorLuckPeriods': '대운',
    'age': '세',
    'generatingInterpretation': '해석 생성 중...',
    'aiAnalyzingDesc': 'AI가 사주를 분석하고 있습니다\n잠시만 기다려주세요',
    'aiAnalyzingWait': '보통 1~2분 소요됩니다',
    'generateInterpretation': '해석 생성',
    'generateInterpretationDesc': 'Claude AI가 당신의 사주를 상세히 분석합니다',
    'addTokensToSee': '토큰 추가하고 분석 전체 보기',
    'fiveElements': '오행 분포',
    'elementCount': '{n}개',
    'kwGrowth': '성장',
    'kwCreativity': '창의',
    'kwBenevolence': '인자',
    'kwPassion': '열정',
    'kwEtiquette': '예의',
    'kwWisdom': '지혜',
    'kwTrust': '신용',
    'kwStability': '안정',
    'kwTolerance': '포용',
    'kwLoyalty': '의리',
    'kwDecisiveness': '결단',
    'kwJustice': '정의',
    'kwFlexibility': '유연',
    'kwStrategy': '지모',
    // Life Events
    'lifeEvents': '생활 이벤트',
    'loadEventsFailed': '이벤트를 불러올 수 없습니다.',
    'noEventsRecorded': '기록된 생활 이벤트가 없습니다',
    'noEventsDesc': '인생의 주요 사건을 기록하면\nAI 해석의 정확도가 높아집니다',
    'addEvent': '이벤트 추가',
    'editEvent': '이벤트 수정',
    'deleteEvent': '이벤트 삭제',
    'deleteEventConfirm': '이 이벤트를 삭제하시겠습니까?',
    'deleteEventFailed': '이벤트 삭제에 실패했습니다.',
    'addEventFailed': '이벤트 추가에 실패했습니다.',
    'updateEventFailed': '이벤트 수정에 실패했습니다.',
    'eventTitle': '제목',
    'eventTitleHint': '이벤트 제목을 입력하세요',
    'eventTitleRequired': '제목을 입력해주세요.',
    'eventContent': '내용',
    'eventContentHint': '어떤 일이 있었나요? (예: 결혼, 이직, 사고 등)',
    'eventContentRequired': '내용을 입력해주세요.',
    'eventYear': '연도',
    'eventMonth': '월',
    'eventMonthOptional': '월 (선택사항)',
    'allMonths': '전체',
    'impact': '영향도',
    'impactVeryPositive': '매우 긍정',
    'impactPositive': '긍정',
    'impactNeutral': '중립',
    'impactNegative': '부정',
    'impactVeryNegative': '매우 부정',
    'recordLifeEvents': '생활 이벤트를 기록해보세요',
    'recordLifeEventsDesc': '중요한 사건을 기록하면\nAI 해석의 정확도가 높아집니다',
    // Consultation
    'aiConsultationTitle': 'AI 상담',
    'credit': '크래딧',
    'chatHistory': '채팅 기록',
    'noChatHistory': '아직 다른 채팅 기록이 없어요\n상단 + 버튼으로 새 채팅을 시작하세요',
    'currentConversation': '현재 대화',
    'chatInputHint': '질문을 입력하세요...',
    'chatStartFailed': '채팅을 시작할 수 없습니다.',
    'cannotLoadHistory': '채팅 기록을 불러올 수 없습니다.',
    'suggestFortune': '올해 운세가 어떤가요?',
    'suggestCareer': '적성에 맞는 직업은?',
    'suggestLove': '연애운을 알려주세요',
    'chatEmptyHint': '사주에 대해 궁금한 것을\n무엇이든 물어보세요.',
    'messagesCount': '{n}개 메시지',
    'conversation': '대화',
    'newChat': '새 채팅',
    'renameChat': '이름 바꾸기',
    'deleteChat': '채팅 삭제',
    'deleteChatConfirm': '"{title}" 채팅을 삭제하시겠습니까?\n삭제된 채팅은 복구할 수 없습니다.',
    'pin': '고정하기',
    'unpin': '고정 해제',
    'chatPinned': '채팅을 고정했습니다',
    'chatUnpinned': '고정을 해제했습니다',
    'pinFailedPrefix': '고정 상태 변경 실패',
    'renameFailedPrefix': '이름 변경 실패',
    'nameChangedOk': '이름을 변경했습니다',
    'deleteChatFailedPrefix': '채팅 삭제 실패',
    'chatDeletedOk': '채팅이 삭제되었습니다',
    'sessionStartFailedPrefix': '채팅 세션을 시작할 수 없습니다',
    'errorPrefix': '오류',
    'creditsCount': '{n} 크래딧',
    // Compatibility
    'compatibilityTitle': '궁합 분석',
    'first': '첫 번째',
    'second': '두 번째',
    'compatibilityType': '궁합 유형',
    'typeLove': '연애',
    'typeMarriage': '결혼',
    'typeFamily': '가족',
    'typeBusiness': '사업',
    'typeFriendship': '우정',
    'startCompatAnalysis': '{type}궁합 분석 시작',
    'compatSubtitleOf': '{type} 궁합',
    'compatStartFailedPrefix': '궁합 분석을 시작할 수 없습니다',
    'compatPromptLove': '두 사람의 연애궁합을 사주를 기반으로 상세히 분석해주세요.',
    'compatPromptMarriage': '두 사람의 결혼궁합을 사주를 기반으로 상세히 분석해주세요.',
    'compatPromptFamily': '두 사람의 가족궁합(부모-자식 또는 형제자매 관계)을 사주를 기반으로 상세히 분석해주세요. 특히 소통 방식, 갈등 요인, 서로 맞춰가는 법에 집중해주세요.',
    'compatPromptBusiness': '두 사람의 사업궁합을 사주를 기반으로 상세히 분석해주세요.',
    'compatPromptFriendship': '두 사람의 우정궁합을 사주를 기반으로 상세히 분석해주세요.',
    'selectDifferentProfiles': '서로 다른 프로필을 선택해주세요.',
    'analyzing': '분석 중...',
    'startAnalysis': '궁합 분석 시작',
    'noProfiles': '선택 가능한 프로필이 없습니다.',
    'selectProfile': '프로필 선택',
    'analysisHistory': '분석 기록',
    'noAnalysisHistory': '분석 기록이 없어요',
    'noAnalysisHistoryDesc': '궁합을 분석하면 여기에 저장돼요',
    'tapToChange': '탭하여 변경',
    'remainingTokens': '남은 토큰',
    'addTokens': '토큰 충전',
    'me': '나',
    'compatibilityWith': '{a}님과 {b}님의 {type} 궁합 분석',
  },
  'en': {
    // App
    'appTitle': 'Saju',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'save': 'Save',
    'add': 'Add',
    'edit': 'Edit',
    'confirm': 'Confirm',
    'retry': 'Try Again',
    'close': 'Close',
    'done': 'Done',
    'unknown': 'Unknown',
    'optional': 'Optional',
    'current': 'Current',
    'justNow': 'Just now',
    'minutesAgo': '{n}m ago',
    'hoursAgo': '{n}h ago',
    'daysAgo': '{n}d ago',
    // Auth
    'login': 'Log In',
    'logout': 'Log Out',
    'logoutConfirm': 'Are you sure you want to log out?',
    'signup': 'Sign Up',
    'next': 'Next',
    'email': 'Email',
    'password': 'Password',
    'passwordHint': 'At least 8 characters',
    'passwordConfirm': 'Confirm Password',
    'passwordConfirmHint': 'Re-enter your password',
    'passwordMismatch': 'Passwords do not match',
    'forgotPassword': 'Forgot Password',
    'forgotPasswordDesc': "We'll send a reset link to your email.",
    'send': 'Send',
    'name': 'Name',
    'nameHint': 'Full name',
    'nameRequired': 'Please enter your name.',
    'orContinueWith': 'Or continue with',
    'continueWithGoogle': 'Continue with Google',
    'continueWithApple': 'Continue with Apple',
    'continueWithFacebook': 'Continue with Facebook',
    'noAccount': "Don't have an account?",
    'hasAccount': 'Already have an account?',
    'aiSajuAnalysis': 'AI Saju Analysis',
    'startAiAnalysis': 'Start your AI Saju analysis',
    'checkYourEmail': 'Check your email',
    'confirmLinkSent': 'Confirmation link sent',
    'confirmLinkDesc': 'Click the confirmation link in your email\nto complete sign up.',
    'checkSpam': "Can't find it? Check your spam folder.",
    'alreadyConfirmed': 'Already confirmed?',
    'passwordWeak': 'Weak',
    'passwordFair': 'Fair',
    'passwordStrong': 'Strong',
    'passwordVeryStrong': 'Very Strong',
    'passwordMinLength': 'At least 8 characters',
    'passwordTooShort': 'Password must be at least 8 characters.',
    'passwordRequired': 'Please enter a password.',
    'passwordConfirmRequired': 'Please confirm your password.',
    'checkDuplicate': 'Check',
    'checkingEmail': 'Checking...',
    'emailAvailable': 'Email is available',
    'checkEmailFirst': 'Please check email availability first.',
    'emailCheckUnavailable': 'Email check is unavailable. Will be verified during signup.',
    'agreeToTerms': 'I agree to the Terms of Service and Privacy Policy',
    'agreeToTermsTemplate': 'I agree to the {terms} and {privacy}',
    'termsRequired': 'Please agree to the Terms of Service.',
    'emailAlreadyUsed': 'This email is already registered.',
    'emailRateLimit': 'Email rate limit exceeded. Please try again later.',
    'signupFailed': 'Sign up failed. Please try again.',
    'loginFailed': 'Incorrect email or password.',
    'socialLoginFailed': 'Social login failed.',
    'resetEmailSent': 'Password reset email sent. Please check your spam folder too.',
    'resetEmailFailed': 'Failed to send email.',
    // Account / Settings
    'myPage': 'My Page',
    'editProfile': 'Edit Profile',
    'changeId': 'Change Email',
    'changePassword': 'Change Password',
    'currentEmail': 'Current email',
    'newEmail': 'New email',
    'newEmailHint': 'Enter your new email',
    'newPassword': 'New password',
    'newPasswordHint': 'At least 8 characters',
    'confirmNewPassword': 'Confirm new password',
    'emailChangeConfirmSent': 'A confirmation link was sent to your new email. Please check your inbox.',
    'passwordChangeSuccess': 'Password updated successfully.',
    'emailChangeFailed': 'Failed to change email.',
    'passwordChangeFailed': 'Failed to change password.',
    'emailRequired': 'Please enter an email.',
    'invalidEmail': 'Invalid email format.',
    'sameAsCurrentEmail': 'Same as current email.',
    'currentPassword': 'Current password',
    'currentPasswordHint': 'Enter to confirm your identity',
    'currentPasswordRequired': 'Please enter your current password.',
    'currentPasswordWrong': 'Current password is incorrect.',
    'upgrade': 'Upgrade',
    'tokenUsage': 'Token Usage',
    'tokensRemaining': '{n} remaining',
    'tokenUsageOf': '{used} / {total}',
    'planFree': 'Free Plan',
    'planBasic': 'Basic Plan',
    'planPro': 'Pro Plan',
    'planUltimate': 'Ultimate Plan',
    'planPlus': 'Plus Plan',
    'selectPlan': 'Select Plan',
    'currentPlanBadge': 'Current',
    'selectThisPlan': 'Select Plan',
    'priceFreeLabel': 'Free',
    'pricePerMonth': '\${price}/mo',
    'settings': 'Settings',
    'notificationSettings': 'Notifications',
    'languageSettings': 'Language',
    'support': 'Support',
    'help': 'Help',
    'howToReadSaju': 'How to Read Saju',
    'helpCategoryTheory': 'Understanding Saju',
    'helpCategoryUsage': 'Using the App',
    'privacyPolicy': 'Privacy Policy',
    'termsOfService': 'Terms of Service',
    // Notifications
    'notifReminderEventTime': '8:00 PM',
    'notifReminderEventTitle': 'How was your day?',
    'notifReminderEventSubtitle': "We'll remind you at 8 PM to log today's events.",
    'notifReminderFortuneTime': '9:30 AM',
    'notifReminderFortuneTitle': "Today's Fortune",
    'notifReminderFortuneSubtitle': "We'll share today's fortune at 9:30 AM.",
    'notifChannelOff': 'Off',
    'notifChannelPush': 'Push',
    'notifChannelEmail': 'Email',
    'notifChannelBoth': 'Both',
    // Onboarding
    'onboardingTagline': "AI will analyze your Saju\nand reveal the flow of your life.",
    'onboardingFeatureCalcTitle': 'Accurate Saju calculation',
    'onboardingFeatureCalcDesc': 'Precise math based on the Manseryeok',
    'onboardingFeatureAiTitle': 'AI reading',
    'onboardingFeatureAiDesc': 'Detailed analysis by Claude AI',
    'onboardingFeatureElementsTitle': 'Five Elements analysis',
    'onboardingFeatureElementsDesc': 'See how Wood/Fire/Earth/Metal/Water balance',
    'getStarted': 'Get started',
    'basicInfo': 'Basic information',
    'basicInfoDesc': 'Please enter basic info for your Saju analysis.',
    'knowExactly': 'Know exactly',
    'knowRoughly': 'Approximate',
    'startAnalysisAction': 'Start analysis',
    'noBirthDate': 'No date',
    // Profiles
    'helloUser': 'Hello, {name}',
    'mySajuProfile': 'My Saju Profile →',
    'addProfile': 'Add Profile',
    'profileDetail': 'Profile',
    'loadProfileFailed': 'Could not load profile.',
    'noChartData': 'No chart data available.',
    'dragToReorder': 'Drag to reorder',
    'mySaju': 'My Saju',
    'timeUnknown': 'Time Unknown',
    'birthHour': 'Birth Hour',
    'birthDate': 'Date of Birth',
    'selectBirthDate': 'Select Date of Birth',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'calendarType': 'Calendar Type',
    'solar': 'Solar',
    'lunar': 'Lunar',
    'relationship': 'Relationship',
    'relationshipHint': 'e.g., Friend, Spouse, Parent (optional)',
    'addProfileDesc': "Enter basic info to analyze someone's Saju",
    'birthDateRequired': 'Please select a date of birth.',
    'createProfileFailed': 'Failed to create profile.',
    'selectDate': 'Select date',
    'year': 'Y',
    'month': 'M',
    'day': 'D',
    'exactly': 'Exactly',
    'approximately': 'Approx.',
    'deleteProfile': 'Delete Profile',
    'deleteProfileConfirm': 'Delete this profile?\nThis action cannot be undone.',
    'editProfileFailed': 'Failed to update profile.',
    'deleteProfileFailed': 'Failed to delete profile.',
    // Profile detail tabs
    'tabSaju': 'Saju',
    'tabInterpretation': 'Reading',
    'tabEvents': 'Events',
    'aiConsultation': 'AI Consultation',
    'majorLuckPeriods': 'Luck Cycles',
    'age': 'yrs',
    'generatingInterpretation': 'Generating reading...',
    'aiAnalyzingDesc': 'AI is analyzing your Saju\nPlease wait a moment',
    'aiAnalyzingWait': 'Usually takes 1–2 minutes',
    'generateInterpretation': 'Generate Reading',
    'generateInterpretationDesc': 'Claude AI will analyze your Saju in detail',
    'addTokensToSee': 'Add tokens to see full reading',
    'fiveElements': 'Five Elements',
    'elementCount': '×{n}',
    'kwGrowth': 'Growth',
    'kwCreativity': 'Creativity',
    'kwBenevolence': 'Benevolence',
    'kwPassion': 'Passion',
    'kwEtiquette': 'Etiquette',
    'kwWisdom': 'Wisdom',
    'kwTrust': 'Trust',
    'kwStability': 'Stability',
    'kwTolerance': 'Tolerance',
    'kwLoyalty': 'Loyalty',
    'kwDecisiveness': 'Resolve',
    'kwJustice': 'Justice',
    'kwFlexibility': 'Flexibility',
    'kwStrategy': 'Insight',
    // Life Events
    'lifeEvents': 'Life Events',
    'loadEventsFailed': 'Could not load events.',
    'noEventsRecorded': 'No life events recorded',
    'noEventsDesc': 'Recording major life events\nimproves AI reading accuracy',
    'addEvent': 'Add Event',
    'editEvent': 'Edit Event',
    'deleteEvent': 'Delete Event',
    'deleteEventConfirm': 'Delete this event?',
    'deleteEventFailed': 'Failed to delete event.',
    'addEventFailed': 'Failed to add event.',
    'updateEventFailed': 'Failed to update event.',
    'eventTitle': 'Title',
    'eventTitleHint': 'Enter event title',
    'eventTitleRequired': 'Please enter a title.',
    'eventContent': 'Description',
    'eventContentHint': 'What happened? (e.g., marriage, new job, accident)',
    'eventContentRequired': 'Please enter a description.',
    'eventYear': 'Year',
    'eventMonth': 'Month',
    'eventMonthOptional': 'Month (optional)',
    'allMonths': 'All',
    'impact': 'Impact',
    'impactVeryPositive': 'Very Positive',
    'impactPositive': 'Positive',
    'impactNeutral': 'Neutral',
    'impactNegative': 'Negative',
    'impactVeryNegative': 'Very Negative',
    'recordLifeEvents': 'Record life events',
    'recordLifeEventsDesc': 'Recording important events\nimproves AI reading accuracy',
    // Consultation
    'aiConsultationTitle': 'AI Consultation',
    'credit': 'Credits',
    'chatHistory': 'Chat History',
    'noChatHistory': 'No other chats yet\nTap + above to start a new chat',
    'currentConversation': 'Current Chat',
    'chatInputHint': 'Ask a question...',
    'chatStartFailed': 'Could not start chat.',
    'cannotLoadHistory': 'Could not load chat history.',
    'suggestFortune': "What's my fortune this year?",
    'suggestCareer': 'What career suits me?',
    'suggestLove': 'Tell me about my love fortune',
    'chatEmptyHint': 'Ask me anything\nabout your Saju.',
    'messagesCount': '{n} messages',
    'conversation': 'Chat',
    'newChat': 'New chat',
    'renameChat': 'Rename',
    'deleteChat': 'Delete chat',
    'deleteChatConfirm': 'Delete the chat "{title}"?\nThis cannot be undone.',
    'pin': 'Pin',
    'unpin': 'Unpin',
    'chatPinned': 'Chat pinned',
    'chatUnpinned': 'Chat unpinned',
    'pinFailedPrefix': 'Failed to change pin state',
    'renameFailedPrefix': 'Rename failed',
    'nameChangedOk': 'Name updated',
    'deleteChatFailedPrefix': 'Delete failed',
    'chatDeletedOk': 'Chat deleted',
    'sessionStartFailedPrefix': "Couldn't start chat session",
    'errorPrefix': 'Error',
    'creditsCount': '{n} credits',
    // Compatibility
    'compatibilityTitle': 'Compatibility',
    'first': 'First',
    'second': 'Second',
    'compatibilityType': 'Type',
    'typeLove': 'Romance',
    'typeMarriage': 'Marriage',
    'typeFamily': 'Family',
    'typeBusiness': 'Business',
    'typeFriendship': 'Friendship',
    'startCompatAnalysis': 'Start {type} compatibility analysis',
    'compatSubtitleOf': '{type} compatibility',
    'compatStartFailedPrefix': "Couldn't start compatibility analysis",
    'compatPromptLove': "Please analyze the two people's romantic compatibility in detail based on their Saju charts.",
    'compatPromptMarriage': "Please analyze the two people's marriage compatibility in detail based on their Saju charts.",
    'compatPromptFamily': "Please analyze the two people's family compatibility (parent-child or sibling relationship) in detail based on their Saju charts. Focus especially on communication styles, sources of conflict, and how they adjust to each other.",
    'compatPromptBusiness': "Please analyze the two people's business compatibility in detail based on their Saju charts.",
    'compatPromptFriendship': "Please analyze the two people's friendship compatibility in detail based on their Saju charts.",
    'selectDifferentProfiles': 'Please select two different profiles.',
    'analyzing': 'Analyzing...',
    'startAnalysis': 'Start Analysis',
    'noProfiles': 'No profiles available.',
    'selectProfile': 'Select Profile',
    'analysisHistory': 'History',
    'noAnalysisHistory': 'No history yet',
    'noAnalysisHistoryDesc': 'Your analyses will be saved here',
    'tapToChange': 'Tap to change',
    'remainingTokens': 'Tokens Left',
    'addTokens': 'Add Tokens',
    'me': 'Me',
    'compatibilityWith': '{a} & {b} — {type} Compatibility',
  },
};
