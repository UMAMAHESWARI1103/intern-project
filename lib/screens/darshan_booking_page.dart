import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/temple.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DarshanBookingPage extends StatefulWidget {
  final User? user;
  const DarshanBookingPage({super.key, this.user});

  @override
  State<DarshanBookingPage> createState() => _DarshanBookingPageState();
}

class _DarshanBookingPageState extends State<DarshanBookingPage> {
  // Temple data from API
  List<Temple> _temples       = [];
  Temple?      _selectedTemple;
  bool         _loadingTemples = true;

  DateTime? _selectedDate;
  String?   _selectedTimeSlot;
  int       _numberOfPeople = 1;
  bool      _isLoading      = false;
  String?   _pendingOrderId;

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  late Razorpay _razorpay;

  String _darshanType = 'Normal';

  static const Map<String, double> _darshanFees = {
    'Normal':  50.0,
    'Special': 100.0,
  };

  double get _feePerPerson => _darshanFees[_darshanType]!;
  double get _totalAmount  => _feePerPerson * _numberOfPeople;

  final List<String> _timeSlots = [
    '6:00 AM - 8:00 AM',
    '8:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _prefillUser();
    _loadTemples();
  }

  // ── Auto-fill from logged-in user ────────────────────────────────────────
  void _prefillUser() {
    if (widget.user != null) {
      _nameCtrl.text  = widget.user!.name;
      _emailCtrl.text = widget.user!.email;
      _phoneCtrl.text = widget.user!.phone;
    }
  }

  // ── Load temples from API ────────────────────────────────────────────────
  Future<void> _loadTemples() async {
    try {
      final raw = await ApiService.getAllTemples();
      final temples = raw
          .map((e) => Temple.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() { _temples = temples; _loadingTemples = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTemples = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(primary: Color(0xFFFF9933))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _startBooking() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemple == null)   { _showError('Please select a temple'); return; }
    if (_selectedDate == null)     { _showError('Please select a date'); return; }
    if (_selectedTimeSlot == null) { _showError('Please select a time slot'); return; }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Booking'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          _confirmRow('Temple',       _selectedTemple!.name),
          _confirmRow('Darshan Type', '$_darshanType Darshan'),
          _confirmRow('Date',
              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
          _confirmRow('Time Slot',    _selectedTimeSlot!),
          _confirmRow('People',       '$_numberOfPeople'),
          _confirmRow('Fee/person',
              '₹${_feePerPerson.toStringAsFixed(0)}'),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('₹${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFFFF9933))),
          ]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _processPayment(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933),
                foregroundColor: Colors.white),
            child: const Text('Pay & Book'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    try {
      final order = await ApiService.createRazorpayOrder(
        _totalAmount,
        'darshan_${DateTime.now().millisecondsSinceEpoch}',
        {
          'temple':         _selectedTemple!.name,
          'darshanType':    _darshanType,
          'numberOfPeople': _numberOfPeople,
        },
      );
      _pendingOrderId = order['order_id'];

      _razorpay.open({
        'key':         order['razorpay_key'] ?? 'rzp_test_SK0xB85zCUyk1j',
        'amount':      order['amount'],
        'currency':    order['currency'] ?? 'INR',
        'order_id':    order['order_id'],
        'name':        'GodsConnect',
        'description': '$_darshanType Darshan - ${_selectedTemple!.name}',
        'prefill': {
          'name':    _nameCtrl.text.trim(),
          'email':   _emailCtrl.text.trim(),
          'contact': _phoneCtrl.text.trim(),
        },
        'theme': {'color': '#FF9933'},
      });
    } catch (e) {
      if (mounted) _showError('Failed to initiate payment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService.saveDarshanBooking({
        'templeName':        _selectedTemple!.name,
        'darshanType':       _darshanType,
        'date':
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        'timeSlot':          _selectedTimeSlot,
        'numberOfPeople':    _numberOfPeople,
        'userName':          _nameCtrl.text.trim(),
        'userEmail':         _emailCtrl.text.trim(),
        'userPhone':         _phoneCtrl.text.trim(),
        'amount':            _totalAmount,
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpayOrderId':   response.orderId   ?? _pendingOrderId ?? '',
        'razorpaySignature': response.signature  ?? '',
      });
    } catch (e) {
      debugPrint('Save booking error: $e');
    }
    if (mounted) _showSuccessDialog(response.paymentId ?? 'N/A');
  }

  void _onPaymentError(PaymentFailureResponse r) {
    if (mounted) _showError('Payment failed: ${r.message}');
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wallet: ${r.walletName}'),
        backgroundColor: const Color(0xFFFF9933),
      ));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccessDialog(String paymentId) {
    final bookingId =
        'DB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const SizedBox(height: 16),
          const Text('Booking Confirmed! 🙏',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _confirmRow('Temple',       _selectedTemple!.name),
          _confirmRow('Darshan Type', '$_darshanType Darshan'),
          _confirmRow('Date',
              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
          _confirmRow('Time Slot',    _selectedTimeSlot!),
          _confirmRow('People',       '$_numberOfPeople'),
          _confirmRow('Paid',         '₹${_totalAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Text('Booking ID: $bookingId',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('Payment ID: $paymentId',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933),
                foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.end)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Darshan'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
      ),
      body: _loadingTemples
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9933)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                  // ── Visitor Details ──────────────────────────────────
                  _sectionTitle('👤 Visitor Details'),
                  const SizedBox(height: 10),

                  // Auto-fill banner
                  if (widget.user != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text('Auto-filled from your account',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700)),
                      ]),
                    ),
                  ],

                  _inputField(_nameCtrl, 'Full Name', Icons.person,
                      TextInputType.name,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Enter your name' : null),
                  const SizedBox(height: 10),
                  _inputField(_emailCtrl, 'Email Address', Icons.email,
                      TextInputType.emailAddress,
                      validator: (v) =>
                          !v!.contains('@') ? 'Enter valid email' : null),
                  const SizedBox(height: 10),
                  _inputField(_phoneCtrl, 'Phone Number', Icons.phone,
                      TextInputType.phone,
                      validator: (v) =>
                          v!.length < 10 ? 'Enter valid phone' : null),

                  const SizedBox(height: 24),

                  // ── Temple Selection (from API) ───────────────────────
                  _sectionTitle('🛕 Select Temple'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF9933)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Temple>(
                        value: _selectedTemple,
                        hint: const Text('Choose a temple'),
                        isExpanded: true,
                        selectedItemBuilder: (context) => _temples
                            .map((t) => Text(
                                  t.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ))
                            .toList(),
                        items: _temples
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTemple = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Darshan Type ─────────────────────────────────────
                  _sectionTitle('🎟️ Darshan Type'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _darshanTypeCard('Normal',  '🙏', '₹50 / person',  'General queue')),
                    const SizedBox(width: 12),
                    Expanded(child: _darshanTypeCard('Special', '⭐', '₹100 / person', 'Priority entry')),
                  ]),

                  const SizedBox(height: 24),

                  // ── Date Selection ───────────────────────────────────
                  _sectionTitle('📅 Select Date'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: const Color(0xFFFF9933)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFFFF9933)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Pick a date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                              fontSize: 16,
                              color: _selectedDate == null
                                  ? Colors.grey
                                  : Colors.black),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Time Slot ────────────────────────────────────────
                  _sectionTitle('⏰ Select Time Slot'),
                  const SizedBox(height: 8),
                  ..._timeSlots.map((slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTimeSlot = slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedTimeSlot == slot
                                  ? const Color(0xFFFF9933)
                                      .withValues(alpha:0.08)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedTimeSlot == slot
                                    ? const Color(0xFFFF9933)
                                    : Colors.grey.shade300,
                                width:
                                    _selectedTimeSlot == slot ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedTimeSlot == slot
                                        ? const Color(0xFFFF9933)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: _selectedTimeSlot == slot
                                    ? Center(
                                        child: Container(
                                          width: 10, height: 10,
                                          decoration:
                                              const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFFF9933),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(slot,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        _selectedTimeSlot == slot
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color: _selectedTimeSlot == slot
                                        ? const Color(0xFFFF9933)
                                        : Colors.black87,
                                  )),
                            ]),
                          ),
                        ),
                      )),

                  const SizedBox(height: 24),

                  // ── Number of People ─────────────────────────────────
                  _sectionTitle('👨‍👩‍👧‍👦 Number of People'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF9933)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      IconButton(
                        onPressed: _numberOfPeople > 1
                            ? () =>
                                setState(() => _numberOfPeople--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFFFF9933), iconSize: 32,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFFF9933)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$_numberOfPeople',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _numberOfPeople < 10
                            ? () =>
                                setState(() => _numberOfPeople++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFFFF9933), iconSize: 32,
                      ),
                      const Spacer(),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        const Text('Total Fee',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        Text('₹${_totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9933))),
                        Text(
                            '₹${_feePerPerson.toStringAsFixed(0)} × $_numberOfPeople',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 32),

                  // ── Book Button ──────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9933),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Pay ₹${_totalAmount.toStringAsFixed(0)} & Book Darshan',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }

  Widget _darshanTypeCard(
      String type, String emoji, String price, String subtitle) {
    final sel = _darshanType == type;
    return GestureDetector(
      onTap: () => setState(() => _darshanType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF9933) : Colors.white,
          border: Border.all(color: const Color(0xFFFF9933), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(type,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: sel ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(
                  fontSize: 13,
                  color: sel ? Colors.white70 : Colors.grey)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: sel ? Colors.white60 : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _inputField(TextEditingController ctrl, String label,
      IconData icon, TextInputType type,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF9933)),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFF9933), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}