import 'package:flutter/material.dart';
import 'adminstubs.dart';
import '../../services/api_service.dart';
import 'admin_event_registrations.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminUser;
  const AdminDashboard({super.key, this.adminUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final stats = await ApiService.getAdminStats();
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _navigate(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  // ── Safely read stats ─────────────────────────────────────
  String _fmt(String key) {
    final v = _stats[key];
    if (v == null) return '0';
    if (v is num && (key == 'totalDonations' || key == 'todayRevenue')) {
      return '₹${_formatNum(v.toInt())}';
    }
    return v.toString();
  }

  String _formatNum(int n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)   return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  int _int(String key) => (_stats[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  color: _primary,
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _adminGreeting(),
                      const SizedBox(height: 16),

                      // ── Alert Banners ────────────────────────
                      if (_int('pendingApprovals') > 0)
                        _alertBanner(
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          message: '${_int('pendingApprovals')} temple approvals pending',
                          onTap: () => _navigate(const AdminTempleManagementPage()),
                        ),
                      if (_int('lowStock') > 0) ...[
                        const SizedBox(height: 8),
                        _alertBanner(
                          icon: Icons.inventory_2_outlined,
                          color: Colors.red,
                          message: '${_int('lowStock')} products have low stock',
                          onTap: () => _navigate(const AdminProductManagementPage()),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Stat Cards ───────────────────────────
                      _sectionLabel('Overview'),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _statCard('Temples',        _fmt('totalTemples'),       Icons.temple_hindu,            Colors.deepOrange),
                          _statCard('Users',           _fmt('totalUsers'),         Icons.people_outline,           Colors.blue),
                          _statCard('Bookings',        _fmt('totalBookings'),      Icons.book_online,               Colors.green),
                          _statCard('Donations',       _fmt('totalDonations'),     Icons.volunteer_activism,       Colors.purple),
                          _statCard('Orders',          _fmt('totalOrders'),        Icons.shopping_bag_outlined,    Colors.teal),
                          _statCard('Event Reg.',      _fmt('totalEventReg'),      Icons.how_to_reg_outlined,      Colors.indigo),
                        ],
                      ),

                      // ── Booking Breakdown ────────────────────
                      if ((_stats['bookingBreakdown'] as Map?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 20),
                        _sectionLabel('Booking Breakdown'),
                        const SizedBox(height: 10),
                        _bookingBreakdown(),
                      ],
                      const SizedBox(height: 20),

                      // ── Quick Actions ────────────────────────
                      _sectionLabel('Quick Actions'),
                      const SizedBox(height: 10),
                      Row(children: [
                        _quickAction(Icons.add_business, 'Add Temple', Colors.deepOrange, () => _navigate(const AdminTempleManagementPage())),
                        const SizedBox(width: 10),
                        _quickAction(Icons.event_note,   'Add Event',  Colors.blue,       () => _navigate(const AdminEventManagementPage())),
                      ]),
                      const SizedBox(height: 20),

                      // ── All Modules ──────────────────────────
                      _sectionLabel('Manage'),
                      const SizedBox(height: 10),
                      _moduleGrid(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      const Text('Failed to load stats', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(_error ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _loadStats,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
      ),
    ]),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    elevation: 0,
    title: const Row(children: [
      Icon(Icons.temple_hindu, size: 22),
      SizedBox(width: 8),
      Text('GodsConnect Admin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    ]),
    actions: [
      IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
    ],
  );

  Widget _adminGreeting() {
    final name = widget.adminUser?['name'] ?? 'Super Admin';
    final bookings = _int('totalBookings');
    final orders   = _int('totalOrders');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome, $name 🙏',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              '$bookings bookings · $orders orders',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _bookingBreakdown() {
    final bd = (_stats['bookingBreakdown'] as Map<String, dynamic>?) ?? {};
    final types = [
      {'label': 'Darshan',  'key': 'darshan',  'color': Colors.deepOrange},
      {'label': 'Homam',    'key': 'homam',    'color': Colors.blue},
      {'label': 'Marriage', 'key': 'marriage', 'color': Colors.purple},
      {'label': 'Prasadam', 'key': 'prasadam', 'color': Colors.green},
    ];
    return Row(
      children: types.map((t) {
        final count = (bd[t['key']] as num?)?.toInt() ?? 0;
        final color = t['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text('$count',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(t['label'] as String,
                  style: TextStyle(fontSize: 9, color: color),
                  textAlign: TextAlign.center),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _alertBanner({
    required IconData icon,
    required Color color,
    required String message,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 13),
          ]),
        ),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              Text(label, style: const TextStyle(fontSize: 11, color: _textGrey)),
            ]),
          ),
        ]),
      );

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ),
      );

  Widget _moduleGrid() {
    final modules = [
      const _Mod('Temple Management',    Icons.temple_hindu,           Colors.deepOrange, AdminTempleManagementPage()),
      const _Mod('Event Management',     Icons.event,                  Colors.blue,       AdminEventManagementPage()),
      const _Mod('Booking Services',     Icons.book_online,            Colors.green,      AdminBookingManagementPage()),
      const _Mod('Donations',            Icons.volunteer_activism,     Colors.purple,     AdminDonationManagementPage()),
      const _Mod('Prayers',              Icons.self_improvement,       Colors.teal,       AdminPrayerManagementPage()),
      const _Mod('Orders',               Icons.local_shipping,         Colors.indigo,     AdminOrderManagementPage()),
      const _Mod('E-Commerce',           Icons.shopping_bag_outlined,  Colors.cyan,       AdminProductManagementPage()),
      const _Mod('Event Registrations',  Icons.how_to_reg,             Colors.orange,     AdminEventRegistrationsPage()),
      const _Mod('Users',                Icons.people_outline,         Colors.blueGrey,   AdminUserManagementPage()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, i) {
        final m = modules[i];
        return InkWell(
          onTap: () => _navigate(m.page),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent),
              boxShadow: [BoxShadow(
                  color: m.color.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(m.icon, color: m.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _textDark)),
                    const SizedBox(height: 2),
                    const Row(children: [
                      Text('Manage',
                          style: TextStyle(fontSize: 10, color: _textGrey)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 9, color: _textGrey),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label) => Text(label.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _textGrey,
          letterSpacing: 1.2));

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ApiService.clearToken();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }
}

class _Mod {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  const _Mod(this.title, this.icon, this.color, this.page);
}