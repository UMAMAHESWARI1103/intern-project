// lib/screens/admin/admin_event_registrations.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminEventRegistrationsPage extends StatefulWidget {
  const AdminEventRegistrationsPage({super.key});
  @override
  State<AdminEventRegistrationsPage> createState() => _AdminEventRegistrationsPageState();
}

class _AdminEventRegistrationsPageState extends State<AdminEventRegistrationsPage> {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _bg      = Color(0xFFFFF8F0);

  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await ApiService.loadToken();
      final response = await ApiService.get('admin/event-registrations');
      final List raw = response['registrations'] ?? response ?? [];
      if (mounted) {
        setState(() {
          _registrations = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _registrations;
    return _registrations.where((r) {
      return (r['userName']   ?? '').toString().toLowerCase().contains(q) ||
             (r['userEmail']  ?? '').toString().toLowerCase().contains(q) ||
             (r['eventTitle'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Event Registrations', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, email, event...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _search.clear(); setState(() {}); })
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: _bg,
            ),
          ),
        ),
        // Summary
        if (!_isLoading && _error == null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text('Total: ${_registrations.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(width: 16),
              Text('Free: ${_registrations.where((r) => (r['paymentStatus'] ?? 'free') == 'free').length}',
                  style: const TextStyle(color: Colors.green, fontSize: 13)),
              const SizedBox(width: 16),
              Text('Paid: ${_registrations.where((r) => r['paymentStatus'] == 'paid').length}',
                  style: const TextStyle(color: Colors.orange, fontSize: 13)),
            ]),
          ),
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _filtered.isEmpty
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No registrations found', style: TextStyle(color: Colors.grey)),
                        ]))
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _regCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _regCard(Map<String, dynamic> r) {
    final payStatus = r['paymentStatus'] ?? 'free';
    final status    = r['status']        ?? 'confirmed';
    final fee       = (r['registrationFee'] as num?)?.toInt() ?? 0;
    final rawDate   = r['createdAt'] ?? '';
    String fmtDate  = '';
    if (rawDate is String && rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate).toLocal();
        fmtDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) { fmtDate = rawDate; }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(r['eventTitle'] ?? 'Event',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            _chip(payStatus == 'paid' ? 'PAID' : 'FREE',
                  payStatus == 'paid' ? Colors.green : Colors.blue),
            const SizedBox(width: 6),
            _chip(status.toUpperCase(), Colors.orange),
          ]),
          const SizedBox(height: 6),
          Text(r['userName'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(r['userEmail'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if ((r['userPhone'] ?? '').toString().isNotEmpty)
            Text(r['userPhone'],
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: [
            if ((r['templeName'] ?? '').toString().isNotEmpty) ...[
              const Icon(Icons.temple_hindu, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Flexible(child: Text(r['templeName'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey))),
              const SizedBox(width: 12),
            ],
            if (fmtDate.isNotEmpty) ...[
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(fmtDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const Spacer(),
            if (fee > 0)
              Text('₹$fee', style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: _primary)),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Error'),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
        child: const Text('Retry'),
      ),
    ]),
  );
}