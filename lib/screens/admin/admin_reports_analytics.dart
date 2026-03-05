import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// Place at: lib/screens/admin/admin_reports_analytics.dart

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

  // ── Real data from DB ────────────────────────────────────────────────────
  Map<String, dynamic> _stats         = {};
  Map<String, dynamic> _revenueData   = {};
  List<Map<String, dynamic>> _topTemples    = [];
  List<Map<String, dynamic>> _donationByCategory = [];
  List<Map<String, dynamic>> _monthlyTrend = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch everything from backend ────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminStats(),
        ApiService.getAdminReports(),
      ]);

      final stats   = results[0];
      final reports = results[1];

      setState(() {
        _stats = stats;

        // Revenue breakdown from real DB
        _revenueData = {
          'bookingsRevenue':  reports['bookingsRevenue']  ?? 0,
          'donationsRevenue': reports['donationsRevenue'] ?? 0,
          'ecommerceRevenue': reports['ecommerceRevenue'] ?? 0,
          'ordersRevenue':    reports['ordersRevenue']    ?? 0,
          'totalRevenue':     reports['totalRevenue']     ?? 0,
          'growth':           reports['growth']           ?? '+0%',
        };

        // Top temples from DB
        _topTemples = List<Map<String, dynamic>>.from(
          (reports['topTemples'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );

        // Donation breakdown by category
        _donationByCategory = List<Map<String, dynamic>>.from(
          (reports['donationsByCategory'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );

        // Monthly booking trend (last 6 months)
        _monthlyTrend = List<Map<String, dynamic>>.from(
          (reports['monthlyTrend'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error    = e.toString();
        _isLoading = false;
      });
    }
  }

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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '💰 Revenue'),
            Tab(text: '📊 Bookings'),
            Tab(text: '🛕 Temples'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_revenueTab(), _bookingsTab(), _templesTab()],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 52),
          const SizedBox(height: 14),
          const Text('Failed to load data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── REVENUE TAB ──────────────────────────────────────────────────────────
  Widget _revenueTab() {
    final total     = (_revenueData['totalRevenue']     ?? 0) as num;
    final bookings  = (_revenueData['bookingsRevenue']  ?? 0) as num;
    final donations = (_revenueData['donationsRevenue'] ?? 0) as num;
    final ecommerce = (_revenueData['ecommerceRevenue'] ?? 0) as num;
    final orders    = (_revenueData['ordersRevenue']    ?? 0) as num;
    final growth    = _revenueData['growth'] ?? '+0%';

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Period header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withValues(alpha: 0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Period: This Month',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Text(growth,
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Total revenue card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF9933), Color(0xFFFFB347)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Revenue',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('₹${_fmt(total.toInt())}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Growth: $growth vs last period',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),

      const Text('Revenue Breakdown',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
      const SizedBox(height: 12),
      _revenueBar('Bookings',   bookings.toInt(),  total.toInt(), Colors.blue),
      const SizedBox(height: 10),
      _revenueBar('Donations',  donations.toInt(), total.toInt(), Colors.purple),
      const SizedBox(height: 10),
      _revenueBar('E-Commerce', ecommerce.toInt(), total.toInt(), Colors.teal),
      const SizedBox(height: 10),
      _revenueBar('Orders',     orders.toInt(),    total.toInt(), Colors.indigo),

      if (_donationByCategory.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Donations by Category',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
            const SizedBox(height: 14),
            ..._donationByCategory.map((d) {
              final categoryColors = {
                'General':    Colors.blue,
                'Renovation': Colors.brown,
                'Annadhanam': Colors.orange,
                'Festival':   Colors.purple,
                'Cow Seva':   Colors.green,
              };
              final color = categoryColors[d['category']] ?? Colors.grey;
              final amount  = (d['amount']  ?? 0) as num;
              final percent = (d['percent'] ?? 0) as num;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(d['category'] ?? '',
                          style: const TextStyle(fontSize: 13, color: _textDark)),
                    ]),
                    Text('₹${_fmt(amount.toInt())}  (${percent.toInt()}%)',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: _textDark)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      backgroundColor: _accent,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ]),
              );
            }),
          ]),
        ),
      ],
    ]);
  }

  Widget _revenueBar(String label, int amount, int total, Color color) {
    final pct = total > 0 ? amount / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
                width: 10, height: 10,
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
                    fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            Text('${(pct * 100).toInt()}% of total',
                style: const TextStyle(fontSize: 10, color: _textGrey)),
          ]),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: _accent,
            color: color,
            minHeight: 8,
          ),
        ),
      ]),
    );
  }

  // ── BOOKINGS TAB ─────────────────────────────────────────────────────────
  Widget _bookingsTab() {
    final breakdown = (_stats['bookingBreakdown'] ?? {}) as Map;
    final darshan   = (breakdown['darshan']  ?? 0) as num;
    final homam     = (breakdown['homam']    ?? 0) as num;
    final marriage  = (breakdown['marriage'] ?? 0) as num;
    final prasadam  = (breakdown['prasadam'] ?? 0) as num;
    final total     = darshan + homam + marriage + prasadam;

    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.7,
        children: [
          _miniCard('Total',    '$total',           Icons.book_online,           Colors.blue),
          _miniCard('Darshan',  '${darshan.toInt()}',  Icons.temple_hindu,          Colors.deepOrange),
          _miniCard('Homam',    '${homam.toInt()}',    Icons.local_fire_department, Colors.red),
          _miniCard('Marriage', '${marriage.toInt()}', Icons.favorite,              Colors.pink),
        ],
      ),
      const SizedBox(height: 20),

      // Monthly trend chart
      if (_monthlyTrend.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly Booking Trend',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _monthlyTrend.map((m) {
                  final t = (m['total'] ?? 0) as num;
                  final maxVal = _monthlyTrend
                      .map((x) => (x['total'] ?? 0) as num)
                      .fold(0.0, (a, b) => a > b.toDouble() ? a : b.toDouble());
                  final h = maxVal > 0
                      ? (t.toDouble() / maxVal * 130).clamp(10.0, 130.0)
                      : 10.0;
                  return Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                      Text('${t.toInt()}',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold,
                              color: _textDark)),
                      const SizedBox(height: 3),
                      Container(
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, Colors.orange.shade300],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(m['month'] ?? '',
                          style: const TextStyle(
                              fontSize: 10, color: _textGrey)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      // Booking type breakdown
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Booking Type Breakdown',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
          const SizedBox(height: 12),
          _bookTypeRow('🙏 Darshan',   darshan.toInt(),  total.toInt(), Colors.deepOrange),
          _bookTypeRow('🔥 Homam',     homam.toInt(),    total.toInt(), Colors.red),
          _bookTypeRow('💍 Marriage',  marriage.toInt(), total.toInt(), Colors.pink),
          _bookTypeRow('🍛 Prasadham', prasadam.toInt(), total.toInt(), Colors.orange),
        ]),
      ),
    ]);
  }

  Widget _bookTypeRow(String label, int count, int total, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _textDark))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0,
                backgroundColor: _accent,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ]),
      );

  // ── TEMPLES TAB ──────────────────────────────────────────────────────────
  Widget _templesTab() {
    final totalTemples  = (_stats['temples']          ?? 0) as num;
    final verified      = (_stats['verifiedTemples']  ?? 0) as num;
    final pending       = (_stats['pendingTemples']   ?? 0) as num;
    final states        = (_stats['statesCovered']    ?? 0) as num;

    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.7,
        children: [
          _miniCard('Total Temples',    '${totalTemples.toInt()}', Icons.temple_hindu,    Colors.deepOrange),
          _miniCard('Verified',         '${verified.toInt()}',     Icons.verified,        Colors.green),
          _miniCard('Pending Approval', '${pending.toInt()}',      Icons.pending_actions, Colors.orange),
          _miniCard('States Covered',   '${states.toInt()}',       Icons.map_outlined,    Colors.blue),
        ],
      ),
      const SizedBox(height: 20),

      if (_topTemples.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent)),
          child: const Column(children: [
            Text('🛕', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No temple performance data yet',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            SizedBox(height: 6),
            Text('Data will appear once bookings are recorded',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        )
      else ...[
        const Text('Top Performing Temples',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
        const SizedBox(height: 12),
        ..._topTemples.asMap().entries.map((e) {
          final i = e.key;
          final t = e.value;
          final bookings  = (t['bookings']  ?? 0) as num;
          final donations = (t['donations'] ?? 0) as num;
          final rating    = (t['rating']    ?? 0.0);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent),
                boxShadow: [
                  BoxShadow(
                      color: _primary.withValues(alpha: 0.04),
                      blurRadius: 6)
                ]),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Center(
                    child: Text('#${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _primary))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(t['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _textDark)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.book_online, size: 11, color: _textGrey),
                    const SizedBox(width: 3),
                    Text('${bookings.toInt()} bookings',
                        style: const TextStyle(fontSize: 11, color: _textGrey)),
                    const SizedBox(width: 10),
                    const Icon(Icons.volunteer_activism, size: 11, color: _textGrey),
                    const SizedBox(width: 3),
                    Text('₹${_fmt(donations.toInt())}',
                        style: const TextStyle(fontSize: 11, color: _textGrey)),
                  ]),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text('$rating',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _textDark)),
              ]),
            ]),
          );
        }),
      ],
    ]);
  }

  Widget _miniCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.1), blurRadius: 6)
            ]),
        child: Row(children: [
          Container(
            width: 36, height: 36,
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
                  style: const TextStyle(fontSize: 10, color: _textGrey)),
            ]),
          ),
        ]),
      );

  String _fmt(int n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)   return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}