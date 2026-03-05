import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventsPage extends StatefulWidget {
  final String? loggedInName;
  final String? loggedInEmail;
  final String? loggedInPhone;

  const EventsPage({
    super.key,
    this.loggedInName,
    this.loggedInEmail,
    this.loggedInPhone,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // ✅ Events are always shown — DB events + seed events merged from backend
  List<Event> _events           = [];
  bool        _isLoading        = true;
  String      _selectedCategory = 'All';

  static const List<String> _categories = [
    'All', 'Festival', 'Pooja', 'Special', 'Cultural', 'Other'
  ];

  // ✅ A seed event has id starting with 'seed_'
  bool _isSeed(Event e) => e.id.startsWith('seed_');

  List<Event> get _filtered {
    if (_selectedCategory == 'All') return _events;
    return _events.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final rawEvents = await ApiService.getAllEvents();
      final events = rawEvents
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _events = events; _isLoading = false; });
    } catch (_) {
      // Even on error, backend returns seed events — but handle complete failure
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRegister(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RegisterSheet(
        event:        event,
        isSeed:       _isSeed(event),
        prefillName:  widget.loggedInName,
        prefillEmail: widget.loggedInEmail,
        prefillPhone: widget.loggedInPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: const Color(0xFFFF9933),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9933)));
    }
    final events = _filtered;
    if (events.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No events in this category',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _selectedCategory = 'All'),
            child: const Text('Show all events',
                style: TextStyle(color: Color(0xFFFF9933))),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF9933),
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (_, i) => _buildEventCard(events[i]),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final isSeed = _isSeed(event);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.orange.withValues(alpha: 0.08),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFF9933),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15),
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Text(event.title,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 8),
            // ✅ "Sample" badge for seed events, "Admin" badge for DB events
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(isSeed ? 'Sample' : 'Live',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(event.category,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🛕', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(child: Text(event.templeName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 15, color: Color(0xFFFF9933)),
              const SizedBox(width: 6),
              Text(_formatDate(event.date), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 15, color: Color(0xFFFF9933)),
              const SizedBox(width: 4),
              Expanded(child: Text(event.time,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on, size: 15, color: Color(0xFFFF9933)),
                const SizedBox(width: 6),
                Expanded(child: Text(event.location,
                    style: const TextStyle(fontSize: 13, color: Colors.grey))),
              ]),
            ],
            const SizedBox(height: 10),
            Text(event.description,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Entry Fee', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  event.isFree ? 'FREE' : '₹${event.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: event.isFree ? Colors.green : const Color(0xFFFF9933),
                  ),
                ),
              ]),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _onRegister(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9933),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Register',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmation Page
// ─────────────────────────────────────────────────────────────────────────────
class EventConfirmationPage extends StatelessWidget {
  final Event   event;
  final String  userName;
  final String  userEmail;
  final String? paymentId;
  final bool    isPaid;
  final bool    isSeed;

  const EventConfirmationPage({
    super.key,
    required this.event,
    required this.userName,
    required this.userEmail,
    this.paymentId,
    this.isPaid  = false,
    this.isSeed  = false,
  });

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dateStr = '${days[event.date.weekday - 1]}, ${event.date.day} '
        '${months[event.date.month - 1]} ${event.date.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        title: const Text('Registration Confirmed'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              color: Colors.green.shade50, shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade300, width: 3),
            ),
            child: const Center(child: Text('✅', style: TextStyle(fontSize: 52))),
          ),
          const SizedBox(height: 20),
          Text(
            isPaid ? 'Payment & Registration\nSuccessful!' : 'Registration Successful!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          if (isSeed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text('📋 Sample event — your registration has been saved!',
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                  textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 8),
          Text('Please keep this confirmation safe.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          // Booking card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF9933), width: 1.5),
            ),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9933),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15), topRight: Radius.circular(15),
                  ),
                ),
                child: const Row(children: [
                  Text('🎫', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text('Booking Details', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _detailRow('Event',    event.title),
                  _divider(),
                  _detailRow('Temple',   event.templeName),
                  _divider(),
                  _detailRow('Date',     dateStr),
                  _divider(),
                  _detailRow('Time',     event.time),
                  if (event.location.isNotEmpty) ...[
                    _divider(), _detailRow('Location', event.location),
                  ],
                  _divider(),
                  _detailRow('Name',  userName),
                  _divider(),
                  _detailRow('Email', userEmail),
                  if (isPaid && paymentId != null) ...[
                    _divider(),
                    _detailRow('Payment ID', paymentId!, highlight: true),
                    _divider(),
                    _detailRow('Amount Paid', '₹${event.price.toStringAsFixed(0)}', highlight: true),
                  ],
                  if (event.isFree) ...[
                    _divider(), _detailRow('Entry Fee', 'FREE', highlight: true),
                  ],
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                isSeed
                    ? 'Sample event registration saved. When the admin adds real events, you can register for those too!'
                    : 'A confirmation has been sent to $userEmail. Please carry a valid ID on the day of the event.',
                style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
              )),
            ]),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
          color: highlight ? const Color(0xFFFF9933) : Colors.black87))),
    ]),
  );

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}

// ─────────────────────────────────────────────────────────────────────────────
// Register Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterSheet extends StatefulWidget {
  final Event   event;
  final bool    isSeed;
  final String? prefillName;
  final String? prefillEmail;
  final String? prefillPhone;

  const _RegisterSheet({
    required this.event,
    required this.isSeed,
    this.prefillName,
    this.prefillEmail,
    this.prefillPhone,
  });

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey   = GlobalKey<FormState>();
  bool  _isLoading = false;
  String? _pendingOrderId;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.prefillName  ?? '');
    _emailCtrl = TextEditingController(text: widget.prefillEmail ?? '');
    _phoneCtrl = TextEditingController(text: widget.prefillPhone ?? '');
    _razorpay  = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userData = {
      'user_name':  _nameCtrl.text.trim(),
      'user_email': _emailCtrl.text.trim(),
      'user_phone': _phoneCtrl.text.trim(),
    };

    try {
      if (widget.isSeed) {
        // ✅ Seed event — always free, use sample-register or /:id/register
        await ApiService.registerForEvent(widget.event.id, userData);
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => EventConfirmationPage(
              event: widget.event, userName: _nameCtrl.text.trim(),
              userEmail: _emailCtrl.text.trim(), isSeed: true,
            ),
          ));
        }
      } else if (widget.event.isFree) {
        // ✅ Real free DB event
        await ApiService.registerForEvent(widget.event.id, userData);
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => EventConfirmationPage(
              event: widget.event, userName: _nameCtrl.text.trim(),
              userEmail: _emailCtrl.text.trim(),
            ),
          ));
        }
      } else {
        // ✅ Real paid DB event — Razorpay
        final order = await ApiService.createRazorpayOrder(
          widget.event.price, 'event_${widget.event.id}',
          {'event_id': widget.event.id, 'type': 'event_registration'},
        );
        if (order['order_id'] == null) {
          throw Exception('Payment server unavailable. Please try again.');
        }
        _pendingOrderId = order['order_id'] as String;
        _razorpay.open({
          'key':         order['razorpay_key'] ?? 'rzp_test_SJdyZblt9njE1Z',
          'amount':      order['amount'],
          'currency':    order['currency'] ?? 'INR',
          'order_id':    order['order_id'],
          'name':        'GodsConnect Events',
          'description': widget.event.title,
          'prefill': {
            'name':    _nameCtrl.text.trim(),
            'email':   _emailCtrl.text.trim(),
            'contact': _phoneCtrl.text.trim(),
          },
          'theme': {'color': '#FF9933'},
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService.registerForEvent(widget.event.id, {
        'user_name':           _nameCtrl.text.trim(),
        'user_email':          _emailCtrl.text.trim(),
        'user_phone':          _phoneCtrl.text.trim(),
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id':   response.orderId ?? _pendingOrderId,
        'razorpay_signature':  response.signature,
      });
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => EventConfirmationPage(
          event: widget.event, userName: _nameCtrl.text.trim(),
          userEmail: _emailCtrl.text.trim(),
          paymentId: response.paymentId, isPaid: true,
        ),
      ));
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed: ${r.message ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ));
      setState(() => _isLoading = false);
    }
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wallet selected: ${r.walletName}'),
        backgroundColor: const Color(0xFFFF9933),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAutoFilled =
        (widget.prefillName?.isNotEmpty == true) ||
        (widget.prefillEmail?.isNotEmpty == true) ||
        (widget.prefillPhone?.isNotEmpty == true);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Register: ${widget.event.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          if (widget.isSeed)
            _infoBanner(color: Colors.orange, icon: Icons.info_outline,
                text: 'Sample event — Registration is FREE')
          else
            Text(
              widget.event.isFree
                  ? 'Free Entry — No payment required'
                  : 'Entry Fee: ₹${widget.event.price.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: widget.event.isFree ? Colors.green : const Color(0xFFFF9933)),
            ),
          if (isAutoFilled) ...[
            const SizedBox(height: 8),
            _infoBanner(color: Colors.green, icon: Icons.check_circle,
                text: 'Details auto-filled from your account ✓'),
          ],
          const SizedBox(height: 16),
          _field(_nameCtrl, 'Full Name', Icons.person,
              validator: (v) => v!.trim().isEmpty ? 'Enter name' : null),
          const SizedBox(height: 10),
          _field(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress,
              validator: (v) => !v!.contains('@') ? 'Enter valid email' : null),
          const SizedBox(height: 10),
          _field(_phoneCtrl, 'Phone', Icons.phone, type: TextInputType.phone,
              validator: (v) => v!.length < 10 ? 'Enter valid phone' : null),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      widget.isSeed ? '🎉 Register (Free)'
                          : widget.event.isFree ? '🎉 Register for Free'
                          : 'Pay ₹${widget.event.price.toStringAsFixed(0)} & Register',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _infoBanner({required Color color, required IconData icon, required String text}) =>
    Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
      ]),
    );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl, keyboardType: type, validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFF9933)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF9933), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
}