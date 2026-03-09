import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminEventRegistrationsPage extends StatefulWidget {
  const AdminEventRegistrationsPage({super.key});
  @override
  State<AdminEventRegistrationsPage> createState() =>
      _AdminEventRegistrationsPageState();
}

class _AdminEventRegistrationsPageState
    extends State<AdminEventRegistrationsPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  final _searchCtrl = TextEditingController();
  String _filter    = 'All';

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ApiService.getAllEvents();
      if (mounted) {
        setState(() {
          _events    = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _computeStatus(Map<String, dynamic> e) {
    final stored = e['status']?.toString() ?? '';
    if (stored.isNotEmpty) return stored;
    try {
      final d   = DateTime.parse(e['date']?.toString() ?? '');
      final now = DateTime.now();
      if (d.isAfter(now)) return 'Upcoming';
      if (d.isAfter(now.subtract(const Duration(days: 1)))) return 'Ongoing';
      return 'Completed';
    } catch (_) { return 'Upcoming'; }
  }

  List<Map<String, dynamic>> get _filtered => _events.where((e) {
    final q           = _searchCtrl.text.toLowerCase();
    final matchSearch = q.isEmpty ||
        (e['title']      ?? '').toString().toLowerCase().contains(q) ||
        (e['templeName'] ?? '').toString().toLowerCase().contains(q);
    final status      = _computeStatus(e);
    final matchFilter = _filter == 'All' || status == _filter;
    return matchSearch && matchFilter;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Event Registrations',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        // ── Search + Filter bar ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search events or temples...',
                prefixIcon: const Icon(Icons.search, color: _primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
                filled: true, fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Upcoming', 'Ongoing', 'Completed'].map((f) {
                  final active = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f), selected: active,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: _primary,
                      labelStyle: TextStyle(
                          color: active ? Colors.white : _textGrey,
                          fontWeight: FontWeight.w600, fontSize: 12),
                      backgroundColor: _accent,
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _filtered.isEmpty
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎪', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _events.isEmpty
                                  ? 'No registrations yet'
                                  : 'No events found',
                              style: const TextStyle(
                                  color: _textGrey, fontSize: 15),
                            ),
                          ]))
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _eventCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _eventCard(Map<String, dynamic> e) {
    final status      = _computeStatus(e);
    final statusColor = _statusColor(status);
    final isFree      = e['isFree'] == true || (e['registrationFee'] ?? 0) == 0;
    final maxP        = (e['maxParticipants'] as num?)?.toInt() ?? 0;
    final registered  = (e['registeredCount'] as num?)?.toInt() ?? 0;
    final title       = e['title']      ?? 'Event';
    final templeName  = e['templeName'] ?? '';
    final date        = e['date']       ?? '';
    final time        = e['time']       ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent),
        boxShadow: [BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Icon ──────────────────────────────────────────────────────
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              (e['category'] == 'Festival') ? '🪔' :
              (e['category'] == 'Pooja')    ? '🛕' :
              (e['category'] == 'Special')  ? '✨' :
              (e['category'] == 'Cultural') ? '🎭' : '🎪',
              style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 10),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title + status
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, color: _textDark)),
                ),
                const SizedBox(width: 6),
                _statusBadge(status, statusColor),
              ]),
              const SizedBox(height: 4),

              // Temple name
              if (templeName.isNotEmpty)
                Row(children: [
                  const Icon(Icons.temple_hindu, size: 12, color: _textGrey),
                  const SizedBox(width: 3),
                  Expanded(child: Text(templeName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _textGrey, fontSize: 12))),
                ]),
              const SizedBox(height: 3),

              // Date / time / free badge
              Wrap(
                spacing: 6, runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (date.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: _textGrey),
                      const SizedBox(width: 3),
                      Text(date,
                          style: const TextStyle(
                              color: _textGrey, fontSize: 11)),
                    ]),
                  if (time.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time,
                          size: 11, color: _textGrey),
                      const SizedBox(width: 3),
                      Text(time,
                          style: const TextStyle(
                              color: _textGrey, fontSize: 11)),
                    ]),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFree
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isFree ? 'Free' : 'Paid',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold,
                            color: isFree ? Colors.green : Colors.blue)),
                  ),
                ],
              ),

              // Participants progress bar — only shown when maxP > 0
              // AND at least 1 person has registered
              if (maxP > 0 && registered > 0) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('Participants: $registered/$maxP',
                      style: const TextStyle(
                          fontSize: 12, color: _textGrey)),
                  Text(
                    '${((registered / maxP) * 100).clamp(0, 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: registered >= maxP ? Colors.red : _primary),
                  ),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (registered / maxP).clamp(0.0, 1.0),
                    backgroundColor: _accent,
                    color: registered >= maxP ? Colors.red : _primary,
                    minHeight: 6,
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'Upcoming'  => Colors.orange,
    'Ongoing'   => Colors.green,
    'Completed' => Colors.grey,
    _           => Colors.blue,
  };

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6)),
    child: Text(status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Error', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 12),
      ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary, foregroundColor: Colors.white),
          child: const Text('Retry')),
    ]),
  );
}