import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
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
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.nameRequired);
      return;
    }
    if (_birthDate == null) {
      setState(() => _error = l10n.birthDateRequired);
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
      if (mounted) {
        final l10nCtx = AppLocalizations.of(context);
        setState(() => _error = l10nCtx.createProfileFailed);
      }
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
    final l10n = AppLocalizations.of(context);
    final name = context.read<AuthProvider>().displayName;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: kGold,
              fontWeight: FontWeight.w300,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helloUser(name.isNotEmpty ? name : ''),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: kTextMuted, height: 1.6),
          ),
          const SizedBox(height: 48),
          // Feature cards as GlassCards
          ...[
            ('✦', l10n.onboardingFeatureCalcTitle, l10n.onboardingFeatureCalcDesc),
            ('✦', l10n.onboardingFeatureAiTitle, l10n.onboardingFeatureAiDesc),
            ('✦', l10n.onboardingFeatureElementsTitle, l10n.onboardingFeatureElementsDesc),
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
            text: l10n.getStarted,
            onPressed: () => setState(() => _step = 1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.basicInfo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.basicInfoDesc,
            style: const TextStyle(fontSize: 13, color: kTextMuted),
          ),
          const SizedBox(height: 24),
          // 이름
          _sectionLabel(l10n.name),
          const SizedBox(height: 6),
          _textField(controller: _nameCtrl, hint: l10n.nameHint),
          const SizedBox(height: 20),
          // 생년월일
          _sectionLabel(l10n.birthDate),
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
            ),
          ),
          const SizedBox(height: 20),
          // 성별
          _sectionLabel(l10n.gender),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _selectButton(l10n.male, 'male', _gender, (v) => setState(() => _gender = v))),
              const SizedBox(width: 12),
              Expanded(child: _selectButton(l10n.female, 'female', _gender, (v) => setState(() => _gender = v))),
            ],
          ),
          const SizedBox(height: 20),
          // 달력 종류
          _sectionLabel(l10n.calendarType),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _selectButton(l10n.solar, 'solar', _calendarType, (v) => setState(() => _calendarType = v))),
              const SizedBox(width: 12),
              Expanded(child: _selectButton(l10n.lunar, 'lunar', _calendarType, (v) => setState(() => _calendarType = v))),
            ],
          ),
          const SizedBox(height: 20),
          // 태어난 시간
          _sectionLabel(l10n.birthHour),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _selectButton(l10n.knowExactly, 'exact', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
              const SizedBox(width: 8),
              Expanded(child: _selectButton(l10n.knowRoughly, 'rough', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
              const SizedBox(width: 8),
              Expanded(child: _selectButton(l10n.unknown, 'unknown', _birthHourPrecision, (v) => setState(() => _birthHourPrecision = v))),
            ],
          ),
          if (_birthHourPrecision == 'exact') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: l10n.birthHourList.map((h) {
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
          PrimaryButton(text: l10n.startAnalysisAction, onPressed: _submit, loading: _loading),
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
