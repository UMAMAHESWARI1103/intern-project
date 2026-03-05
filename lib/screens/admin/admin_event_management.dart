import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminEventManagementPage extends StatefulWidget {
  const AdminEventManagementPage({super.key});
  @override
  State<AdminEventManagementPage> createState() => _AdminEventManagementPageState();
}

class _AdminEventManagementPageState extends State<AdminEventManagementPage>
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

  // ── Compute status from event date ───────────────────────────
  String _computeStatus(Map<String, dynamic> e) {
    final stored = e['status']?.toString() ?? '';
    if (stored.isNotEmpty) return stored;
    try {
      final d = DateTime.parse(e['date']?.toString() ?? '');
      final now = DateTime.now();
      if (d.isAfter(now)) return 'Upcoming';
      if (d.isAfter(now.subtract(const Duration(days: 1)))) return 'Ongoing';
      return 'Completed';
    } catch (_) { return 'Upcoming'; }
  }

  List<Map<String, dynamic>> get _filtered => _events.where((e) {
    final q = _searchCtrl.text.toLowerCase();
    final matchSearch = q.isEmpty ||
        (e['title']      ?? '').toString().toLowerCase().contains(q) ||
        (e['templeName'] ?? '').toString().toLowerCase().contains(q);
    final status = _computeStatus(e);
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
        title: const Text('Event Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _openForm())],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Events'), Tab(text: 'Analytics')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text('Add Event'),
        onPressed: () => _openForm(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_eventsTab(), _analyticsTab()],
      ),
    );
  }

  // ── Events Tab ───────────────────────────────────────────────
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
                ? IconButton(icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _searchCtrl.clear(); setState(() {}); })
                : null,
            filled: true, fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent)),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: ['All', 'Upcoming', 'Ongoing', 'Completed'].map((f) {
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
          }).toList()),
        ),
      ]),
    ),

    // Summary chips
    if (!_isLoading && _error == null)
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(children: [
          _chip('Total',    '${_events.length}',                                                        Colors.blue),
          const SizedBox(width: 8),
          _chip('Upcoming', '${_events.where((e) => _computeStatus(e) == 'Upcoming').length}',          Colors.orange),
          const SizedBox(width: 8),
          _chip('Ongoing',  '${_events.where((e) => _computeStatus(e) == 'Ongoing').length}',           Colors.green),
          const SizedBox(width: 8),
          _chip('Done',     '${_events.where((e) => _computeStatus(e) == 'Completed').length}',         Colors.grey),
        ]),
      ),

    Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _errorView()
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🎪', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(_events.isEmpty ? 'No events added yet' : 'No events found',
                          style: const TextStyle(color: _textGrey, fontSize: 15)),
                      if (_events.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Event'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primary, foregroundColor: Colors.white),
                        ),
                      ],
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
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]),
  );

  Widget _eventCard(Map<String, dynamic> e) {
    final status       = _computeStatus(e);
    final statusColor  = _statusColor(status);
    final isFree       = e['isFree'] == true || (e['registrationFee'] ?? 0) == 0;
    final registered   = (e['registeredCount'] as num?)?.toInt() ?? 0;
    final maxP         = (e['maxParticipants']  as num?)?.toInt() ?? 0;
    final progress     = maxP > 0 ? (registered / maxP).clamp(0.0, 1.0) : 0.0;
    final title        = e['title']      ?? 'Event';
    final templeName   = e['templeName'] ?? '';
    final date         = e['date']       ?? '';
    final time         = e['time']       ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(
                (e['category'] == 'Festival') ? '🪔' :
                (e['category'] == 'Pooja')    ? '🛕' :
                (e['category'] == 'Special')  ? '✨' :
                (e['category'] == 'Cultural') ? '🎭' : '🎪',
                style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark))),
                  _statusBadge(status, statusColor),
                ]),
                const SizedBox(height: 4),
                if (templeName.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.temple_hindu, size: 12, color: _textGrey),
                    const SizedBox(width: 3),
                    Expanded(child: Text(templeName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textGrey, fontSize: 12))),
                  ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 12, color: _textGrey),
                  const SizedBox(width: 3),
                  Text('$date${time.isNotEmpty ? '  •  $time' : ''}',
                      style: const TextStyle(color: _textGrey, fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFree
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isFree ? 'Free' : 'Paid',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: isFree ? Colors.green : Colors.blue)),
                  ),
                ]),
              ]),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: _textGrey, size: 20),
              onSelected: (action) => _handleAction(action, e),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                PopupMenuItem(value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
  );

  // ── Analytics Tab ────────────────────────────────────────────
  Widget _analyticsTab() {
    final total      = _events.length;
    final upcoming   = _events.where((e) => _computeStatus(e) == 'Upcoming').length;
    final ongoing    = _events.where((e) => _computeStatus(e) == 'Ongoing').length;
    final completed  = _events.where((e) => _computeStatus(e) == 'Completed').length;
    final totalPax   = _events.fold<int>(0, (s, e) => s + ((e['registeredCount'] as num?)?.toInt() ?? 0));
    final freeEvents = _events.where((e) => e['isFree'] == true || (e['registrationFee'] ?? 0) == 0).length;

    final top3 = List<Map<String, dynamic>>.from(_events)
      ..sort((a, b) => ((b['registeredCount'] as num?)?.toInt() ?? 0)
          .compareTo((a['registeredCount'] as num?)?.toInt() ?? 0));

    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
        children: [
          _aCard('Total Events',    '$total',      Icons.event,         Colors.blue),
          _aCard('Upcoming',        '$upcoming',   Icons.upcoming,       Colors.orange),
          _aCard('Ongoing',         '$ongoing',    Icons.play_circle,    Colors.green),
          _aCard('Completed',       '$completed',  Icons.check_circle,   Colors.teal),
          _aCard('Total Attendees', '$totalPax',   Icons.people,         Colors.purple),
          _aCard('Free Events',     '$freeEvents', Icons.free_breakfast,  Colors.cyan),
        ],
      ),
      const SizedBox(height: 20),
      if (top3.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: _accent)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Top Events by Participation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: (pct / 100).clamp(0.0, 1.0),
                          backgroundColor: _accent, color: _primary, minHeight: 6)),
                  const SizedBox(height: 2),
                  Text('$pct% full', style: const TextStyle(fontSize: 11, color: _textGrey)),
                ]),
              );
            }),
          ]),
        ),
    ]);
  }

  Widget _aCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 6)]),
    child: Row(children: [
      Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
        Text(label, style: const TextStyle(fontSize: 10, color: _textGrey)),
      ])),
    ]),
  );

  // ── Add / Edit Form ──────────────────────────────────────────
  void _openForm({Map<String, dynamic>? event}) {
    final isEdit     = event != null;
    final titleCtrl  = TextEditingController(text: isEdit ? event['title']      ?? '' : '');
    final templeCtrl = TextEditingController(text: isEdit ? event['templeName'] ?? '' : '');
    final dateCtrl   = TextEditingController(text: isEdit ? event['date']       ?? '' : '');
    final timeCtrl   = TextEditingController(text: isEdit ? event['time']       ?? '' : '');
    final maxCtrl    = TextEditingController(text: isEdit ? '${event['maxParticipants'] ?? ''}' : '');
    final feeCtrl    = TextEditingController(text: isEdit ? '${event['registrationFee'] ?? 0}' : '0');
    final descCtrl   = TextEditingController(text: isEdit ? event['description'] ?? '' : '');
    bool isFree      = isEdit ? (event['isFree'] == true || (event['registrationFee'] ?? 0) == 0) : true;
    String category  = isEdit ? (event['category'] ?? 'Other') : 'Other';
    final formKey    = GlobalKey<FormState>();
    bool saving      = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text(isEdit ? 'Edit Event' : 'Add Event',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                  const SizedBox(height: 20),

                  _ff(titleCtrl,  'Event Title *',         Icons.event,         required: true),
                  const SizedBox(height: 12),
                  _ff(templeCtrl, 'Temple Name',           Icons.temple_hindu),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ff(dateCtrl, 'Date (YYYY-MM-DD) *', Icons.calendar_today, required: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _ff(timeCtrl, 'Time (e.g. 6:00 AM)', Icons.access_time)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ff(maxCtrl, 'Max Participants', Icons.people,
                        keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _ff(feeCtrl, 'Fee (₹)', Icons.currency_rupee,
                        keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _ff(descCtrl, 'Description', Icons.description_outlined, maxLines: 2),
                  const SizedBox(height: 12),

                  // Category
                  Row(children: [
                    const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        isDense: true,
                        decoration: InputDecoration(
                          filled: true, fillColor: _bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: ['Festival', 'Pooja', 'Special', 'Cultural', 'Other']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setSheet(() => category = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Free / Paid
                  Row(children: [
                    const Text('Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    ...['Free', 'Paid'].map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t), selected: (t == 'Free') == isFree,
                        onSelected: (_) => setSheet(() => isFree = t == 'Free'),
                        selectedColor: _primary,
                        labelStyle: TextStyle(
                            color: (t == 'Free') == isFree ? Colors.white : _textGrey,
                            fontWeight: FontWeight.w600),
                        backgroundColor: _accent,
                      ),
                    )),
                  ]),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => saving = true);
                        final data = {
                          'title':           titleCtrl.text.trim(),
                          'templeName':      templeCtrl.text.trim(),
                          'date':            dateCtrl.text.trim(),
                          'time':            timeCtrl.text.trim(),
                          'maxParticipants': int.tryParse(maxCtrl.text) ?? 500,
                          'registrationFee': double.tryParse(feeCtrl.text) ?? 0,
                          'isFree':          isFree,
                          'category':        category,
                          'description':     descCtrl.text.trim(),
                          'isActive':        true,
                        };
                        try {
                          if (isEdit) {
                            await ApiService.updateEvent(event['_id']?.toString() ?? '', data);
                          } else {
                            await ApiService.addEvent(data);
                          }
                          if (context.mounted) Navigator.pop(context);
                          _load();
                          _snack(isEdit ? 'Event updated ✓' : 'Event added ✓', _primary);
                        } catch (e) {
                          setSheet(() => saving = false);
                          _snack('Error: $e', Colors.red);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'Update Event' : 'Add Event',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ff(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) =>
      TextFormField(
        controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  void _handleAction(String action, Map<String, dynamic> e) {
    switch (action) {
      case 'edit':   _openForm(event: e); break;
      case 'delete': _deleteEvent(e); break;
    }
  }

  Future<void> _deleteEvent(Map<String, dynamic> e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${e['title']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _primary))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteEvent(e['_id']?.toString() ?? '');
        _load();
        _snack('Event deleted', Colors.red);
      } catch (err) {
        _snack('Failed to delete: $err', Colors.red);
      }
    }
  }

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, color: Colors.red, size: 48),
    const SizedBox(height: 12),
    Text(_error ?? 'Error', style: const TextStyle(color: Colors.grey)),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
        child: const Text('Retry')),
  ]));

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
}