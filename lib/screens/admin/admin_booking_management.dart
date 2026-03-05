import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminBookingManagementPage extends StatefulWidget {
  const AdminBookingManagementPage({super.key});
  @override
  State<AdminBookingManagementPage> createState() => _AdminBookingManagementPageState();
}

class _AdminBookingManagementPageState extends State<AdminBookingManagementPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);

  late TabController _tab;
  final _search = TextEditingController();

  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  final _tabs = ['All', 'Darshan', 'Homam', 'Marriage', 'Prasadam'];
  final _tabKeys = ['all', 'darshan', 'homam', 'marriage', 'prasadam'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() { if (!_tab.indexIsChanging) setState(() {}); });
    _loadBookings();
  }

  @override
  void dispose() { _tab.dispose(); _search.dispose(); super.dispose(); }

  Future<void> _loadBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getAdminBookings(
        status: _statusFilter,
        type: _tabKeys[_tab.index],
        search: _search.text.trim(),
      );
      if (mounted) setState(() { _allBookings = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // Summary counts
  int get _total     => _allBookings.length;
  int get _confirmed => _allBookings.where((b) => b['status'] == 'confirmed').length;
  int get _pending   => _allBookings.where((b) => b['status'] == 'pending').length;
  double get _revenue => _allBookings.fold(0, (s, b) => s + ((b['totalAmount'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Booking Management', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (_) => _loadBookings(),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(children: [
        // Search + filter bar
        _searchBar(),
        // Summary row
        if (!_isLoading && _error == null) _summaryBar(),
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _allBookings.isEmpty
                      ? _emptyView()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _loadBookings,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _allBookings.length,
                            itemBuilder: (_, i) => _bookingCard(_allBookings[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _searchBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search name, email, temple...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _search.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _search.clear(); _loadBookings(); })
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true, fillColor: const Color(0xFFFFF8F0),
          ),
          onSubmitted: (_) => _loadBookings(),
        ),
      ),
      const SizedBox(width: 8),
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'all',       child: Text('All Status')),
            DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
            DropdownMenuItem(value: 'pending',   child: Text('Pending')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (v) { setState(() => _statusFilter = v!); _loadBookings(); },
        ),
      ),
    ]),
  );

  Widget _summaryBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      _summaryItem('Total', '$_total', Colors.blue),
      _summaryItem('Confirmed', '$_confirmed', Colors.green),
      _summaryItem('Pending', '$_pending', Colors.orange),
      _summaryItem('Revenue', '₹${_revenue.toInt()}', Colors.purple),
    ]),
  );

  Widget _summaryItem(String label, String val, Color color) => Expanded(
    child: Column(children: [
      Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );

  Widget _bookingCard(Map<String, dynamic> b) {
    final type   = b['bookingType'] ?? b['type'] ?? 'darshan';
    final status = b['status'] ?? 'confirmed';
    final amount = (b['totalAmount'] as num?)?.toDouble() ?? 0;
    final date   = b['date'] ?? b['weddingDate'] ?? '';
    final id     = b['_id']?.toString() ?? '';

    final typeColors = {
      'darshan':  Colors.deepOrange,
      'homam':    Colors.blue,
      'marriage': Colors.purple,
      'prasadam': Colors.green,
    };
    final color = typeColors[type] ?? _primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(type.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(width: 8),
            _statusChip(status),
            const Spacer(),
            Text('₹${amount.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            _statusMenu(b),
          ]),
          const SizedBox(height: 8),
          Text(b['userName'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(b['userEmail'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.temple_hindu, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(child: Text(b['templeName'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey))),
          ]),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (b['timeSlot'] != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(b['timeSlot'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ]),
          ],
          // Type-specific details
          ..._typeDetails(b, type),
          const SizedBox(height: 4),
          Text('ID: ${id.length > 12 ? id.substring(id.length - 12) : id}',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }

  List<Widget> _typeDetails(Map<String, dynamic> b, String type) {
    switch (type) {
      case 'darshan':
        return [
          if (b['numberOfPersons'] != null)
            _detailRow(Icons.people, '${b['numberOfPersons']} person(s)'),
        ];
      case 'homam':
        return [
          if (b['homamType'] != null) _detailRow(Icons.local_fire_department, b['homamType']),
          if (b['iyer'] != null) _detailRow(Icons.person, 'Priest: ${b['iyer']}'),
        ];
      case 'marriage':
        return [
          if (b['groomName'] != null && b['brideName'] != null)
            _detailRow(Icons.favorite, '${b['groomName']} ♥ ${b['brideName']}'),
          if (b['guestCount'] != null)
            _detailRow(Icons.people, '${b['guestCount']} guests'),
        ];
      case 'prasadam':
        final items = b['items'] as List? ?? [];
        return [
          if (items.isNotEmpty)
            _detailRow(Icons.shopping_basket, '${items.length} item(s)'),
        ];
      default: return [];
    }
  }

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Icon(icon, size: 13, color: Colors.grey),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]),
  );

  Widget _statusChip(String status) {
    final colors = {
      'confirmed': Colors.green,
      'pending':   Colors.orange,
      'completed': Colors.blue,
      'cancelled': Colors.red,
    };
    final color = colors[status] ?? Colors.grey;
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

  Widget _statusMenu(Map<String, dynamic> b) => PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert, size: 18),
    onSelected: (newStatus) async {
      final id   = b['_id']?.toString() ?? '';
      final type = b['bookingType'] ?? b['type'] ?? 'darshan';
      final ok = await ApiService.updateBookingStatus(id, type, newStatus);
      if (ok && mounted) {
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.green));
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'confirmed', child: Text('Mark Confirmed')),
      PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
      PopupMenuItem(value: 'cancelled', child: Text('Cancel Booking')),
    ],
  );

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Error loading bookings'),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadBookings, child: const Text('Retry')),
    ]),
  );

  Widget _emptyView() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.book_online, size: 64, color: Colors.grey),
      SizedBox(height: 12),
      Text('No bookings found', style: TextStyle(color: Colors.grey)),
    ]),
  );
}