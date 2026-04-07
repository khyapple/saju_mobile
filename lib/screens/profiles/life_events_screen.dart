import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class LifeEventsScreen extends StatefulWidget {
  final String profileId;

  const LifeEventsScreen({super.key, required this.profileId});

  @override
  State<LifeEventsScreen> createState() => _LifeEventsScreenState();
}

class _LifeEventsScreenState extends State<LifeEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final events = await _api.getEvents(widget.profileId);
      setState(() => _events = events);
    } catch (e) {
      setState(() => _error = '이벤트를 불러올 수 없습니다.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _api.deleteEvent(widget.profileId, eventId);
      await _loadEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이벤트 삭제에 실패했습니다.')),
        );
      }
    }
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEventSheet(
        profileId: widget.profileId,
        onAdded: _loadEvents,
      ),
    );
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
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '생활 이벤트',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventSheet,
        backgroundColor: kGold,
        foregroundColor: kInk,
        child: const Icon(Icons.add),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kGold))
              : _error != null
                  ? _errorView()
                  : _events.isEmpty
                      ? _emptyView()
                      : RefreshIndicator(
                          color: kGold,
                          onRefresh: _loadEvents,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            itemCount: _events.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _eventCard(_events[i]),
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _errorView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: kTextMuted, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: kTextMuted)),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loadEvents,
          child: const Text('다시 시도', style: TextStyle(color: kGold)),
        ),
      ],
    ),
  );

  Widget _emptyView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, color: kTextMuted.withOpacity(0.5), size: 52),
            const SizedBox(height: 16),
            const Text('기록된 생활 이벤트가 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark)),
            const SizedBox(height: 8),
            const Text(
              '인생의 주요 사건을 기록하면\nAI 해석의 정확도가 높아집니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextMuted, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddEventSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('이벤트 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: kInk,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _eventCard(Map<String, dynamic> event) {
    final eventId = event['id'] as String? ?? '';
    final year = event['eventYear'] as int? ?? 0;
    final month = event['eventMonth'] as int?;
    final description = event['description'] as String? ?? '';
    final impact = event['impact'] as String? ?? 'neutral';

    final impactColor = _impactColor(impact);
    final impactLabel = _impactLabel(impact);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kGlassBorder, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year column
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$year년',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: kSecondaryGold),
                    ),
                  ),
                  if (month != null) ...[
                    const SizedBox(height: 4),
                    Text('$month월',
                      style: const TextStyle(fontSize: 11, color: kTextMuted)),
                  ],
                ],
              ),
              const SizedBox(width: 12),
              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description,
                      style: const TextStyle(fontSize: 14, color: kDark, height: 1.5)),
                    const SizedBox(height: 8),
                    // Impact badge — glass background with color accent
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: impactColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: impactColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        impactLabel,
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: impactColor),
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              if (eventId.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: kTextMuted),
                  onPressed: () => _confirmDelete(eventId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        title: const Text('이벤트 삭제', style: TextStyle(color: kDark)),
        content: const Text('이 이벤트를 삭제하시겠습니까?',
          style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteEvent(eventId);
  }

  Color _impactColor(String impact) {
    switch (impact) {
      case 'very_positive': return const Color(0xFF4CAF50);
      case 'positive': return const Color(0xFF81C784);
      case 'negative': return const Color(0xFFE57373);
      case 'very_negative': return kErrorColor;
      default: return kTextMuted;
    }
  }

  String _impactLabel(String impact) {
    switch (impact) {
      case 'very_positive': return '매우 긍정';
      case 'positive': return '긍정';
      case 'negative': return '부정';
      case 'very_negative': return '매우 부정';
      default: return '중립';
    }
  }
}

// ─── Add Event Bottom Sheet ────────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final String profileId;
  final VoidCallback onAdded;

  const _AddEventSheet({required this.profileId, required this.onAdded});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _descCtrl = TextEditingController();
  int _year = DateTime.now().year;
  int? _month;
  String _impact = 'neutral';
  bool _loading = false;
  String? _error;

  final ApiService _api = ApiService();

  static const _impacts = [
    ('very_positive', '매우긍정', Color(0xFF4CAF50)),
    ('positive', '긍정', Color(0xFF81C784)),
    ('neutral', '중립', Color(0xFF8B87A0)),
    ('negative', '부정', Color(0xFFE57373)),
    ('very_negative', '매우부정', Color(0xFFC8393A)),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _error = '내용을 입력해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _api.addEvent(
        widget.profileId,
        eventYear: _year,
        description: _descCtrl.text.trim(),
        impact: _impact,
        eventMonth: _month,
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '이벤트 추가에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('이벤트 추가',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark)),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Year input
            const Text('연도',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.remove_circle_outline, color: kGold),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGlassBorder),
                    ),
                    child: Center(
                      child: Text('$_year년',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (_year < DateTime.now().year) _year++;
                  }),
                  icon: const Icon(Icons.add_circle_outline, color: kGold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Month input (optional)
            const Text('월 (선택사항)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _monthChip(null, '전체'),
                for (int m = 1; m <= 12; m++) _monthChip(m, '$m월'),
              ],
            ),
            const SizedBox(height: 16),
            // Description
            const Text('내용',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: kDark),
              decoration: InputDecoration(
                hintText: '어떤 일이 있었나요? (예: 결혼, 이직, 사고 등)',
                hintStyle: const TextStyle(color: kTextMuted, fontSize: 13),
                filled: true, fillColor: const Color(0x08FFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kGlassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kGlassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kGold, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            // Impact selector
            const Text('영향도',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Row(
              children: _impacts.map((item) {
                final selected = _impact == item.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _impact = item.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? kGold : const Color(0x0AFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? kGold : kGlassBorder,
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selected ? Icons.check_circle : Icons.circle_outlined,
                            size: 14,
                            color: selected ? kInk : kTextMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(item.$2,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                              color: selected ? kInk : kTextMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kInk,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: kInk, strokeWidth: 2))
                    : const Text('추가',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthChip(int? month, String label) {
    final selected = _month == month;
    return GestureDetector(
      onTap: () => setState(() => _month = month),
      child: SizedBox(
        width: 48,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kGold : const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? kGold : kGlassBorder,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(fontSize: 12,
                color: selected ? kInk : kTextMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
          ),
        ),
      ),
    );
  }
}
