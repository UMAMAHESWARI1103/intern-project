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
  String _filter = 'All';

  List<Map<String, dynamic>> _registrations = [];
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
      final raw = await ApiService.getAdminEventRegistrations();
      if (mounted) {
        setState(() {
          _registrations = raw;
          _isLoading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // Extract event info — handles both nested {event: {}} and flat fields
  String _eventTitle(Map r) =>
      (r['event']?['title'] ?? r['eventTitle'] ?? r['title'] ?? 'Event').toString();
  String _eventDate(Map r) =>
      (r['event']?['date'] ?? r['eventDate'] ?? r['date'] ?? '').toString();
  String _eventTime(Map r) =>
      (r['event']?['time'] ?? r['eventTime'] ?? r['time'] ?? '').toString();
  String _eventCategory(Map r) =>
      (r['event']?['category'] ?? r['category'] ?? '').toString();

  // Extract registrant info — handles both nested {user: {}} and flat fields
  String _userName(Map r) =>
      (r['user']?['name'] ?? r['userName'] ?? r['name'] ?? 'Unknown').toString();
  String _userEmail(Map r) =>
      (r['user']?['email'] ?? r['userEmail'] ?? r['email'] ?? '').toString();
  String _userPhone(Map r) =>
      (r['user']?['phone'] ?? r['userPhone'] ?? r['phone'] ?? '').toString();

  String _regStatus(Map r) =>
      (r['status'] ?? 'Confirmed').toString();

  /// Safely parses both ISO-8601 and JS-style date strings like
  /// "Mon Mar 16 2026 13:02:25 GMT+0530 India Standard Time"
  String _shortDate(String raw) {
    if (raw.isEmpty) return '';
    // Try standard ISO parse first
    try {
      final d = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {}

    // Fallback: handle JS-style "Mon Mar 16 2026 13:02:25 GMT+0530 ..."
    try {
      final parts = raw.trim().split(RegExp(r'\s+'));
      // Expected: [DayName, MonthName, Day, Year, ...]
      if (parts.length >= 4) {
        return '${parts[2]} ${parts[1]} ${parts[3]}';
      }
    } catch (_) {}

    // Last resort: just show first 11 chars to avoid overflow
    return raw.length > 11 ? raw.substring(0, 11) : raw;
  }

  List<Map<String, dynamic>> get _filtered => _registrations.where((r) {
    final q     = _searchCtrl.text.toLowerCase();
    final match = q.isEmpty ||
        _eventTitle(r).toLowerCase().contains(q) ||
        _userName(r).toLowerCase().contains(q) ||
        _userEmail(r).toLowerCase().contains(q);
    final status      = _regStatus(r);
    final matchFilter = _filter == 'All' ||
        status.toLowerCase() == _filter.toLowerCase();
    return match && matchFilter;
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
        // ── Search + Filter ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by event, name or email...',
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
                children: ['All', 'Confirmed', 'Pending', 'Cancelled'].map((f) {
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

        // ── Count ────────────────────────────────────────────────────────
        if (!_isLoading && _error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            child: Row(children: [
              const Icon(Icons.how_to_reg, size: 14, color: _textGrey),
              const SizedBox(width: 6),
              Text(
                '${_filtered.length} registration${_filtered.length == 1 ? "" : "s"}',
                style: const TextStyle(fontSize: 12, color: _textGrey),
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
                            const Text('📋', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _registrations.isEmpty
                                  ? 'No registrations yet'
                                  : 'No results found',
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
                            itemBuilder: (_, i) =>
                                _registrationCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  // ── Registration card ─────────────────────────────────────────────────────
  Widget _registrationCard(Map<String, dynamic> r) {
    final eventTitle  = _eventTitle(r);
    final eventDate   = _eventDate(r);
    final eventTime   = _eventTime(r);
    final category    = _eventCategory(r);
    final userName    = _userName(r);
    final userEmail   = _userEmail(r);
    final userPhone   = _userPhone(r);
    final status      = _regStatus(r);
    final statusColor = _statusColor(status);
    final registeredAt =
        (r['registeredAt'] ?? r['createdAt'] ?? '').toString();

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
        // ── Event header ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category icon
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(
                  category == 'Festival' ? '🪔' :
                  category == 'Pooja'    ? '🛕' :
                  category == 'Special'  ? '✨' :
                  category == 'Cultural' ? '🎭' : '🎪',
                  style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),

              // Title + date/time — Expanded so it never overflows
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _textDark),
                    ),
                    const SizedBox(height: 3),
                    // ── FIX: wrap date+time in its own Expanded row ──
                    Row(
                      children: [
                        if (eventDate.isNotEmpty) ...[
                          const Icon(Icons.calendar_today,
                              size: 10, color: _textGrey),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _shortDate(eventDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: _textGrey),
                            ),
                          ),
                        ],
                        if (eventTime.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time,
                              size: 10, color: _textGrey),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              eventTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: _textGrey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              // ── Status badge stays fixed on the right ──
              _statusBadge(status, statusColor),
            ],
          ),
        ),

        // ── Registrant details ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _detailRow(Icons.person_outline, userName,
                _textDark, bold: true),
            if (userEmail.isNotEmpty) ...[
              const SizedBox(height: 6),
              _detailRow(Icons.email_outlined, userEmail, _textGrey),
            ],
            if (userPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              _detailRow(Icons.phone_outlined, userPhone, _textGrey),
            ],
            if (registeredAt.isNotEmpty) ...[
              const SizedBox(height: 6),
              _detailRow(Icons.access_time_outlined,
                  'Registered on ${_shortDate(registeredAt)}', _textGrey),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String text, Color color,
      {bool bold = false}) =>
      Row(children: [
        Icon(icon, size: 13, color: _textGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight:
                      bold ? FontWeight.w600 : FontWeight.normal)),
        ),
      ]);

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'confirmed' => Colors.green,
    'pending'   => Colors.orange,
    'cancelled' => Colors.red,
    _           => Colors.blue,
  };

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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