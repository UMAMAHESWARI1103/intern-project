import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminEventManagementPage extends StatefulWidget {
  const AdminEventManagementPage({super.key});

  @override
  State<AdminEventManagementPage> createState() =>
      _AdminEventManagementPageState();
}

class _AdminEventManagementPageState extends State<AdminEventManagementPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  List<Map<String, dynamic>> _events  = [];
  bool   _isLoading = true;
  String _filter    = 'All';
  String? _error;
  final _searchCtrl = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────────────
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _templeNameCtrl  = TextEditingController();
  final _maxPaxCtrl      = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _timeCtrl        = TextEditingController();
  DateTime? _pickedDate;
  String    _category    = 'Festival';
  bool      _isFree      = true;
  String?   _editingId;

  static const List<String> _categories = [
    'Festival', 'Pooja', 'Special', 'Cultural', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _searchCtrl, _titleCtrl, _descCtrl, _locationCtrl,
      _templeNameCtrl, _maxPaxCtrl, _priceCtrl, _timeCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ApiService.getAllEvents();
      if (mounted) {
        setState(() {
          _events    = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _computeStatus(Map<String, dynamic> e) {
    final stored = e['status']?.toString() ?? '';
    if (stored.isNotEmpty) return stored;
    try {
      final d   = DateTime.parse(e['date']?.toString() ?? '');
      final now = DateTime.now();
      if (d.isAfter(now)) return 'Upcoming';
      if (d.isAfter(now.subtract(const Duration(days: 1)))) return 'Ongoing';
      return 'Completed';
    } catch (_) { return 'Upcoming'; }
  }

  List<Map<String, dynamic>> get _filtered => _events.where((e) {
    final q     = _searchCtrl.text.toLowerCase();
    final match = q.isEmpty ||
        (e['title']      ?? '').toString().toLowerCase().contains(q) ||
        (e['templeName'] ?? '').toString().toLowerCase().contains(q);
    final status      = _computeStatus(e);
    final matchFilter = _filter == 'All' || status == _filter;
    return match && matchFilter;
  }).toList();

  void _clearForm() {
    _editingId = null;
    _titleCtrl.clear(); _descCtrl.clear(); _locationCtrl.clear();
    _templeNameCtrl.clear(); _maxPaxCtrl.clear(); _priceCtrl.clear();
    _timeCtrl.clear();
    _pickedDate = null;
    _category   = 'Festival';
    _isFree     = true;
  }

  void _populateForm(Map<String, dynamic> e) {
    _editingId = (e['_id'] ?? e['id'] ?? '').toString();
    _titleCtrl.text      = e['title']      ?? '';
    _descCtrl.text       = e['description'] ?? '';
    _locationCtrl.text   = e['location']   ?? '';
    _templeNameCtrl.text = e['templeName'] ?? '';
    _maxPaxCtrl.text     = (e['maxParticipants'] ?? '').toString();
    _priceCtrl.text      = (e['registrationFee'] ?? '').toString();
    _timeCtrl.text       = e['time'] ?? '';
    _category            = e['category'] ?? 'Festival';
    _isFree              = e['isFree'] == true || (e['registrationFee'] ?? 0) == 0;
    try { _pickedDate = DateTime.parse(e['date'].toString()); } catch (_) {}
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title is required', Colors.red); return;
    }
    final payload = {
      'title':           _titleCtrl.text.trim(),
      'description':     _descCtrl.text.trim(),
      'location':        _locationCtrl.text.trim(),
      'templeName':      _templeNameCtrl.text.trim(),
      'maxParticipants': int.tryParse(_maxPaxCtrl.text) ?? 0,
      'registrationFee': _isFree ? 0 : (double.tryParse(_priceCtrl.text) ?? 0),
      'isFree':          _isFree,
      'category':        _category,
      'time':            _timeCtrl.text.trim(),
      if (_pickedDate != null) 'date': _pickedDate!.toIso8601String(),
    };
    try {
      if (_editingId != null) {
        await ApiService.updateEvent(_editingId!, payload);
        _snack('Event updated', Colors.green);
      } else {
        await ApiService.addEvent(payload);
        _snack('Event created', Colors.green);
      }
      _clearForm();
      _load();
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  String _resolveId(Map<String, dynamic> e) =>
      (e['_id'] ?? e['id'] ?? '').toString();

  Future<void> _delete(Map<String, dynamic> e) async {
    final id = _resolveId(e);
    if (id.isEmpty) {
      _snack('Cannot delete: event ID not found', Colors.red);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteEvent(id);
      _snack('Event deleted', Colors.orange);
      _load();
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Event Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Event',
            onPressed: () { _clearForm(); _showForm(); },
          ),
        ],
      ),
      body: Column(children: [
        // ── Search + Filter bar ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search events or temples...',
                prefixIcon: const Icon(Icons.search, color: _primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
                filled: true, fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Upcoming', 'Ongoing', 'Completed'].map((f) {
                  final active = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f), selected: active,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: _primary,
                      labelStyle: TextStyle(
                          color: active ? Colors.white : _textGrey,
                          fontWeight: FontWeight.w600, fontSize: 12),
                      backgroundColor: _accent,
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : _filtered.isEmpty
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎪', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _events.isEmpty ? 'No events yet' : 'No events found',
                              style: const TextStyle(color: _textGrey, fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () { _clearForm(); _showForm(); },
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Event'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white),
                            ),
                          ]))
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _eventCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () { _clearForm(); _showForm(); },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Event card ───────────────────────────────────────────────────────────
  Widget _eventCard(Map<String, dynamic> e) {
    final status      = _computeStatus(e);
    final statusColor = _statusColor(status);
    final isFree      = e['isFree'] == true || (e['registrationFee'] ?? 0) == 0;
    final title       = e['title']      ?? 'Event';
    final templeName  = e['templeName'] ?? '';
    final date        = e['date']       ?? '';
    final time        = e['time']       ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent),
        boxShadow: [BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Icon ────────────────────────────────────────────────────
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(
                (e['category'] == 'Festival') ? '🪔' :
                (e['category'] == 'Pooja')    ? '🛕' :
                (e['category'] == 'Special')  ? '✨' :
                (e['category'] == 'Cultural') ? '🎭' : '🎪',
                style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 10),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13, color: _textDark)),
                      ),
                      const SizedBox(width: 6),
                      _statusBadge(status, statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Temple name
                  if (templeName.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.temple_hindu, size: 12, color: _textGrey),
                      const SizedBox(width: 3),
                      Expanded(child: Text(templeName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _textGrey, fontSize: 12))),
                    ]),
                  const SizedBox(height: 4),

                  // Date / time / free badge
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (date.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.calendar_today,
                              size: 11, color: _textGrey),
                          const SizedBox(width: 3),
                          Text(_shortDate(date),
                              style: const TextStyle(
                                  color: _textGrey, fontSize: 11)),
                        ]),
                      if (time.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.access_time,
                              size: 11, color: _textGrey),
                          const SizedBox(width: 3),
                          Text(time,
                              style: const TextStyle(
                                  color: _textGrey, fontSize: 11)),
                        ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFree
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isFree
                              ? 'Free'
                              : '₹${(e['registrationFee'] ?? 0).toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold,
                              color: isFree ? Colors.green : Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),

        // ── Action buttons ───────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: _bg,
            border: Border(top: BorderSide(color: _accent)),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Row(children: [
            Expanded(child: TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Edit', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: _primary),
              onPressed: () { _populateForm(e); _showForm(); },
            )),
            Container(width: 1, height: 36, color: _accent),
            Expanded(child: TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('Delete', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _delete(e),
            )),
          ]),
        ),
      ]),
    );
  }

  String _shortDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) { return raw; }
  }

  Color _statusColor(String status) => switch (status) {
    'Upcoming'  => Colors.orange,
    'Ongoing'   => Colors.green,
    'Completed' => Colors.grey,
    _           => Colors.blue,
  };

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6)),
    child: Text(status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );

  // ── Add / Edit form bottom sheet ─────────────────────────────────────────
  void _showForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Text(_editingId == null ? 'Add New Event' : 'Edit Event',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _formField(_titleCtrl, 'Event Title *', Icons.title),
              const SizedBox(height: 10),
              _formField(_templeNameCtrl, 'Temple Name', Icons.temple_hindu),
              const SizedBox(height: 10),
              _formField(_descCtrl, 'Description', Icons.description,
                  maxLines: 3),
              const SizedBox(height: 10),
              _formField(_locationCtrl, 'Location', Icons.location_on),
              const SizedBox(height: 10),
              _formField(_timeCtrl, 'Time (e.g. 6:00 AM)', Icons.access_time),
              const SizedBox(height: 10),

              // Date picker
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: _pickedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setBS(() => _pickedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        color: _primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _pickedDate == null
                          ? 'Pick Date'
                          : '${_pickedDate!.day}/${_pickedDate!.month}/${_pickedDate!.year}',
                      style: TextStyle(
                          color: _pickedDate == null
                              ? Colors.grey
                              : _textDark),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category, color: _primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setBS(() => _category = v ?? 'Festival'),
              ),
              const SizedBox(height: 10),

              // Free / Paid toggle
              SwitchListTile(
                value: _isFree,
                onChanged: (v) => setBS(() => _isFree = v),
                title: Text(_isFree ? 'Free Event' : 'Paid Event',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                secondary: Icon(
                    _isFree ? Icons.free_breakfast : Icons.paid,
                    color: _primary),
                activeThumbColor: _primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_isFree) ...[
                const SizedBox(height: 6),
                _formField(_priceCtrl, 'Registration Fee (₹)',
                    Icons.currency_rupee,
                    type: TextInputType.number),
              ],
              const SizedBox(height: 10),
              _formField(_maxPaxCtrl, 'Max Participants (0 = unlimited)',
                  Icons.people,
                  type: TextInputType.number),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _save();
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _editingId == null ? 'Create Event' : 'Save Changes',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? type,
  }) =>
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
      ),
    );

  Widget _errorView() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Error', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 12),
      ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary, foregroundColor: Colors.white),
          child: const Text('Retry')),
    ]),
  );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }
}