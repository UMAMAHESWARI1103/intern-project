// lib/screens/admin/admin_booking_management.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminBookingManagementPage extends StatefulWidget {
  const AdminBookingManagementPage({super.key});

  @override
  State<AdminBookingManagementPage> createState() =>
      _AdminBookingManagementPageState();
}

class _AdminBookingManagementPageState
    extends State<AdminBookingManagementPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _bg = Color(0xFFFFF8F0);

  late TabController _tab;

  List<Map<String, dynamic>> _darshan  = [];
  List<Map<String, dynamic>> _homam    = [];
  List<Map<String, dynamic>> _marriage = [];
  List<Map<String, dynamic>> _prasadam = [];
  List<Map<String, dynamic>> _orders   = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    // ✅ Reload orders when switching to Orders tab
    _tab.addListener(() {
      if (!_tab.indexIsChanging && _tab.index == 4) {
        _loadOrders();
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getAdminBookings(type: 'darshan'),
        ApiService.getAdminBookings(type: 'homam'),
        ApiService.getAdminBookings(type: 'marriage'),
        ApiService.getAdminBookings(type: 'prasadam'),
        ApiService.getAdminOrders(),
      ]);
      setState(() {
        _darshan  = results[0];
        _homam    = results[1];
        _marriage = results[2];
        _prasadam = results[3];
        _orders   = results[4];
        _loading  = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ✅ Separate orders reload — always fetches fresh from server
  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.getAdminOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (_) {}
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> order) async {
    final statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    final current = order['status']?.toString() ?? 'pending';

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _StatusPickerDialog(
        statuses: statuses,
        current: current,
        statusColor: _statusColor,
      ),
    );

    if (selected != null && selected != current) {
      String? trackingId;
      // ✅ Ask for tracking ID when marking as shipped
      if (selected == 'shipped') {
        trackingId = await _askTrackingId();
      }

      final ok = await ApiService.updateOrderStatus(
        order['_id'].toString(),
        selected,
        trackingId: trackingId,
      );

      if (ok && mounted) {
        setState(() {
          order['status'] = selected;
          if (trackingId != null && trackingId.isNotEmpty) {
            order['trackingId'] = trackingId;
          }
        });
        _snack('Order updated to $selected ✅');
      } else {
        _snack('Failed to update status ❌');
      }
    }
  }

  Future<String?> _askTrackingId() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Tracking ID'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. DTDC123456789IN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':  return Colors.green;
      case 'paid':       return Colors.green;
      case 'confirmed':  return Colors.teal;
      case 'cancelled':  return Colors.red;
      case 'failed':     return Colors.red;
      case 'shipped':    return Colors.blue;
      case 'processing': return Colors.orange;
      case 'pending':    return Colors.orange;
      default:           return Colors.grey;
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Booking Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Darshan (${_darshan.length})'),
            Tab(text: 'Homam (${_homam.length})'),
            Tab(text: 'Marriage (${_marriage.length})'),
            Tab(text: 'Prasadam (${_prasadam.length})'),
            Tab(text: 'Orders (${_orders.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9933)))
          : TabBarView(
              controller: _tab,
              children: [
                _bookingList(_darshan,  'darshan'),
                _bookingList(_homam,    'homam'),
                _bookingList(_marriage, 'marriage'),
                _bookingList(_prasadam, 'prasadam'),
                _orderList(_orders),
              ],
            ),
    );
  }

  // ── Booking List ─────────────────────────────────────────────────────────
  Widget _bookingList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(child: Text('No $type bookings yet',
          style: const TextStyle(color: Color(0xFF9E7A50))));
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _bookingCard(items[i], type),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b, String type) {
    final status = b['paymentStatus'] ?? b['status'] ?? 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(b['userName'] ?? b['name'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            _statusBadge(status.toString()),
          ]),
          const SizedBox(height: 6),
          if (b['userEmail'] != null)   _row(Icons.email,          b['userEmail'].toString()),
          if (b['userPhone'] != null)   _row(Icons.phone,          b['userPhone'].toString()),
          if (b['templeName'] != null)  _row(Icons.temple_hindu,   b['templeName'].toString()),
          if (b['date'] != null)        _row(Icons.calendar_today, b['date'].toString()),
          if (b['ceremony'] != null)    _row(Icons.celebration,    b['ceremony'].toString()),
          if (b['amount'] != null || b['totalAmount'] != null)
            _row(Icons.currency_rupee, '₹${b['amount'] ?? b['totalAmount'] ?? 0}'),
          if (b['razorpayPaymentId'] != null &&
              b['razorpayPaymentId'].toString().isNotEmpty)
            _row(Icons.receipt, b['razorpayPaymentId'].toString()),
        ]),
      ),
    );
  }

  // ── Orders List ──────────────────────────────────────────────────────────
  Widget _orderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet',
          style: TextStyle(color: Color(0xFF9E7A50))));
    }

    // ✅ Summary counts
    final confirmed = orders.where((o) => o['status'] == 'confirmed').length;
    final shipped   = orders.where((o) => o['status'] == 'shipped').length;
    final delivered = orders.where((o) => o['status'] == 'delivered').length;
    final cancelled = orders.where((o) => o['status'] == 'cancelled').length;

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Summary chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _summaryChip('Total',     '${orders.length}', Colors.blue),
              const SizedBox(width: 8),
              _summaryChip('Confirmed', '$confirmed',       Colors.teal),
              const SizedBox(width: 8),
              _summaryChip('Shipped',   '$shipped',         Colors.blue),
              const SizedBox(width: 8),
              _summaryChip('Delivered', '$delivered',       Colors.green),
              const SizedBox(width: 8),
              _summaryChip('Cancelled', '$cancelled',       Colors.red),
            ]),
          ),
          const SizedBox(height: 12),
          ...orders.map((o) => _orderCard(o)),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      Text(label,  style: TextStyle(fontSize: 10, color: color)),
    ]),
  );

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'pending';
    final items  = (order['items'] as List?) ?? [];
    final total  = order['grandTotal'] ?? order['totalAmount'] ?? 0;

    String fmtDate = '';
    try {
      final dt = DateTime.parse(order['createdAt'].toString()).toLocal();
      fmtDate = '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        // ✅ Red border for cancelled so admin can spot easily
        side: status == 'cancelled'
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Expanded(child: Text(order['userName']?.toString() ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            _statusBadge(status),
          ]),
          const SizedBox(height: 6),

          if (order['userEmail'] != null)
            _row(Icons.email, order['userEmail'].toString()),
          if ((order['userPhone'] ?? '').toString().isNotEmpty)
            _row(Icons.phone, order['userPhone'].toString()),
          if ((order['deliveryAddress'] ?? '').toString().isNotEmpty)
            _row(Icons.location_on,
                '${order['deliveryAddress']}, ${order['city'] ?? ''} - ${order['pincode'] ?? ''}'),

          // ✅ FIXED: Items with correct field names
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ...items.map((item) {
              final name  = item['productName'] ?? item['name'] ?? 'Item';
              final qty   = item['quantity']    ?? item['qty']  ?? 1;
              final price = item['subtotal']    ?? item['price'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text('• $name × $qty  ₹$price',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E7A50))),
              );
            }),
          ],

          const SizedBox(height: 6),
          _row(Icons.currency_rupee, 'Total: ₹$total'),

          if ((order['trackingId'] ?? '').toString().isNotEmpty)
            _row(Icons.local_shipping, 'Tracking: ${order['trackingId']}'),
          if (fmtDate.isNotEmpty)
            _row(Icons.calendar_today, 'Ordered: $fmtDate'),
          if ((order['razorpayPaymentId'] ?? '').toString().isNotEmpty)
            _row(Icons.receipt, 'Payment ID: ${order['razorpayPaymentId']}'),

          const SizedBox(height: 10),

          // ✅ Show update button only for active orders
          if (status != 'delivered' && status != 'cancelled')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: Color(0xFFFF9933)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: Text('Update Status  (${status.toUpperCase()})'),
                onPressed: () => _updateOrderStatus(order),
              ),
            )
          else
            // ✅ Final status label for delivered/cancelled
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  status == 'cancelled'
                      ? '❌ Cancelled by User'
                      : '✅ Order Delivered',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF9E7A50)),
      const SizedBox(width: 6),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9E7A50)),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _StatusPickerDialog extends StatefulWidget {
  final List<String> statuses;
  final String current;
  final Color Function(String) statusColor;

  const _StatusPickerDialog({
    required this.statuses,
    required this.current,
    required this.statusColor,
  });

  @override
  State<_StatusPickerDialog> createState() => _StatusPickerDialogState();
}

class _StatusPickerDialogState extends State<_StatusPickerDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Order Status'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.statuses.map((s) {
            final isSelected = s == _selected;
            return InkWell(
              onTap: () => setState(() => _selected = s),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.statusColor(s).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? widget.statusColor(s)
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? widget.statusColor(s)
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(s.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? widget.statusColor(s)
                            : Colors.grey.shade700,
                      )),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9933),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Update'),
        ),
      ],
    );
  }
}