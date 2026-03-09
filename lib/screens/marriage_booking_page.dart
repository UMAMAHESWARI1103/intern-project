import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/temple.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class MarriageBookingPage extends StatefulWidget {
  final User? user;
  const MarriageBookingPage({super.key, this.user});

  @override
  State<MarriageBookingPage> createState() => _MarriageBookingPageState();
}

class _MarriageBookingPageState extends State<MarriageBookingPage> {
  static const Color _primary = Color(0xFFFF9933);
  final _formKey = GlobalKey<FormState>();

  final _groomNameController      = TextEditingController();
  final _groomDobController       = TextEditingController();
  final _groomGotraController     = TextEditingController();
  final _groomNakshatraController = TextEditingController();
  final _brideNameController      = TextEditingController();
  final _brideDobController       = TextEditingController();
  final _brideGotraController     = TextEditingController();
  final _brideNakshatraController = TextEditingController();
  final _contactNameController    = TextEditingController();
  final _contactPhoneController   = TextEditingController();
  final _contactEmailController   = TextEditingController();
  final _venueController          = TextEditingController();
  final _specialRequestController = TextEditingController();

  final Map<String, double> _ceremonyPrices = {
    'Full Wedding Ceremony':      25000,
    'Engagement Ceremony':        8000,
    'Nichayathartham':            5000,
    'Nichayathartham + Wedding':  30000,
  };

  final Map<String, String> _ceremonyDesc = {
    'Full Wedding Ceremony':      'Complete Vedic wedding with all rituals',
    'Engagement Ceremony':        'Traditional ring ceremony with pooja',
    'Nichayathartham':            'Auspicious fixing of marriage date',
    'Nichayathartham + Wedding':  'Combined engagement & wedding package',
  };

  String _venueType = 'temple';

  List<Temple> _temples        = [];
  Temple?      _selectedTemple;
  bool         _loadingTemples = true;

  String _selectedCeremony  = 'Full Wedding Ceremony';
  DateTime _selectedDate     = DateTime.now().add(const Duration(days: 30));
  String _selectedMuhurtham  = '07:00 AM - 09:00 AM';
  bool _isLoading            = false;
  late Razorpay _razorpay;

  final List<String> _muhurthamSlots = [
    '05:30 AM - 07:30 AM', '07:00 AM - 09:00 AM', '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM', '11:00 AM - 01:00 PM',
    '04:00 PM - 06:00 PM', '06:00 PM - 08:00 PM',
  ];

  Map<String, dynamic>? _pendingData;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
    _prefillUser();
    _loadTemples();
  }

  void _prefillUser() {
    if (widget.user != null) {
      _contactNameController.text  = widget.user!.name;
      _contactPhoneController.text = widget.user!.phone;
      _contactEmailController.text = widget.user!.email;
    } else {
      _loadUserFromApi();
    }
  }

  Future<void> _loadUserFromApi() async {
    try {
      final data = await ApiService.getUserProfile();
      if (!mounted) return;
      setState(() {
        _contactNameController.text  = data?['name']  ?? '';
        _contactPhoneController.text = data?['phone'] ?? '';
        _contactEmailController.text = data?['email'] ?? '';
      });
    } catch (_) {}
  }

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
    for (final c in [
      _groomNameController, _groomDobController, _groomGotraController,
      _groomNakshatraController, _brideNameController, _brideDobController,
      _brideGotraController, _brideNakshatraController,
      _contactNameController, _contactPhoneController,
      _contactEmailController, _venueController, _specialRequestController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: _primary)),
          child: child!),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  // ── templeName = required field in backend schema ────────────────────────
  String get _templeName {
    if (_venueType == 'temple' && _selectedTemple != null) {
      return _selectedTemple!.name;
    }
    return _venueController.text.trim().isEmpty
        ? 'Custom Venue'
        : _venueController.text.trim();
  }

  String get _venueString {
    if (_venueType == 'temple' && _selectedTemple != null) {
      return '${_selectedTemple!.name}, ${_selectedTemple!.location}';
    }
    return _venueController.text.trim();
  }

  // ── Date formatted for backend ───────────────────────────────────────────
  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  void _pay() {
    if (!_formKey.currentState!.validate()) return;

    if (_venueType == 'temple' && _selectedTemple == null) {
      _snack('Please select a temple for the ceremony', isError: true);
      return;
    }
    if (_venueType == 'other' && _venueController.text.trim().isEmpty) {
      _snack('Please enter the venue address', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final amount = _ceremonyPrices[_selectedCeremony]!;

    // ✅ FIXED: Field names match MarriageBooking schema in backend
    _pendingData = {
      // Required by backend schema
      'userName':    _contactNameController.text.trim(),
      'userEmail':   _contactEmailController.text.trim(),
      'userPhone':   _contactPhoneController.text.trim(),
      'templeName':  _templeName,                       // ✅ REQUIRED
      'templeId':    _venueType == 'temple' ? (_selectedTemple?.id ?? '') : '',
      'groomName':   _groomNameController.text.trim(),  // ✅ REQUIRED
      'brideName':   _brideNameController.text.trim(),  // ✅ REQUIRED
      'weddingDate': _dateStr,                          // ✅ REQUIRED (schema: weddingDate)
      'timeSlot':    _selectedMuhurtham,                // ✅ matches schema field
      'guestCount':  0,
      'specialNote': _specialRequestController.text.trim(),

      // Extra info stored as well
      'contactName':    _contactNameController.text.trim(),
      'groomDob':       _groomDobController.text.trim(),
      'groomGotra':     _groomGotraController.text.trim(),
      'groomNakshatra': _groomNakshatraController.text.trim(),
      'brideDob':       _brideDobController.text.trim(),
      'brideGotra':     _brideGotraController.text.trim(),
      'brideNakshatra': _brideNakshatraController.text.trim(),
      'ceremonyType':   _selectedCeremony,
      'muhurtham':      _selectedMuhurtham,
      'venueType':      _venueType,
      'venue':          _venueString,
      'totalAmount':    amount,
      'status':         'confirmed',
      'bookingType':    'marriage',
      'paymentStatus':  'pending',
    };

    try {
      _razorpay.open({
        'key':     'rzp_test_SK0xB85zCUyk1j',
        'amount':  (amount * 100).toInt(),
        'name':    'GodsConnect Marriage Booking',
        'description': '$_selectedCeremony on $_dateStr',
        'prefill': {
          'name':    _contactNameController.text.trim(),
          'contact': _contactPhoneController.text.trim(),
          'email':   _contactEmailController.text.trim(),
        },
        'theme': {'color': '#FF9933'},
        'retry': {'enabled': true, 'max_count': 1},
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to open payment. Try again.', isError: true);
    }
  }

  void _onSuccess(PaymentSuccessResponse r) async {
    if (_pendingData == null) {
      setState(() => _isLoading = false);
      return;
    }

    // ✅ Add payment info matching schema fields
    _pendingData!['razorpayPaymentId'] = r.paymentId ?? '';
    _pendingData!['razorpayOrderId']   = r.orderId   ?? '';
    _pendingData!['paymentStatus']     = 'paid';

    String bookingId = 'MBK${DateTime.now().millisecondsSinceEpoch}';

    try {
      // ✅ FIXED: Uses ApiService.saveMarriageBooking → correct URL /api/bookings/marriage
      final result = await ApiService.saveMarriageBooking(_pendingData!);
      bookingId = result['booking']?['_id'] ?? result['_id']?.toString() ?? bookingId;
      debugPrint('✅ Marriage booking saved: $bookingId');
    } catch (e) {
      debugPrint('MongoDB save error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _pendingData = null;
    _successDialog(r.paymentId ?? 'N/A', bookingId);
  }

  void _onError(PaymentFailureResponse r) {
    setState(() => _isLoading = false);
    _pendingData = null;
    _snack(r.code == 2
        ? 'Payment cancelled'
        : 'Payment failed: ${r.message}',
        isError: true);
  }

  void _onWallet(ExternalWalletResponse r) =>
      _snack('Processing with ${r.walletName}...');

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _primary,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 2),
    ));
  }

  void _successDialog(String paymentId, String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.favorite_rounded, size: 72, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Marriage Booked! 🙏',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _tile('Ceremony', _selectedCeremony),
            _tile('Groom', _groomNameController.text.trim()),
            _tile('Bride', _brideNameController.text.trim()),
            _tile('Date', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            _tile('Venue', _venueString),
            _tile('Amount', '₹${_ceremonyPrices[_selectedCeremony]!.toStringAsFixed(0)}'),
            const Divider(height: 20),
            _tile('Payment ID',
                paymentId.length > 20
                    ? '${paymentId.substring(0, 20)}...'
                    : paymentId),
            const SizedBox(height: 8),
            const Text(
                'Our priest team will contact you 48 hrs before the ceremony. 🙏',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tile(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final price = _ceremonyPrices[_selectedCeremony]!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Marriage Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Select Ceremony ──────────────────────────────────────
            _card('💍 Select Ceremony',
                Column(children: _ceremonyPrices.keys.map((c) {
              final sel = _selectedCeremony == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedCeremony = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? _primary : Colors.grey.shade300,
                        width: sel ? 2 : 1),
                  ),
                  child: Row(children: [
                    Icon(
                        sel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: sel ? _primary : Colors.grey,
                        size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(c,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: sel ? _primary : Colors.black87)),
                      Text(_ceremonyDesc[c] ?? '',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ])),
                    Text('₹${_ceremonyPrices[c]!.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: sel ? _primary : Colors.black87)),
                  ]),
                ),
              );
            }).toList())),
            const SizedBox(height: 16),

            // ── Venue Selection ──────────────────────────────────────
            _card('📍 Ceremony Venue', Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _venueType = 'temple'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _venueType == 'temple' ? _primary : Colors.white,
                        border: Border.all(color: _primary),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Column(children: [
                        Icon(Icons.account_balance,
                            color: _venueType == 'temple'
                                ? Colors.white
                                : _primary,
                            size: 22),
                        const SizedBox(height: 4),
                        Text('At Temple',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _venueType == 'temple'
                                    ? Colors.white
                                    : _primary)),
                      ]),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _venueType = 'other'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _venueType == 'other' ? _primary : Colors.white,
                        border: Border.all(color: _primary),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(children: [
                        Icon(Icons.location_on,
                            color: _venueType == 'other'
                                ? Colors.white
                                : _primary,
                            size: 22),
                        const SizedBox(height: 4),
                        Text('Other Venue',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _venueType == 'other'
                                    ? Colors.white
                                    : _primary)),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              if (_venueType == 'temple') ...[
                if (_loadingTemples)
                  const Center(
                      child: CircularProgressIndicator(color: _primary))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Temple>(
                        value: _selectedTemple,
                        hint: const Text('Select a temple'),
                        isExpanded: true,
                        selectedItemBuilder: (context) => _temples
                            .map((t) => Text(t.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1))
                            .toList(),
                        items: _temples
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(t.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                          overflow: TextOverflow.ellipsis),
                                      Text(t.location,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey),
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (t) =>
                            setState(() => _selectedTemple = t),
                      ),
                    ),
                  ),
                if (_selectedTemple != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: _primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_selectedTemple!.location,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.deepOrange))),
                    ]),
                  ),
                ],
              ],
              if (_venueType == 'other') ...[
                _f('Venue / Hall / Address *', _venueController,
                    Icons.location_on_outlined,
                    maxLines: 2,
                    validator: _venueType == 'other'
                        ? (v) => v!.trim().isEmpty ? 'Required' : null
                        : null),
              ],
            ])),
            const SizedBox(height: 16),

            // ── Date & Muhurtham ─────────────────────────────────────
            _card('📅 Date & Muhurtham', Column(children: [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: _primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedMuhurtham,
                decoration: InputDecoration(
                    labelText: 'Muhurtham Time',
                    prefixIcon:
                        const Icon(Icons.access_time, color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _primary, width: 1.5))),
                items: _muhurthamSlots
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMuhurtham = v!),
              ),
            ])),
            const SizedBox(height: 16),

            // ── Groom Details ────────────────────────────────────────
            _card('🤵 Groom Details', Column(children: [
              _f('Groom Full Name *', _groomNameController,
                  Icons.person_outline,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _f('Date of Birth', _groomDobController,
                  Icons.cake_outlined,
                  keyboardType: TextInputType.datetime),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _f('Gotra', _groomGotraController,
                        Icons.family_restroom)),
                const SizedBox(width: 12),
                Expanded(
                    child: _f('Nakshatra', _groomNakshatraController,
                        Icons.star_outline)),
              ]),
            ])),
            const SizedBox(height: 16),

            // ── Bride Details ────────────────────────────────────────
            _card('👰 Bride Details', Column(children: [
              _f('Bride Full Name *', _brideNameController,
                  Icons.person_outline,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _f('Date of Birth', _brideDobController,
                  Icons.cake_outlined,
                  keyboardType: TextInputType.datetime),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _f('Gotra', _brideGotraController,
                        Icons.family_restroom)),
                const SizedBox(width: 12),
                Expanded(
                    child: _f('Nakshatra', _brideNakshatraController,
                        Icons.star_outline)),
              ]),
            ])),
            const SizedBox(height: 16),

            // ── Contact Details ──────────────────────────────────────
            _card('📞 Contact Details', Column(children: [
              if (widget.user != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text('Auto-filled from your account',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green.shade700)),
                  ]),
                ),
              ],
              _f('Contact Person *', _contactNameController,
                  Icons.person_outline,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _f('Mobile Number *', _contactPhoneController,
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.trim().length < 10 ? 'Enter valid number' : null),
              const SizedBox(height: 12),
              _f('Email *', _contactEmailController,
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      !v!.contains('@') ? 'Enter valid email' : null),
              const SizedBox(height: 12),
              _f('Special Requirements', _specialRequestController,
                  Icons.note_outlined,
                  maxLines: 2),
            ])),
            const SizedBox(height: 16),

            // ── Price Summary ────────────────────────────────────────
            _card('💰 Price Summary', Column(children: [
              _row('Ceremony', _selectedCeremony),
              const SizedBox(height: 4),
              _row('Date',
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              _row('Muhurtham', _selectedMuhurtham),
              _row('Venue',
                  _venueType == 'temple'
                      ? (_selectedTemple?.name ?? 'Not selected')
                      : (_venueController.text.isEmpty
                          ? 'Not entered'
                          : _venueController.text.trim())),
              const Divider(height: 20),
              _row('Total Amount', '₹${price.toStringAsFixed(0)}',
                  bold: true, color: _primary),
              const SizedBox(height: 4),
              const Text(
                  '* Includes priest charges, samagri & documentation',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            const SizedBox(height: 24),

            // ── Pay Button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Book & Pay ₹${price.toStringAsFixed(0)} 🙏',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
                child: Text(
              'Secure payment via Razorpay • UPI • Cards • Net Banking',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ]),
      );

  Widget _f(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );

  Widget _row(String l, String v, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                      color: color ?? Colors.black87))),
        ]),
      );
}