import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/temple.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DonationPage extends StatefulWidget {
  final User? user;
  const DonationPage({super.key, this.user});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  List<Temple> _temples        = [];
  Temple?      _selectedTemple;
  double?      _selectedAmount;
  bool         _isLoading      = false;
  bool         _loadingTemples = true;
  String?      _pendingOrderId;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  late Razorpay _razorpay;

  static const List<double> _presetAmounts = [51, 101, 251, 501, 1001, 2100];

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

  @override
  void dispose() {
    _razorpay.clear();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTemples() async {
    try {
      final rawTemples = await ApiService.getAllTemples();
      final temples = rawTemples
          .map((e) => Temple.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _temples = temples; _loadingTemples = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTemples = false);
    }
  }

  Future<void> _startPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemple == null) { _showError('Please select a temple'); return; }
    if (_selectedAmount == null || _selectedAmount! <= 0) {
      _showError('Please select or enter a donation amount');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final order = await ApiService.createRazorpayOrder(
        _selectedAmount!,
        'donation_${_selectedTemple!.id}',
        {'temple_id': _selectedTemple!.id, 'type': 'donation'},
      );
      _pendingOrderId = order['order_id'];

      _razorpay.open({
        'key':         order['razorpay_key'] ?? 'rzp_test_SK0xB85zCUyk1j',
        'amount':      order['amount'],
        'currency':    order['currency'] ?? 'INR',
        'order_id':    order['order_id'],
        'name':        'GodsConnect',
        'description': 'Donation to ${_selectedTemple!.name}',
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
      await ApiService.saveDonation({
        'temple_id':           _selectedTemple!.id.toString(),
        'temple_name':         _selectedTemple!.name,
        'amount':              _selectedAmount!,
        'donor_name':          _nameCtrl.text.trim(),
        'donor_email':         _emailCtrl.text.trim(),
        'donor_phone':         _phoneCtrl.text.trim(),
        'message':             _messageCtrl.text.trim(),
        'razorpay_payment_id': response.paymentId ?? '',
        'razorpay_order_id':   response.orderId   ?? _pendingOrderId ?? '',
        'razorpay_signature':  response.signature ?? '',
      });
    } catch (_) {}
    if (mounted) _showSuccessDialog(response.paymentId ?? 'N/A');
  }

  void _onPaymentError(PaymentFailureResponse r) {
    if (mounted) _showError('Payment failed: ${r.message}');
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('External wallet: ${r.walletName}'),
        backgroundColor: const Color(0xFFFF9933),
      ));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const SizedBox(height: 16),
          const Text('Donation Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('₹${_selectedAmount!.toStringAsFixed(0)} donated to\n${_selectedTemple!.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Payment ID: $paymentId',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _resetForm(); },
            child: const Text('Done', style: TextStyle(color: Color(0xFFFF9933))),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedTemple = null;
      _selectedAmount = null;
      _pendingOrderId = null;
    });
    _messageCtrl.clear();
    // Don't clear user details — keep them for next donation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Make a Donation'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
      ),
      body: _loadingTemples
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9933)))
          : Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(16), children: [

                // ── Temple Selection ─────────────────────────────────────
                _sectionCard(
                  title: '🛕 Select Temple',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Temple>(
                      initialValue: _selectedTemple,
                      hint: const Text('Choose a temple'),
                      isExpanded: true,   // ✅ FIX: prevents overflow
                      decoration: _inputDecoration('Temple'),
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
                      onChanged: (t) => setState(() => _selectedTemple = t),
                      validator: (v) => v == null ? 'Please select a temple' : null,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Amount Selection ─────────────────────────────────────
                _sectionCard(
                  title: '💰 Select Amount',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _presetAmounts.map((amt) {
                        final selected = _selectedAmount == amt;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAmount = amt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFF9933)
                                  : Colors.white,
                              border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFF9933)
                                      : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('₹${amt.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Or enter custom amount (₹)'),
                      onChanged: (v) {
                        final val = double.tryParse(v);
                        if (val != null) setState(() => _selectedAmount = val);
                      },
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── Donor Details ────────────────────────────────────────
                _sectionCard(
                  title: '👤 Your Details',
                  child: Column(children: [
                    // Show autofill banner if user is logged in
                    if (widget.user != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text('Auto-filled from your account',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green.shade700)),
                        ]),
                      ),
                    ],
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (v) =>
                          !v!.contains('@') ? 'Enter valid email' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _inputDecoration('Phone Number', Icons.phone),
                      validator: (v) =>
                          v!.length < 10 ? 'Enter valid phone number' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 3,
                      decoration: _inputDecoration(
                          'Message / Dedication (optional)', Icons.message),
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Total ────────────────────────────────────────────────
                if (_selectedAmount != null && _selectedAmount! > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Donation:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('₹${_selectedAmount!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9933))),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9933),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _selectedAmount != null
                                ? 'Donate ₹${_selectedAmount!.toStringAsFixed(0)} via Razorpay'
                                : 'Proceed to Pay',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  InputDecoration _inputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon, color: const Color(0xFFFF9933)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF9933), width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}