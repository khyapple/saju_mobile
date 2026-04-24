import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _birthDate ?? DateTime(1990);
    int year = initial.year;
    int month = initial.month;
    int day = initial.day;

    final now = DateTime.now();
    final years = List.generate(now.year - 1900 + 1, (i) => 1900 + i).reversed.toList();
    final months = List.generate(12, (i) => i + 1);

    int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final days = List.generate(daysInMonth(year, month), (i) => i + 1);
          if (day > days.length) day = days.length;

          final yearCtrl = FixedExtentScrollController(
              initialItem: years.indexOf(year).clamp(0, years.length - 1));
          final monthCtrl = FixedExtentScrollController(initialItem: month - 1);
          final dayCtrl = FixedExtentScrollController(initialItem: day - 1);

          Widget _wheel(List<int> items, FixedExtentScrollController ctrl,
              String Function(int) label, void Function(int) onChange) {
            return Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: ctrl,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 1.6,
                onSelectedItemChanged: (i) {
                  onChange(items[i]);
                  setSheetState(() {});
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: items.length,
                  builder: (_, i) {
                    final selected = ctrl.selectedItem == i;
                    return Center(
                      child: Text(
                        label(items[i]),
                        style: TextStyle(
                          fontSize: selected ? 18 : 15,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? kGold : kDark.withOpacity(0.35),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF2060611),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: const Border(top: BorderSide(color: Color(0x33FFFFFF), width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: kGlassBorder, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.selectBirthDate,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
                      const SizedBox(height: 16),

                      // 선택 하이라이트 바
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 휠들
                          SizedBox(
                            height: 200,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                _wheel(years, yearCtrl, (v) => l10n.locale.languageCode == 'en' ? '$v' : '$v${l10n.year}', (v) => year = v),
                                _wheel(months, monthCtrl, (v) => l10n.locale.languageCode == 'en' ? '$v' : '$v${l10n.month}', (v) => month = v),
                                _wheel(days, dayCtrl, (v) => l10n.locale.languageCode == 'en' ? '$v' : '$v${l10n.day}', (v) => day = v),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                          // 중앙 선택 영역 하이라이트
                          IgnorePointer(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 78),
                                Container(
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: kGold.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kGold.withOpacity(0.2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _birthDate = DateTime(year, month, day));
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: kInk,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(l10n.done,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
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
      setState(() => _error = l10n.createProfileFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          icon: const Icon(Icons.close, color: kDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.addProfile,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DancheongBar(),
                const SizedBox(height: 20),
                _label(l10n.name),
                const SizedBox(height: 6),
                _field(controller: _nameCtrl, hint: l10n.nameHint),
                const SizedBox(height: 20),
                _label(l10n.relationship),
                const SizedBox(height: 6),
                _field(controller: _relationshipCtrl, hint: l10n.relationshipHint),
                const SizedBox(height: 20),
                _label(l10n.birthDate),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: _dateBox(l10n),
                ),
                const SizedBox(height: 20),
                _label(l10n.gender),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _chip(l10n.male, 'male', _gender, (v) => setState(() => _gender = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _chip(l10n.female, 'female', _gender, (v) => setState(() => _gender = v))),
                ]),
                const SizedBox(height: 20),
                _label(l10n.calendarType),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _chip(l10n.solar, 'solar', _calendarType, (v) => setState(() => _calendarType = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _chip(l10n.lunar, 'lunar', _calendarType, (v) => setState(() => _calendarType = v))),
                ]),
                const SizedBox(height: 20),
                _label(l10n.birthHour),
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
                PrimaryButton(text: l10n.addProfile, onPressed: _submit, loading: _loading),
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

  Widget _dateBox(AppLocalizations l10n) {
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
                      ? l10n.selectDate
                      : l10n.formatBirthDate(_birthDate!.year, _birthDate!.month, _birthDate!.day),
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
