// lib/screens/priest/priest_dashboard.dart
//
// This screen is shown ONLY to priests after they log in.
// Priests cannot access the Admin Dashboard.

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PriestDashboard extends StatefulWidget {
  final Map<String, dynamic>? priestUser;
  const PriestDashboard({super.key, this.priestUser});

  @override
  State<PriestDashboard> createState() => _PriestDashboardState();
}

class _PriestDashboardState extends State<PriestDashboard> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  bool _loading = true;
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getPriestProfile(),
        ApiService.getPriestBookings(),
      ]);
      setState(() {
        _profile  = results[0] as Map<String, dynamic>? ?? {};
        _bookings = (results[1] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    final current = _profile['isAvailable'] == true;
    final id      = _profile['_id']?.toString() ?? '';
    final ok = await ApiService.updatePriestAvailability(id, !current);
    if (ok) {
      setState(() => _profile['isAvailable'] = !current);
      _snack(!current ? 'You are now Available 🟢' : 'You are now Unavailable 🔴');
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final ok = await ApiService.updatePriestBookingStatus(bookingId, status);
    if (ok) {
      _load();
      _snack('Booking $status');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.clearToken();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final name      = _profile['name']?.toString() ??
        widget.priestUser?['name']?.toString() ??
        'Pandit';
    final available = _profile['isAvailable'] == true;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Priest Portal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Availability quick-toggle in AppBar
          GestureDetector(
            onTap: _toggleAvailability,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: available
                    ? Colors.green.withValues(alpha: 0.85)
                    : Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(
                    available
                        ? Icons.circle
                        : Icons.circle_outlined,
                    size: 10,
                    color: Colors.white),
                const SizedBox(width: 4),
                Text(available ? 'Online' : 'Offline',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
              ]),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9933)))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _profileCard(name, available),
                  const SizedBox(height: 20),
                  _statsRow(),
                  const SizedBox(height: 20),
                  _editProfileCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('My Bookings'),
                  const SizedBox(height: 10),
                  ..._bookingsList(),
                ],
              ),
            ),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────
  Widget _profileCard(String name, bool available) => Container(
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
                    (_profile['specializations'] as List?)?.join(', ') ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('📍 ${_profile['location'] ?? ''}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // Availability toggle button
          GestureDetector(
            onTap: _toggleAvailability,
            child: Column(children: [
              Switch(
                value:          available,
                onChanged:      (_) => _toggleAvailability(),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
              Text(
                  available ? 'Available' : 'Unavailable',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
            ]),
          ),
        ]),
      );

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _statsRow() {
    final total    = _bookings.length;
    final pending  = _bookings.where((b) => b['status'] == 'pending').length;
    final confirmed= _bookings.where((b) => b['status'] == 'confirmed').length;
    final rating   = _profile['rating']?.toString() ?? '0';

    return Row(children: [
      _statBox('Total\nBookings', '$total', Colors.blue),
      const SizedBox(width: 10),
      _statBox('Pending', '$pending', Colors.orange),
      const SizedBox(width: 10),
      _statBox('Confirmed', '$confirmed', Colors.green),
      const SizedBox(width: 10),
      _statBox('Rating', '⭐ $rating', Colors.amber),
    ]);
  }

  Widget _statBox(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: _textGrey),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  // ── Edit profile card ─────────────────────────────────────────────────────
  Widget _editProfileCard() => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PriestEditProfilePage(profile: _profile)),
        ).then((_) => _load()),
        child: Container(
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
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color:
                      const Color(0xFFFF9933).withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.edit,
                  color: Color(0xFFFF9933), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit My Profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _textDark)),
                  Text('Update bio, languages, specializations',
                      style: TextStyle(
                          fontSize: 12, color: _textGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textGrey),
          ]),
        ),
      );

  // ── Bookings list ─────────────────────────────────────────────────────────
  List<Widget> _bookingsList() {
    if (_bookings.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No bookings yet',
                style: TextStyle(color: _textGrey)),
          ),
        )
      ];
    }
    return _bookings.map((b) => _bookingCard(b)).toList();
  }

  Widget _bookingCard(Map<String, dynamic> b) {
    final status = b['status']?.toString() ?? 'pending';
    final Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              b['homamType'] ??
                  b['serviceType'] ??
                  b['type'] ??
                  'Booking',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _textDark),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        if (b['userName'] != null)
          _infoRow(Icons.person, b['userName'].toString()),
        if (b['date'] != null)
          _infoRow(Icons.calendar_today, b['date'].toString()),
        if (b['location'] != null)
          _infoRow(Icons.location_on, b['location'].toString()),

        // Action buttons (only for pending bookings)
        if (status == 'pending') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => _updateBookingStatus(
                    b['_id']?.toString() ?? '', 'cancelled'),
                child: const Text('Decline', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => _updateBookingStatus(
                    b['_id']?.toString() ?? '', 'confirmed'),
                child: const Text('Accept', style: TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Icon(icon, size: 13, color: _textGrey),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(fontSize: 12, color: _textGrey)),
        ]),
      );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: _textDark));
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIEST EDIT PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════════

class PriestEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const PriestEditProfilePage({super.key, required this.profile});

  @override
  State<PriestEditProfilePage> createState() =>
      _PriestEditProfilePageState();
}

class _PriestEditProfilePageState extends State<PriestEditProfilePage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);

  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _location;
  late final TextEditingController _bio;
  late final TextEditingController _exp;
  late List<String> _selectedSpecs;
  late List<String> _selectedLangs;
  bool _saving = false;

  final List<String> _allSpecs = [
    'Homam', 'Marriage', 'Grihapravesam', 'Seemantham',
    'Naamakaranam', 'Annaprasanam', 'Upanayanam', 'Satyanarayana Puja',
    'Satabhishekam', 'Funeral Rites',
  ];
  final List<String> _allLangs = [
    'Tamil', 'Telugu', 'Sanskrit', 'Kannada', 'Malayalam', 'Hindi', 'English',
  ];

  @override
  void initState() {
    super.initState();
    _location = TextEditingController(
        text: widget.profile['location']?.toString() ?? '');
    _bio      = TextEditingController(
        text: widget.profile['bio']?.toString() ?? '');
    _exp      = TextEditingController(
        text: widget.profile['experience']?.toString() ?? '');
    _selectedSpecs = List<String>.from(
        widget.profile['specializations'] as List? ?? []);
    _selectedLangs = List<String>.from(
        widget.profile['languages'] as List? ?? []);
  }

  @override
  void dispose() {
    _location.dispose();
    _bio.dispose();
    _exp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = widget.profile['_id']?.toString() ?? '';
    final ok = await ApiService.updatePriestProfile(id, {
      'location':        _location.text.trim(),
      'bio':             _bio.text.trim(),
      'experience':      int.tryParse(_exp.text.trim()) ?? 0,
      'specializations': _selectedSpecs,
      'languages':       _selectedLangs,
    });
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated ✅')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_location, 'Location', Icons.location_on, required: true),
            _field(_exp, 'Years of Experience', Icons.work,
                keyboard: TextInputType.number, required: true),
            _field(_bio, 'Bio', Icons.info_outline, maxLines: 3),
            const SizedBox(height: 16),
            const Text('Specializations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _chips(_allSpecs, _selectedSpecs),
            const SizedBox(height: 16),
            const Text('Languages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _chips(_allLangs, _selectedLangs),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {bool required = false,
          int maxLines = 1,
          TextInputType keyboard = TextInputType.text}) =>
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
            border:     OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _primary, width: 1.5)),
          ),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        ),
      );

  Widget _chips(List<String> options, List<String> selected) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((o) {
          final sel = selected.contains(o);
          return GestureDetector(
            onTap: () => setState(() =>
                sel ? selected.remove(o) : selected.add(o)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _primary : Colors.white,
                border: Border.all(
                    color: sel ? _primary : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o,
                  style: TextStyle(
                      color:
                          sel ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: sel
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ),
          );
        }).toList(),
      );
}