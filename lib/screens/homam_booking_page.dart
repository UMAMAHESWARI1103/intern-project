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

class _HomamBookingPageState extends State<HomamBookingPage>
    with TickerProviderStateMixin {
  static const Color _primary = Color(0xFFFF9933);
  static const Color _darkBg  = Color(0xFF1A0A00);
  static const Color _accent  = Color(0xFFE65C00);

  // ── Step ──────────────────────────────────────────────────────
  int _step = 0; // 0=venue 1=details 2=homam 3=datetime 4=priest 5=payment

  // ── Venue ─────────────────────────────────────────────────────
  String       _venueType      = '';
  List<Temple> _temples        = [];
  Temple?      _selectedTemple;
  bool         _loadingTemples = false;

  // ── User details ──────────────────────────────────────────────
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _gotraCtrl       = TextEditingController();
  final _nakshatraCtrl   = TextEditingController();
  final _specialNoteCtrl = TextEditingController();

  // ── Homam ─────────────────────────────────────────────────────
  String? _selectedHomam;

  final Map<String, Map<String, dynamic>> _homamInfo = {
    'Ganapathi Homam':      {'price': 1100.0, 'desc': 'Removes obstacles & bestows success',         'emoji': '🐘'},
    'Navagraha Homam':      {'price': 2100.0, 'desc': 'Pacifies 9 planets, removes malefic effects', 'emoji': '🌟'},
    'Sudarshana Homam':     {'price': 3100.0, 'desc': 'Protection from enemies & evil forces',       'emoji': '🔱'},
    'Mrityunjaya Homam':    {'price': 5100.0, 'desc': 'Long life, health & victory over death',      'emoji': '🕉️'},
    'Lakshmi Kubera Homam': {'price': 4100.0, 'desc': 'Wealth, prosperity & financial growth',       'emoji': '💰'},
    'Saraswathi Homam':     {'price': 2100.0, 'desc': 'Education, arts & knowledge',                 'emoji': '📚'},
    'Ayush Homam':          {'price': 2500.0, 'desc': 'Longevity & good health for children',        'emoji': '🌱'},
    'Rudra Homam':          {'price': 6100.0, 'desc': 'Destroys sins & grants moksha',               'emoji': '⚡'},
  };

  // ── Date & Time ───────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  String   _selectedTime = '04:30 AM';

  final List<String> _earlyMorningSlots = [
    '04:30 AM', '05:00 AM', '05:30 AM', '06:00 AM',
    '06:30 AM', '07:00 AM', '07:30 AM', '08:00 AM',
  ];
  final List<String> _midMorningSlots = [
    '08:30 AM', '09:00 AM', '09:30 AM', '10:00 AM',
    '10:30 AM', '11:00 AM', '11:30 AM',
  ];

  // ── Priest ────────────────────────────────────────────────────
  List<dynamic>         _priests        = [];
  Map<String, dynamic>? _selectedPriest;
  bool                  _loadingPriests = false;

  // ── Payment ───────────────────────────────────────────────────
  bool   _isLoading = false;
  late   Razorpay _razorpay;
  Map<String, dynamic>? _pendingBookingData;

  // ── Animation ─────────────────────────────────────────────────
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
            begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    _prefillUser();
  }

  void _prefillUser() {
    if (widget.user != null) {
      _nameCtrl.text  = widget.user!.name;
      _phoneCtrl.text = widget.user!.phone;
      _emailCtrl.text = widget.user!.email;
    } else {
      _loadUserFromApi();
    }
  }

  Future<void> _loadUserFromApi() async {
    try {
      final p = await ApiService.getUserProfile();
      if (!mounted || p == null) return;
      setState(() {
        _nameCtrl.text  = p['name']  ?? '';
        _phoneCtrl.text = p['phone'] ?? '';
        _emailCtrl.text = p['email'] ?? '';
      });
    } catch (_) {}
  }

  Future<void> _loadTemples() async {
    setState(() => _loadingTemples = true);
    try {
      final raw = await ApiService.getAllTemples();
      if (mounted) {
        setState(() {
          _temples        = raw.map((e) => Temple.fromJson(e as Map<String, dynamic>)).toList();
          _loadingTemples = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTemples = false);
    }
  }

  Future<void> _loadPriests() async {
    if (_selectedHomam == null) return;
    setState(() {
      _loadingPriests = true;
      _selectedPriest = null;
      _priests        = [];
    });
    try {
      final priests = await ApiService.getPriests(homamType: _selectedHomam!);
      if (mounted) {
        setState(() {
          _priests        = priests;
          _loadingPriests = false;
          if (_priests.isNotEmpty) {
            _selectedPriest = Map<String, dynamic>.from(_priests[0] as Map);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPriests = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _slideCtrl.dispose();
    for (final c in [
      _nameCtrl, _phoneCtrl, _emailCtrl, _addressCtrl,
      _gotraCtrl, _nakshatraCtrl, _specialNoteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToStep(int s) {
    setState(() => _step = s);
    _slideCtrl.forward(from: 0);
  }

  static const List<String> _stepLabels = [
    'Venue', 'Details', 'Homam', 'Date & Time', 'Pandit', 'Payment'
  ];
  static const List<IconData> _stepIcons = [
    Icons.location_on_outlined,
    Icons.person_outline,
    Icons.local_fire_department_outlined,
    Icons.calendar_today_outlined,
    Icons.self_improvement_outlined,
    Icons.payment_outlined,
  ];

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: Column(children: [
        _buildHeader(),
        _buildStepBar(),
        Expanded(
          child: SlideTransition(
            position: _slideAnim,
            child: _buildCurrentStep(),
          ),
        ),
      ]),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    padding: EdgeInsets.fromLTRB(
        16, MediaQuery.of(context).padding.top + 8, 16, 16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE65C00), Color(0xFFFF9933)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(children: [
      GestureDetector(
        onTap: () {
          if (_step == 0) {
            Navigator.pop(context);
          } else {
            _goToStep(_step - 1);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔥 Homam Booking',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(_stepLabels[_step],
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${_step + 1} / 6',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ]),
  );

  // ── STEP BAR ─────────────────────────────────────────────────
  Widget _buildStepBar() => Container(
    color: const Color(0xFFFF9933),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: List.generate(6, (i) {
        final done   = i < _step;
        final active = i == _step;
        return Expanded(
          child: Row(children: [
            GestureDetector(
              onTap: done ? () => _goToStep(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width:  active ? 32 : 24,
                height: active ? 32 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? Colors.white
                      : done
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 13, color: Color(0xFFE65C00))
                      : Icon(_stepIcons[i],
                          size:  active ? 16 : 12,
                          color: active ? _accent : Colors.white),
                ),
              ),
            ),
            if (i < 5)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: done
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ]),
        );
      }),
    ),
  );

  // ── CURRENT STEP ─────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:  return _buildVenueStep();
      case 1:  return _buildDetailsStep();
      case 2:  return _buildHomamStep();
      case 3:  return _buildDateTimeStep();
      case 4:  return _buildPriestStep();
      case 5:  return _buildPaymentStep();
      default: return _buildVenueStep();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 0 — VENUE
  // ══════════════════════════════════════════════════════════════
  Widget _buildVenueStep() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeading('Where to perform the Homam?', 'Choose your preferred venue'),
      const SizedBox(height: 24),
      _venueCard(
        type: 'home', emoji: '🏠', title: 'At My Home',
        subtitle: 'Pandit visits your home & performs homam',
        points: ['Personal & comfortable', 'Pandit brings all samagri', 'Private atmosphere'],
      ),
      const SizedBox(height: 14),
      _venueCard(
        type: 'temple', emoji: '🛕', title: 'At Temple',
        subtitle: 'Performed at a sacred temple by temple priests',
        points: ['Sacred environment', 'All arrangements provided', 'Auspicious blessings'],
      ),
      if (_venueType == 'temple') ...[
        const SizedBox(height: 20),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Select Temple',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          if (_loadingTemples)
            const Center(child: CircularProgressIndicator(color: _primary))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Temple>(
                  value: _selectedTemple,
                  hint: const Text('Choose a temple'),
                  isExpanded: true,
                  selectedItemBuilder: (_) => _temples
                      .map((t) => Text(t.name, overflow: TextOverflow.ellipsis))
                      .toList(),
                  items: _temples
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTemple = v),
                ),
              ),
            ),
          if (_selectedTemple != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on, color: _primary, size: 14),
              const SizedBox(width: 4),
              Text(_selectedTemple!.location,
                  style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
            ]),
          ],
        ])),
      ],
      const SizedBox(height: 32),
      _nextButton(
        label: 'Continue to Details',
        onTap: () {
          if (_venueType.isEmpty) { _snack('Please select a venue'); return; }
          if (_venueType == 'temple' && _selectedTemple == null) {
            _snack('Please select a temple'); return;
          }
          _goToStep(1);
        },
      ),
    ]),
  );

  // ══════════════════════════════════════════════════════════════
  // STEP 1 — DETAILS
  // ══════════════════════════════════════════════════════════════
  Widget _buildDetailsStep() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeading('Your Details', 'Fill in your personal information'),
        const SizedBox(height: 20),
        _venueBadge(),
        const SizedBox(height: 20),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('👤 Personal Information'),
          const SizedBox(height: 14),
          _field('Full Name *', _nameCtrl, Icons.person_outline,
              validator: (v) => v!.trim().isEmpty ? 'Enter your name' : null),
          const SizedBox(height: 12),
          _field('Mobile Number *', _phoneCtrl, Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().length < 10 ? 'Enter valid number' : null),
          const SizedBox(height: 12),
          _field('Email *', _emailCtrl, Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => !v!.contains('@') ? 'Enter valid email' : null),
          if (_venueType == 'home') ...[
            const SizedBox(height: 12),
            _field('Home Address *', _addressCtrl, Icons.location_on_outlined,
                maxLines: 3,
                validator: (v) => v!.trim().isEmpty ? 'Enter your address' : null),
          ],
        ])),
        const SizedBox(height: 14),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('🕉️ Ritual Details (Optional)'),
          const SizedBox(height: 14),
          _field('Gotra', _gotraCtrl, Icons.family_restroom_outlined),
          const SizedBox(height: 12),
          _field('Nakshatra', _nakshatraCtrl, Icons.star_outline),
          const SizedBox(height: 12),
          _field('Special Requests', _specialNoteCtrl, Icons.note_outlined, maxLines: 3),
        ])),
        const SizedBox(height: 32),
        _nextButton(
          label: 'Continue to Homam Selection',
          onTap: () {
            if (!_formKey.currentState!.validate()) return;
            _goToStep(2);
          },
        ),
      ]),
    ),
  );

  // ══════════════════════════════════════════════════════════════
  // STEP 2 — HOMAM TYPE
  // ══════════════════════════════════════════════════════════════
  Widget _buildHomamStep() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeading('Select Homam Type', 'Choose the homam for your ceremony'),
      const SizedBox(height: 20),
      _venueBadge(),
      const SizedBox(height: 20),
      _card(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: _primary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedHomam,
              hint: const Text('Choose Homam Type', style: TextStyle(color: Colors.grey)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: _primary),
              items: _homamInfo.keys
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Row(children: [
                          Text(_homamInfo[h]!['emoji']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(h,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                    '₹${(_homamInfo[h]!['price']! as double).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, color: _primary)),
                              ],
                            ),
                          ),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedHomam = v),
            ),
          ),
        ),
        if (_selectedHomam != null) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.deepOrange.shade50]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              Text(_homamInfo[_selectedHomam]!['emoji']!,
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_selectedHomam!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_homamInfo[_selectedHomam]!['desc']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _primary, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '₹${(_homamInfo[_selectedHomam]!['price']! as double).toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ])),
      const SizedBox(height: 32),
      _nextButton(
        label: 'Continue to Date & Time',
        onTap: () {
          if (_selectedHomam == null) { _snack('Please select a homam type'); return; }
          _goToStep(3);
        },
      ),
    ]),
  );

  // ══════════════════════════════════════════════════════════════
  // STEP 3 — DATE & TIME
  // ══════════════════════════════════════════════════════════════
  Widget _buildDateTimeStep() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeading('Choose Date & Time', 'Select an auspicious date for your homam'),
      const SizedBox(height: 20),

      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('📅 Select Date'),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (_, i) {
              final date = DateTime.now().add(Duration(days: i + 3));
              final selected = _selectedDate.day == date.day &&
                               _selectedDate.month == date.month;
              const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              final dayName = days[date.weekday - 1];
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 64,
                  decoration: BoxDecoration(
                    color: selected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? _primary : Colors.grey.shade300,
                        width: selected ? 2 : 1),
                    boxShadow: selected
                        ? [BoxShadow(
                            color: _primary.withValues(alpha: 0.3),
                            blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(dayName,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: selected ? Colors.white70 : Colors.grey)),
                    Text('${date.day}',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.black87)),
                    Text(_monthShort(date.month),
                        style: TextStyle(
                            fontSize: 10,
                            color: selected ? Colors.white70 : Colors.grey)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().add(const Duration(days: 3)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: _primary)),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          icon: const Icon(Icons.edit_calendar, color: _primary, size: 16),
          label: Text(
            'Selected: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: const TextStyle(color: _primary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ])),

      const SizedBox(height: 14),

      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('⏰ Select Time'),
        const SizedBox(height: 6),
        Row(children: [
          _timeLegendBadge('🌅', 'Early Morning (4:30–8:00 AM)', Colors.deepOrange),
          const SizedBox(width: 8),
          _timeLegendBadge('☀️', 'Mid-Morning (8:00–11:30 AM)', Colors.orange),
        ]),
        const SizedBox(height: 6),
        Text('Most powerful: Brahma Muhurtha & early morning slots',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _primary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTime,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: _primary),
              items: [
                DropdownMenuItem<String>(
                  value: '__header_early__',
                  enabled: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.orange.shade200))),
                    child: Row(children: [
                      const Text('🌅', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Early Morning  •  Most Powerful',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade700)),
                    ]),
                  ),
                ),
                ..._earlyMorningSlots.map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(children: [
                          const Icon(Icons.access_time, size: 14, color: _primary),
                          const SizedBox(width: 8),
                          Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          if (t == '04:30 AM' || t == '05:00 AM') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('Best',
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ),
                    )),
                DropdownMenuItem<String>(
                  value: '__header_mid__',
                  enabled: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.orange.shade200))),
                    child: Row(children: [
                      const Text('☀️', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Mid-Morning  •  Also Very Good',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800)),
                    ]),
                  ),
                ),
                ..._midMorningSlots.map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(children: [
                          const Icon(Icons.access_time, size: 14, color: _primary),
                          const SizedBox(width: 8),
                          Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    )),
              ],
              onChanged: (v) {
                if (v == null || v.startsWith('__header')) return;
                setState(() => _selectedTime = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.check_circle_rounded, color: _primary, size: 16),
          const SizedBox(width: 6),
          Text('Selected: $_selectedTime',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
        ]),
      ])),

      const SizedBox(height: 32),
      _nextButton(
        label: 'Find Available Pandits',
        onTap: () { _loadPriests(); _goToStep(4); },
      ),
    ]),
  );

  Widget _timeLegendBadge(String emoji, String label, Color color) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );

  // ══════════════════════════════════════════════════════════════
  // STEP 4 — PRIEST  ✅ DROPDOWN + OVERFLOW FIXED
  // ══════════════════════════════════════════════════════════════
  Widget _buildPriestStep() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeading('Select Pandit', 'Choose an experienced pandit for your homam'),
      const SizedBox(height: 20),

      // ── Summary chips ─────────────────────────────────────────
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _infoBadge(
              _venueType == 'home' ? '🏠 Home' : '🛕 ${_selectedTemple?.name ?? "Temple"}',
              Colors.orange),
          const SizedBox(width: 8),
          _infoBadge('${_homamInfo[_selectedHomam]!['emoji']} $_selectedHomam',
              Colors.deepOrange),
          const SizedBox(width: 8),
          _infoBadge('📅 ${_selectedDate.day}/${_selectedDate.month}', Colors.teal),
          const SizedBox(width: 8),
          _infoBadge('⏰ $_selectedTime', Colors.indigo),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Loading ───────────────────────────────────────────────
      if (_loadingPriests)
        _card(child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Column(children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 12),
            Text('Finding pandits for your homam...',
                style: TextStyle(color: Colors.grey)),
          ]),
        ))

      // ── Empty state ───────────────────────────────────────────
      else if (_priests.isEmpty)
        _card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('🙏', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('No specific pandits found',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('We will assign an expert pandit for your $_selectedHomam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadPriests,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white),
            ),
          ]),
        ))

      // ── Pandit Selectable List ────────────────────────────────
      else ...[
        Text('${_priests.length} pandits available',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 12),

        // Render each pandit as a tappable card — no DropdownMenuItem height issues
        ..._priests.map((p) {
          final pr       = Map<String, dynamic>.from(p as Map);
          final id       = pr['_id'] as String? ?? '';
          final selected = _selectedPriest?['_id'] == id;
          final langs    = (pr['languages'] as List?)?.join(', ') ?? '';
          final specs    = (pr['specializations'] as List?) ?? [];

          return GestureDetector(
            onTap: () => setState(() => _selectedPriest = pr),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF3E0) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected ? _primary : Colors.grey.shade200,
                    width: selected ? 2 : 1),
                boxShadow: [
                  BoxShadow(
                      color: selected
                          ? _primary.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _priestAvatar(pr, size: 48, selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Name + Selected badge
                    Row(children: [
                      Expanded(
                        child: Text(pr['name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: selected ? _primary : Colors.black87)),
                      ),
                      if (selected)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('✓ Selected',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    // Exp + Location
                    Row(children: [
                      const Icon(Icons.work_outline, size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('${pr['experience'] ?? 0} yrs',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(pr['location'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ]),
                    // Languages
                    if (langs.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text('🗣 $langs',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                    // Specialization tags
                    if (specs.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: specs.take(2).map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s.toString(),
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: _primary,
                                      fontWeight: FontWeight.w600)),
                            )).toList(),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(width: 8),
                // Rating + radio
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text('${pr['rating'] ?? 0}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? _primary : Colors.grey,
                      size: 22),
                ]),
              ]),
            ),
          );
        }),
      ],

      const SizedBox(height: 32),
      _nextButton(
        label: 'Continue to Payment',
        onTap: () {
          if (_priests.isNotEmpty && _selectedPriest == null) {
            _snack('Please select a pandit'); return;
          }
          _goToStep(5);
        },
      ),
    ]),
  );

  // ── Reusable priest avatar ────────────────────────────────────
  Widget _priestAvatar(Map<String, dynamic> pr,
      {required double size, required bool selected}) {
    final name = pr['name'] as String? ?? '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? _primary : Colors.orange.shade100),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : _primary),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 5 — PAYMENT
  // ══════════════════════════════════════════════════════════════
  Widget _buildPaymentStep() {
    final price = _homamInfo[_selectedHomam]!['price']! as double;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeading('Booking Summary', 'Review your booking before payment'),
        const SizedBox(height: 20),

        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.deepOrange.shade50]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(_homamInfo[_selectedHomam]!['emoji']!,
                  style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_selectedHomam!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  Text(_homamInfo[_selectedHomam]!['desc']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _summaryRow('📍 Venue',
              _venueType == 'home'
                  ? 'At Home — ${_nameCtrl.text}'
                  : _selectedTemple!.name),
          _summaryRow('👤 Name', _nameCtrl.text),
          _summaryRow('📞 Phone', _phoneCtrl.text),
          _summaryRow('📅 Date',
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
          _summaryRow('⏰ Time', _selectedTime),
          _summaryRow('🧑‍⚕️ Pandit', _selectedPriest?['name'] ?? 'To be assigned'),
          if (_gotraCtrl.text.isNotEmpty)
            _summaryRow('🌿 Gotra', _gotraCtrl.text),
          if (_nakshatraCtrl.text.isNotEmpty)
            _summaryRow('⭐ Nakshatra', _nakshatraCtrl.text),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _priceRow('Homam Fee', '₹${price.toStringAsFixed(0)}'),
          _priceRow('Samagri & Prasadam', 'Included'),
          _priceRow('Pandit Dakshina', 'Included'),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('₹${price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 22, color: _primary)),
          ]),
          const SizedBox(height: 8),
          const Text('✅ Includes all materials, dakshina & prasadam',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ])),

        const SizedBox(height: 14),

        if (_selectedPriest != null)
          _card(child: Row(children: [
            _priestAvatar(_selectedPriest!, size: 44, selected: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_selectedPriest!['name'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Will contact you 24 hrs before the homam 🙏',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              Text('${_selectedPriest!['rating'] ?? 0}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ])),

        const SizedBox(height: 28),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE65C00), Color(0xFFFF9933)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withValues(alpha: 0.4),
                        blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                      'Pay ₹${price.toStringAsFixed(0)} & Confirm Booking 🙏',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
        const SizedBox(height: 10),
        const Center(
            child: Text('🔒 Secure payment via Razorpay • UPI • Cards',
                style: TextStyle(fontSize: 11, color: Colors.grey))),
        const SizedBox(height: 40),
      ]),
    );
  }

  // ── PAYMENT LOGIC ─────────────────────────────────────────────
  void _initiatePayment() {
    final price = _homamInfo[_selectedHomam]!['price']! as double;
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    _pendingBookingData = {
      'userName':     _nameCtrl.text.trim(),
      'userEmail':    _emailCtrl.text.trim(),
      'userPhone':    _phoneCtrl.text.trim(),
      'templeName':   _venueType == 'temple'
          ? (_selectedTemple?.name ?? '')
          : 'Home - ${_nameCtrl.text.trim()}',
      'templeId':     _venueType == 'temple' ? (_selectedTemple?.id ?? '') : '',
      'homamType':    _selectedHomam,
      'date':         dateStr,
      'timeSlot':     _selectedTime,
      'priestId':     _selectedPriest?['_id']    ?? '',
      'iyer':         _selectedPriest?['name']   ?? 'To be assigned',
      'priestName':   _selectedPriest?['name']   ?? 'To be assigned',
      'priestPhone':  _selectedPriest?['phone']  ?? '',
      'priestRating': _selectedPriest?['rating'] ?? 0,
      'specialNote':  _specialNoteCtrl.text.trim(),
      'venueType':    _venueType,
      'address':      _venueType == 'home' ? _addressCtrl.text.trim() : '',
      'gotra':        _gotraCtrl.text.trim(),
      'nakshatra':    _nakshatraCtrl.text.trim(),
      'totalAmount':  price,
      'status':       'confirmed',
      'bookingType':  'homam',
    };
    setState(() => _isLoading = true);
    try {
      _razorpay.open({
        'key':         'rzp_test_SK0xB85zCUyk1j',
        'amount':      (price * 100).toInt(),
        'name':        'GodsConnect – Homam',
        'description': '$_selectedHomam on $dateStr at $_selectedTime',
        'prefill': {
          'name':    _nameCtrl.text.trim(),
          'contact': _phoneCtrl.text.trim(),
          'email':   _emailCtrl.text.trim(),
        },
        'theme': {'color': '#FF9933'},
      });
    } catch (_) {
      setState(() => _isLoading = false);
      _snack('Failed to open payment. Please try again.');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingData == null) {
      setState(() => _isLoading = false);
      return;
    }
    _pendingBookingData!['razorpayPaymentId'] = response.paymentId ?? '';
    _pendingBookingData!['razorpayOrderId']   = response.orderId  ?? '';
    _pendingBookingData!['paymentStatus']     = 'paid';
    try {
      await ApiService.saveHomamBooking(_pendingBookingData!);
    } catch (e) {
      debugPrint('Save error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _pendingBookingData = null;
    _showSuccessDialog(response.paymentId ?? 'N/A');
  }

  void _onPaymentError(PaymentFailureResponse r) {
    setState(() => _isLoading = false);
    _snack(r.code == 2 ? 'Payment cancelled' : 'Payment failed: ${r.message}');
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    _snack('Processing via ${r.walletName}...');
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, size: 72, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Homam Booked! 🙏',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _summaryRow('Homam',  _selectedHomam ?? ''),
            _summaryRow('Date',
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            _summaryRow('Time',   _selectedTime),
            _summaryRow('Pandit', _selectedPriest?['name'] ?? 'To be assigned'),
            _summaryRow('Amount',
                '₹${(_homamInfo[_selectedHomam]!['price']! as double).toStringAsFixed(0)}'),
            const Divider(height: 20),
            Text(
                'Payment ID: ${paymentId.length > 20 ? '${paymentId.substring(0, 20)}...' : paymentId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Your pandit will contact you 24 hrs before the homam 🙏',
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
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Back to Home',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────
  Widget _stepHeading(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _darkBg)),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
    ],
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))
      ],
    ),
    child: child,
  );

  Widget _sectionLabel(String label) =>
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));

  Widget _venueBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(_venueType == 'home' ? '🏠' : '🛕',
          style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(
        _venueType == 'home' ? 'At My Home' : _selectedTemple?.name ?? 'Temple',
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.deepOrange),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _goToStep(0),
        child: const Icon(Icons.edit, size: 14, color: Colors.deepOrange),
      ),
    ]),
  );

  Widget _infoBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _venueCard({
    required String type,
    required String emoji,
    required String title,
    required String subtitle,
    required List<String> points,
  }) {
    final sel = _venueType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _venueType = type);
        if (type == 'temple' && _temples.isEmpty) _loadTemples();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? _primary : Colors.grey.shade200, width: sel ? 2 : 1),
          boxShadow: [
            BoxShadow(
                color: sel
                    ? _primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 22, height: 22,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? _primary : Colors.grey, width: 2)),
            child: sel
                ? Center(
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _primary),
                    ))
                : null,
          ),
          const SizedBox(width: 12),
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: sel ? _primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: sel ? _primary : Colors.black87)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              ...points.map((pt) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  Icon(Icons.check_circle,
                      size: 13, color: sel ? _primary : Colors.grey),
                  const SizedBox(width: 5),
                  Text(pt,
                      style: TextStyle(
                          fontSize: 11,
                          color: sel ? Colors.black87 : Colors.grey)),
                ]),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
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

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  Widget _priceRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _nextButton({required String label, required VoidCallback onTap}) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: _primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _accent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _monthShort(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun',
       'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}