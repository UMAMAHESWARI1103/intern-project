// lib/screens/admin/admin_order_management.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({super.key});

  @override
  State<AdminOrderManagementPage> createState() =>
      _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _bg      = Color(0xFFFFF8F0);

  List<Map<String, dynamic>> _allOrders      = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool   _loading      = true;
  String _statusFilter = 'all';
  String _searchQuery  = '';

  final _searchCtrl = TextEditingController();

  final List<String> _statusOptions = [
    'all', 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Load from backend ────────────────────────────────────────────────────
  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService.getAdminOrders(
        status: _statusFilter,
        search: _searchQuery,
      );
      setState(() {
        _allOrders      = orders;
        _filteredOrders = orders;
        _loading        = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('Failed to load orders: $e');
    }
  }

  // ── Local filter (instant — no need to hit backend again) ────────────────
  void _applyLocalFilter() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filteredOrders = _allOrders.where((o) {
        final matchStatus = _statusFilter == 'all' ||
            (o['status'] ?? '') == _statusFilter;
        final matchSearch = q.isEmpty ||
            (o['userName']  ?? '').toString().toLowerCase().contains(q) ||
            (o['userEmail'] ?? '').toString().toLowerCase().contains(q) ||
            (o['userPhone'] ?? '').toString().toLowerCase().contains(q) ||
            (o['_id']       ?? '').toString().toLowerCase().contains(q);
        return matchStatus && matchSearch;
      }).toList();
    });
  }

  // ── Stats ────────────────────────────────────────────────────────────────
  int _countByStatus(String s) =>
      _allOrders.where((o) => o['status'] == s).length;

  num _totalRevenue() => _allOrders.fold<num>(
      0, (sum, o) => sum + (o['totalAmount'] ?? 0));

  // ── Update status ────────────────────────────────────────────────────────
  Future<void> _updateStatus(Map<String, dynamic> order) async {
    final statuses = [
      'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
    ];
    final current = order['status']?.toString() ?? 'pending';

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _StatusPickerDialog(
        statuses:    statuses,
        current:     current,
        statusColor: _statusColor,
      ),
    );

    if (selected == null || selected == current) return;

    final ok = await ApiService.updateOrderStatus(
        order['_id'].toString(), selected);
    if (ok) {
      setState(() {
        order['status'] = selected;
        // Re-apply local filter so the card updates immediately
        _applyLocalFilter();
      });
      _snack('Status updated to ${selected.toUpperCase()} ✅');
    } else {
      _snack('Failed to update status ❌');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg),
            behavior: SnackBarBehavior.floating));
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Order Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(children: [
        // ── Search bar ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search name, email, tracking ID...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _applyLocalFilter();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _applyLocalFilter();
            },
          ),
        ),

        // ── Status filter chips ─────────────────────────────────────────
        Container(
          color: Colors.white,
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _statusOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s       = _statusOptions[i];
              final label   = s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1);
              final selected = _statusFilter == s;
              return GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = s);
                  _applyLocalFilter();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? _primary : Colors.grey.shade300),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (selected) ...[
                      const Icon(Icons.check, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? Colors.white : Colors.black87,
                        )),
                  ]),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // ── Stats row ───────────────────────────────────────────────────
        if (!_loading)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCell('${_allOrders.length}', 'Total',   Colors.blue),
                _statCell('${_countByStatus('pending')}',  'Pending',  Colors.orange),
                _statCell('${_countByStatus('shipped')}',  'Shipped',  Colors.indigo),
                _statCell('₹${_totalRevenue()}',           'Revenue',  Colors.purple),
              ],
            ),
          ),

        const Divider(height: 1),

        // ── Order list ──────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _primary))
              : _filteredOrders.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: _primary,
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (_, i) =>
                            _orderCard(_filteredOrders[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _statCell(String value, String label, Color color) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.local_shipping_outlined,
          size: 80, color: Colors.grey.shade400),
      const SizedBox(height: 16),
      Text(
        _searchQuery.isNotEmpty || _statusFilter != 'all'
            ? 'No orders match your filter'
            : 'No orders found',
        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
      ),
      if (_searchQuery.isNotEmpty || _statusFilter != 'all') ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _searchCtrl.clear();
            setState(() {
              _searchQuery  = '';
              _statusFilter = 'all';
            });
            _applyLocalFilter();
          },
          child: const Text('Clear filters',
              style: TextStyle(color: _primary)),
        ),
      ],
    ]),
  );

  // ── Order Card ───────────────────────────────────────────────────────────
  Widget _orderCard(Map<String, dynamic> order) {
    final status   = order['status']?.toString() ?? 'pending';
    final items    = (order['items'] as List?) ?? [];
    final total    = order['totalAmount'] ?? 0;
    final orderId  = order['_id']?.toString() ?? '';
    final shortId  = orderId.length > 8
        ? '#${orderId.substring(orderId.length - 8).toUpperCase()}'
        : '#$orderId';
    final statusColor = _statusColor(status);

    String fmtDate = '';
    final raw = order['createdAt'];
    if (raw != null) {
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        fmtDate = '${dt.day}/${dt.month}/${dt.year}  '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        fmtDate = raw.toString();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ────────────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shortId,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              if (fmtDate.isNotEmpty)
                Text(fmtDate,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
            ])),
            _statusBadge(status),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── User info ─────────────────────────────────────────────────
          if ((order['userName'] ?? '').toString().isNotEmpty)
            _row(Icons.person_outline,
                order['userName'].toString()),
          if ((order['userEmail'] ?? '').toString().isNotEmpty)
            _row(Icons.email_outlined,
                order['userEmail'].toString()),
          if ((order['userPhone'] ?? '').toString().isNotEmpty)
            _row(Icons.phone_outlined,
                order['userPhone'].toString()),
          if ((order['deliveryAddress'] ?? '').toString().isNotEmpty)
            _row(Icons.location_on_outlined,
                order['deliveryAddress'].toString()),

          // ── Items ─────────────────────────────────────────────────────
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: Color(0xFF9E7A50)),
              const SizedBox(width: 6),
              Text('${items.length} item(s)',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E7A50))),
            ]),
            const SizedBox(height: 4),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                '• ${item['name'] ?? 'Item'} × ${item['quantity'] ?? 1}  '
                '₹${item['price'] ?? 0}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E7A50)),
              ),
            )),
          ],

          const SizedBox(height: 8),

          // ── Total + cancel reason ─────────────────────────────────────
          Row(children: [
            const Icon(Icons.currency_rupee,
                size: 14, color: _primary),
            const SizedBox(width: 4),
            Text('Total: ₹$total',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15, color: _primary)),
          ]),

          if ((order['cancelReason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(Icons.info_outline,
                'Reason: ${order['cancelReason']}'),
          ],

          const SizedBox(height: 12),

          // ── Update status button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                foregroundColor: statusColor,
                elevation: 0,
                side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Update Status  ·  ${status.toUpperCase()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _updateStatus(order),
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
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':  return Colors.teal;
      case 'processing': return Colors.orange;
      case 'shipped':    return Colors.blue;
      case 'delivered':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey; // pending
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Status Picker Dialog — uses RadioGroup (Flutter 3.32+)
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
              final color = widget.statusColor(s);
              return InkWell(
                onTap: () => setState(() => _selected = s),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selected == s
                        ? color.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Radio<String>(
                      value: s,
                      activeColor: color,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(s.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color)),
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