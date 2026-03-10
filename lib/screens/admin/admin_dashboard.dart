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
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  bool _loading = true;
  Map<String, dynamic> _stats = {};

  // Role of logged-in user
  String get _role =>
      widget.adminUser?['role']?.toString() ?? 'user';
  bool get _isAdmin  => _role == 'admin';
  bool get _isPriest => _role == 'priest';

  @override
  void initState() {
    super.initState();
    if (_isAdmin) {
      _loadStats();
    } else {
      _loading = false; // priests skip stats
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getAdminStats(),
        ApiService.getAdminEventRegistrations(),
        ApiService.getAdminPriests(),
      ]);
      final stats    = results[0] as Map<String, dynamic>;
      final eventReg = results[1] as List;
      final priests  = results[2] as List;
      setState(() {
        _stats = {
          'temples':   stats['totalTemples']   ?? 0,
          'events':    stats['totalEvents']    ?? 0,
          'bookings':  stats['totalBookings']  ?? 0,
          'donations': stats['totalDonations'] ?? 0,
          'users':     stats['totalUsers']     ?? 0,
          'orders':    stats['totalOrders']    ?? 0,
          'eventRegs': stats['totalEventReg']  ?? eventReg.length,
          'priests':   stats['totalPriests']   ?? priests.length,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ── Priest sees ONLY priest tab ──────────────────────────
    if (_isPriest) {
      return _PriestOnlyView(
        priestUser: widget.adminUser,
        onLogout: _confirmLogout,
      );
    }

    // ── Admin sees full dashboard ────────────────────────────
    final adminName =
        widget.adminUser?['name']?.toString() ?? 'Admin';

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
                      child:
                          CircularProgressIndicator(color: _primary),
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

  // ── Welcome banner ────────────────────────────────────────
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

  // ── Stats grid ────────────────────────────────────────────
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
          _miniStat('Priests',    '${_stats['priests']   ?? 0}', Icons.person,             Colors.brown),
        ],
      );

  Widget _miniStat(
          String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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

  // ── Analytics banner ──────────────────────────────────────
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
              child: const Icon(Icons.bar_chart,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports & Analytics',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Text('Revenue, bookings, donations & more',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ]),
        ),
      );

  // ── Management grid ───────────────────────────────────────
  Widget _managementGrid() {
    final items = [
      _MgmtItem('Temples',    '🛕', Colors.deepOrange, () => _go(const AdminTempleManagementPage())),
      _MgmtItem('Events',     '📅', Colors.blue,       () => _go(const AdminEventManagementPage())),
      _MgmtItem('Bookings',   '📋', Colors.purple,     () => _go(const AdminBookingManagementPage())),
      _MgmtItem('Donations',  '💰', Colors.teal,       () => _go(const AdminDonationManagementPage())),
      _MgmtItem('Prayers',    '🙏', Colors.orange,     () => _go(const AdminPrayerManagementPage())),
      _MgmtItem('Users',      '👥', Colors.indigo,     () => _go(const AdminUserManagementPage())),
      _MgmtItem('Event Reg.', '✅', Colors.green,      () => _go(const AdminEventRegistrationsPage())),
      _MgmtItem('Priests',    '🧘', Colors.brown,      () => _go(const AdminPriestManagementPage())),
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
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

  // ── E-commerce row ────────────────────────────────────────
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
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: _textDark));
}

// ── Data class ─────────────────────────────────────────────────
class _MgmtItem {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _MgmtItem(this.label, this.emoji, this.color, this.onTap);
}

// ════════════════════════════════════════════════════════════════
// PRIEST-ONLY VIEW
// Shown when role == 'priest' — only sees their own profile tab
// ════════════════════════════════════════════════════════════════

class _PriestOnlyView extends StatefulWidget {
  final Map<String, dynamic>? priestUser;
  final VoidCallback onLogout;
  const _PriestOnlyView(
      {required this.priestUser, required this.onLogout});

  @override
  State<_PriestOnlyView> createState() => _PriestOnlyViewState();
}

class _PriestOnlyViewState extends State<_PriestOnlyView> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _saving  = false;

  // Form controllers
  final _bioCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _expCtrl      = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  final List<String> _allSpecs = [
    'Homam', 'Marriage', 'Grihapravesam', 'Seemantham',
    'Naamakaranam', 'Annaprasanam', 'Upanayanam',
    'Satyanarayana Puja', 'Satabhishekam', 'Funeral Rites',
  ];
  final List<String> _allLangs = [
    'Tamil', 'Telugu', 'Sanskrit', 'Kannada',
    'Malayalam', 'Hindi', 'English',
  ];

  final List<String> _selectedSpecs = [];
  final List<String> _selectedLangs = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _expCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      // Find this priest by email from the priests collection
      final email = widget.priestUser?['email']?.toString() ?? '';
      final priests = await ApiService.getAdminPriests();
      final match = priests.firstWhere(
        (p) => p['email'] == email,
        orElse: () => <String, dynamic>{},
      );

      if (match.isNotEmpty) {
        _profile = match;
        _bioCtrl.text      = match['bio']?.toString() ?? '';
        _locationCtrl.text = match['location']?.toString() ?? '';
        _expCtrl.text      = match['experience']?.toString() ?? '';
        _phoneCtrl.text    = match['phone']?.toString() ?? '';

        _selectedSpecs
          ..clear()
          ..addAll(List<String>.from(match['specializations'] ?? []));
        _selectedLangs
          ..clear()
          ..addAll(List<String>.from(match['languages'] ?? []));
      }
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final id = _profile['_id']?.toString() ?? '';
    final ok = await ApiService.updatePriestProfile(id, {
      'bio':             _bioCtrl.text.trim(),
      'location':        _locationCtrl.text.trim(),
      'experience':      int.tryParse(_expCtrl.text.trim()) ?? 0,
      'phone':           _phoneCtrl.text.trim(),
      'specializations': _selectedSpecs,
      'languages':       _selectedLangs,
    });
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Profile updated ✅' : 'Update failed, try again'),
      backgroundColor: ok ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) _loadProfile();
  }

  Future<void> _toggleAvailability() async {
    final current = _profile['isAvailable'] == true;
    final id = _profile['_id']?.toString() ?? '';
    final ok = await ApiService.updatePriestAvailability(id, !current);
    if (ok) {
      setState(() => _profile['isAvailable'] = !current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.priestUser?['name']?.toString() ?? 'Pandit';
    final available = _profile['isAvailable'] == true;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('My Priest Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Availability toggle chip
          GestureDetector(
            onTap: _toggleAvailability,
            child: Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: available
                    ? Colors.green.withValues(alpha: 0.85)
                    : Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(
                    available ? Icons.circle : Icons.circle_outlined,
                    size: 9,
                    color: Colors.white),
                const SizedBox(width: 4),
                Text(available ? 'Available' : 'Offline',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
              ]),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: widget.onLogout),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Profile header card ───────────────────
                  _profileHeader(name, available),
                  const SizedBox(height: 20),

                  // ── Edit form card ────────────────────────
                  _formCard(),
                  const SizedBox(height: 16),

                  // ── Specializations ───────────────────────
                  _chipCard(
                    title: 'My Specializations',
                    subtitle: 'Select services you perform',
                    icon: Icons.star_outline,
                    options: _allSpecs,
                    selected: _selectedSpecs,
                  ),
                  const SizedBox(height: 16),

                  // ── Languages ─────────────────────────────
                  _chipCard(
                    title: 'Languages I Speak',
                    subtitle: 'Select languages you know',
                    icon: Icons.language,
                    options: _allLangs,
                    selected: _selectedLangs,
                  ),
                  const SizedBox(height: 24),

                  // ── Save button ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          elevation: 2),
                      onPressed: _saving ? null : _saveProfile,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(
                          _saving
                              ? 'Saving...'
                              : 'Save My Details',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Info note ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your details will be shown to users on the Homam Booking page so they can choose you.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ── Profile header ──────────────────────────────────────────
  Widget _profileHeader(String name, bool available) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF9933), Color(0xFFFFB74D)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  Text(
                      _selectedSpecs.isEmpty
                          ? 'No specializations set'
                          : _selectedSpecs.join(', '),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(
                        available
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 13,
                        color: available
                            ? Colors.greenAccent
                            : Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                        available
                            ? 'Available for bookings'
                            : 'Currently unavailable',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ]),
                ]),
          ),
        ]),
      );

  // ── Edit form card ──────────────────────────────────────────
  Widget _formCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Details',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textDark)),
              const SizedBox(height: 14),
              _field(_locationCtrl, 'City / Location',
                  Icons.location_on),
              _field(_phoneCtrl, 'Phone Number', Icons.phone,
                  keyboard: TextInputType.phone),
              _field(_expCtrl, 'Years of Experience', Icons.work,
                  keyboard: TextInputType.number),
              _field(_bioCtrl, 'About Me (Bio)', Icons.info_outline,
                  maxLines: 3),
            ]),
      );

  // ── Chip selector card ──────────────────────────────────────
  Widget _chipCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> options,
    required List<String> selected,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: _primary),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: _textGrey)),
                ]),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((o) {
                  final sel = selected.contains(o);
                  return GestureDetector(
                    onTap: () => setState(() =>
                        sel ? selected.remove(o) : selected.add(o)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? _primary : Colors.white,
                        border: Border.all(
                            color: sel
                                ? _primary
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(o,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
            ]),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: _primary),
            filled: true,
            fillColor: const Color(0xFFFFF8F0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
      );
}