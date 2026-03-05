import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminDonationManagementPage extends StatefulWidget {
  const AdminDonationManagementPage({super.key});
  @override
  State<AdminDonationManagementPage> createState() => _AdminDonationManagementPageState();
}

class _AdminDonationManagementPageState extends State<AdminDonationManagementPage> {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _bg      = Color(0xFFFFF8F0);

  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  String? _error;
  double _totalAmount = 0;

  String _statusFilter   = 'all';
  String _categoryFilter = 'all';
  final _search = TextEditingController();

  final _categories = ['all', 'General', 'Annadhanam', 'Renovation', 'Festival', 'Cow Seva'];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getAdminDonations(
        status:   _statusFilter,
        category: _categoryFilter,
        search:   _search.text.trim(),
      );
      if (mounted) {
        setState(() {
        _donations   = List<Map<String, dynamic>>.from(data['donations'] ?? []);
        _totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        _isLoading   = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Donation Management', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        _filterBar(),
        if (!_isLoading && _error == null) _summaryBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _donations.isEmpty
                      ? _emptyView()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _donations.length,
                            itemBuilder: (_, i) => _donationCard(_donations[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _filterBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(10),
    child: Column(children: [
      TextField(
        controller: _search,
        decoration: InputDecoration(
          hintText: 'Search donor, temple, category...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _search.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18),
                  onPressed: () { _search.clear(); _load(); })
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true, fillColor: _bg,
        ),
        onSubmitted: (_) => _load(),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            items: const [
              DropdownMenuItem(value: 'all',       child: Text('All')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'pending',   child: Text('Pending')),
              DropdownMenuItem(value: 'failed',    child: Text('Failed')),
            ],
            onChanged: (v) { setState(() => _statusFilter = v!); _load(); },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _categoryFilter,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c == 'all' ? 'All Categories' : c)))
                .toList(),
            onChanged: (v) { setState(() => _categoryFilter = v!); _load(); },
          ),
        ),
      ]),
    ]),
  );

  Widget _summaryBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      _sum('Total', '${_donations.length}', Colors.blue),
      _sum('Completed',
          '${_donations.where((d) => d['status'] == 'completed').length}', Colors.green),
      _sum('Pending',
          '${_donations.where((d) => d['status'] == 'pending').length}', Colors.orange),
      _sum('Amount', '₹${_totalAmount.toInt()}', Colors.purple),
    ]),
  );

  Widget _sum(String l, String v, Color c) => Expanded(
    child: Column(children: [
      Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 15)),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );

  Widget _donationCard(Map<String, dynamic> d) {
    final status   = d['status'] ?? 'completed';
    final amount   = (d['amount'] as num?)?.toDouble() ?? 0;
    final category = d['category'] ?? 'General';
    final id       = d['_id']?.toString() ?? '';

    final catColors = {
      'General': Colors.blue, 'Annadhanam': Colors.orange,
      'Renovation': Colors.brown, 'Festival': Colors.purple, 'Cow Seva': Colors.green,
    };
    final catColor = catColors[category] ?? Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(d),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(category,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor)),
              ),
              const SizedBox(width: 8),
              _statusChip(status),
              const Spacer(),
              Text('₹${amount.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.purple)),
            ]),
            const SizedBox(height: 8),
            Text(d['userName'] ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (d['userEmail'] != null)
              Text(d['userEmail'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            if (d['templeName'] != null)
              Row(children: [
                const Icon(Icons.temple_hindu, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(d['templeName'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            if (d['message'] != null && (d['message'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('"${d['message']}"',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 4),
            Row(children: [
              Text('ID: ${id.length > 10 ? id.substring(id.length - 10) : id}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const Spacer(),
              if (status == 'pending')
                TextButton.icon(
                  onPressed: () async {
                    final ok = await ApiService.updateDonationStatus(id, 'completed');
                    if (ok && mounted) { _load(); }
                  },
                  icon: const Icon(Icons.check_circle, size: 14),
                  label: const Text('Mark Received', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(foregroundColor: Colors.green, padding: EdgeInsets.zero),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Donation Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _row('Donor', d['userName'] ?? '-'),
          _row('Email', d['userEmail'] ?? '-'),
          _row('Phone', d['userPhone'] ?? '-'),
          _row('Temple', d['templeName'] ?? '-'),
          _row('Amount', '₹${(d['amount'] as num?)?.toInt() ?? 0}'),
          _row('Category', d['category'] ?? 'General'),
          _row('Status', d['status'] ?? '-'),
          _row('Payment ID', d['razorpayPaymentId'] ?? '-'),
          _row('Message', d['message'] ?? '-'),
          _row('Date', d['createdAt']?.toString().split('T').first ?? '-'),
        ]),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );

  Widget _statusChip(String status) {
    final colors = {'completed': Colors.green, 'pending': Colors.orange, 'failed': Colors.red};
    final color  = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Error'),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  );

  Widget _emptyView() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
      SizedBox(height: 12),
      Text('No donations found', style: TextStyle(color: Colors.grey)),
    ]),
  );
}