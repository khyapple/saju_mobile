import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0=welcome, 1=form
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;
  String? _birthHour;
  String _birthHourPrecision = 'unknown';
  String _gender = 'male';
  String _calendarType = 'solar';
  bool _loading = false;
  String? _error;

  final ApiService _api = ApiService();

  // 12 시진 (2시간 간격)
  static const _hours = [
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kGold, onPrimary: kDark),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '이름을 입력해주세요.');
      return;
    }
    if (_birthDate == null) {
      setState(() => _error = '생년월일을 선택해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final birthDateStr =
          '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
      await _api.createProfile(
        name: _nameCtrl.text.trim(),
        birthDate: birthDateStr,
        birthHour: _birthHourPrecision == 'unknown' ? null : _birthHour,
        birthHourPrecision: _birthHourPrecision,
        gender: _gender,
        calendarType: _calendarType,
      );
      await _api.updateOnboardingStep('complete');
      if (mounted) context.go('/profiles');
    } catch (e) {
      setState(() => _error = '프로필 생성에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        child: SafeArea(
          child: _step == 0 ? _buildWelcome() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    final name = context.read<AuthProvider>().displayName;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            '사주',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: kGold,
              fontWeight: FontWeight.w300,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '안녕하세요, ${name.isNotEmpty ? name : ''}님',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AI가 당신의 사주를 분석해\n삶의 흐름을 알려드립니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: kTextMuted, height: 1.6),
          ),
          const SizedBox(height: 48),
          // Feature cards as GlassCards
          ...[
            ('✦', '정확한 사주 계산', '만세력 기반 정밀 계산'),
            ('✦', 'AI 해석', '클로드 AI가 상세히 분석'),
            ('✦', '오행 분석', '목화토금수 균형 파악'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(item.$1,
                        style: const TextStyle(color: kGold, fontSize: 16)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kDark,
                          ),
                        ),
                        Text(
                          item.$3,
                          style: const TextStyle(fontSize: 12, color: kTextMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          PrimaryButton(
            text: '시작하기',
            onPressed: () => setState(() => _step = 1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: kDark),
                onPressed: () => setState(() => _step = 0),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 4),
              const Text(
                '기본 정보 입력',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '사주 분석을 위해 정확한 정보를 입력해주세요',
            style: TextStyle(fontSize: 13, color: kTextMuted),
          ),
          const SizedBox(height: 24),
          // 이름
          _sectionLabel('이름'),
          const SizedBox(height: 6),
          _textField(controller: _nameCtrl, hint: '홍길동'),
          const SizedBox(height: 20),
          // 생년월일
          _sectionLabel('생년월일'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x08FFFFFF),
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
                            color: _birthDate == null ? kTextMuted : kDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: kTextMuted, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 성별
          _sectionLabel('성별'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _selectButton('남성', 'male', _gender, (v) => setState(() => _gender = v))),
              const SizedBox(width: 12),
              Expanded(child: _selectButton('여성', 'female', _gender, (v) => setState(() => _gender = v))),
            ],
          ),
          const SizedBox(height: 20),
          // 달력 종류
          _sectionLabel('달력 종류'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _selectButton('양력', 'solar', _calendarType, (v) => setState(() => _calendarType = v))),
              const SizedBox(width: 12),
              Expanded(child: _selectButton('음력', 'lunar', _calendarType, (v) => setState(() => _calendarType = v))),
            ],
          ),
          const SizedBox(height: 20),
          // 태어난 시간
          _sectionLabel('태어난 시간'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _selectButton('정확히 앎', 'exact', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
              const SizedBox(width: 8),
              Expanded(child: _selectButton('대략 앎', 'rough', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
              const SizedBox(width: 8),
              Expanded(child: _selectButton('모름', 'unknown', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
            ],
          ),
          if (_birthHourPrecision == 'exact') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hours.map((h) {
                final selected = _birthHour == h.$3;
                return GestureDetector(
                  onTap: () => setState(() => _birthHour = h.$3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? kGold : const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? kGold : kGlassBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          h.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected ? kDark : kDark,
                          ),
                        ),
                        Text(
                          h.$2,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? kDark.withOpacity(0.7) : kTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kErrorColor.withOpacity(0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: kErrorColor, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 28),
          PrimaryButton(text: '분석 시작', onPressed: _submit, loading: _loading),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: kDark,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, color: kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
        filled: true,
        fillColor: const Color(0x08FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _selectButton(
    String label,
    String value,
    String current,
    void Function(String) onTap,
  ) {
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? kDark : kTextMuted,
            ),
          ),
        ),
      ),
    );
  }
}
