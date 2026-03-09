import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// Place at: lib/screens/admin/admin_prayer_management.dart

class AdminPrayerManagementPage extends StatefulWidget {
  const AdminPrayerManagementPage({super.key});
  @override
  State<AdminPrayerManagementPage> createState() =>
      _AdminPrayerManagementPageState();
}

class _AdminPrayerManagementPageState
    extends State<AdminPrayerManagementPage> {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  List<Map<String, dynamic>> _mantras = [];
  bool _isLoading = true;
  String? _error;
  String _categoryFilter = 'All';

  final List<String> _categories = ['All', 'Morning', 'Evening', 'Mantra'];

  @override
  void initState() {
    super.initState();
    _loadMantras();
  }

  Future<void> _loadMantras() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ApiService.getAllPrayers();
      setState(() {
        _mantras = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_categoryFilter == 'All') return _mantras;
    return _mantras
        .where((m) => (m['category'] ?? '') == _categoryFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Prayer Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMantras,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openMantraForm(),
            tooltip: 'Add Prayer / Mantra',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _errorView()
              : Column(children: [
                  // ── Stats bar ────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      _statTile('Total',   '${_mantras.length}',                                                   Colors.blue),
                      _vDivider(),
                      _statTile('Morning', '${_mantras.where((m) => (m['category'] ?? '') == 'Morning').length}',  Colors.orange),
                      _vDivider(),
                      _statTile('Evening', '${_mantras.where((m) => (m['category'] ?? '') == 'Evening').length}',  Colors.purple),
                      _vDivider(),
                      _statTile('Mantra',  '${_mantras.where((m) => (m['category'] ?? '') == 'Mantra').length}',   Colors.teal),
                    ]),
                  ),

                  // ── Category filter chips ────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((c) {
                            final active = _categoryFilter == c;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: active,
                                onSelected: (_) => setState(
                                    () => _categoryFilter = c),
                                selectedColor: _primary,
                                labelStyle: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : _textGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                                backgroundColor: _accent,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  ),

                  // ── Count + inline add button ────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_filtered.length} prayers found',
                            style: const TextStyle(
                                fontSize: 12, color: _textGrey)),
                        TextButton.icon(
                          onPressed: () => _openMantraForm(),
                          icon: const Icon(Icons.add,
                              size: 16, color: _primary),
                          label: const Text('Add New',
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4)),
                        ),
                      ],
                    ),
                  ),

                  // ── Prayer list ──────────────────────────────
                  Expanded(
                    child: _filtered.isEmpty
                        ? _emptyView()
                        : RefreshIndicator(
                            color: _primary,
                            onRefresh: _loadMantras,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _mantraCard(_filtered[i]),
                            ),
                          ),
                  ),
                ]),

      // ── FAB ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMantraForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Prayer',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Prayer / Mantra Card ─────────────────────────────────────
  Widget _mantraCard(Map<String, dynamic> m) {
    final category = (m['category'] ?? 'Mantra').toString();
    final language = (m['language'] ?? '').toString();
    final duration = (m['duration'] ?? m['durationMins'] ?? '').toString();
    final deity    = (m['deity'] ?? '').toString();
    final lyrics   = (m['lyrics'] ?? m['text'] ?? '').toString();
    final meaning  = (m['meaning'] ?? '').toString();
    final id       = (m['_id'] ?? m['id'] ?? '').toString();
    final catColor = _catColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent),
        boxShadow: [
          BoxShadow(
              color: _primary.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                      child: Text('🙏',
                          style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (m['title'] ?? m['name'] ?? '').toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _textDark),
                        ),
                        if (deity.isNotEmpty)
                          Text('Deity: $deity',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _textGrey)),
                      ]),
                ),
                // Edit / Delete menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: _textGrey),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _openMantraForm(existing: m);
                    }
                    if (action == 'delete') {
                      _confirmDelete(
                          id, (m['title'] ?? '').toString());
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined,
                              size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ])),
                    PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ])),
                  ],
                ),
              ]),

              const SizedBox(height: 10),

              // Chips
              Wrap(spacing: 6, runSpacing: 4, children: [
                _pill(category, catColor),
                if (language.isNotEmpty) _pill(language, Colors.blue),
                if (duration.isNotEmpty && duration != '0')
                  _pill('$duration min', Colors.green),
              ]),

              // Lyrics preview
              if (lyrics.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    lyrics.length > 120
                        ? '${lyrics.substring(0, 120)}...'
                        : lyrics,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _textDark,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  ),
                ),
              ],

              // Meaning preview
              if (meaning.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: _textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meaning.length > 80
                              ? '${meaning.substring(0, 80)}...'
                              : meaning,
                          style: const TextStyle(
                              fontSize: 11, color: _textGrey),
                        ),
                      ),
                    ]),
              ],
            ]),
      ),
    );
  }

  // ── Add / Edit Bottom Sheet ──────────────────────────────────
  void _openMantraForm({Map<String, dynamic>? existing}) {
    final isEdit       = existing != null;
    final titleCtrl    = TextEditingController(
        text: existing?['title'] ?? existing?['name'] ?? '');
    final deityCtrl    = TextEditingController(
        text: existing?['deity'] ?? '');
    final lyricsCtrl   = TextEditingController(
        text: existing?['lyrics'] ?? existing?['text'] ?? '');
    final meaningCtrl  = TextEditingController(
        text: existing?['meaning'] ?? '');
    final durationCtrl = TextEditingController(
        text: (existing?['duration'] ?? existing?['durationMins'] ?? '')
                    .toString() == '0'
            ? ''
            : (existing?['duration'] ?? existing?['durationMins'] ?? '')
                .toString());
    String category = existing?['category'] ?? 'Morning';
    String language = existing?['language'] ?? 'Sanskrit';
    final formKey   = GlobalKey<FormState>();
    bool saving     = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEdit
                            ? 'Edit Prayer / Mantra'
                            : 'Add Prayer / Mantra',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textDark),
                      ),
                      const SizedBox(height: 20),

                      _field(titleCtrl,
                          'Title (e.g. Gayatri Mantra)',
                          Icons.title),
                      const SizedBox(height: 12),
                      _field(deityCtrl,
                          'Deity (e.g. Lord Shiva)',
                          Icons.self_improvement),
                      const SizedBox(height: 12),

                      // Category & Language row
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: _dropDecor(
                                'Category', Icons.category),
                            items: ['Morning', 'Evening', 'Mantra']
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setModal(() => category = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: language,
                            decoration: _dropDecor(
                                'Language', Icons.language),
                            items: [
                              'Sanskrit',
                              'Tamil',
                              'Hindi',
                              'Telugu',
                              'Kannada'
                            ]
                                .map((l) => DropdownMenuItem(
                                    value: l, child: Text(l)))
                                .toList(),
                            onChanged: (v) =>
                                setModal(() => language = v!),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      _field(durationCtrl, 'Duration (mins)',
                          Icons.timer,
                          keyboardType: TextInputType.number,
                          required: false),
                      const SizedBox(height: 12),

                      // Lyrics
                      TextFormField(
                        controller: lyricsCtrl,
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                        decoration: InputDecoration(
                          labelText: 'Lyrics / Mantra Text',
                          prefixIcon: const Icon(Icons.music_note,
                              color: _primary, size: 20),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: _accent)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Meaning
                      TextFormField(
                        controller: meaningCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Meaning (optional)',
                          prefixIcon: const Icon(Icons.info_outline,
                              color: _primary, size: 20),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: _accent)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!
                                      .validate()) {
                                    return;
                                  }
                                  setModal(() => saving = true);
                                  final payload = {
                                    'title':    titleCtrl.text.trim(),
                                    'deity':    deityCtrl.text.trim(),
                                    'category': category,
                                    'language': language,
                                    'duration': int.tryParse(
                                            durationCtrl.text.trim()) ??
                                        0,
                                    'lyrics':  lyricsCtrl.text.trim(),
                                    'meaning': meaningCtrl.text.trim(),
                                  };
                                  bool ok;
                                  if (isEdit) {
                                    final id = (existing['_id'] ??
                                            existing['id'] ??
                                            '')
                                        .toString();
                                    ok = await ApiService
                                        .updatePrayer(id, payload);
                                  } else {
                                    final result = await ApiService
                                        .addPrayer(payload);
                                    ok = result != null;
                                  }
                                  setModal(() => saving = false);
                                  // FIX: guard context use after async gap
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _loadMantras();
                                  _snack(
                                      ok
                                          ? (isEdit
                                              ? 'Updated ✓'
                                              : 'Prayer added ✓')
                                          : 'Failed to save',
                                      ok ? _primary : Colors.red);
                                },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                          child: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : Text(
                                  isEdit
                                      ? 'Update Prayer'
                                      : 'Add Prayer / Mantra',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
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

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Prayer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ApiService.deletePrayer(id);
              if (ok) {
                setState(() => _mantras.removeWhere((m) =>
                    (m['_id'] ?? m['id']).toString() == id));
                _snack('Deleted', Colors.red);
              } else {
                _snack('Delete failed', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Reusable helpers ─────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = true,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  InputDecoration _dropDecor(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: _textGrey),
            const SizedBox(height: 12),
            const Text('Failed to load prayers',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 6),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _textGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMantras,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white),
            ),
          ]),
        ),
      );

  Widget _emptyView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🙏', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('No prayers added yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark)),
          const SizedBox(height: 6),
          const Text('Tap + to add prayers & mantras for users',
              style: TextStyle(fontSize: 12, color: _textGrey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openMantraForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Prayer'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white),
          ),
        ]),
      );

  Color _catColor(String cat) => switch (cat) {
        'Morning' => Colors.orange,
        'Evening' => Colors.purple,
        _         => Colors.teal,
      };

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );

  Widget _statTile(String label, String value, Color color) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: _textGrey)),
        ]),
      );

  Widget _vDivider() => Container(
        width: 1,
        height: 30,
        color: _accent,
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