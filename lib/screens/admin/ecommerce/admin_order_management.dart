import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({super.key});
  @override
  State<AdminOrderManagementPage> createState() => _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _bg      = Color(0xFFFFF8F0);

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getAdminOrders(
        status: _statusFilter,
        search: _search.text.trim(),
      );
      if (mounted) setState(() { _orders = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _totalRevenue => _orders.fold(0, (s, o) => s + ((o['totalAmount'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        _filterBar(),
        if (!_isLoading && _error == null) _summaryBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _orders.isEmpty
                      ? _emptyView()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _orderCard(_orders[i]),
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
          hintText: 'Search name, email, tracking ID...',
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
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _filterChip('All', 'all'),
          _filterChip('Pending', 'pending'),
          _filterChip('Confirmed', 'confirmed'),
          _filterChip('Shipped', 'shipped'),
          _filterChip('Delivered', 'delivered'),
          _filterChip('Cancelled', 'cancelled'),
        ]),
      ),
    ]),
  );

  Widget _filterChip(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label, style: TextStyle(
          fontSize: 12,
          color: _statusFilter == value ? Colors.white : Colors.black87)),
      selected: _statusFilter == value,
      selectedColor: _primary,
      checkmarkColor: Colors.white,
      onSelected: (_) { setState(() => _statusFilter = value); _load(); },
    ),
  );

  Widget _summaryBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      _sum('Total',    '${_orders.length}', Colors.blue),
      _sum('Pending',  '${_orders.where((o) => o['status'] == 'pending').length}', Colors.orange),
      _sum('Shipped',  '${_orders.where((o) => o['status'] == 'shipped').length}', Colors.indigo),
      _sum('Revenue',  '₹${_totalRevenue.toInt()}', Colors.purple),
    ]),
  );

  Widget _sum(String l, String v, Color c) => Expanded(
    child: Column(children: [
      Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 15)),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );

  Widget _orderCard(Map<String, dynamic> o) {
    final status  = o['status'] ?? 'pending';
    final amount  = (o['totalAmount'] as num?)?.toDouble() ?? 0;
    final items   = o['items'] as List? ?? [];
    final id      = o['_id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(o),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#$shortId',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: Color(0xFF3E1F00))),
              const SizedBox(width: 8),
              _statusChip(status),
              const Spacer(),
              Text('₹${amount.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                      color: Colors.indigo)),
            ]),
            const SizedBox(height: 8),
            Text(o['userName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (o['userEmail'] != null)
              Text(o['userEmail'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (o['userPhone'] != null)
              Text(o['userPhone'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${items.length} item(s)',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (o['trackingId'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.local_shipping, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Tracking: ${o['trackingId']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ],
            const SizedBox(height: 8),
            // Action buttons based on current status
            _actionButtons(o),
          ]),
        ),
      ),
    );
  }

  Widget _actionButtons(Map<String, dynamic> o) {
    final status = o['status'] ?? 'pending';
    final id     = o['_id']?.toString() ?? '';

    final nextActions = <Widget>[];

    if (status == 'pending') {
      nextActions.add(_actionBtn('Confirm', Colors.green, () async {
        await ApiService.updateOrderStatus(id, 'confirmed');
        _load();
      }));
    }
    if (status == 'confirmed') {
      nextActions.add(_actionBtn('Mark Shipped', Colors.blue, () => _shipDialog(o)));
    }
    if (status == 'shipped') {
      nextActions.add(_actionBtn('Mark Delivered', Colors.teal, () async {
        await ApiService.updateOrderStatus(id, 'delivered');
        _load();
      }));
    }
    if (status != 'cancelled' && status != 'delivered') {
      nextActions.add(_actionBtn('Cancel', Colors.red, () async {
        await ApiService.updateOrderStatus(id, 'cancelled');
        _load();
      }));
    }

    if (nextActions.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, children: nextActions);
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 30),
          textStyle: const TextStyle(fontSize: 11),
        ),
        child: Text(label),
      );

  void _shipDialog(Map<String, dynamic> o) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Shipped'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Tracking ID (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.updateOrderStatus(
                o['_id']?.toString() ?? '', 'shipped',
                trackingId: ctrl.text.isNotEmpty ? ctrl.text : null,
              );
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetail(Map<String, dynamic> o) {
    final items = o['items'] as List? ?? [];
    final addr  = o['address'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Order Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Customer', o['userName'] ?? '-'),
            _row('Email',    o['userEmail'] ?? '-'),
            _row('Phone',    o['userPhone'] ?? '-'),
            _row('Status',   o['status'] ?? '-'),
            _row('Total',    '₹${(o['totalAmount'] as num?)?.toInt() ?? 0}'),
            _row('Payment ID', o['razorpayPaymentId'] ?? '-'),
            if (o['trackingId'] != null) _row('Tracking', o['trackingId']),
            if (addr.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text([
                addr['name'], addr['line1'], addr['line2'],
                addr['city'], addr['state'], addr['pincode'],
              ].where((v) => v != null && v.toString().isNotEmpty).join(', '),
                  style: const TextStyle(fontSize: 13)),
            ],
            if (items.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...items.map((item) {
                final it = item as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(it['name']?.toString() ?? 'Item',
                        style: const TextStyle(fontSize: 13))),
                    Text('x${it['quantity'] ?? 1}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 12),
                    Text('₹${(it['price'] as num?)?.toInt() ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 90, child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );

  Widget _statusChip(String status) {
    final colors = {
      'pending':   Colors.orange,
      'confirmed': Colors.green,
      'shipped':   Colors.blue,
      'delivered': Colors.teal,
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

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Error loading orders'),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  );

  Widget _emptyView() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.local_shipping, size: 64, color: Colors.grey),
      SizedBox(height: 12),
      Text('No orders found', style: TextStyle(color: Colors.grey)),
    ]),
  );
}