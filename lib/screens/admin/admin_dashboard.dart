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
// Shown when role == 'priest' — form to add priest details to DB
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

  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _locationCtrl= TextEditingController();
  final _expCtrl     = TextEditingController();
  final _bioCtrl     = TextEditingController();

  bool _saving    = false;
  bool _submitted = false;

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
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _expCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecs.isEmpty) {
      _snack('Please select at least one specialization');
      return;
    }
    setState(() => _saving = true);

    final ok = await ApiService.adminAddPriest({
      'name':            _nameCtrl.text.trim(),
      'email':           _emailCtrl.text.trim(),
      'phone':           _phoneCtrl.text.trim(),
      'location':        _locationCtrl.text.trim(),
      'experience':      int.tryParse(_expCtrl.text.trim()) ?? 0,
      'bio':             _bioCtrl.text.trim(),
      'specializations': _selectedSpecs,
      'languages':       _selectedLangs,
      'isApproved':      false,
      'isAvailable':     false,
    });

    setState(() => _saving = false);

    if (ok) {
      setState(() => _submitted = true);
    } else {
      _snack('Submission failed. Please try again.');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _locationCtrl.clear();
    _expCtrl.clear();
    _bioCtrl.clear();
    _selectedSpecs.clear();
    _selectedLangs.clear();
    setState(() => _submitted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Priest Registration',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: widget.onLogout),
        ],
      ),
      body: _submitted ? _successView() : _formView(),
    );
  }

  // ── Success screen ──────────────────────────────────────────
  Widget _successView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 52),
              ),
              const SizedBox(height: 24),
              const Text('Details Submitted!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F00))),
              const SizedBox(height: 12),
              Text(
                'Your profile has been submitted for admin review.\nYou will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.add, color: Color(0xFFFF9933)),
                label: const Text('Add Another Priest',
                    style: TextStyle(color: Color(0xFFFF9933))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF9933)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Registration form ───────────────────────────────────────
  Widget _formView() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9933), Color(0xFFFFB74D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Priest Details',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Details will be stored and reviewed by admin',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),

            _sectionLabel('Basic Information'),
            _field(_nameCtrl,     'Full Name',           Icons.person,      required: true),
            _field(_emailCtrl,    'Email Address',        Icons.email,       required: true, keyboard: TextInputType.emailAddress),
            _field(_phoneCtrl,    'Phone Number',         Icons.phone,       required: true, keyboard: TextInputType.phone),
            _field(_locationCtrl, 'City / Location',      Icons.location_on, required: true),
            _field(_expCtrl,      'Years of Experience',  Icons.work,        required: true, keyboard: TextInputType.number),
            _field(_bioCtrl,      'About (Bio)',          Icons.info_outline, maxLines: 3),
            const SizedBox(height: 16),

            _chipCard(
              title:    'Specializations',
              subtitle: 'Select services this priest performs',
              icon:     Icons.star_outline,
              options:  _allSpecs,
              selected: _selectedSpecs,
            ),
            const SizedBox(height: 16),

            _chipCard(
              title:    'Languages',
              subtitle: 'Select languages this priest speaks',
              icon:     Icons.language,
              options:  _allLangs,
              selected: _selectedLangs,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                    _saving ? 'Saving...' : 'Save to Database',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'After admin approval, this priest will be visible to users on the Homam Booking page.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textDark)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required    = false,
    int maxLines     = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller:   ctrl,
          maxLines:     maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText:  label,
            prefixIcon: Icon(icon, color: _primary),
            filled:     true,
            fillColor:  Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _primary, width: 1.5)),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '$label is required'
                  : null
              : null,
        ),
      );

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
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
}