import 'package:flutter/material.dart';

// Place at: lib/screens/admin/admin_content_management.dart

class AdminContentManagementPage extends StatefulWidget {
  const AdminContentManagementPage({super.key});
  @override
  State<AdminContentManagementPage> createState() =>
      _AdminContentManagementPageState();
}

class _AdminContentManagementPageState extends State<AdminContentManagementPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  late TabController _tabController;

  // ── Banners ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _banners = [
    {'id': 'B001', 'title': 'Karthigai Deepam Festival',   'subtitle': 'Celebrate the festival of lights',        'active': true,  'type': 'Festival', 'order': 1},
    {'id': 'B002', 'title': 'New Temple: Palani Murugan',  'subtitle': 'Now available for darshan booking',        'active': true,  'type': 'Temple',   'order': 2},
    {'id': 'B003', 'title': 'Free Archana This Weekend',   'subtitle': 'Special offer for all devotees',           'active': false, 'type': 'Offer',    'order': 3},
    {'id': 'B004', 'title': 'Annadhanam Drive',            'subtitle': 'Contribute to feed 1000 devotees',         'active': true,  'type': 'Donation', 'order': 4},
  ];

  // ── FAQs ─────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _faqs = [
    {'id': 'F001', 'q': 'How do I book a darshan?',              'a': 'Go to the temple page and tap "Book Darshan". Choose your date and time slot.',              'category': 'Booking',  'active': true},
    {'id': 'F002', 'q': 'Can I cancel my booking?',             'a': 'Yes, you can cancel up to 24 hours before your booking. Refunds are processed in 3–5 days.', 'category': 'Booking',  'active': true},
    {'id': 'F003', 'q': 'How do I make a donation?',            'a': 'Visit the Donation section, choose your temple, select a category, and pay securely.',        'category': 'Donation', 'active': true},
    {'id': 'F004', 'q': 'Are donations tax-exempt?',            'a': 'Yes, all donations made through GodsConnect are eligible for 80G tax deduction.',             'category': 'Donation', 'active': true},
    {'id': 'F005', 'q': 'How does e-commerce delivery work?',   'a': 'Orders are processed within 2 business days and delivered within 5–7 days across India.',     'category': 'Shop',     'active': false},
  ];

  // ── About / Policies ─────────────────────────────────────────
  final List<Map<String, dynamic>> _pages = [
    {'id': 'P001', 'title': 'About GodsConnect',    'content': 'GodsConnect is a digital platform connecting devotees with temples across Tamil Nadu and beyond.',      'lastUpdated': '2026-02-15'},
    {'id': 'P002', 'title': 'Privacy Policy',       'content': 'We respect your privacy. Personal data is collected solely for service delivery and never sold.',      'lastUpdated': '2026-01-20'},
    {'id': 'P003', 'title': 'Terms of Service',     'content': 'By using GodsConnect, you agree to our terms. Misuse of the platform may result in account suspension.','lastUpdated': '2026-01-20'},
    {'id': 'P004', 'title': 'Refund Policy',        'content': 'Bookings cancelled 24 hrs in advance receive full refunds. Donations are non-refundable.',              'lastUpdated': '2026-02-01'},
    {'id': 'P005', 'title': 'Shipping Policy',      'content': 'All e-commerce orders ship within 2 business days. Free shipping on orders above ₹999.',              'lastUpdated': '2026-02-01'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Content Management (CMS)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '🖼️ Banners'),
            Tab(text: '❓ FAQs'),
            Tab(text: '📄 Pages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_bannersTab(), _faqsTab(), _pagesTab()],
      ),
    );
  }

  // ── BANNERS TAB ───────────────────────────────────────────────
  Widget _bannersTab() => Column(children: [
        _statsBar([
          ('Total',  '${_banners.length}',                                          Colors.blue),
          ('Active', '${_banners.where((b) => b['active'] == true).length}',        Colors.green),
          ('Hidden', '${_banners.where((b) => b['active'] == false).length}',       Colors.grey),
        ]),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _banners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _bannerCard(_banners[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Banner', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _editBanner(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
      ]);

  Widget _bannerCard(Map<String, dynamic> b) {
    final typeColor = _bannerTypeColor(b['type']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: b['active'] == true ? _accent : Colors.grey.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(
              color: _primary.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_bannerTypeIcon(b['type']), color: typeColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b['title'],
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: b['active'] == true ? _textDark : _textGrey)),
            const SizedBox(height: 2),
            Text(b['subtitle'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _textGrey)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(b['type'],
                    style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text('Order: ${b['order']}',
                  style: const TextStyle(fontSize: 10, color: _textGrey)),
            ]),
          ]),
        ),
        Column(children: [
          Switch(
            value: b['active'] == true,
            activeThumbColor: Colors.white,
            activeTrackColor: _primary,
            onChanged: (v) {
              setState(() => b['active'] = v);
              _snack('Banner ${v ? 'activated' : 'hidden'}', v ? Colors.green : Colors.grey);
            },
          ),
          GestureDetector(
            onTap: () => _editBanner(banner: b),
            child: const Icon(Icons.edit_outlined, size: 18, color: _textGrey),
          ),
        ]),
      ]),
    );
  }

  void _editBanner({Map<String, dynamic>? banner}) {
    final isEdit    = banner != null;
    final titleCtrl = TextEditingController(text: isEdit ? banner['title']    : '');
    final subCtrl   = TextEditingController(text: isEdit ? banner['subtitle'] : '');
    String type     = isEdit ? banner['type'] : 'Festival';
    final formKey   = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setLocal) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Banner' : 'Add Banner',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 20),
            _field(titleCtrl, 'Banner Title', Icons.image_outlined),
            const SizedBox(height: 12),
            _field(subCtrl, 'Subtitle', Icons.subtitles_outlined),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['Festival', 'Temple', 'Offer', 'Donation', 'Event'].map((t) {
                final active = type == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: active,
                    onSelected: (_) => setLocal(() => type = t),
                    selectedColor: _primary,
                    labelStyle: TextStyle(
                        color: active ? Colors.white : _textGrey,
                        fontWeight: FontWeight.w600, fontSize: 12),
                    backgroundColor: _accent,
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  setState(() {
                    if (isEdit) {
                      banner['title']    = titleCtrl.text.trim();
                      banner['subtitle'] = subCtrl.text.trim();
                      banner['type']     = type;
                    } else {
                      _banners.add({
                        'id':       'B${(_banners.length + 1).toString().padLeft(3, '0')}',
                        'title':    titleCtrl.text.trim(),
                        'subtitle': subCtrl.text.trim(),
                        'active':   true,
                        'type':     type,
                        'order':    _banners.length + 1,
                      });
                    }
                  });
                  Navigator.pop(context);
                  _snack(isEdit ? 'Banner updated ✓' : 'Banner added ✓', _primary);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(isEdit ? 'Update' : 'Add Banner',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ])),
        )),
      ),
    );
  }

  // ── FAQs TAB ──────────────────────────────────────────────────
  Widget _faqsTab() => Column(children: [
        _statsBar([
          ('Total',  '${_faqs.length}',                                      Colors.blue),
          ('Active', '${_faqs.where((f) => f['active'] == true).length}',    Colors.green),
          ('Hidden', '${_faqs.where((f) => f['active'] == false).length}',   Colors.grey),
        ]),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _faqCard(_faqs[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _editFaq(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
      ]);

  Widget _faqCard(Map<String, dynamic> f) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: f['active'] == true ? _accent : Colors.grey.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(
                color: _primary.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5)),
              child: Text(f['category'],
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            const Spacer(),
            Switch(
              value: f['active'] == true,
              activeThumbColor: Colors.white,
              activeTrackColor: _primary,
              onChanged: (v) => setState(() => f['active'] = v),
            ),
            GestureDetector(
              onTap: () => _editFaq(faq: f),
              child: const Icon(Icons.edit_outlined, size: 18, color: _textGrey),
            ),
          ]),
          const SizedBox(height: 8),
          Text(f['q'],
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: f['active'] == true ? _textDark : _textGrey)),
          const SizedBox(height: 6),
          Text(f['a'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _textGrey)),
        ]),
      );

  void _editFaq({Map<String, dynamic>? faq}) {
    final isEdit  = faq != null;
    final qCtrl   = TextEditingController(text: isEdit ? faq['q'] : '');
    final aCtrl   = TextEditingController(text: isEdit ? faq['a'] : '');
    String cat    = isEdit ? faq['category'] : 'Booking';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setLocal) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit FAQ' : 'Add FAQ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 20),
            _field(qCtrl, 'Question', Icons.help_outline),
            const SizedBox(height: 12),
            TextFormField(
              controller: aCtrl,
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              decoration: InputDecoration(
                labelText: 'Answer',
                prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.question_answer_outlined, color: _primary, size: 20)),
                filled: true, fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: ['Booking', 'Donation', 'Shop', 'General'].map((c) {
              final active = cat == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: active,
                  onSelected: (_) => setLocal(() => cat = c),
                  selectedColor: _primary,
                  labelStyle: TextStyle(
                      color: active ? Colors.white : _textGrey,
                      fontWeight: FontWeight.w600, fontSize: 12),
                  backgroundColor: _accent,
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  setState(() {
                    if (isEdit) {
                      faq['q'] = qCtrl.text.trim();
                      faq['a'] = aCtrl.text.trim();
                      faq['category'] = cat;
                    } else {
                      _faqs.add({
                        'id':       'F${(_faqs.length + 1).toString().padLeft(3, '0')}',
                        'q':        qCtrl.text.trim(),
                        'a':        aCtrl.text.trim(),
                        'category': cat,
                        'active':   true,
                      });
                    }
                  });
                  Navigator.pop(context);
                  _snack(isEdit ? 'FAQ updated ✓' : 'FAQ added ✓', _primary);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(isEdit ? 'Update' : 'Add FAQ',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]))),
        )),
      ),
    );
  }

  // ── PAGES TAB ─────────────────────────────────────────────────
  Widget _pagesTab() => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _pages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _pageCard(_pages[i]),
      );

  Widget _pageCard(Map<String, dynamic> p) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent),
            boxShadow: [BoxShadow(
                color: _primary.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.article_outlined, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['title'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: _textDark)),
              const SizedBox(height: 3),
              Text(p['content'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _textGrey)),
              const SizedBox(height: 4),
              Text('Last updated: ${p['lastUpdated']}',
                  style: const TextStyle(fontSize: 10, color: _textGrey)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _primary, size: 20),
            onPressed: () => _editPage(p),
          ),
        ]),
      );

  void _editPage(Map<String, dynamic> p) {
    final contentCtrl = TextEditingController(text: p['content']);
    final formKey     = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text('Edit: ${p['title']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 20),
            TextFormField(
              controller: contentCtrl,
              maxLines: 6,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              decoration: InputDecoration(
                labelText: 'Content',
                prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: Icon(Icons.article_outlined, color: _primary, size: 20)),
                filled: true, fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final now = DateTime.now();
                  setState(() {
                    p['content']     = contentCtrl.text.trim();
                    p['lastUpdated'] = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
                  });
                  Navigator.pop(context);
                  _snack('Page updated ✓', _primary);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ])),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _statsBar(List<(String, String, Color)> items) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: items.expand((item) {
            final idx = items.indexOf(item);
            return [
              Expanded(
                child: Column(children: [
                  Text(item.$2,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: item.$3)),
                  Text(item.$1, style: const TextStyle(fontSize: 10, color: _textGrey)),
                ]),
              ),
              if (idx < items.length - 1)
                Container(width: 1, height: 28, color: _accent,
                    margin: const EdgeInsets.symmetric(horizontal: 4)),
            ];
          }).toList(),
        ),
      );

  Widget _sheetHandle() => Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
            color: Colors.grey[300], borderRadius: BorderRadius.circular(2)));

  Widget _field(TextEditingController ctrl, String label, IconData icon) =>
      TextFormField(
        controller: ctrl,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  Color _bannerTypeColor(String t) => switch (t) {
        'Festival' => Colors.deepOrange,
        'Temple'   => Colors.teal,
        'Offer'    => Colors.red,
        'Donation' => Colors.purple,
        'Event'    => Colors.blue,
        _          => _primary,
      };

  IconData _bannerTypeIcon(String t) => switch (t) {
        'Festival' => Icons.celebration,
        'Temple'   => Icons.temple_hindu,
        'Offer'    => Icons.local_offer,
        'Donation' => Icons.volunteer_activism,
        'Event'    => Icons.event,
        _          => Icons.image,
      };

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }
}