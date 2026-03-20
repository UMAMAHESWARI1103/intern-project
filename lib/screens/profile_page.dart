import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfilePage({super.key, this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  List<Map<String, dynamic>> _bookings           = [];
  List<Map<String, dynamic>> _eventRegistrations = [];
  bool _bookingsLoading = true;

  // ── ORDERS ──────────────────────────────────
  List<Map<String, dynamic>> _orders        = [];
  bool                       _ordersLoading = true;
  // ────────────────────────────────────────────

  static const _primary = Color(0xFFFF9933);

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // was 2, now 3
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (_userData != null) {
      _loadBookings();
      _loadOrders();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (widget.userData != null) {
      setState(() { _userData = widget.userData; _isLoading = false; });
      _loadBookings();
      _loadOrders();
      return;
    }
    final token = await ApiService.loadToken();
    if (token == null || token.isEmpty) {
      setState(() { _userData = null; _isLoading = false; });
      return;
    }
    try {
      final data = await ApiService.getUserProfile();
      setState(() { _userData = data; _isLoading = false; });
      if (data != null) {
        _loadBookings();
        _loadOrders();
      }
    } catch (_) {
      setState(() { _userData = null; _isLoading = false; });
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _bookingsLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getUserBookings(),
        ApiService.getUserEventRegistrations(),
      ]);
      setState(() {
        _bookings           = results[0];
        _eventRegistrations = results[1].map((e) => {...e, 'type': 'event'}).toList();
        _bookingsLoading    = false;
      });
    } catch (_) {
      setState(() => _bookingsLoading = false);
    }
  }

  // ── Load orders ──────────────────────────────
  Future<void> _loadOrders() async {
    setState(() => _ordersLoading = true);
    try {
      final result = await ApiService.getUserOrders();
      setState(() {
        _orders        = result;
        _ordersLoading = false;
      });
    } catch (_) {
      setState(() => _ordersLoading = false);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await ApiService.cancelOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ────────────────────────────────────────────

  Future<void> _logout() async {
    ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ════════════════════════════════════════════
  //  BOOKING DETAIL BOTTOM SHEET
  // ════════════════════════════════════════════
  void _showBookingDetail(BuildContext context, Map<String, dynamic> data) {
    final type        = (data['type'] ?? data['bookingType'] ?? 'booking') as String;
    final status      = (data['status'] ?? 'confirmed') as String;
    final amount      = data['totalAmount'] ?? data['amount'] ?? 0;
    final cfg         = _typeConfig(type);
    final statusColor = _statusColor(status);

    String fmtDate(dynamic raw) {
      if (raw == null || raw.toString().isEmpty) return '—';
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) { return raw.toString(); }
    }

    List<_DetailRow> rows = [];

    if ((data['userName'] ?? '').toString().isNotEmpty) {
      rows.add(_DetailRow(Icons.person, 'Name', data['userName'].toString()));
    }
    if ((data['userEmail'] ?? '').toString().isNotEmpty) {
      rows.add(_DetailRow(Icons.email, 'Email', data['userEmail'].toString()));
    }
    if ((data['userPhone'] ?? '').toString().isNotEmpty) {
      rows.add(_DetailRow(Icons.phone, 'Phone', data['userPhone'].toString()));
    }
    rows.add(const _DetailRow(Icons.circle, '', ''));

    switch (type) {
      case 'darshan':
        rows.addAll([
          _DetailRow(Icons.temple_hindu,   'Temple',       data['templeName'] ?? '—'),
          _DetailRow(Icons.star,           'Darshan Type', data['darshanType'] ?? 'Normal'),
          _DetailRow(Icons.calendar_today, 'Date',         fmtDate(data['date'])),
          _DetailRow(Icons.access_time,    'Time Slot',    data['timeSlot'] ?? '—'),
          _DetailRow(Icons.people,         'Persons',      '${data['numberOfPersons'] ?? 1}'),
        ]);
        break;
      case 'homam':
        rows.addAll([
          _DetailRow(Icons.temple_hindu,          'Temple',     data['templeName'] ?? '—'),
          _DetailRow(Icons.local_fire_department, 'Homam Type', data['homamType']  ?? '—'),
          _DetailRow(Icons.calendar_today,        'Date',       fmtDate(data['date'])),
          _DetailRow(Icons.access_time,           'Time Slot',  data['timeSlot']   ?? '—'),
          _DetailRow(Icons.person,                'Priest',     data['iyer']       ?? 'To be assigned'),
        ]);
        if ((data['specialNote'] ?? '').toString().isNotEmpty) {
          rows.add(_DetailRow(Icons.note, 'Note', data['specialNote'].toString()));
        }
        break;
      case 'marriage':
        rows.addAll([
          _DetailRow(Icons.temple_hindu,   'Temple',       data['templeName']  ?? '—'),
          _DetailRow(Icons.man,            'Groom',        data['groomName']   ?? '—'),
          _DetailRow(Icons.woman,          'Bride',        data['brideName']   ?? '—'),
          _DetailRow(Icons.calendar_today, 'Wedding Date', fmtDate(data['weddingDate'])),
          _DetailRow(Icons.access_time,    'Time Slot',    data['timeSlot']    ?? '—'),
          _DetailRow(Icons.people,         'Guests',       '${data['guestCount'] ?? 0}'),
        ]);
        if ((data['specialNote'] ?? '').toString().isNotEmpty) {
          rows.add(_DetailRow(Icons.note, 'Note', data['specialNote'].toString()));
        }
        break;
      case 'prasadam':
        rows.add(_DetailRow(Icons.temple_hindu, 'Temple', data['templeName'] ?? '—'));
        final items = data['items'];
        if (items != null && items is List && items.isNotEmpty) {
          for (final item in items) {
            rows.add(_DetailRow(Icons.fastfood, 'Item',
                '${item['name'] ?? item.toString()} × ${item['qty'] ?? item['quantity'] ?? 1}'));
          }
        }
        break;
      case 'event':
        rows.addAll([
          _DetailRow(Icons.event,          'Event',      data['eventTitle'] ?? data['title'] ?? '—'),
          _DetailRow(Icons.temple_hindu,   'Temple',     data['templeName'] ?? '—'),
          _DetailRow(Icons.calendar_today, 'Event Date', fmtDate(data['eventDate'])),
        ]);
        break;
    }

    rows.add(const _DetailRow(Icons.circle, '', ''));
    rows.add(_DetailRow(Icons.calendar_today, 'Booked On', fmtDate(data['createdAt'])));
    if ((data['razorpayPaymentId'] ?? '').toString().isNotEmpty) {
      rows.add(_DetailRow(Icons.payment, 'Payment ID', data['razorpayPaymentId'].toString()));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (__, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (cfg['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(cfg['icon'] as String,
                      style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_bookingTitle(type, data),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor)),
                    ),
                  ],
                )),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹$amount',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22, color: _primary)),
                  const Text('Paid',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ]),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 4),
              ...rows.map((row) {
                if (row.label.isEmpty) {
                  return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider());
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(row.icon, size: 18, color: _primary),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: Text(row.label,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(row.value,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              if ((data['razorpayPaymentId'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: data['razorpayPaymentId'].toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Payment ID copied!'),
                            behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: _primary),
                    label: const Text('Copy Payment ID',
                        style: TextStyle(color: _primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close 🙏',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bookingTitle(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'darshan':  return data['templeName'] ?? 'Darshan Booking';
      case 'homam':    return data['homamType']  ?? 'Homam Booking';
      case 'marriage': return 'Marriage Ceremony';
      case 'prasadam': return 'Prasadam Order';
      case 'event':    return data['eventTitle'] ?? data['title'] ?? 'Event';
      default:         return 'Booking';
    }
  }

  void _showLoginRequired(BuildContext context, String featureName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(isDark),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline, color: _primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Login Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Create an account to access $featureName',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 24),
          _fullBtn('Login / Sign Up', () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/login');
          }),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
        ]),
      ),
    );
  }

  void _openAbout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.temple_hindu, color: _primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text('GodsConnect',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('Version 1.0.0', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 16),
          Text(
            'GodsConnect is your complete digital companion for temple visits. '
            'Book darshan, homam, prasadam, and marriages. '
            'Stay updated on events, access prayers, and connect with the divine.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.6,
                color: isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          const Text('Built with ❤️ for Devotees',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) => _openTextSheet(
    context, title: 'Privacy Policy',
    icon: Icons.privacy_tip_outlined, iconColor: Colors.purple,
    content: '''
**GodsConnect Privacy Policy**
Last updated: January 2025

**1. Information We Collect**
We collect information you provide when creating an account — name, email, and phone number — along with booking and transaction data.

**2. How We Use Your Information**
• Process temple bookings and donations
• Send booking confirmations and reminders
• Improve services and user experience
• Communicate important updates about bookings

**3. Data Security**
We use industry-standard SSL encryption. Passwords are hashed and never stored in plain text. Payments are processed securely via Razorpay.

**4. Data Sharing**
We do not sell your personal data. Data is shared only with temples for booking fulfillment and payment processors for transactions.

**5. Your Rights**
You may request to view, update, or delete your personal data by contacting privacy@godsconnect.app.

**6. Contact**
privacy@godsconnect.app
    ''',
  );

  void _openTerms(BuildContext context) => _openTextSheet(
    context, title: 'Terms & Conditions',
    icon: Icons.description_outlined, iconColor: Colors.indigo,
    content: '''
**GodsConnect Terms & Conditions**
Last updated: January 2025

**1. Acceptance of Terms**
By using GodsConnect, you agree to these terms.

**2. User Accounts**
You are responsible for maintaining the confidentiality of your credentials. Provide accurate information during registration.

**3. Booking Policy**
• Bookings are subject to temple availability
• Cancellations must be made 24 hours in advance for a full refund
• No-shows are non-refundable
• GodsConnect acts as a facilitator — services are provided by temples

**4. Payments**
Payments are processed via Razorpay. GodsConnect does not store card details. Refunds within 5-7 business days.

**5. Prohibited Use**
You may not use this app for fraudulent bookings, misrepresentation, or illegal activity.

**6. Contact**
legal@godsconnect.app
    ''',
  );

  void _openHelpSupport(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqs = [
      {'q': 'How do I book a darshan?',
       'a': 'Go to Home → Booking Services → Darshan. Select your temple, date, and number of persons.'},
      {'q': 'How do I cancel a booking?',
       'a': 'Go to Profile → Bookings, find your booking and tap Cancel. Allowed up to 24 hours before.'},
      {'q': 'Is my payment secure?',
       'a': 'Yes! We use Razorpay — a trusted payment gateway with 256-bit SSL encryption.'},
      {'q': 'How do I update my profile?',
       'a': 'Go to Settings → Account → tap the edit icon to update name, phone, or email.'},
      {'q': 'Can I use the app without login?',
       'a': 'Yes! Browse temples, view events and prayers freely. Bookings require login.'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.92, minChildSize: 0.4,
        builder: (__, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ListView(controller: ctrl, children: [
            Center(child: _handle(isDark)),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.help_outline, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Help & Support',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            ]),
            const SizedBox(height: 20),
            ...faqs.map((faq) => Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(faq['q']!,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                iconColor: _primary, collapsedIconColor: Colors.grey,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(faq['a']!,
                        style: TextStyle(fontSize: 13, height: 1.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri(scheme: 'mailto', path: 'support@godsconnect.app');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  await Clipboard.setData(
                      const ClipboardData(text: 'support@godsconnect.app'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Email copied: support@godsconnect.app'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              icon: const Icon(Icons.email_outlined, color: _primary),
              label: const Text('Email Support', style: TextStyle(color: _primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _openTextSheet(BuildContext context, {
    required String title, required IconData icon,
    required Color iconColor, required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (__, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Column(children: [
                _handle(isDark),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: isDark ? Colors.grey[400] : Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                Divider(color: isDark ? Colors.grey[800] : const Color(0xFFFFE0B2)),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: content.trim().split('\n').map((line) {
                  if (line.startsWith('**') && line.endsWith('**')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text(line.replaceAll('**', ''),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                    );
                  }
                  if (line.startsWith('•')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(line,
                          style: TextStyle(fontSize: 13, height: 1.6,
                              color: isDark ? Colors.grey[300] : Colors.grey[800])),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(line,
                        style: TextStyle(fontSize: 13, height: 1.6,
                            color: isDark ? Colors.grey[300] : Colors.grey[800])),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_userData == null) return _buildGuestProfile(context);

    final name    = (_userData!['name']  ?? 'User') as String;
    final email   = (_userData!['email'] ?? '')     as String;
    final phone   = (_userData!['phone'] ?? '')     as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        _buildLoggedInHeader(context, initial, name, email, phone),
        Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _primary,
            labelColor: _primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
              Tab(icon: Icon(Icons.history),        text: 'Bookings'),
              Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Orders'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(context, name, email, phone),
              _buildBookingsTab(context),
              _buildOrdersTab(context),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F0);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textDark  = isDark ? Colors.white            : const Color(0xFF1A1A1A);
    final textGrey  = isDark ? Colors.grey[400]!       : Colors.grey[600]!;
    final divColor  = isDark ? Colors.grey[800]!       : const Color(0xFFFFE0B2);

    final lockedFeatures = [
      {'icon': Icons.bookmark_border,             'label': 'Saved Temples',    'color': Colors.deepOrange},
      {'icon': Icons.calendar_today_outlined,     'label': 'My Bookings',      'color': Colors.green},
      {'icon': Icons.volunteer_activism_outlined, 'label': 'Donation History', 'color': Colors.purple},
      {'icon': Icons.favorite_border,             'label': 'Favorites',        'color': Colors.red},
    ];

    final appInfoItems = [
      {'icon': Icons.info_outline,        'label': 'About GodsConnect',  'onTap': () => _openAbout(context)},
      {'icon': Icons.privacy_tip_outlined,'label': 'Privacy Policy',     'onTap': () => _openPrivacyPolicy(context)},
      {'icon': Icons.description_outlined,'label': 'Terms & Conditions', 'onTap': () => _openTerms(context)},
      {'icon': Icons.help_outline,        'label': 'Help & Support',     'onTap': () => _openHelpSupport(context)},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: const Icon(Icons.person_outline, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text('Welcome to GodsConnect 🙏',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Login to personalise your experience',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Login / Sign Up',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Why Login?', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                ]),
                const SizedBox(height: 12),
                _benefitRow('🛕', 'Track your temple visits', textGrey),
                _benefitRow('📅', 'Manage all your bookings', textGrey),
                _benefitRow('🚨', 'Get emergency alerts',     textGrey),
                _benefitRow('💝', 'Manage donations',         textGrey),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text('Quick Access', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                ),
                ...lockedFeatures.asMap().entries.map((e) {
                  final f = e.value;
                  return Column(children: [
                    if (e.key > 0) Divider(height: 1, color: divColor, indent: 56),
                    ListTile(
                      leading: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: (f['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f['icon'] as IconData,
                            color: f['color'] as Color, size: 20),
                      ),
                      title: Text(f['label'] as String,
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w500, color: textDark)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Login',
                              style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      ]),
                      onTap: () => _showLoginRequired(context, f['label'] as String),
                    ),
                  ]);
                }),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text('App Info', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                ),
                ...appInfoItems.asMap().entries.map((e) {
                  final item = e.value;
                  return Column(children: [
                    if (e.key > 0) Divider(height: 1, color: divColor, indent: 56),
                    ListTile(
                      leading: Icon(item['icon'] as IconData, color: _primary, size: 22),
                      title: Text(item['label'] as String,
                          style: TextStyle(fontSize: 14, color: textDark)),
                      trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                      onTap: item['onTap'] as VoidCallback,
                    ),
                  ]);
                }),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Column(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.temple_hindu, color: _primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text('GodsConnect',
                style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 2),
            Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: textGrey)),
            Text('Built with ❤️ for Devotees',
                style: TextStyle(fontSize: 12, color: textGrey)),
          ]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _benefitRow(String emoji, String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Text(text, style: TextStyle(fontSize: 13, color: color)),
    ]),
  );

  Widget _buildLoggedInHeader(BuildContext context, String initial,
      String name, String email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 40, backgroundColor: Colors.white,
          child: Text(initial,
              style: const TextStyle(fontSize: 34,
                  fontWeight: FontWeight.bold, color: _primary)),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 3),
        Text(email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(phone, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, size: 15, color: Colors.white),
          label: const Text('Logout',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ),
      ]),
    );
  }

  Widget _buildProfileTab(BuildContext context, String name,
      String email, String phone) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final divColor  = isDark ? Colors.grey[800]! : const Color(0xFFFFE0B2);
    final textColor = isDark ? Colors.grey[300]! : Colors.black87;

    Widget infoCard(String title, List<Widget> rows) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: _primary)),
        ),
        Divider(height: 1, color: divColor),
        ...rows,
      ]),
    );

    Widget infoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(width: 12),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 13, color: textColor))),
      ]),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 8),
        infoCard('Personal Details', [
          infoRow(Icons.person, 'Name',  name),
          infoRow(Icons.email,  'Email', email),
          if (phone.isNotEmpty) infoRow(Icons.phone, 'Phone', phone),
        ]),
        const SizedBox(height: 16),
        infoCard('Account Info', [
          infoRow(Icons.verified_user, 'Status', 'Active Member'),
          infoRow(Icons.temple_hindu,  'App',    'GodsConnect'),
        ]),
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  BOOKINGS TAB
  // ════════════════════════════════════════════
  Widget _buildBookingsTab(BuildContext context) {
    if (_bookingsLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    final allDocs = [..._bookings, ..._eventRegistrations];
    if (allDocs.isEmpty) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📋', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('No bookings yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Darshan, homam, prasadam, marriage\nbookings & events will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadBookings,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]));
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadBookings,
      child: _buildBookingList(allDocs),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> docs) {
    int h = 0, d = 0, m = 0, p = 0, e = 0;
    for (final doc in docs) {
      final t = (doc['type'] ?? doc['bookingType'] ?? '') as String;
      switch (t) {
        case 'homam':    h++; break;
        case 'darshan':  d++; break;
        case 'marriage': m++; break;
        case 'prasadam': p++; break;
        case 'event':    e++; break;
      }
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _chip('Total',    '${docs.length}', Colors.blue),
        const SizedBox(width: 8), _chip('Darshan',  '$d', Colors.green),
        const SizedBox(width: 8), _chip('Homam',    '$h', Colors.deepOrange),
        const SizedBox(width: 8), _chip('Prasadam', '$p', Colors.teal),
        const SizedBox(width: 8), _chip('Marriage', '$m', Colors.purple),
        const SizedBox(width: 8), _chip('Events',   '$e', Colors.indigo),
      ])),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.only(bottom: 12, top: 4),
        child: Row(children: [
          Icon(Icons.touch_app, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('Tap any booking to view details',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
      ...docs.map((doc) => _buildBookingCard(doc)),
    ]);
  }

  Widget _chip(String label, String count, Color color) => Container(
    width: 72, padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(count, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _buildBookingCard(Map<String, dynamic> data) {
    final type   = (data['type'] ?? data['bookingType'] ?? 'booking') as String;
    final status = (data['status'] ?? 'confirmed') as String;
    final amount = data['totalAmount'] ?? data['amount'];

    final rawDate = data['date'] ?? data['weddingDate'] ?? data['createdAt'] ?? '';
    String fmtDate = '';
    if (rawDate is String && rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate).toLocal();
        fmtDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) { fmtDate = rawDate; }
    }

    String title = '', subtitle = '';
    switch (type) {
      case 'homam':
        title    = data['homamType'] ?? 'Homam Booking';
        subtitle = '🛕 ${data['templeName'] ?? ''}'
            '${(data['iyer'] ?? '').toString().isNotEmpty ? '  ·  Iyer: ${data['iyer']}' : ''}';
        break;
      case 'darshan':
        title    = data['templeName'] ?? 'Darshan Booking';
        subtitle = '👥 ${data['numberOfPersons'] ?? 1} person(s)'
            '${(data['timeSlot'] ?? '').toString().isNotEmpty ? '  ·  🕐 ${data['timeSlot']}' : ''}';
        break;
      case 'marriage':
        title    = 'Marriage Ceremony';
        subtitle = '💍 ${data['groomName'] ?? ''}  &  ${data['brideName'] ?? ''}'
            '\n🛕 ${data['templeName'] ?? ''}';
        break;
      case 'prasadam':
        title    = 'Prasadam Order';
        subtitle = '🛕 ${data['templeName'] ?? ''}';
        break;
      case 'event':
        title    = data['eventTitle'] ?? data['title'] ?? 'Event Registration';
        final evDate = _fmtRaw(data['eventDate']);
        subtitle = '🛕 ${data['templeName'] ?? ''}'
            '${evDate.isNotEmpty ? '  ·  📅 $evDate' : ''}';
        break;
      default:
        title = type.isNotEmpty
            ? '${type[0].toUpperCase()}${type.substring(1)} Booking'
            : 'Booking';
    }

    final cfg         = _typeConfig(type);
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () => _showBookingDetail(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: (cfg['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(cfg['icon'] as String,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.bold, color: statusColor)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ]),
            ]),
            if (fmtDate.isNotEmpty || amount != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(children: [
                if (fmtDate.isNotEmpty) ...[
                  const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(fmtDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const Spacer(),
                if (amount != null && amount != 0)
                  Text('₹$amount', style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, color: _primary))
                else
                  const Text('FREE', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, color: Colors.green)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  ORDERS TAB  (NEW)
  // ════════════════════════════════════════════
  Widget _buildOrdersTab(BuildContext context) {
    if (_ordersLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🛍️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('No orders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your ecommerce orders will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId  = order['_id']?.toString() ?? '';
    final status   = (order['status'] ?? 'pending') as String;
    final total    = order['totalAmount'] ?? order['total'] ?? 0;
    final items    = order['items'] as List? ?? [];
    final statusColor = _orderStatusColor(status);

    String fmtDate = '';
    final raw = order['createdAt'];
    if (raw != null) {
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        fmtDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) { fmtDate = raw.toString(); }
    }

    final canCancel = status == 'pending' || status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('🛍️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              if (fmtDate.isNotEmpty)
                Text(fmtDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(),
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ]),

          // Items list
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...items.map((item) {
              final name = item['name'] ?? item['productName'] ?? 'Item';
              final qty  = item['qty'] ?? item['quantity'] ?? 1;
              final price = item['price'] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  const Icon(Icons.circle, size: 6, color: _primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$name × $qty',
                      style: const TextStyle(fontSize: 13))),
                  Text('₹$price',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              );
            }),
          ],

          // Footer: total + cancel button
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            Text('Total: ₹$total',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, color: _primary)),
            const Spacer(),
            if (canCancel)
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cancel Order'),
                        content: const Text(
                            'Are you sure you want to cancel this order?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes, Cancel',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _cancelOrder(orderId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel Order',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Color _orderStatusColor(String s) {
    switch (s) {
      case 'confirmed':  return Colors.green;
      case 'shipped':    return Colors.blue;
      case 'delivered':  return Colors.teal;
      case 'cancelled':  return Colors.red;
      default:           return Colors.orange; // pending
    }
  }

  // ════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════
  String _fmtRaw(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return raw.toString(); }
  }

  Map<String, dynamic> _typeConfig(String type) {
    switch (type) {
      case 'homam':    return {'icon': '🔥', 'color': Colors.deepOrange};
      case 'darshan':  return {'icon': '🙏', 'color': Colors.green};
      case 'marriage': return {'icon': '💒', 'color': Colors.purple};
      case 'prasadam': return {'icon': '🍽️', 'color': Colors.teal};
      case 'event':    return {'icon': '🎉', 'color': Colors.indigo};
      default:         return {'icon': '📋', 'color': Colors.blue};
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default:          return Colors.orange;
    }
  }

  Widget _handle(bool isDark) => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(2)),
  );

  Widget _fullBtn(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ),
  );
}

// ── Helper class for detail rows ─────────────────────────────────────────────
class _DetailRow {
  final IconData icon;
  final String   label;
  final String   value;
  const _DetailRow(this.icon, this.label, this.value);
}