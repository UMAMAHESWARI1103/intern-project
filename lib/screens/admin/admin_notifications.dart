import 'package:flutter/material.dart';

// Place at: lib/screens/admin/admin_notifications.dart

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});
  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _bg       = Color(0xFFFFF8F0);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  late TabController _tabController;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  String _type     = 'General';
  String _audience = 'All Users';

  final List<Map<String, dynamic>> _history = [
    {'id': 'N001', 'title': 'Karthigai Deepam Reminder',  'body': 'Join us for the grand festival of lights this Friday at 6 AM.', 'audience': 'All Users',     'sentAt': '2026-02-28 10:30', 'type': 'Event',   'reach': 1380, 'opened': 892},
    {'id': 'N002', 'title': 'New Temple Added',            'body': 'Arulmigu Subramanya Swamy Temple has been added to the platform.','audience': 'All Users',   'sentAt': '2026-02-27 14:00', 'type': 'Temple',  'reach': 1380, 'opened': 654},
    {'id': 'N003', 'title': 'Booking Confirmed',           'body': 'Your Darshan booking for March 5 has been confirmed.',           'audience': 'Specific User','sentAt': '2026-02-26 09:15', 'type': 'Booking', 'reach': 1,    'opened': 1},
    {'id': 'N004', 'title': 'Donation Receipt',            'body': 'Thank you for your donation of ₹5,000 to Meenakshi Amman.',     'audience': 'Specific User','sentAt': '2026-02-25 16:45', 'type': 'Donation','reach': 1,    'opened': 1},
    {'id': 'N005', 'title': 'Festival Offer: Free Archana','body': 'Get free Archana on all bookings this Navratri!',               'audience': 'All Users',     'sentAt': '2026-02-24 08:00', 'type': 'Offer',   'reach': 1380, 'opened': 1102},
    {'id': 'N006', 'title': 'App Update Available',        'body': 'New version 2.1 is available with improved features.',          'audience': 'All Users',     'sentAt': '2026-02-22 11:00', 'type': 'System',  'reach': 1380, 'opened': 780},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '📢 Broadcast'),
            Tab(text: '📋 History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_broadcastTab(), _historyTab()],
      ),
    );
  }

  Widget _broadcastTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats
          Row(children: [
            _statCard('Total Sent', '${_history.length}',   Icons.send,       Colors.blue),
            const SizedBox(width: 12),
            _statCard('Avg Open',
                '${_history.isNotEmpty ? (_history.fold(0, (s, n) => s + (n['opened'] as int)) * 100 / _history.fold(0, (s, n) => s + (n['reach'] as int))).toInt() : 0}%',
                Icons.open_in_new, Colors.green),
            const SizedBox(width: 12),
            _statCard('Reach', '${_history.fold(0, (s, n) => s + (n['reach'] as int))}', Icons.people, Colors.purple),
          ]),
          const SizedBox(height: 20),

          // Compose
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent),
                boxShadow: [BoxShadow(
                    color: _primary.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Compose Notification',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Notification Title *',
                  prefixIcon: const Icon(Icons.title, color: _primary, size: 20),
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
              TextField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message Body *',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.message_outlined, color: _primary, size: 20),
                  ),
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
              const SizedBox(height: 14),
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textDark)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['General', 'Event', 'Temple', 'Booking', 'Donation', 'Offer', 'System'].map((t) {
                    final active = _type == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: active,
                        onSelected: (_) => setState(() => _type = t),
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
              const SizedBox(height: 12),
              const Text('Send To', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['All Users', 'Temple Admins', 'Priests', 'Specific User'].map((a) {
                  final active = _audience == a;
                  return ChoiceChip(
                    label: Text(a),
                    selected: active,
                    onSelected: (_) => setState(() => _audience = a),
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                        color: active ? Colors.white : _textGrey,
                        fontWeight: FontWeight.w600, fontSize: 12),
                    backgroundColor: _accent,
                  );
                }).toList(),
              ),

              // Live preview
              if (_titleCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.temple_hindu, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('GodsConnect',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12, color: _textDark)),
                        Text('Preview', style: TextStyle(fontSize: 10, color: _textGrey)),
                      ]),
                    ]),
                    const SizedBox(height: 8),
                    Text(_titleCtrl.text,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13, color: _textDark)),
                    if (_bodyCtrl.text.isNotEmpty)
                      Text(_bodyCtrl.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _textGrey)),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text('Send to $_audience',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _sendNotification,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ),
        ]),
      );

  Widget _historyTab() => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _notifCard(_history[i]),
      );

  Widget _notifCard(Map<String, dynamic> n) {
    final typeColor = _typeColor(n['type']);
    final openRate  = n['reach'] > 0
        ? ((n['opened'] as int) / (n['reach'] as int) * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent),
          boxShadow: [BoxShadow(
              color: _primary.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text(n['type'],
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: typeColor)),
          ),
          const Spacer(),
          Text(n['sentAt'], style: const TextStyle(fontSize: 11, color: _textGrey)),
        ]),
        const SizedBox(height: 8),
        Text(n['title'],
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
        const SizedBox(height: 4),
        Text(n['body'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _textGrey)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.people_outline, size: 13, color: _textGrey),
          const SizedBox(width: 4),
          Text(n['audience'], style: const TextStyle(fontSize: 12, color: _textGrey)),
          const Spacer(),
          _pill('${n['reach']} sent', Colors.blue),
          const SizedBox(width: 6),
          _pill('$openRate% opened', openRate > 60 ? Colors.green : Colors.orange),
        ]),
      ]),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent)),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: _textGrey)),
          ]),
        ),
      );

  Color _typeColor(String t) => switch (t) {
        'Event'    => Colors.blue,
        'Temple'   => Colors.deepOrange,
        'Booking'  => Colors.green,
        'Donation' => Colors.purple,
        'Offer'    => Colors.red,
        'System'   => Colors.grey,
        _          => _primary,
      };

  void _sendNotification() {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      _snack('Please enter title and message', Colors.red);
      return;
    }
    final now = DateTime.now();
    setState(() {
      _history.insert(0, {
        'id':       'N${(_history.length + 1).toString().padLeft(3, '0')}',
        'title':    _titleCtrl.text.trim(),
        'body':     _bodyCtrl.text.trim(),
        'audience': _audience,
        'sentAt':   '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
        'type':     _type,
        'reach':    _audience == 'All Users' ? 1380 : _audience == 'Specific User' ? 1 : 50,
        'opened':   0,
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _type     = 'General';
      _audience = 'All Users';
    });
    _snack('Notification sent 📢', Colors.green);
    _tabController.animateTo(1);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }
}