import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/profiles_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/dancheong_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  DateTime? _birthDate;
  String? _birthHour;
  String _birthHourPrecision = 'unknown';
  String _gender = 'male';
  String _calendarType = 'solar';
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
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
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
      final dateStr =
          '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
      final result = await _api.createProfile(
        name: _nameCtrl.text.trim(),
        birthDate: dateStr,
        birthHour: _birthHourPrecision == 'unknown' ? null : _birthHour,
        birthHourPrecision: _birthHourPrecision,
        gender: _gender,
        calendarType: _calendarType,
        relationship: _relationshipCtrl.text.trim().isEmpty ? null : _relationshipCtrl.text.trim(),
      );
      await context.read<ProfilesProvider>().loadProfiles();
      // Fire-and-forget: trigger interpretation in background
      final profileId = result['profile']?['id'] as String?;
      if (profileId != null) {
        _api.triggerInterpretation(profileId).catchError((_) {});
      }
      if (mounted) context.pop();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '프로필 추가',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DancheongBar(),
                const SizedBox(height: 16),
                const Text(
                  '지인의 사주를 분석하려면 기본 정보를 입력하세요',
                  style: TextStyle(fontSize: 13, color: kTextMuted),
                ),
                const SizedBox(height: 24),
                _label('이름'),
                const SizedBox(height: 6),
                _field(controller: _nameCtrl, hint: '홍길동'),
                const SizedBox(height: 20),
                _label('관계'),
                const SizedBox(height: 6),
                _field(controller: _relationshipCtrl, hint: '예) 친구, 배우자, 부모님 (선택사항)'),
                const SizedBox(height: 20),
                _label('생년월일'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: _dateBox(),
                ),
                const SizedBox(height: 20),
                _label('성별'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _chip('남성', 'male', _gender, (v) => setState(() => _gender = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _chip('여성', 'female', _gender, (v) => setState(() => _gender = v))),
                ]),
                const SizedBox(height: 20),
                _label('달력 종류'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _chip('양력', 'solar', _calendarType, (v) => setState(() => _calendarType = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _chip('음력', 'lunar', _calendarType, (v) => setState(() => _calendarType = v))),
                ]),
                const SizedBox(height: 20),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _hours.map((h) {
                      final selected = _birthHour == h.$3;
                      return GestureDetector(
                        onTap: () => setState(() => _birthHour = h.$3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? kDancheongRed : const Color(0x0AFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? kDancheongRed : kGlassBorder),
                          ),
                          child: Column(
                            children: [
                              Text(h.$1,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: selected ? kDark : kDark)),
                              Text(h.$2,
                                style: TextStyle(fontSize: 9,
                                  color: selected ? kDark.withOpacity(0.8) : kTextMuted)),
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
                PrimaryButton(text: '프로필 추가', onPressed: _submit, loading: _loading),
                const SizedBox(height: 32),
              ],
            ),
          ),
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
        filled: true, fillColor: const Color(0x08FFFFFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGlassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGlassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGold, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dateBox() {
    return ClipRRect(
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
                    fontSize: 15, color: _birthDate == null ? kTextMuted : kDark),
                ),
              ),
              const Icon(Icons.calendar_today, color: kTextMuted, size: 18),
            ],
          ),
        ),
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
