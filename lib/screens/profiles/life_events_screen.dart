import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    setState(() { _loading = true; _error = null; });
    try {
      final events = await _api.getEvents(widget.profileId);
      setState(() => _events = events);
    } catch (e) {
      setState(() => _error = l10n.loadEventsFailed);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _api.deleteEvent(widget.profileId, eventId);
      await _loadEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteEventFailed)),
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
      builder: (_) => _EventFormSheet(
        profileId: widget.profileId,
        onSaved: _loadEvents,
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EventDetailSheet(
        event: event,
        profileId: widget.profileId,
        onEdit: () {
          Navigator.pop(context);
          _showEditSheet(event);
        },
        onDelete: () async {
          Navigator.pop(context);
          final eventId = event['id'] as String? ?? '';
          if (eventId.isNotEmpty) await _confirmDelete(eventId);
        },
      ),
    );
  }

  void _showEditSheet(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCosmicNavy.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EventFormSheet(
        profileId: widget.profileId,
        existingEvent: event,
        onSaved: _loadEvents,
      ),
    );
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
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.lifeEvents,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark),
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
                  ? _errorView(l10n)
                  : _events.isEmpty
                      ? _emptyView(l10n)
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

  Widget _errorView(AppLocalizations l10n) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: kTextMuted, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: kTextMuted)),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loadEvents,
          child: Text(l10n.retry, style: const TextStyle(color: kGold)),
        ),
      ],
    ),
  );

  Widget _emptyView(AppLocalizations l10n) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, color: kTextMuted.withOpacity(0.5), size: 52),
            const SizedBox(height: 16),
            Text(l10n.noEventsRecorded,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDark)),
            const SizedBox(height: 8),
            Text(
              l10n.noEventsDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kTextMuted, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddEventSheet,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addEvent),
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
    final l10n = AppLocalizations.of(context);
    final year = event['eventYear'] as int? ?? 0;
    final month = event['eventMonth'] as int?;
    final title = event['title'] as String? ?? '';
    final description = event['description'] as String? ?? '';
    final impact = event['impact'] as String? ?? 'neutral';

    final impactColor = _impactColor(impact);
    final impactLabel = _impactLabel(l10n, impact);

    return GestureDetector(
      onTap: () => _showDetailSheet(event),
      child: ClipRRect(
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
                        '$year${l10n.year}',
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: kSecondaryGold),
                      ),
                    ),
                    if (month != null) ...[
                      const SizedBox(height: 4),
                      Text('$month${l10n.month}',
                        style: const TextStyle(fontSize: 11, color: kTextMuted)),
                    ],
                  ],
                ),
                const SizedBox(width: 12),
                // Title + impact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : description,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
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
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: kTextMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String eventId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCosmicNavy.withOpacity(0.95),
        title: Text(l10n.deleteEvent, style: const TextStyle(color: kDark)),
        content: Text(l10n.deleteEventConfirm,
          style: const TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: kErrorColor)),
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

  String _impactLabel(AppLocalizations l10n, String impact) {
    switch (impact) {
      case 'very_positive': return l10n.impactVeryPositive;
      case 'positive': return l10n.impactPositive;
      case 'negative': return l10n.impactNegative;
      case 'very_negative': return l10n.impactVeryNegative;
      default: return l10n.impactNeutral;
    }
  }
}

// ─── Event Detail Bottom Sheet ────────────────────────────────────────────────

class _EventDetailSheet extends StatelessWidget {
  final Map<String, dynamic> event;
  final String profileId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventDetailSheet({
    required this.event,
    required this.profileId,
    required this.onEdit,
    required this.onDelete,
  });

  Color _impactColor(String impact) {
    switch (impact) {
      case 'very_positive': return const Color(0xFF4CAF50);
      case 'positive': return const Color(0xFF81C784);
      case 'negative': return const Color(0xFFE57373);
      case 'very_negative': return kErrorColor;
      default: return kTextMuted;
    }
  }

  String _impactLabel(AppLocalizations l10n, String impact) {
    switch (impact) {
      case 'very_positive': return l10n.impactVeryPositive;
      case 'positive': return l10n.impactPositive;
      case 'negative': return l10n.impactNegative;
      case 'very_negative': return l10n.impactVeryNegative;
      default: return l10n.impactNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = event['title'] as String? ?? '';
    final year = event['eventYear'] as int? ?? 0;
    final month = event['eventMonth'] as int?;
    final description = event['description'] as String? ?? '';
    final impact = event['impact'] as String? ?? 'neutral';

    final impactColor = _impactColor(impact);
    final impactLabel = _impactLabel(l10n, impact);
    final dateLabel = month != null ? '$year${l10n.year} $month${l10n.month}' : '$year${l10n.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: kGlassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: kDark),
            ),
            const SizedBox(height: 8),
          ],
          // Date + impact row
          Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 13, color: kSecondaryGold, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: impactColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: impactColor.withOpacity(0.4)),
                ),
                child: Text(
                  impactLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: impactColor),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: kGlassBorder, height: 1),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: kDark, height: 1.7),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.edit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGold,
                    side: const BorderSide(color: kGold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n.delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kErrorColor,
                    side: const BorderSide(color: kErrorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit Event Bottom Sheet ────────────────────────────────────────────

class _EventFormSheet extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? existingEvent;
  final VoidCallback onSaved;

  const _EventFormSheet({
    required this.profileId,
    this.existingEvent,
    required this.onSaved,
  });

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _year;
  late int? _month;
  late String _impact;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existingEvent != null;

  final ApiService _api = ApiService();

  static const _impacts = [
    ('very_positive', Color(0xFF4CAF50)),
    ('positive', Color(0xFF81C784)),
    ('neutral', Color(0xFF8B87A0)),
    ('negative', Color(0xFFE57373)),
    ('very_negative', Color(0xFFC8393A)),
  ];

  String _impactLabel(AppLocalizations l10n, String impact) {
    switch (impact) {
      case 'very_positive': return l10n.impactVeryPositive;
      case 'positive': return l10n.impactPositive;
      case 'negative': return l10n.impactNegative;
      case 'very_negative': return l10n.impactVeryNegative;
      default: return l10n.impactNeutral;
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existingEvent;
    _titleCtrl = TextEditingController(text: e?['title'] as String? ?? '');
    _descCtrl = TextEditingController(text: e?['description'] as String? ?? '');
    _year = e?['eventYear'] as int? ?? DateTime.now().year;
    _month = e?['eventMonth'] as int?;
    _impact = e?['impact'] as String? ?? 'neutral';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.eventTitleRequired);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.eventContentRequired);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isEdit) {
        final eventId = widget.existingEvent!['id'] as String;
        await _api.updateEvent(
          widget.profileId,
          eventId: eventId,
          eventYear: _year,
          eventMonth: _month,
          description: _descCtrl.text.trim(),
          impact: _impact,
          title: _titleCtrl.text.trim(),
        );
      } else {
        await _api.addEvent(
          widget.profileId,
          eventYear: _year,
          description: _descCtrl.text.trim(),
          impact: _impact,
          eventMonth: _month,
          title: _titleCtrl.text.trim(),
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = _isEdit ? l10n.updateEventFailed : l10n.addEventFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Text(
                  _isEdit ? l10n.editEvent : l10n.addEvent,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kDark),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Title input
            Text(l10n.eventTitle,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 14, color: kDark),
              decoration: InputDecoration(
                hintText: l10n.eventTitleHint,
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
            // Year input
            Text(l10n.eventYear,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
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
                      child: Text('$_year${l10n.year}',
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
            Text(l10n.eventMonthOptional,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _monthChip(null, l10n.allMonths),
                for (int m = 1; m <= 12; m++) _monthChip(m, '$m${l10n.month}'),
              ],
            ),
            const SizedBox(height: 16),
            // Description
            Text(l10n.eventContent,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: kDark),
              decoration: InputDecoration(
                hintText: l10n.eventContentHint,
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
            Text(l10n.impact,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
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
                          Text(_impactLabel(l10n, item.$1),
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
                    : Text(
                        _isEdit ? l10n.save : l10n.add,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
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
