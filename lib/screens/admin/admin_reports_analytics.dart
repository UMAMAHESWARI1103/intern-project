// lib/screens/admin/admin_reports_analytics.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminReportsAnalyticsPage extends StatefulWidget {
  const AdminReportsAnalyticsPage({super.key});
  @override
  State<AdminReportsAnalyticsPage> createState() =>
      _AdminReportsAnalyticsPageState();
}

class _AdminReportsAnalyticsPageState
    extends State<AdminReportsAnalyticsPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _stats   = {};
  Map<String, dynamic> _reports = {};
  int _eventRegCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminStats(),
        ApiService.getAdminReports(),
        ApiService.getAdminEventRegistrations(),
      ]);
      if (mounted) {
        setState(() {
          _stats          = results[0] as Map<String, dynamic>;
          _reports        = results[1] as Map<String, dynamic>;
          _eventRegCount  = (results[2] as List).length;
          _isLoading      = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  num _n(Map m, String key, [num def = 0]) => (m[key] as num?) ?? def;

  String _fmt(num n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)   return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }

  List<Map<String, dynamic>> _list(String key) =>
      List<Map<String, dynamic>>.from(
          (_reports[key] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Reports & Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '💰 Revenue'),
            Tab(text: '📊 Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _errorView()
              : TabBarView(
                  controller: _tabController,
                  children: [_revenueTab(), _bookingsTab()],
                ),
    );
  }

  // ── ERROR ─────────────────────────────────────────────────────────────────
  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 52),
        const SizedBox(height: 14),
        const Text('Failed to load data',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(_error ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    ),
  );

  // ── REVENUE TAB ───────────────────────────────────────────────────────────
  Widget _revenueTab() {
    // ✅ backend reports: bookingsRevenue, donationsRevenue, ecommerceRevenue, ordersRevenue, totalRevenue, growth
    final total     = _n(_reports, 'totalRevenue');
    final bookings  = _n(_reports, 'bookingsRevenue');
    final donations = _n(_reports, 'donationsRevenue');
    final ecommerce = _n(_reports, 'ecommerceRevenue');
    final orders    = _n(_reports, 'ordersRevenue');
    final growth    = (_reports['growth'] ?? '+0%').toString();
    final donCats   = _list('donationsByCategory');

    return ListView(padding: const EdgeInsets.all(16), children: [

      // Total revenue card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF9933), Color(0xFFFFB347)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Total Revenue',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('₹${_fmt(total)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Growth: $growth vs last month',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Text(growth,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      const Text('Revenue Breakdown',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: _textDark)),
      const SizedBox(height: 12),

      _revenueBar('Bookings',   bookings,  total, Colors.blue),
      const SizedBox(height: 10),
      _revenueBar('Donations',  donations, total, Colors.purple),
      const SizedBox(height: 10),
      _revenueBar('E-Commerce', ecommerce, total, Colors.teal),
      const SizedBox(height: 10),
      _revenueBar('Orders',     orders,    total, Colors.indigo),

      if (donCats.isNotEmpty) ...[
        const SizedBox(height: 20),
        _card(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Donations by Category',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _textDark)),
            const SizedBox(height: 14),
            ...donCats.map((d) {
              final color   = _categoryColor(d['category']?.toString() ?? '');
              final amount  = _n(d, 'amount');
              final percent = _n(d, 'percent');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(d['category']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: _textDark)),
                    ]),
                    Text('₹${_fmt(amount)}  (${percent.toInt()}%)',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _textDark)),
                  ]),
                  const SizedBox(height: 6),
                  _progressBar(percent.toDouble() / 100, color),
                ]),
              );
            }),
          ]),
        ),
      ],
    ]);
  }

  Widget _revenueBar(String label, num amount, num total, Color color) {
    final pct =
        total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return _card(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _textDark)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${_fmt(amount)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16)),
            Text('${(pct * 100).toInt()}% of total',
                style: const TextStyle(fontSize: 10, color: _textGrey)),
          ]),
        ]),
        const SizedBox(height: 10),
        _progressBar(pct.toDouble(), color),
      ]),
    );
  }

  // ── BOOKINGS TAB ──────────────────────────────────────────────────────────
  Widget _bookingsTab() {
    // ✅ bookingBreakdown is inside _stats (from /admin/stats)
    final bd       = (_stats['bookingBreakdown'] as Map?) ?? {};
    final darshan  = _n(bd, 'darshan');
    final homam    = _n(bd, 'homam');
    final marriage = _n(bd, 'marriage');
    final prasadam = _n(bd, 'prasadam');
    final eventReg = _eventRegCount;
    final total    = darshan + homam + marriage + prasadam + eventReg;
    final trend    = _list('monthlyTrend');

    return ListView(padding: const EdgeInsets.all(16), children: [

      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: [
          _miniStat('Total',      '${total.toInt()}',    Icons.book_online,           Colors.blue),
          _miniStat('Darshan',    '${darshan.toInt()}',  Icons.temple_hindu,          Colors.deepOrange),
          _miniStat('Homam',      '${homam.toInt()}',    Icons.local_fire_department, Colors.red),
          _miniStat('Marriage',   '${marriage.toInt()}', Icons.favorite,              Colors.pink),
          _miniStat('Event Regs', '$eventReg',           Icons.app_registration,      Colors.green),
        ],
      ),
      const SizedBox(height: 20),

      if (trend.isNotEmpty) ...[
        _card(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Monthly Trend',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _textDark)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((m) {
                  final t      = _n(m, 'total');
                  final maxVal = trend
                      .map((x) => _n(x, 'total').toDouble())
                      .fold(0.0, (a, b) => a > b ? a : b);
                  final h = maxVal > 0
                      ? (t.toDouble() / maxVal * 120).clamp(10.0, 120.0)
                      : 10.0;
                  return Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                      Text('${t.toInt()}',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _textDark)),
                      const SizedBox(height: 3),
                      Container(
                        height: h,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF9933),
                              Color(0xFFFFCC80)
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(m['month']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 9, color: _textGrey)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      _card(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Booking Types',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _textDark)),
          const SizedBox(height: 14),
          _bookTypeRow('🙏 Darshan',    darshan,  total, Colors.deepOrange),
          _bookTypeRow('🔥 Homam',      homam,    total, Colors.red),
          _bookTypeRow('💍 Marriage',   marriage, total, Colors.pink),
          _bookTypeRow('🍛 Prasadham',  prasadam, total, Colors.orange),
          _bookTypeRow('🎉 Event Regs', eventReg, total, Colors.green),
        ]),
      ),
    ]);
  }

  Widget _bookTypeRow(String label, num count, num total, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: _textDark))),
          Expanded(
            child: _progressBar(
                total > 0
                    ? (count / total).clamp(0.0, 1.0).toDouble()
                    : 0.0,
                color),
          ),
          const SizedBox(width: 10),
          Text('${count.toInt()}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14)),
        ]),
      );

  // ── Shared widgets ────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent)),
    child: child,
  );

  Widget _progressBar(double value, Color color) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      backgroundColor: _accent,
      color: color,
      minHeight: 8,
    ),
  );

  Widget _miniStat(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.08), blurRadius: 6)
            ]),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: _textGrey)),
            ]),
          ),
        ]),
      );

  Color _categoryColor(String cat) => switch (cat) {
        'General'    => Colors.blue,
        'Renovation' => Colors.brown,
        'Annadhanam' => Colors.orange,
        'Festival'   => Colors.purple,
        'Cow Seva'   => Colors.green,
        _            => Colors.grey,
      };
}