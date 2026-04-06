import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminTempleManagementPage extends StatefulWidget {
  const AdminTempleManagementPage({super.key});
  @override
  State<AdminTempleManagementPage> createState() => _AdminTempleManagementPageState();
}

class _AdminTempleManagementPageState extends State<AdminTempleManagementPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  final _searchCtrl = TextEditingController();
  String _filter    = 'All';
  List<Map<String, dynamic>> _temples = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ApiService.getAdminTemples();
      if (mounted) {
        setState(() {
          _temples   = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered => _temples.where((t) {
    final q = _searchCtrl.text.toLowerCase();
    final matchSearch = q.isEmpty ||
        (t['name']     ?? '').toString().toLowerCase().contains(q) ||
        (t['location'] ?? t['city'] ?? '').toString().toLowerCase().contains(q);
    final status = t['isVerified'] == true ? 'Verified' : 'Pending';
    final matchFilter = _filter == 'All' || status == _filter;
    return matchSearch && matchFilter;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Temple Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _openTempleForm),
        ],
      ),
      body: Column(children: [
        // ── Search + Filter ──────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search temples...',
                prefixIcon: const Icon(Icons.search, color: _primary),
                filled: true, fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: ['All', 'Verified', 'Pending'].map((f) {
              final active = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f), selected: active,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: _primary,
                  labelStyle: TextStyle(
                      color: active ? Colors.white : _textGrey,
                      fontWeight: FontWeight.w600),
                  backgroundColor: _accent,
                ),
              );
            }).toList()),
          ]),
        ),

        // ── List ─────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _filtered.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('🛕', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(_temples.isEmpty ? 'No temples added yet' : 'No temples found',
                              style: const TextStyle(color: _textGrey, fontSize: 15)),
                          if (_temples.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openTempleForm,
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Temple'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary, foregroundColor: Colors.white),
                            ),
                          ],
                        ]))
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _templeCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text('Add Temple'),
        onPressed: _openTempleForm,
      ),
    );
  }

  Widget _templeCard(Map<String, dynamic> t) {
    final isVerified = t['isVerified'] == true;
    final name     = t['name']     ?? 'Unknown Temple';
    final location = t['location'] ?? t['city'] ?? '';
    final rating   = (t['rating'] as num?)?.toDouble() ?? 0.0;

    final openTime       = t['openTime']       ?? t['open_time']        ?? '6:00 AM';
    final closeTime      = t['closeTime']      ?? t['close_time']       ?? '12:00 PM';
    final reopenTime     = t['reopenTime']     ?? t['reopen_time']      ?? '4:00 PM';
    final finalCloseTime = t['finalCloseTime'] ?? t['final_close_time'] ?? '8:30 PM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('🛕', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark))),
              if (isVerified) const Icon(Icons.verified, color: Colors.blue, size: 16),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on, size: 12, color: _textGrey),
              const SizedBox(width: 2),
              Flexible(child: Text(location,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textGrey, fontSize: 12))),
              if (rating > 0) ...[
                const SizedBox(width: 10),
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text('$rating', style: const TextStyle(color: _textGrey, fontSize: 12)),
              ],
            ]),
            const SizedBox(height: 4),

            // ── FIXED: Two-session timing display ─────────────
            Row(children: [
              const Icon(Icons.wb_sunny_outlined, size: 11, color: _textGrey),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  '$openTime – $closeTime',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textGrey, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.nights_stay_outlined, size: 11, color: _textGrey),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  '$reopenTime – $finalCloseTime',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textGrey, fontSize: 11),
                ),
              ),
            ]),

            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(isVerified ? 'Verified' : 'Pending',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: isVerified ? Colors.green : Colors.orange)),
            ),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _textGrey),
          onSelected: (action) => _handleAction(action, t),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',
                child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
            if (!isVerified)
              const PopupMenuItem(value: 'verify',
                  child: Row(children: [Icon(Icons.verified_outlined, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Verify')])),
            const PopupMenuItem(value: 'delete',
                child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ]),
    );
  }

  void _handleAction(String action, Map<String, dynamic> t) {
    switch (action) {
      case 'edit':   _openTempleForm(temple: t); break;
      case 'verify': _verifyTemple(t); break;
      case 'delete': _deleteTemple(t); break;
    }
  }

  Future<void> _verifyTemple(Map<String, dynamic> t) async {
    final id = t['_id']?.toString() ?? '';
    try {
      await ApiService.updateTemple(id, {...t, 'isVerified': true});
      _load();
      _snack('${t['name']} verified ✓', Colors.green);
    } catch (e) {
      _snack('Failed to verify: $e', Colors.red);
    }
  }

  Future<void> _deleteTemple(Map<String, dynamic> t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Temple', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${t['name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _primary))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteTemple(t['_id']?.toString() ?? '');
        _load();
        _snack('Temple deleted', Colors.red);
      } catch (e) {
        _snack('Failed to delete: $e', Colors.red);
      }
    }
  }

  Future<void> _pickTime(
    BuildContext ctx,
    TextEditingController ctrl,
    StateSetter setSheet,
  ) async {
    TimeOfDay initial = TimeOfDay.now();
    try {
      final text = ctrl.text.trim();
      if (text.isNotEmpty) {
        final parts  = text.split(' ');
        final hm     = parts[0].split(':');
        int h        = int.parse(hm[0]);
        final m      = hm.length > 1 ? int.parse(hm[1]) : 0;
        final period = parts.length > 1 ? parts[1] : 'AM';
        if (period == 'PM' && h != 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
        initial = TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: ctx,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final period = picked.hour < 12 ? 'AM' : 'PM';
      final h      = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final m      = picked.minute.toString().padLeft(2, '0');
      setSheet(() => ctrl.text = '$h:$m $period');
    }
  }

  void _openTempleForm({Map<String, dynamic>? temple}) {
    final isEdit           = temple != null;
    final nameCtrl         = TextEditingController(text: isEdit ? temple['name']           ?? '' : '');
    final locationCtrl     = TextEditingController(text: isEdit ? temple['location']       ?? temple['city'] ?? '' : '');
    final deityCtrl        = TextEditingController(text: isEdit ? temple['deity']          ?? '' : '');
    final openCtrl         = TextEditingController(text: isEdit ? temple['openTime']       ?? temple['open_time']        ?? '6:00 AM'  : '6:00 AM');
    final closeCtrl        = TextEditingController(text: isEdit ? temple['closeTime']      ?? temple['close_time']       ?? '12:00 PM' : '12:00 PM');
    final reopenCtrl       = TextEditingController(text: isEdit ? temple['reopenTime']     ?? temple['reopen_time']      ?? '4:00 PM'  : '4:00 PM');
    final finalCloseCtrl   = TextEditingController(text: isEdit ? temple['finalCloseTime'] ?? temple['final_close_time'] ?? '8:30 PM'  : '8:30 PM');
    final descCtrl         = TextEditingController(text: isEdit ? temple['description']    ?? '' : '');
    final imageCtrl        = TextEditingController(text: isEdit ? temple['imageUrl']       ?? '' : '');
    final formKey          = GlobalKey<FormState>();
    bool saving            = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text(isEdit ? 'Edit Temple' : 'Add Temple',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                  const SizedBox(height: 20),

                  _ff(nameCtrl,     'Temple Name *',     Icons.temple_hindu,  required: true),
                  const SizedBox(height: 12),
                  _ff(locationCtrl, 'Location / City *', Icons.location_on,   required: true),
                  const SizedBox(height: 12),
                  _ff(deityCtrl,    'Main Deity',        Icons.person_outline),
                  const SizedBox(height: 16),

                  _sectionLabel('🌅  Morning Session', _primary),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _timePicker(ctx, openCtrl,   'Opens',  Icons.wb_sunny_outlined,  setSheet)),
                    const SizedBox(width: 10),
                    Expanded(child: _timePicker(ctx, closeCtrl,  'Closes', Icons.wb_cloudy_outlined, setSheet)),
                  ]),
                  const SizedBox(height: 16),

                  _sectionLabel('🌆  Evening Session', _primary),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _timePicker(ctx, reopenCtrl,     'Re-opens', Icons.nights_stay_outlined, setSheet)),
                    const SizedBox(width: 10),
                    Expanded(child: _timePicker(ctx, finalCloseCtrl, 'Closes',   Icons.bedtime_outlined,     setSheet)),
                  ]),
                  const SizedBox(height: 16),

                  _ff(imageCtrl, 'Image URL (optional)', Icons.image_outlined),
                  const SizedBox(height: 12),
                  _ff(descCtrl,  'Description',          Icons.description_outlined, maxLines: 2),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => saving = true);
                        final data = {
                          'name':           nameCtrl.text.trim(),
                          'location':       locationCtrl.text.trim(),
                          'deity':          deityCtrl.text.trim(),
                          'openTime':       openCtrl.text.trim(),
                          'closeTime':      closeCtrl.text.trim(),
                          'reopenTime':     reopenCtrl.text.trim(),
                          'finalCloseTime': finalCloseCtrl.text.trim(),
                          'imageUrl':       imageCtrl.text.trim(),
                          'description':    descCtrl.text.trim(),
                          'isVerified':     false,
                        };
                        try {
                          if (isEdit) {
                            await ApiService.updateTemple(temple['_id']?.toString() ?? '', data);
                          } else {
                            await ApiService.addTemple(data);
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _load();
                          _snack(isEdit ? 'Temple updated ✓' : 'Temple added ✓', _primary);
                        } catch (e) {
                          setSheet(() => saving = false);
                          _snack('Error: $e', Colors.red);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'Update Temple' : 'Add Temple',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String label, Color color) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
  ]);

  Widget _timePicker(
    BuildContext ctx,
    TextEditingController ctrl,
    String label,
    IconData icon,
    StateSetter setSheet,
  ) =>
      TextFormField(
        controller: ctrl,
        readOnly: true,
        onTap: () => _pickTime(ctx, ctrl, setSheet),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          suffixIcon: const Icon(Icons.access_time, color: _primary, size: 18),
          filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  Widget _ff(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, color: Colors.red, size: 48),
    const SizedBox(height: 12),
    Text(_error ?? 'Error', style: const TextStyle(color: Colors.grey)),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
        child: const Text('Retry')),
  ]));

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
}