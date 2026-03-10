// lib/screens/admin/admin_priest_management.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminPriestManagementPage extends StatefulWidget {
  const AdminPriestManagementPage({super.key});

  @override
  State<AdminPriestManagementPage> createState() =>
      _AdminPriestManagementPageState();
}

class _AdminPriestManagementPageState
    extends State<AdminPriestManagementPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  List<Map<String, dynamic>> _priests = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getAdminPriests();
      setState(() {
        _priests = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _priests;
    final q = _search.toLowerCase();
    return _priests.where((p) {
      return (p['name'] ?? '').toString().toLowerCase().contains(q) ||
          (p['location'] ?? '').toString().toLowerCase().contains(q) ||
          (p['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggleApproval(Map<String, dynamic> priest) async {
    final id       = priest['_id']?.toString() ?? '';
    final approved = priest['isApproved'] == true;
    final ok = await ApiService.updatePriestApproval(id, !approved);
    if (ok) {
      _load();
      _showSnack(!approved ? 'Priest approved ✅' : 'Approval revoked');
    }
  }

  Future<void> _toggleAvailability(Map<String, dynamic> priest) async {
    final id        = priest['_id']?.toString() ?? '';
    final available = priest['isAvailable'] == true;
    final ok =
        await ApiService.updatePriestAvailability(id, !available);
    if (ok) {
      _load();
      _showSnack(!available ? 'Marked available' : 'Marked unavailable');
    }
  }

  Future<void> _delete(Map<String, dynamic> priest) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Priest'),
        content: Text(
            'Remove ${priest['name']} permanently?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      final ok =
          await ApiService.deletePriest(priest['_id']?.toString() ?? '');
      if (ok) {
        _load();
        _showSnack('Priest deleted');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openAddPriest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminAddPriestPage()),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Priest Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Priest'),
        onPressed: _openAddPriest,
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, location, email…',
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFFFF9933)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // ── Summary chips ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _chip('Total ${_priests.length}', Colors.orange),
              const SizedBox(width: 8),
              _chip(
                  'Approved ${_priests.where((p) => p['isApproved'] == true).length}',
                  Colors.green),
              const SizedBox(width: 8),
              _chip(
                  'Pending ${_priests.where((p) => p['isApproved'] != true).length}',
                  Colors.red),
            ]),
          ),
          const SizedBox(height: 10),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF9933)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No priests found',
                            style: TextStyle(color: Color(0xFF9E7A50))))
                    : RefreshIndicator(
                        color: _primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _priestCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _priestCard(Map<String, dynamic> p) {
    final approved  = p['isApproved'] == true;
    final available = p['isAvailable'] == true;
    final specs     = (p['specializations'] as List?)?.join(', ') ?? '';
    final langs     = (p['languages'] as List?)?.join(', ') ?? '';
    final rating    = p['rating']?.toString() ?? '0';
    final exp       = p['experience']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // ── Header row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      const Color(0xFFFF9933).withValues(alpha: 0.15),
                  child: Text(
                    (p['name'] ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFFFF9933),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            p['name'] ?? 'Unknown',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textDark),
                          ),
                        ),
                        // Approval badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: approved
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                              approved ? 'Approved' : 'Pending',
                              style: TextStyle(
                                  color: approved
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 13, color: Color(0xFF9E7A50)),
                        const SizedBox(width: 3),
                        Text(p['location'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: _textGrey)),
                        const SizedBox(width: 10),
                        const Icon(Icons.star,
                            size: 13, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(rating,
                            style: const TextStyle(
                                fontSize: 12, color: _textGrey)),
                        const SizedBox(width: 10),
                        Text('$exp yrs',
                            style: const TextStyle(
                                fontSize: 12, color: _textGrey)),
                      ]),
                      if (specs.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text('Specializations: $specs',
                            style: const TextStyle(
                                fontSize: 11, color: _textGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (langs.isNotEmpty)
                        Text('Languages: $langs',
                            style: const TextStyle(
                                fontSize: 11, color: _textGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
            ),
            child: Row(children: [
              // Approve toggle
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _toggleApproval(p),
                  icon: Icon(
                      approved
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      size: 16,
                      color:
                          approved ? Colors.red : Colors.green),
                  label: Text(
                      approved ? 'Revoke' : 'Approve',
                      style: TextStyle(
                          fontSize: 12,
                          color: approved ? Colors.red : Colors.green)),
                ),
              ),
              _vDivider(),
              // Availability toggle
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _toggleAvailability(p),
                  icon: Icon(
                      available
                          ? Icons.toggle_on
                          : Icons.toggle_off_outlined,
                      size: 16,
                      color: available
                          ? Colors.blue
                          : Colors.grey),
                  label: Text(
                      available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              available ? Colors.blue : Colors.grey)),
                ),
              ),
              _vDivider(),
              // Delete
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _delete(p),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  label: const Text('Delete',
                      style:
                          TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2));
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD PRIEST PAGE
// ═══════════════════════════════════════════════════════════════════════════

class AdminAddPriestPage extends StatefulWidget {
  const AdminAddPriestPage({super.key});

  @override
  State<AdminAddPriestPage> createState() => _AdminAddPriestPageState();
}

class _AdminAddPriestPageState extends State<AdminAddPriestPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);

  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _email   = TextEditingController();
  final _phone   = TextEditingController();
  final _password= TextEditingController();
  final _location= TextEditingController();
  final _exp     = TextEditingController();
  final _bio     = TextEditingController();

  final List<String> _allSpecs = [
    'Homam', 'Marriage', 'Grihapravesam', 'Seemantham',
    'Naamakaranam', 'Annaprasanam', 'Upanayanam', 'Satyanarayana Puja',
    'Satabhishekam', 'Funeral Rites',
  ];
  final List<String> _allLangs = [
    'Tamil', 'Telugu', 'Sanskrit', 'Kannada', 'Malayalam', 'Hindi', 'English',
  ];

  final List<String> _selectedSpecs = [];
  final List<String> _selectedLangs = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _location, _exp, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecs.isEmpty) {
      _snack('Select at least one specialization');
      return;
    }
    setState(() => _saving = true);

    final ok = await ApiService.adminAddPriest({
      'name':            _name.text.trim(),
      'email':           _email.text.trim(),
      'phone':           _phone.text.trim(),
      'password':        _password.text,
      'location':        _location.text.trim(),
      'experience':      int.tryParse(_exp.text.trim()) ?? 0,
      'bio':             _bio.text.trim(),
      'specializations': _selectedSpecs,
      'languages':       _selectedLangs,
      'isApproved':      true,
      'isAvailable':     true,
    });

    setState(() => _saving = false);

    if (ok) {
      _snack('Priest added successfully! ✅');
      if (mounted) Navigator.pop(context);
    } else {
      _snack('Failed to add priest. Try again.');
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
        title: const Text('Add New Priest',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Basic Info'),
            _field(_name,     'Full Name',    Icons.person,       required: true),
            _field(_email,    'Email',        Icons.email,        required: true, keyboard: TextInputType.emailAddress),
            _field(_phone,    'Phone Number', Icons.phone,        required: true, keyboard: TextInputType.phone),
            _field(_password, 'Password',     Icons.lock,         required: true, obscure: true),
            _field(_location, 'Location (City)', Icons.location_on, required: true),
            _field(_exp,      'Years of Experience', Icons.work, required: true, keyboard: TextInputType.number),
            _field(_bio,      'Short Bio',    Icons.info_outline,  maxLines: 3),
            const SizedBox(height: 16),

            _section('Specializations'),
            _multiChip(_allSpecs, _selectedSpecs,
                (v) => setState(() {
                      _selectedSpecs.contains(v)
                          ? _selectedSpecs.remove(v)
                          : _selectedSpecs.add(v);
                    })),
            const SizedBox(height: 16),

            _section('Languages'),
            _multiChip(_allLangs, _selectedLangs,
                (v) => setState(() {
                      _selectedLangs.contains(v)
                          ? _selectedLangs.remove(v)
                          : _selectedLangs.add(v);
                    })),
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
                    : const Text('Add Priest',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
    bool required = false,
    bool obscure  = false,
    int maxLines  = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller:  ctrl,
          obscureText: obscure,
          maxLines:    maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText:   label,
            prefixIcon:  Icon(icon, color: _primary),
            filled:      true,
            fillColor:   Colors.white,
            border:      OutlineInputBorder(
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

  Widget _multiChip(List<String> options, List<String> selected,
          void Function(String) onTap) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((o) {
          final sel = selected.contains(o);
          return GestureDetector(
            onTap: () => onTap(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? _primary
                    : Colors.white,
                border: Border.all(
                    color: sel ? _primary : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: sel
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ),
          );
        }).toList(),
      );
}