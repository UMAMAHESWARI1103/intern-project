// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'adminstubs.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminUser;
  const AdminDashboard({super.key, this.adminUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _primary   = Color(0xFFFF9933);
  static const Color _bg        = Color(0xFFFFF8F0);
  static const Color _textDark  = Color(0xFF3E1F00);
  static const Color _textGrey  = Color(0xFF9E7A50);

  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getAdminStats(),
        ApiService.getAdminEventRegistrations(),
      ]);
      final stats    = results[0] as Map<String, dynamic>;
      final eventReg = results[1] as List;
      setState(() {
        _stats = {
          'temples':   stats['totalTemples']   ?? 0,
          'events':    stats['totalEvents']    ?? 0,
          'bookings':  stats['totalBookings']  ?? 0,
          'donations': stats['totalDonations'] ?? 0,
          'users':     stats['totalUsers']     ?? 0,
          'orders':    stats['totalOrders']    ?? 0,
          'eventRegs': stats['totalEventReg']  ?? eventReg.length,
        };
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _go(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.clearToken();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName = widget.adminUser?['name']?.toString() ?? 'Admin';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () => _go(const AdminReportsAnalyticsPage()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _welcomeBanner(adminName),
            const SizedBox(height: 20),
            _sectionTitle('Quick Stats'),
            const SizedBox(height: 10),
            _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: _primary),
                    ))
                : _statsGrid(),
            const SizedBox(height: 24),
            _analyticsBannerCard(),
            const SizedBox(height: 24),
            _sectionTitle('Manage'),
            const SizedBox(height: 10),
            _managementGrid(),
            const SizedBox(height: 24),
            _sectionTitle('E-Commerce'),
            const SizedBox(height: 10),
            _ecommerceRow(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Welcome banner ────────────────────────────────────────────────────────
  Widget _welcomeBanner(String name) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFFFB74D)]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      const CircleAvatar(
        backgroundColor: Colors.white24,
        radius: 26,
        child: Text('🛕', style: TextStyle(fontSize: 24)),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back, $name',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const Text('GodsConnect Admin Portal',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    ]),
  );

  // ── Stats grid ────────────────────────────────────────────────────────────
  Widget _statsGrid() => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.2,
    children: [
      _miniStat('Temples',    '${_stats['temples']   ?? 0}', Icons.temple_hindu,       Colors.deepOrange),
      _miniStat('Events',     '${_stats['events']    ?? 0}', Icons.event,              Colors.blue),
      _miniStat('Bookings',   '${_stats['bookings']  ?? 0}', Icons.book_online,        Colors.purple),
      _miniStat('Donations',  '${_stats['donations'] ?? 0}', Icons.volunteer_activism, Colors.teal),
      _miniStat('Users',      '${_stats['users']     ?? 0}', Icons.people,             Colors.indigo),
      _miniStat('Orders',     '${_stats['orders']    ?? 0}', Icons.shopping_bag,       Colors.pink),
      _miniStat('Event Regs', '${_stats['eventRegs'] ?? 0}', Icons.app_registration,   Colors.green),
    ],
  );

  Widget _miniStat(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.orange.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textDark)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: _textGrey)),
        ]),
      );

  // ── Analytics banner card ─────────────────────────────────────────────────
  Widget _analyticsBannerCard() => GestureDetector(
    onTap: () => _go(const AdminReportsAnalyticsPage()),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [                          // ✅ FIX: removed redundant const
              Text('Reports & Analytics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 3),
              Text('Revenue, bookings, donations & more',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios,
            color: Colors.white70, size: 16),
      ]),
    ),
  );

  // ── Management grid ───────────────────────────────────────────────────────
  Widget _managementGrid() {
    final items = [
      _MgmtItem('Temples',    '🛕', Colors.deepOrange, () => _go(const AdminTempleManagementPage())),
      _MgmtItem('Events',     '📅', Colors.blue,       () => _go(const AdminEventManagementPage())),
      _MgmtItem('Bookings',   '📋', Colors.purple,     () => _go(const AdminBookingManagementPage())),
      _MgmtItem('Donations',  '💰', Colors.teal,       () => _go(const AdminDonationManagementPage())),
      _MgmtItem('Prayers',    '🙏', Colors.orange,     () => _go(const AdminPrayerManagementPage())),
      _MgmtItem('Users',      '👥', Colors.indigo,     () => _go(const AdminUserManagementPage())),
      _MgmtItem('Event Reg.', '✅', Colors.green,      () => _go(const AdminEventRegistrationsPage())),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: items.map(_mgmtCard).toList(),
    );
  }

  Widget _mgmtCard(_MgmtItem item) => GestureDetector(
    onTap: item.onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.orange.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Center(
              child: Text(item.emoji,
                  style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(height: 6),
        Text(item.label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textDark),
            textAlign: TextAlign.center),
      ]),
    ),
  );

  // ── E-commerce row ────────────────────────────────────────────────────────
  Widget _ecommerceRow() => Row(children: [
    Expanded(
      child: _ecomCard('Products', '🛍️', Colors.pink,
          () => _go(const AdminProductManagementPage())),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _ecomCard('Orders', '📦', Colors.amber,
          () => _go(const AdminOrderManagementPage())),
    ),
  ]);

  Widget _ecomCard(
          String label, String emoji, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: Colors.orange.withValues(alpha: 0.07),
                blurRadius: 6,
                offset: const Offset(0, 2))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textDark)),
          ]),
        ),
      );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: _textDark));
}

// ── Data class ────────────────────────────────────────────────────────────────
class _MgmtItem {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _MgmtItem(this.label, this.emoji, this.color, this.onTap);
}