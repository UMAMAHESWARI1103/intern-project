import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// ── RENAMED from AdminEventManagementPage → AdminEventRegistrationsPage
// This file shows event registrations (who registered for which event).
// The actual event CRUD lives in admin_event_management.dart.

class AdminEventRegistrationsPage extends StatefulWidget {
  const AdminEventRegistrationsPage({super.key});
  @override
  State<AdminEventRegistrationsPage> createState() =>
      _AdminEventRegistrationsPageState();
}

class _AdminEventRegistrationsPageState
    extends State<AdminEventRegistrationsPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _filter    = 'All';

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Events'), Tab(text: 'Analytics')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_eventsTab(), _analyticsTab()],
      ),
    );
  }

  Widget _eventsTab() => Column(children: [
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

    if (!_isLoading && _error == null)
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(children: [
          _chip('Total',    '${_events.length}',                                                Colors.blue),
          const SizedBox(width: 8),
          _chip('Upcoming', '${_events.where((e) => _computeStatus(e) == 'Upcoming').length}', Colors.orange),
          const SizedBox(width: 8),
          _chip('Ongoing',  '${_events.where((e) => _computeStatus(e) == 'Ongoing').length}',  Colors.green),
          const SizedBox(width: 8),
          _chip('Done',     '${_events.where((e) => _computeStatus(e) == 'Completed').length}',Colors.grey),
        ]),
      ),

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
                          style: const TextStyle(color: _textGrey, fontSize: 15),
                        ),
                      ]))
                  : RefreshIndicator(
                      color: _primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _eventCard(_filtered[i]),
                      ),
                    ),
    ),
  ]);

  Widget _chip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Column(children: [
      Text(value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]),
  );

  Widget _eventCard(Map<String, dynamic> e) {
    final status      = _computeStatus(e);
    final statusColor = _statusColor(status);
    final isFree      = e['isFree'] == true || (e['registrationFee'] ?? 0) == 0;
    final registered  = (e['registeredCount'] as num?)?.toInt() ?? 0;
    final maxP        = (e['maxParticipants']  as num?)?.toInt() ?? 0;
    final progress    = maxP > 0 ? (registered / maxP).clamp(0.0, 1.0) : 0.0;
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
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                if (templeName.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.temple_hindu, size: 12, color: _textGrey),
                    const SizedBox(width: 3),
                    Expanded(child: Text(templeName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textGrey, fontSize: 12))),
                  ]),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today, size: 11, color: _textGrey),
                      const SizedBox(width: 3),
                      Text(date, style: const TextStyle(color: _textGrey, fontSize: 11)),
                    ]),
                    if (time.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.access_time, size: 11, color: _textGrey),
                        const SizedBox(width: 3),
                        Text(time, style: const TextStyle(color: _textGrey, fontSize: 11)),
                      ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.how_to_reg, size: 12, color: _primary),
                  const SizedBox(width: 4),
                  Text('$registered registered',
                      style: const TextStyle(
                          fontSize: 12, color: _primary, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ]),
        ),
        if (maxP > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Participants: $registered/$maxP',
                    style: const TextStyle(fontSize: 12, color: _textGrey)),
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: progress >= 1.0 ? Colors.red : _primary)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress, backgroundColor: _accent,
                  color: progress >= 1.0 ? Colors.red : _primary, minHeight: 6,
                ),
              ),
            ]),
          ),
      ]),
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _analyticsTab() {
    final total      = _events.length;
    final upcoming   = _events.where((e) => _computeStatus(e) == 'Upcoming').length;
    final ongoing    = _events.where((e) => _computeStatus(e) == 'Ongoing').length;
    final completed  = _events.where((e) => _computeStatus(e) == 'Completed').length;
    final totalPax   = _events.fold<int>(
        0, (s, e) => s + ((e['registeredCount'] as num?)?.toInt() ?? 0));
    final freeEvents = _events
        .where((e) => e['isFree'] == true || (e['registrationFee'] ?? 0) == 0)
        .length;

    final top3 = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => ((b['registeredCount'] as num?)?.toInt() ?? 0)
          .compareTo((a['registeredCount'] as num?)?.toInt() ?? 0));

    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
        children: [
          _aCard('Total Events',    '$total',      Icons.event,          Colors.blue),
          _aCard('Upcoming',        '$upcoming',   Icons.upcoming,        Colors.orange),
          _aCard('Ongoing',         '$ongoing',    Icons.play_circle,     Colors.green),
          _aCard('Completed',       '$completed',  Icons.check_circle,    Colors.teal),
          _aCard('Total Attendees', '$totalPax',   Icons.people,          Colors.purple),
          _aCard('Free Events',     '$freeEvents', Icons.free_breakfast,  Colors.cyan),
        ],
      ),
      const SizedBox(height: 20),
      if (top3.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Top Events by Registration',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
            const SizedBox(height: 14),
            ...top3.take(3).map((e) {
              final reg  = (e['registeredCount'] as num?)?.toInt() ?? 0;
              final maxP = (e['maxParticipants']  as num?)?.toInt() ?? 0;
              final pct  = maxP > 0 ? (reg / maxP * 100).toInt() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(e['title'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: _textDark))),
                    Text('$reg pax',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          backgroundColor: _accent, color: _primary, minHeight: 6)),
                  const SizedBox(height: 2),
                  Text('$pct% full',
                      style: const TextStyle(fontSize: 11, color: _textGrey)),
                ]),
              );
            }),
          ]),
        ),
    ]);
  }

  Widget _aCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 6)
            ]),
        child: Row(children: [
          Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
            Text(label, style: const TextStyle(fontSize: 10, color: _textGrey)),
          ])),
        ]),
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
  ]));
}