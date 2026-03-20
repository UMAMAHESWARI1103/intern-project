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

  Future<void> _updateOrderStatus(Map<String, dynamic> order) async {
    final statuses = [
      'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
    ];
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
      final ok = await ApiService.updateOrderStatus(
          order['_id'].toString(), selected);
      if (ok) {
        setState(() => order['status'] = selected);
        _snack('Order status updated to $selected ✅');
      } else {
        _snack('Failed to update status');
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':   return Colors.green;
      case 'paid':        return Colors.green;
      case 'cancelled':   return Colors.red;
      case 'failed':      return Colors.red;
      case 'shipped':     return Colors.blue;
      case 'processing':  return Colors.orange;
      case 'confirmed':   return Colors.teal;
      default:            return Colors.grey;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9933)))
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
      return Center(
        child: Text('No $type bookings yet',
            style: const TextStyle(color: Color(0xFF9E7A50))),
      );
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
            Expanded(
              child: Text(b['userName'] ?? b['name'] ?? 'User',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _statusBadge(status.toString()),
          ]),
          const SizedBox(height: 6),
          if (b['userEmail'] != null)
            _row(Icons.email, b['userEmail'].toString()),
          if (b['userPhone'] != null)
            _row(Icons.phone, b['userPhone'].toString()),
          if (b['templeName'] != null)
            _row(Icons.temple_hindu, b['templeName'].toString()),
          if (b['date'] != null)
            _row(Icons.calendar_today, b['date'].toString()),
          if (b['ceremony'] != null)
            _row(Icons.celebration, b['ceremony'].toString()),
          if (b['amount'] != null || b['totalAmount'] != null)
            _row(Icons.currency_rupee,
                '₹${b['amount'] ?? b['totalAmount'] ?? 0}'),
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
      return const Center(
        child: Text('No orders yet',
            style: TextStyle(color: Color(0xFF9E7A50))),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i]),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'pending';
    final items  = (order['items'] as List?) ?? [];
    final total  = order['totalAmount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(order['userName']?.toString() ?? 'User',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _statusBadge(status),
          ]),
          const SizedBox(height: 6),
          if (order['userEmail'] != null)
            _row(Icons.email, order['userEmail'].toString()),
          if (order['userPhone'] != null)
            _row(Icons.phone, order['userPhone'].toString()),
          if (order['deliveryAddress'] != null &&
              order['deliveryAddress'].toString().isNotEmpty)
            _row(Icons.location_on, order['deliveryAddress'].toString()),

          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Items:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '• ${item['name']} × ${item['quantity']}  ₹${item['price']}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E7A50)),
              ),
            )),
          ],

          const SizedBox(height: 6),
          _row(Icons.currency_rupee, 'Total: ₹$total'),

          if (order['cancelReason'] != null &&
              order['cancelReason'].toString().isNotEmpty)
            _row(Icons.info_outline, 'Reason: ${order['cancelReason']}'),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: Color(0xFFFF9933)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: Text('Update Status  (${status.toUpperCase()})'),
              onPressed: () => _updateOrderStatus(order),
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
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E7A50)),
                overflow: TextOverflow.ellipsis),
          ),
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
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Status Picker Dialog — uses RadioGroup (Flutter 3.32+) instead of
//  deprecated RadioListTile.groupValue / RadioListTile.onChanged
// ═══════════════════════════════════════════════════════════════════════════
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
        child: RadioGroup<String>(
          groupValue: _selected,
          onChanged: (v) {
            if (v != null) setState(() => _selected = v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.statuses.map((s) {
              return InkWell(
                onTap: () => setState(() => _selected = s),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Radio<String>(
                      value: s,
                      activeColor: const Color(0xFFFF9933),
                    ),
                    Text(
                      s.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: s == _selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: widget.statusColor(s),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Update'),
        ),
      ],
    );
  }
}