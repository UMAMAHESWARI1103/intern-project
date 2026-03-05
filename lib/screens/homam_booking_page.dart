import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/temple.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class HomamBookingPage extends StatefulWidget {
  final User? user;
  const HomamBookingPage({super.key, this.user});
  @override
  State<HomamBookingPage> createState() => _HomamBookingPageState();
}

class _HomamBookingPageState extends State<HomamBookingPage> {
  static const Color _primary = Color(0xFFFF9933);

  int _currentStep = 0;

  String _venueType = '';
  List<Temple> _temples = [];
  Temple? _selectedTemple;
  bool _loadingTemples = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController          = TextEditingController();
  final _phoneController         = TextEditingController();
  final _emailController         = TextEditingController();
  final _addressController       = TextEditingController();
  final _gotraController         = TextEditingController();
  final _nakshatraController     = TextEditingController();
  final _specialRequestController= TextEditingController();

  String   _selectedHomam = 'Ganapathi Homam';
  DateTime _selectedDate  = DateTime.now().add(const Duration(days: 3));
  String   _selectedTime  = '06:00 AM';
  bool     _isLoading     = false;

  late Razorpay _razorpay;

  final Map<String, double> _homamPrices = {
    'Ganapathi Homam':    1100,
    'Navagraha Homam':    2100,
    'Sudarshana Homam':   3100,
    'Mrityunjaya Homam':  5100,
    'Lakshmi Kubera Homam': 4100,
    'Saraswathi Homam':   2100,
    'Ayush Homam':        2500,
    'Rudra Homam':        6100,
  };

  final Map<String, String> _homamDescriptions = {
    'Ganapathi Homam':    'Removes obstacles & bestows success',
    'Navagraha Homam':    'Pacifies 9 planets, removes malefic effects',
    'Sudarshana Homam':   'Protection from enemies & evil forces',
    'Mrityunjaya Homam':  'Long life, health & victory over death',
    'Lakshmi Kubera Homam': 'Wealth, prosperity & financial growth',
    'Saraswathi Homam':   'Education, arts & knowledge',
    'Ayush Homam':        'Longevity & good health for children',
    'Rudra Homam':        'Destroys sins & grants moksha',
  };

  final List<String> _availableTimes = [
    '06:00 AM','07:00 AM','08:00 AM','09:00 AM','10:00 AM','11:00 AM',
    '04:00 PM','05:00 PM','06:00 PM',
  ];

  Map<String, dynamic>? _pendingBookingData;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _prefillUser();
  }

  void _prefillUser() {
    if (widget.user != null) {
      _nameController.text  = widget.user!.name;
      _phoneController.text = widget.user!.phone;
      _emailController.text = widget.user!.email;
    } else {
      _loadUserFromApi();
    }
  }

  Future<void> _loadUserFromApi() async {
    try {
      final profile = await ApiService.getUserProfile();
      if (!mounted || profile == null) return;
      setState(() {
        _nameController.text  = profile['name']  ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _emailController.text = profile['email'] ?? '';
      });
    } catch (_) {}
  }

  Future<void> _loadTemples() async {
    setState(() => _loadingTemples = true);
    try {
      final raw = await ApiService.getAllTemples();
      final temples = raw
          .map((e) => Temple.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _temples = temples; _loadingTemples = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTemples = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    for (final c in [
      _nameController, _phoneController, _emailController,
      _addressController, _gotraController, _nakshatraController,
      _specialRequestController,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _selectVenueType(String type) {
    setState(() { _venueType = type; });
    if (type == 'temple' && _temples.isEmpty) _loadTemples();
  }

  void _proceedToForm() {
    if (_venueType == 'temple' && _selectedTemple == null) {
      _showSnack('Please select a temple', isError: true);
      return;
    }
    setState(() => _currentStep = 1);
  }

  // ── Venue label used in booking data ────────────────────────────────────
  String get _venueLabel {
    if (_venueType == 'temple' && _selectedTemple != null) {
      return _selectedTemple!.name;
    }
    if (_venueType == 'home') {
      return _addressController.text.trim().isEmpty
          ? 'At Home'
          : _addressController.text.trim();
    }
    return '';
  }

  // ── Temple name (required field in backend schema) ───────────────────────
  String get _templeName {
    if (_venueType == 'temple' && _selectedTemple != null) {
      return _selectedTemple!.name;
    }
    return 'Home - ${_nameController.text.trim()}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _initiatePayment() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}';

    // ✅ FIXED: Field names match HomamBooking schema in backend
    _pendingBookingData = {
      // Required by backend schema
      'userName':    _nameController.text.trim(),
      'userEmail':   _emailController.text.trim(),
      'userPhone':   _phoneController.text.trim(),
      'templeName':  _templeName,          // ✅ REQUIRED field in schema
      'templeId':    _venueType == 'temple' ? (_selectedTemple?.id ?? '') : '',
      'homamType':   _selectedHomam,       // ✅ REQUIRED field in schema
      'date':        dateStr,              // ✅ REQUIRED field in schema
      'timeSlot':    _selectedTime,        // ✅ matches schema field 'timeSlot'
      'iyer':        'To be assigned',
      'specialNote': _specialRequestController.text.trim(),

      // Extra info
      'venueType':   _venueType,
      'address':     _venueType == 'home' ? _addressController.text.trim() : '',
      'gotra':       _gotraController.text.trim(),
      'nakshatra':   _nakshatraController.text.trim(),
      'totalAmount': _homamPrices[_selectedHomam],
      'status':      'confirmed',
      'bookingType': 'homam',
      'paymentStatus': 'pending',
    };

    try {
      _razorpay.open({
        'key':    'rzp_test_SK0xB85zCUyk1j',
        'amount': (_homamPrices[_selectedHomam]! * 100).toInt(),
        'name':   'GodsConnect – Homam Booking',
        'description': '$_selectedHomam on $dateStr at $_selectedTime',
        'prefill': {
          'name':    _nameController.text.trim(),
          'contact': _phoneController.text.trim(),
          'email':   _emailController.text.trim(),
        },
        'notes': {'homam_type': _selectedHomam, 'booking_date': dateStr},
        'theme': {'color': '#FF9933'},
        'retry': {'enabled': true, 'max_count': 1},
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to open payment. Please try again.', isError: true);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingData == null) {
      setState(() => _isLoading = false);
      return;
    }

    // ✅ Add payment info matching schema fields
    _pendingBookingData!['razorpayPaymentId'] = response.paymentId ?? '';
    _pendingBookingData!['razorpayOrderId']   = response.orderId  ?? '';
    _pendingBookingData!['paymentStatus']     = 'paid';

    String bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';
    try {
      // ✅ FIXED: Uses correct endpoint 'bookings/homam'
      final result = await ApiService.saveHomamBooking(_pendingBookingData!);
      bookingId = result['booking']?['_id'] ?? result['_id'] ?? bookingId;
      debugPrint('✅ Homam booking saved: $bookingId');
    } catch (e) {
      debugPrint('Save homam booking error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _pendingBookingData = null;
    _showSuccessDialog(response.paymentId ?? 'N/A', bookingId);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    _pendingBookingData = null;
    _showSnack(
      response.code == 2
          ? 'Payment cancelled'
          : 'Payment failed: ${response.message}',
      isError: true,
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _showSnack('Processing with ${response.walletName}...');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _primary,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 2),
    ));
  }

  void _showSuccessDialog(String paymentId, String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Homam Booked! 🙏',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoTile('Homam', _selectedHomam),
            _infoTile('Temple / Venue', _templeName),
            _infoTile('Date',
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            _infoTile('Time', _selectedTime),
            _infoTile('Amount',
                '₹${_homamPrices[_selectedHomam]!.toStringAsFixed(0)}'),
            const Divider(height: 20),
            _infoTile('Payment ID',
                paymentId.length > 20
                    ? '${paymentId.substring(0, 20)}...'
                    : paymentId),
            const SizedBox(height: 8),
            const Text(
              'Our priest will contact you 24 hrs before the homam. 🙏',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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

  Widget _infoTile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Homam Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 0),
              )
            : null,
      ),
      body: _currentStep == 0 ? _buildVenueStep() : _buildFormStep(),
    );
  }

  Widget _buildVenueStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildStepIndicator(),
        const SizedBox(height: 28),
        const Text('Where should we perform the Homam?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Choose the venue for your homam ceremony',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 28),
        _venueCard(
          type: 'home',
          emoji: '🏠',
          title: 'At My Home',
          subtitle: 'Priest visits your home & performs homam',
          details: ['Comfortable & private', 'Priest brings samagri', 'You provide basic setup'],
        ),
        const SizedBox(height: 14),
        _venueCard(
          type: 'temple',
          emoji: '🛕',
          title: 'At Temple',
          subtitle: 'Homam performed at a temple by temple priests',
          details: ['Sacred atmosphere', 'All samagri provided', 'Can attend in person'],
        ),
        if (_venueType == 'temple') ...[
          const SizedBox(height: 20),
          _sectionCard(
            title: '🛕 Select Temple',
            child: _loadingTemples
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: _primary),
                    ))
                : Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _primary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Temple>(
                          value: _selectedTemple,
                          hint: const Text('Choose a temple'),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.location_on, color: _primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(_selectedTemple!.location,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.deepOrange))),
                        ]),
                      ),
                    ],
                  ]),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _venueType.isEmpty ? null : _proceedToForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _venueType.isEmpty ? Colors.grey.shade300 : _primary,
              foregroundColor: _venueType.isEmpty ? Colors.grey : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _venueType.isEmpty ? 'Select a venue to continue' : 'Continue →',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _venueCard({
    required String type,
    required String emoji,
    required String title,
    required String subtitle,
    required List<String> details,
  }) {
    final selected = _venueType == type;
    return GestureDetector(
      onTap: () => _selectVenueType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? _primary : Colors.grey.shade300,
              width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.orange.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? _primary : Colors.grey, width: 2),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _primary),
                    ))
                : null,
          ),
          const SizedBox(width: 14),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? _primary.withOpacity(0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected ? _primary : Colors.black87)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              ...details.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      Icon(Icons.check_circle,
                          size: 13,
                          color: selected ? _primary : Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: selected ? Colors.black87 : Colors.grey))),
                    ]),
                  )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildFormStep() {
    final price = _homamPrices[_selectedHomam]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildStepIndicator(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_venueType == 'home' ? '🏠' : '🛕',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                _venueType == 'home'
                    ? 'Venue: At My Home'
                    : 'Venue: ${_selectedTemple!.name}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _currentStep = 0),
                child: const Icon(Icons.edit, size: 14, color: Colors.deepOrange),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: '🔥 Select Homam',
            child: Column(
                children: _homamPrices.keys.map((homam) {
              final selected = _selectedHomam == homam;
              return GestureDetector(
                onTap: () => setState(() => _selectedHomam = homam),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? _primary : Colors.grey.shade300,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? _primary : Colors.grey,
                        size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(homam,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: selected ? _primary : Colors.black87)),
                      Text(_homamDescriptions[homam] ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600)),
                    ])),
                    Text('₹${_homamPrices[homam]!.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: selected ? _primary : Colors.black87)),
                  ]),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: '📅 Date & Time',
            child: Column(children: [
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
                initialValue: _selectedTime,
                decoration: InputDecoration(
                  labelText: 'Select Time',
                  prefixIcon:
                      const Icon(Icons.access_time, color: _primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _primary, width: 1.5)),
                ),
                items: _availableTimes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTime = v!),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: '👤 Personal Details',
            child: Column(children: [
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
              _field('Full Name *', _nameController, Icons.person_outline,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your name' : null),
              const SizedBox(height: 12),
              _field('Mobile Number *', _phoneController,
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.trim().length < 10 ? 'Enter valid number' : null),
              const SizedBox(height: 12),
              _field('Email *', _emailController, Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      !v!.contains('@') ? 'Enter valid email' : null),
              if (_venueType == 'home') ...[
                const SizedBox(height: 12),
                _field('Home Address *', _addressController,
                    Icons.location_on_outlined,
                    maxLines: 3,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Enter address' : null),
              ],
              const SizedBox(height: 12),
              _field('Gotra (Optional)', _gotraController,
                  Icons.family_restroom),
              const SizedBox(height: 12),
              _field('Nakshatra (Optional)', _nakshatraController,
                  Icons.star_outline),
              const SizedBox(height: 12),
              _field('Special Request', _specialRequestController,
                  Icons.note_outlined,
                  maxLines: 3),
            ]),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: '💰 Price Summary',
            child: Column(children: [
              _summaryRow('Homam Type', _selectedHomam),
              const SizedBox(height: 6),
              _summaryRow('Venue', _templeName),
              const SizedBox(height: 6),
              _summaryRow('Date & Time',
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} • $_selectedTime'),
              const Divider(height: 20),
              _summaryRow('Total Amount', '₹${price.toStringAsFixed(0)}',
                  isBold: true, valueColor: _primary),
              const SizedBox(height: 4),
              const Text('* Includes priest dakshina, samagri & prasadam',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
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
                  : Text(
                      'Book & Pay ₹${price.toStringAsFixed(0)} 🙏',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
              child: Text(
                  'Secure payment via Razorpay • UPI • Cards • Net Banking',
                  style: TextStyle(fontSize: 11, color: Colors.grey))),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(children: [
      _stepDot(1, _currentStep >= 0, 'Venue'),
      Expanded(
          child: Container(
              height: 2,
              color: _currentStep >= 1 ? _primary : Colors.grey.shade300)),
      _stepDot(2, _currentStep >= 1, 'Booking'),
    ]);
  }

  Widget _stepDot(int step, bool active, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _primary : Colors.grey.shade300,
        ),
        child: Center(
          child: Text('$step',
              style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: active ? _primary : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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

  Widget _field(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator}) =>
      TextFormField(
        controller: controller,
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

  Widget _summaryRow(String label, String value,
          {bool isBold = false, Color? valueColor}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87)),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: valueColor ?? Colors.black87))),
      ]);
}