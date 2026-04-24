import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart'; // 이메일 확인 화면에서 사용
import '../../widgets/policy_sheet.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// 이메일 중복확인 결과 상태
enum _EmailCheck {
  unchecked,   // 아직 확인 안 함
  available,   // 사용 가능
  duplicate,   // 이미 사용 중
  unavailable, // 서버에서 확인 불가 — 폴백으로 통과시킴 (가입 시 재확인)
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _signupSuccess = false;

  // 2-step: 0 = 계정 정보, 1 = 프로필 정보
  int _step = 0;

  // 필드별 인라인 에러 (다음 버튼 눌렀을 때 검증해서 채움)
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _termsError;
  String? _birthDateError;

  // 이메일 중복확인 상태
  _EmailCheck _emailCheck = _EmailCheck.unchecked;
  bool _emailCheckLoading = false;

  // 프로필 입력 (step 1)
  DateTime? _birthDate;
  String? _birthHour;
  String _birthHourPrecision = 'unknown';
  String _gender = 'male';
  String _calendarType = 'solar';

  final ApiService _api = ApiService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // 웹과 동일한 비밀번호 강도 계산 (0~4)
  int get _passwordStrength {
    final pw = _passwordCtrl.text;
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[a-z]')) && pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[^a-zA-Z0-9]'))) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return const Color(0xFFB5413B);
      case 2: return const Color(0xFFC97B49);
      case 3: return kGold;
      default: return kSuccessColor;
    }
  }

  String _strengthLabel(AppLocalizations l10n) {
    switch (_passwordStrength) {
      case 1: return l10n.passwordWeak;
      case 2: return l10n.passwordFair;
      case 3: return l10n.passwordStrong;
      default: return l10n.passwordVeryStrong;
    }
  }

  /// 이메일 중복확인 버튼 핸들러 — 형식 검증 + 서버 조회.
  Future<void> _checkEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = l10n.emailRequired;
        _emailCheck = _EmailCheck.unchecked;
      });
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _emailError = l10n.invalidEmail;
        _emailCheck = _EmailCheck.unchecked;
      });
      return;
    }
    setState(() {
      _emailError = null;
      _emailCheckLoading = true;
    });
    try {
      final available = await _api.checkEmailAvailable(email);
      if (!mounted) return;
      setState(() {
        _emailCheckLoading = false;
        _emailCheck = available ? _EmailCheck.available : _EmailCheck.duplicate;
        _emailError = available ? null : l10n.emailAlreadyUsed;
      });
    } catch (_) {
      // 엔드포인트 미구현/네트워크 실패 — 체크는 fallback으로 통과.
      // 실제 중복은 Supabase.signUp에서 잡아낸다.
      if (!mounted) return;
      setState(() {
        _emailCheckLoading = false;
        _emailCheck = _EmailCheck.unavailable;
        _emailError = null;
      });
    }
  }

  // Step 0 → Step 1로 전환하기 전 계정 정보 검증 — 모든 필드를 한 번에 점검하고
  // 누락/오류 항목은 인라인에 빨간 메시지로 표시한다. 전부 통과해야 step 1로 전환.
  void _goNext() {
    final l10n = AppLocalizations.of(context);
    String? nameErr;
    String? emailErr;
    String? pwErr;
    String? confirmErr;
    String? termsErr;

    if (_nameCtrl.text.trim().isEmpty) {
      nameErr = l10n.nameRequired;
    }

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      emailErr = l10n.emailRequired;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailErr = l10n.invalidEmail;
    } else if (_emailCheck == _EmailCheck.duplicate) {
      emailErr = l10n.emailAlreadyUsed;
    } else if (_emailCheck == _EmailCheck.unchecked) {
      emailErr = l10n.checkEmailFirst;
    }

    if (_passwordCtrl.text.isEmpty) {
      pwErr = l10n.passwordRequired;
    } else if (_passwordCtrl.text.length < 8) {
      pwErr = l10n.passwordTooShort;
    }

    if (_confirmCtrl.text.isEmpty) {
      confirmErr = l10n.passwordConfirmRequired;
    } else if (_confirmCtrl.text != _passwordCtrl.text) {
      confirmErr = l10n.passwordMismatch;
    }

    if (!_agreeTerms) {
      termsErr = l10n.termsRequired;
    }

    final allOk = nameErr == null &&
        emailErr == null &&
        pwErr == null &&
        confirmErr == null &&
        termsErr == null;

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = pwErr;
      _confirmError = confirmErr;
      _termsError = termsErr;
      if (allOk) _step = 1;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _signup() async {
    final l10n = AppLocalizations.of(context);
    if (_birthDate == null) {
      setState(() => _birthDateError = l10n.birthDateRequired);
      return;
    }

    setState(() { _loading = true; _birthDateError = null; });
    final birthDateStr = '${_birthDate!.year.toString().padLeft(4, '0')}-'
        '${_birthDate!.month.toString().padLeft(2, '0')}-'
        '${_birthDate!.day.toString().padLeft(2, '0')}';

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'full_name': _nameCtrl.text.trim(),
          'display_name': _nameCtrl.text.trim(),
          'onboarding_step': 'welcome',
          // 이메일 인증 플로우에서도 서버가 참고할 수 있도록 메타데이터에 동봉
          'pending_profile': {
            'birth_date': birthDateStr,
            'birth_hour': _birthHourPrecision == 'unknown' ? null : _birthHour,
            'birth_time_type': _birthHourPrecision,
            'gender': _gender,
            'calendar_type': _calendarType,
          },
        },
      );

      if (!mounted) return;

      // 세션이 바로 생기면 프로필도 즉시 생성하고 /profiles로
      if (response.session != null) {
        try {
          await _api.createProfile(
            name: _nameCtrl.text.trim(),
            birthDate: birthDateStr,
            birthHour: _birthHourPrecision == 'unknown' ? null : _birthHour,
            birthHourPrecision: _birthHourPrecision,
            gender: _gender,
            calendarType: _calendarType,
          );
          await _api.updateOnboardingStep('complete');
        } catch (_) {
          // 프로필 생성 실패해도 가입은 끝났으니 온보딩으로 폴백
          if (mounted) context.go('/onboarding');
          return;
        }
        if (mounted) context.go('/profiles');
        return;
      }

      // 세션이 null이면 이메일 인증 필요 — 프로필 입력값은 로컬에 임시 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_profile.birth_date', birthDateStr);
      await prefs.setString('pending_profile.birth_time_type', _birthHourPrecision);
      if (_birthHour != null) {
        await prefs.setString('pending_profile.birth_hour', _birthHour!);
      }
      await prefs.setString('pending_profile.gender', _gender);
      await prefs.setString('pending_profile.calendar_type', _calendarType);
      await prefs.setString('pending_profile.name', _nameCtrl.text.trim());

      if (mounted) setState(() { _signupSuccess = true; _loading = false; });
    } on AuthException catch (e) {
      if (e.message.contains('already registered') || e.message.contains('User already registered')) {
        // 이메일 중복 — step 0으로 돌아가 이메일 필드 아래 빨간 글자로 표시
        if (mounted) {
          setState(() {
            _step = 0;
            _emailCheck = _EmailCheck.duplicate;
            _emailError = l10n.emailAlreadyUsed;
          });
        }
      } else if (e.message.contains('rate limit') || e.message.contains('email rate')) {
        _showSnack(l10n.emailRateLimit);
      } else {
        _showSnack(l10n.signupFailed);
      }
    } catch (_) {
      _showSnack(l10n.signupFailed);
    } finally {
      if (mounted && !_signupSuccess) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_signupSuccess) return _emailConfirmScreen();
    return _formScreen();
  }

  // 이메일 인증 안내 화면 (웹과 동일)
  Widget _emailConfirmScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kGold.withOpacity(0.25), width: 2),
                    ),
                    child: const Icon(Icons.mail_outline, color: kGold, size: 36),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    borderRadius: 20,
                    child: Column(
                      children: [
                        Text(
                          l10n.checkYourEmail,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.confirmLinkSent,
                          style: const TextStyle(fontSize: 13, color: kTextMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailCtrl.text.trim(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(width: 60, height: 0.5, color: kGold.withOpacity(0.25)),
                        const SizedBox(height: 16),
                        Text(
                          l10n.confirmLinkDesc,
                          style: const TextStyle(fontSize: 12, color: kTextMuted, height: 1.6),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.checkSpam,
                          style: const TextStyle(fontSize: 11, color: kTextMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${l10n.alreadyConfirmed}  ', style: const TextStyle(fontSize: 12, color: kTextMuted)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          l10n.login,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step = 0);
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(l10n.signup,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kDark)),
      ),
      body: CosmicBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: _step == 0 ? _accountStep(l10n) : _profileStep(l10n),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: _bottomFixed(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 화면 하단에 고정되는 주 액션 버튼 + "계정이 있으신가요?" 링크.
  Widget _bottomFixed(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: _step == 0 ? l10n.next : l10n.signup,
          onPressed: _step == 0 ? _goNext : _signup,
          loading: _step == 1 && _loading,
          textColor: kCosmicNavy,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${l10n.hasAccount}  ',
              style: const TextStyle(color: kTextMuted, fontSize: 14)),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(l10n.login,
                style: const TextStyle(color: kGold, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accountStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.startAiAnalysis,
          style: const TextStyle(fontSize: 14, color: kTextMuted)),
        const SizedBox(height: 20),

        // 4개 입력 필드 — 박스 없이
        _field(
          controller: _nameCtrl,
          label: l10n.name,
          hint: l10n.nameHint,
          error: _nameError,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 16),
        _labelText(l10n.email),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_emailError != null || _emailCheck != _EmailCheck.unchecked) {
                    setState(() {
                      _emailError = null;
                      _emailCheck = _EmailCheck.unchecked;
                    });
                  }
                },
                style: const TextStyle(fontSize: 15, color: kDark),
                decoration: _inputDeco(hint: 'example@email.com', error: _emailError),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _emailCheckLoading ? null : _checkEmail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGold,
                  side: BorderSide(color: kGold.withOpacity(0.55)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _emailCheckLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kGold),
                      )
                    : Text(l10n.checkDuplicate,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (_emailCheck == _EmailCheck.available || _emailCheck == _EmailCheck.unavailable) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _emailCheck == _EmailCheck.available
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 14,
                color: _emailCheck == _EmailCheck.available ? kSuccessColor : kTextMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _emailCheck == _EmailCheck.available
                      ? l10n.emailAvailable
                      : l10n.emailCheckUnavailable,
                  style: TextStyle(
                    fontSize: 11,
                    color: _emailCheck == _EmailCheck.available ? kSuccessColor : kTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // 비밀번호 + 강도 바
        _labelText(l10n.password),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          onChanged: (_) => setState(() {
            if (_passwordError != null) _passwordError = null;
          }),
          style: const TextStyle(fontSize: 15, color: kDark),
          decoration: _inputDeco(
            hint: l10n.passwordMinLength,
            error: _passwordError,
            suffix: _eyeIcon(_obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
          ),
        ),
        if (_passwordCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(4, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < _passwordStrength ? _strengthColor : const Color(0x08FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
              if (_passwordStrength > 0) ...[
                const SizedBox(width: 8),
                Text(_strengthLabel(l10n), style: TextStyle(fontSize: 11, color: _strengthColor)),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),

        // 비밀번호 확인
        _labelText(l10n.passwordConfirm),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {
            if (_confirmError != null) _confirmError = null;
          }),
          style: const TextStyle(fontSize: 15, color: kDark),
          decoration: _inputDeco(
            hint: l10n.passwordConfirmHint,
            error: _confirmError,
            suffix: _eyeIcon(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
          ),
        ),
        const SizedBox(height: 20),

        // 약관 동의 — 체크박스 + 하이퍼링크
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _agreeTerms = !_agreeTerms;
                if (_agreeTerms && _termsError != null) _termsError = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _agreeTerms ? kGold : Colors.transparent,
                  border: Border.all(
                    color: _agreeTerms
                        ? kGold
                        : (_termsError != null ? kErrorColor : kGlassBorder),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _agreeTerms
                    ? const Icon(Icons.check, color: kInk, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _agreeTermsRichText(l10n),
            ),
          ],
        ),
        if (_termsError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(_termsError!,
              style: const TextStyle(fontSize: 11, color: kErrorColor)),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _profileStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGold.withOpacity(0.45), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: kGold.withOpacity(0.9), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.basicInfoDesc,
                  style: const TextStyle(fontSize: 13, color: kGold, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 생년월일
        _labelText(l10n.birthDate),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickBirthDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _birthDateError != null ? kErrorColor : kGlassBorder,
                width: _birthDateError != null ? 1.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _birthDate == null
                        ? l10n.selectDate
                        : l10n.formatBirthDate(_birthDate!.year, _birthDate!.month, _birthDate!.day),
                    style: TextStyle(
                      fontSize: 15,
                      color: _birthDate == null ? kTextMuted : kDark,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: kTextMuted, size: 18),
              ],
            ),
          ),
        ),
        if (_birthDateError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(_birthDateError!,
              style: const TextStyle(fontSize: 11, color: kErrorColor)),
          ),
        ],
        const SizedBox(height: 20),

        // 성별
        _labelText(l10n.gender),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _chip(l10n.male, 'male', _gender, (v) => setState(() => _gender = v))),
            const SizedBox(width: 12),
            Expanded(child: _chip(l10n.female, 'female', _gender, (v) => setState(() => _gender = v))),
          ],
        ),
        const SizedBox(height: 20),

        // 달력 종류
        _labelText(l10n.calendarType),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _chip(l10n.solar, 'solar', _calendarType, (v) => setState(() => _calendarType = v))),
            const SizedBox(width: 12),
            Expanded(child: _chip(l10n.lunar, 'lunar', _calendarType, (v) => setState(() => _calendarType = v))),
          ],
        ),
        const SizedBox(height: 20),

        // 태어난 시간
        _labelText(l10n.birthHour),
        const SizedBox(height: 8),
        ...[
          l10n.birthHourList.sublist(0, 6),
          l10n.birthHourList.sublist(6, 12),
        ].map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: List.generate(row.length * 2 - 1, (i) {
              if (i.isOdd) return const SizedBox(width: 6);
              final h = row[i ~/ 2];
              final selected = _birthHour == h.$3 && _birthHourPrecision != 'unknown';
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _birthHour = h.$3;
                    _birthHourPrecision = 'exact';
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? kGold.withOpacity(0.2) : const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? kGold : kGlassBorder),
                    ),
                    child: Column(
                      children: [
                        Text(h.$1,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: selected ? kGold : kDark)),
                        Text(h.$2,
                          style: TextStyle(fontSize: 8,
                            color: selected ? kGold.withOpacity(0.8) : kTextMuted)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        )),
        GestureDetector(
          onTap: () => setState(() {
            _birthHour = null;
            _birthHourPrecision = 'unknown';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _birthHourPrecision == 'unknown' ? kGold.withOpacity(0.2) : const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _birthHourPrecision == 'unknown' ? kGold : kGlassBorder),
            ),
            child: Center(
              child: Text(l10n.unknown,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _birthHourPrecision == 'unknown' ? kGold : kDark)),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
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

  Future<void> _pickBirthDate() async {
    final l10n = AppLocalizations.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: l10n.locale,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kGold, onPrimary: kDark),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _birthDate = date;
        _birthDateError = null;
      });
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: kDark),
          decoration: _inputDeco(hint: hint, error: error),
        ),
      ],
    );
  }

  Widget _labelText(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark),
  );

  InputDecoration _inputDeco({required String hint, Widget? suffix, String? error}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
    errorText: error,
    errorStyle: const TextStyle(color: kErrorColor, fontSize: 11),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kErrorColor, width: 1.0)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kErrorColor, width: 1.5)),
    filled: true,
    fillColor: const Color(0x08FFFFFF),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGlassBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGlassBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGold, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _eyeIcon(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: kTextMuted, size: 20),
    onPressed: onTap,
  );

  /// "{terms} 및 {privacy}에 동의합니다" 템플릿을 파싱해서 두 키워드는 하이퍼링크로 렌더링.
  Widget _agreeTermsRichText(AppLocalizations l10n) {
    const baseStyle = TextStyle(fontSize: 13, color: kTextMuted);
    final linkStyle = TextStyle(
      fontSize: 13,
      color: kGold,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: kGold.withOpacity(0.7),
    );
    final template = l10n.agreeToTermsTemplate;
    final termsLabel = l10n.termsOfService;
    final privacyLabel = l10n.privacyPolicy;

    // placeholder 순서대로 3조각(또는 그 이상)으로 분할해 순서 유지
    final termsIdx = template.indexOf('{terms}');
    final privacyIdx = template.indexOf('{privacy}');
    final spans = <InlineSpan>[];

    int cursor = 0;
    // placeholder 위치를 오름차순으로 정렬
    final placeholders = <(int, String, TapGestureRecognizer)>[
      (termsIdx, '{terms}', TapGestureRecognizer()
        ..onTap = () => PolicySheet.show(context, PolicyType.terms)),
      (privacyIdx, '{privacy}', TapGestureRecognizer()
        ..onTap = () => PolicySheet.show(context, PolicyType.privacy)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    for (final p in placeholders) {
      final idx = p.$1;
      final token = p.$2;
      if (idx < 0) continue;
      if (idx > cursor) {
        spans.add(TextSpan(text: template.substring(cursor, idx), style: baseStyle));
      }
      final label = token == '{terms}' ? termsLabel : privacyLabel;
      spans.add(TextSpan(text: label, style: linkStyle, recognizer: p.$3));
      cursor = idx + token.length;
    }
    if (cursor < template.length) {
      spans.add(TextSpan(text: template.substring(cursor), style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
