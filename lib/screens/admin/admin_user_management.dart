import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// Place at: lib/screens/admin/admin_user_management.dart

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});
  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  final _searchCtrl = TextEditingController();
  String _roleFilter   = 'All';
  String _statusFilter = 'All';
  String _sortBy       = 'Newest';

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _roles = ['All', 'User', 'Temple Admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ApiService.getAllUsers();
      setState(() {
        _users = raw.map((u) => _normalizeUser(Map<String, dynamic>.from(u as Map))).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  /// Normalize DB field names to match UI expectations.
  /// Tries multiple common field name variants for bookings & donations.
  Map<String, dynamic> _normalizeUser(Map<String, dynamic> u) {
    final name = (u['name'] ?? '').toString();

    // ── Bookings: try every common field name variant ──
    final bookings = _parseInt(
      u['bookingsCount'] ??
      u['bookingCount'] ??
      u['totalBookings'] ??
      u['bookings'] ??
      u['booking_count'] ??
      u['noOfBookings'],
    );

    // ── Donations: try every common field name variant ──
    final donations = _parseInt(
      u['donationsCount'] ??
      u['donationCount'] ??
      u['totalDonations'] ??
      u['donations'] ??
      u['donation_count'] ??
      u['noOfDonations'],
    );

    return {
      'id':        u['_id'] ?? u['id'] ?? '',
      'name':      name,
      'email':     u['email'] ?? '',
      'phone':     u['phone'] ?? u['phoneNumber'] ?? '',
      'role':      _normalizeRole(u['role'] ?? 'User'),
      'status':    u['isBlocked'] == true ? 'Blocked'
                   : (u['status'] ?? 'Active'),
      'joined':    _formatDate(u['createdAt'] ?? u['joined'] ?? ''),
      'bookings':  bookings,
      'donations': donations,
      'avatar':    name.isNotEmpty ? name[0].toUpperCase() : '?',
      // Keep raw data so we can debug if needed
      '_raw':      u,
    };
  }

  /// Safely parse any value (int, String, null) to int.
  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _normalizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'temple_admin':
      case 'templeadmin': return 'Temple Admin';
      case 'priest':      return 'Priest';
      default:            return 'User';
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    } catch (_) { return raw; }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _users.where((u) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = u['name'].toString().toLowerCase().contains(q) ||
          u['email'].toString().toLowerCase().contains(q) ||
          u['phone'].toString().contains(q) ||
          u['id'].toString().toLowerCase().contains(q);
      final matchRole   = _roleFilter   == 'All' || u['role']   == _roleFilter;
      final matchStatus = _statusFilter == 'All' || u['status'] == _statusFilter;
      return matchSearch && matchRole && matchStatus;
    }).toList();

    switch (_sortBy) {
      case 'Name':      list.sort((a, b) => a['name'].toString().compareTo(b['name'].toString())); break;
      case 'Bookings':  list.sort((a, b) => (b['bookings'] as int).compareTo(a['bookings'] as int)); break;
      case 'Donations': list.sort((a, b) => (b['donations'] as int).compareTo(a['donations'] as int)); break;
      default:          list.sort((a, b) => b['joined'].toString().compareTo(a['joined'].toString())); break;
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('User Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => ['Newest', 'Name', 'Bookings', 'Donations']
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _errorView()
              : Column(children: [
                  // ── Stats ──────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      _statTile('Total',   '${_users.length}',                                           Colors.blue),
                      _vDivider(),
                      _statTile('Active',  '${_users.where((u) => u['status'] == 'Active').length}',     Colors.green),
                      _vDivider(),
                      _statTile('Blocked', '${_users.where((u) => u['status'] == 'Blocked').length}',    Colors.red),
                      _vDivider(),
                      _statTile('Admins',  '${_users.where((u) => u['role'] == 'Temple Admin').length}', Colors.purple),
                    ]),
                  ),

                  // ── Search + Filters ────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search name, email, phone or ID...',
                          prefixIcon: const Icon(Icons.search, color: _primary),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () { _searchCtrl.clear(); setState(() {}); })
                              : null,
                          filled: true,
                          fillColor: _bg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _accent)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _accent)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _roles.map((r) {
                            final active = _roleFilter == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(r),
                                selected: active,
                                onSelected: (_) => setState(() => _roleFilter = r),
                                selectedColor: _primary,
                                labelStyle: TextStyle(
                                    color: active ? Colors.white : _textGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                                backgroundColor: _accent,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          const Text('Status: ',
                              style: TextStyle(fontSize: 12, color: _textGrey, fontWeight: FontWeight.w600)),
                          ...['All', 'Active', 'Blocked', 'Inactive'].map((s) {
                            final active = _statusFilter == s;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(s),
                                selected: active,
                                onSelected: (_) => setState(() => _statusFilter = s),
                                selectedColor: _statusChipColor(s),
                                labelStyle: TextStyle(
                                    color: active ? Colors.white : _textGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11),
                                backgroundColor: _accent,
                              ),
                            );
                          }),
                        ]),
                      ),
                    ]),
                  ),

                  // ── Count row ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${_filtered.length} users found',
                          style: const TextStyle(fontSize: 12, color: _textGrey)),
                      Text('Sort: $_sortBy',
                          style: const TextStyle(
                              fontSize: 12, color: _primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),

                  // ── User List ────────────────────────────────────────
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No users found 👤',
                              style: TextStyle(color: _textGrey, fontSize: 15)))
                        : RefreshIndicator(
                            color: _primary,
                            onRefresh: _loadUsers,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _userCard(_filtered[i]),
                            ),
                          ),
                  ),
                ]),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: _textGrey),
            const SizedBox(height: 12),
            const Text('Failed to load users',
                style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 6),
            Text(_error ?? '', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _textGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );

  Widget _userCard(Map<String, dynamic> u) {
    final isBlocked  = u['status'] == 'Blocked';
    final isInactive = u['status'] == 'Inactive';
    final roleColor  = _roleColor(u['role'].toString());
    final statusColor = isBlocked ? Colors.red : isInactive ? Colors.grey : Colors.green;
    final bookings  = u['bookings'] as int;
    final donations = u['donations'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isBlocked ? Colors.red.withValues(alpha: 0.3) : _accent),
        boxShadow: [BoxShadow(
            color: _primary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(u['avatar'].toString(),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roleColor)),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(u['name'].toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isBlocked
                                ? Colors.red.withValues(alpha: 0.7)
                                : _textDark,
                            decoration: isBlocked
                                ? TextDecoration.lineThrough
                                : null)),
                  ),
                  _badge(u['status'].toString(), statusColor),
                ]),
                Text(u['email'].toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _textGrey)),
              ]),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: _textGrey, size: 20),
              onSelected: (action) => _handleAction(action, u),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('View Details')
                  ]),
                ),
                PopupMenuItem(
                  value: isBlocked ? 'unblock' : 'block',
                  child: Row(children: [
                    Icon(
                      isBlocked ? Icons.lock_open_outlined : Icons.block,
                      size: 18,
                      color: isBlocked ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBlocked ? 'Unblock' : 'Block',
                      style: TextStyle(color: isBlocked ? Colors.green : Colors.red),
                    ),
                  ]),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(children: [
            const Icon(Icons.phone, size: 13, color: _textGrey),
            const SizedBox(width: 4),
            Text(u['phone'].toString(),
                style: const TextStyle(fontSize: 12, color: _textGrey)),
            const SizedBox(width: 16),
            const Icon(Icons.calendar_today, size: 13, color: _textGrey),
            const SizedBox(width: 4),
            Text('Joined ${u['joined']}',
                style: const TextStyle(fontSize: 12, color: _textGrey)),
          ]),
          const SizedBox(height: 8),

          Row(children: [
            _roleBadge(u['role'].toString(), roleColor),
            const Spacer(),
            // ── Only show bookings/donations if value > 0 ──
            if (bookings > 0) ...[
              _miniStat(Icons.book_online, '$bookings', Colors.blue),
              const SizedBox(width: 12),
            ],
            if (donations > 0)
              _miniStat(Icons.volunteer_activism, '$donations', Colors.purple),
          ]),
        ]),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) => Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]);

  void _handleAction(String action, Map<String, dynamic> u) {
    switch (action) {
      case 'view':    _showDetail(u); break;
      case 'block':   _confirmBlock(u); break;
      case 'unblock': _doToggleBlock(u); break;
    }
  }

  Future<void> _doToggleBlock(Map<String, dynamic> u) async {
    final wasBlocked = u['status'] == 'Blocked';
    final ok = await ApiService.toggleBlockUser(u['id'].toString());
    if (ok) {
      setState(() => u['status'] = wasBlocked ? 'Active' : 'Blocked');
      _snack(wasBlocked ? '${u['name']} unblocked' : '${u['name']} blocked',
          wasBlocked ? Colors.green : Colors.red);
    } else {
      _snack('Action failed. Please try again.', Colors.red);
    }
  }

  void _confirmBlock(Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Block User', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Block ${u['name']}? They will not be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _doToggleBlock(u);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showDetail(Map<String, dynamic> u) {
    final roleColor = _roleColor(u['role'].toString());
    final bookings  = u['bookings'] as int;
    final donations = u['donations'] as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            // Avatar
            CircleAvatar(
              radius: 34,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(u['avatar'].toString(),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: roleColor)),
            ),
            const SizedBox(height: 12),

            // Name
            Text(u['name'].toString(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textDark)),
            const SizedBox(height: 6),

            // Role badge
            _roleBadge(u['role'].toString(), roleColor),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            _detailRow(Icons.email,          'Email',   u['email'].toString()),
            _detailRow(Icons.phone,          'Phone',   u['phone'].toString()),
            _detailRow(Icons.calendar_today, 'Joined',  u['joined'].toString()),
            _detailRow(Icons.circle,         'Status',  u['status'].toString()),

            // ── Only show bookings/donations rows if value > 0 ──
            if (bookings > 0)
              _detailRow(Icons.book_online, 'Bookings', '$bookings'),
            if (donations > 0)
              _detailRow(Icons.volunteer_activism, 'Donations', '$donations'),

            // If both are 0 show a friendly note
            if (bookings == 0 && donations == 0) ...[
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.info_outline, size: 14, color: _textGrey),
                SizedBox(width: 6),
                Text('No bookings or donations yet',
                    style: TextStyle(fontSize: 12, color: _textGrey)),
              ]),
            ],

            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: _textGrey, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: _textDark, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Color _roleColor(String role) => switch (role) {
        'Temple Admin' => Colors.purple,
        'Priest'       => Colors.teal,
        _              => Colors.blue,
      };

  IconData _roleIcon(String role) => switch (role) {
        'Temple Admin' => Icons.admin_panel_settings,
        'Priest'       => Icons.self_improvement,
        _              => Icons.person,
      };

  Color _statusChipColor(String s) => switch (s) {
        'Active'   => Colors.green,
        'Blocked'  => Colors.red,
        'Inactive' => Colors.grey,
        _          => _primary,
      };

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _roleBadge(String role, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_roleIcon(role), size: 13, color: color),
          const SizedBox(width: 4),
          Text(role,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ]),
      );

  Widget _statTile(String label, String value, Color color) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: _textGrey)),
        ]),
      );

  Widget _vDivider() => Container(
        width: 1, height: 30, color: _accent,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }
}