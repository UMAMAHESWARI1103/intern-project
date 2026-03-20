import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/facilities_page.dart';
import '../screens/facilities_emergency_page.dart';
import '../screens/darshan_booking_page.dart';
import '../screens/donation_page.dart';
import '../screens/homam_booking_page.dart';
import '../screens/prasadam_booking_page.dart';
import '../screens/dos_and_donts_page.dart';
import '../screens/temple_list_page.dart';
import '../screens/events_page.dart';
import '../screens/prayers_page.dart';
import '../screens/marriage_booking_page.dart';
import '../screens/ecommerce_page.dart';
import '../models/temple.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../screens/temple_detail_page.dart';
import '../screens/profile_page.dart';
import '../screens/bakthi_padal.dart';
import '../screens/settings.dart';
import '../screens/ai_suggestions_page.dart';
import '../screens/chatbot_page.dart';

final List<Map<String, String>> _allQuotes = [
  {'quote': 'You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions.', 'author': 'Lord Krishna'},
  {'quote': 'The only way to do great work is to love what you do.', 'author': 'Swami Vivekananda'},
  {'quote': 'The soul is neither born nor dies. It is eternal and ancient.', 'author': 'Lord Krishna'},
  {'quote': 'He who surrenders to God with a pure heart will always find peace.', 'author': 'Lord Rama'},
  {'quote': 'Where there is love, there is life. Where there is life, there is hope.', 'author': 'Swami Vivekananda'},
  {'quote': 'Do your duty without attachment. That is the path to liberation.', 'author': 'Lord Krishna'},
  {'quote': 'Truth is God. God is truth. Pray and you shall know.', 'author': 'Swami Vivekananda'},
  {'quote': 'The one who sees the divine in every living being, sees the truth.', 'author': 'Lord Krishna'},
  {'quote': 'Patience is the key to peace. Faith is the key to victory.', 'author': 'Lord Rama'},
  {'quote': 'A man who is pure in thought, word and deed will never touch misery.', 'author': 'Swami Vivekananda'},
];

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Map<String, String> _todayQuote;

  List<Temple> _apiTemples = [];
  bool _isLoadingTemples = false;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Temple> _searchResults = [];
  bool _isSearchLoading = false;

  double? _userLat;
  double? _userLon;
  bool _locationPermissionGranted = false;

  static const List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.business,      'label': 'Facilities'},
    {'icon': Icons.rule,          'label': 'Do/Don\'t'},
    {'icon': Icons.shopping_bag,  'label': 'Store'},
    {'icon': Icons.music_note,    'label': 'Bakthi Padal'},
    {'icon': Icons.settings,      'label': 'Settings'},
  ];

  static const List<Map<String, String>> _temples = [
    {'name': 'Sri Venkateswara Temple', 'location': 'Tirupati, Andhra Pradesh', 'icon': '⛰️', 'distance': '250 km'},
    {'name': 'Meenakshi Temple',        'location': 'Madurai, Tamil Nadu',       'icon': '🪷', 'distance': '450 km'},
    {'name': 'Brihadeeswarar Temple',   'location': 'Thanjavur, Tamil Nadu',     'icon': '🔱', 'distance': '320 km'},
  ];

  static const List<Map<String, String>> _quickActions = [
    {'icon': '🏛️', 'label': 'Temples'},
    {'icon': '📅', 'label': 'Events'},
    {'icon': '🙏', 'label': 'Prayers'},
    {'icon': '💰', 'label': 'Donate'},
  ];

  static const List<String> _prayers = [
    'Morning Prayer',
    'Evening Aarti',
    'Gayatri Mantra',
    'Hanuman Chalisa',
  ];

  static const double _emulatorDefaultLat = 13.0827;
  static const double _emulatorDefaultLon = 80.2707;

  List<Map<String, dynamic>> get _bookingModules => [
    {
      'icon': '🙏',
      'label': 'Darshan',
      'description': 'Book your temple darshan',
      'color': const Color(0xFFFFF3E0),
      'page': DarshanBookingPage(user: widget.user),
    },
    {
      'icon': '🍽️',
      'label': 'Prasadham',
      'description': 'Order temple prasadham',
      'color': const Color(0xFFE8F5E9),
      'page': PrasadamBookingPage(user: widget.user),
    },
    {
      'icon': '🔥',
      'label': 'Homam',
      'description': 'Book homam services',
      'color': const Color(0xFFFFEBEE),
      'page': HomamBookingPage(user: widget.user),
    },
    {
      'icon': '💑',
      'label': 'Marriage',
      'description': 'Book marriage hall',
      'color': const Color(0xFFF3E5F5),
      'page': MarriageBookingPage(user: widget.user),
    },
  ];

  @override
  void initState() {
    super.initState();
    _todayQuote = _allQuotes[DateTime.now().millisecondsSinceEpoch % _allQuotes.length];
    _getUserLocation();
    _fetchTemples();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToAIPage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AiSuggestionsPage()));
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationPermissionGranted = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationPermissionGranted = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationPermissionGranted = false; });
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final bool isEmulatorLocation =
          (position.latitude > 30 && position.longitude < 0) ||
          (position.latitude == 0 && position.longitude == 0);
      setState(() {
        _userLat = isEmulatorLocation ? _emulatorDefaultLat : position.latitude;
        _userLon = isEmulatorLocation ? _emulatorDefaultLon : position.longitude;
        _locationPermissionGranted = true;
      });
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() { _locationPermissionGranted = false; });
    }
  }

  Future<void> _fetchTemples() async {
    setState(() { _isLoadingTemples = true; _errorMessage = ''; });
    try {
      final raw = await ApiService.getAllTemples();
      final parsed = raw
          .map((e) => Temple.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _apiTemples = parsed; _isLoadingTemples = false; });
    } catch (e) {
      setState(() {
        _isLoadingTemples = false;
        _errorMessage = 'Unable to load temples from API. Showing local data.';
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    setState(() { _isSearching = true; _isSearchLoading = true; });
    try {
      final results = await ApiService.searchTemples(query.trim());
      setState(() { _searchResults = List<Temple>.from(results); _isSearchLoading = false; });
    } catch (_) {
      final q = query.trim().toLowerCase();
      setState(() {
        _searchResults = _apiTemples
            .where((t) =>
                t.name.toLowerCase().contains(q) ||
                t.location.toLowerCase().contains(q) ||
                t.deity.toLowerCase().contains(q))
            .toList();
        _isSearchLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() { _isSearching = false; _searchResults = []; });
  }

  void _goToEvents() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EventsPage(
        loggedInName:  widget.user?.name,
        loggedInEmail: widget.user?.email,
        loggedInPhone: widget.user?.phone,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              ),
              backgroundColor: const Color(0xFFFF9933),
              foregroundColor: Colors.white,
              icon: const Text('🛕', style: TextStyle(fontSize: 20)),
              label: const Text('Ask AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      title: Row(children: [
        Image.asset('assets/temple_icon.png', height: 28,
            errorBuilder: (_, __, ___) =>
                const Text('🛕', style: TextStyle(fontSize: 22))),
        const SizedBox(width: 6),
        const Text('GodsConnect',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome, size: 22),
          tooltip: 'Smart Temple Locator', // ✅ CHANGED
          onPressed: _goToAIPage,
        ),
        if (widget.user != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF9933),
              child: Text(widget.user!.initials[0],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14)),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Color(0xFFFF9933)),
          child: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Text(
                  widget.user != null ? widget.user!.initials[0] : 'G',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9933)),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.user != null ? widget.user!.name : 'GodsConnect',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              if (widget.user != null)
                Text(widget.user!.email,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _menuItems.length,
            itemBuilder: (context, index) => ListTile(
              leading: Icon(_menuItems[index]['icon'] as IconData,
                  color: const Color(0xFFFF9933)),
              title: Text(_menuItems[index]['label'] as String,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                final label = _menuItems[index]['label'] as String;
                if (label == 'Facilities') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FacilitiesPage()));
                } else if (label == 'Do/Don\'t') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DosAndDontsPage()));
                } else if (label == 'Store') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EcommercePage()));
                } else if (label == 'Bakthi Padal') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BakthiPadalPage()));
                } else if (label == 'Settings') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()));
                }
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) return const FacilitiesPage();
    if (_selectedIndex == 2) return const FacilitiesEmergencyPage();
    if (_selectedIndex == 3) {
      return ProfilePage(
        userData: widget.user != null
            ? {
                'name':  widget.user!.name,
                'email': widget.user!.email,
                'phone': widget.user!.phone,
                'id':    widget.user!.id?.toString() ?? '',
              }
            : null,
      );
    }

    return GestureDetector(
      onTap: () { if (_isSearching) FocusScope.of(context).unfocus(); },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            if (_isSearching) _buildSearchResults(),
            if (!_isSearching) ...[
              const SizedBox(height: 8),
              _buildAIBanner(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildInspiration(),
              const SizedBox(height: 20),
              _buildTemples(),
              const SizedBox(height: 20),
              _buildBookingModules(),
              const SizedBox(height: 20),
              _buildPrayers(),
              const SizedBox(height: 80),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildAIBanner() {
    return GestureDetector(
      onTap: _goToAIPage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFFFFCC80)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.shade200,
                blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✨ Smart Temple Locator', // ✅ CHANGED
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 3),
              Text('Pick a temple & vehicle — get crowd, travel time & best visit time',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search temples...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9933)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9933))));
    }
    final query = _searchController.text.trim().toLowerCase();
    if (_searchResults.isNotEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('${_searchResults.length} temple(s) found',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        ..._searchResults.map((temple) => GestureDetector(
              onTap: () {
                _clearSearch();
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TempleDetailPage(temple: temple)));
              },
              child: _TempleCardAPI(
                temple: temple,
                userLat: _userLat,
                userLon: _userLon,
                locationGranted: _locationPermissionGranted,
              ),
            )),
      ]);
    }
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No temples found for "$query"',
            style: const TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Try searching by temple name, city, or deity',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            _clearSearch();
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TempleListPage()));
          },
          icon: const Text('🏛️'),
          label: const Text('Browse All Temples'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9933),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9),
      itemCount: _quickActions.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            final label = _quickActions[index]['label']!;
            if (label == 'Temples') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TempleListPage()));
            } else if (label == 'Events') {
              _goToEvents();
            } else if (label == 'Prayers') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrayersPage()));
            } else if (label == 'Donate') {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DonationPage(user: widget.user)));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF9933)),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(_quickActions[index]['icon']!,
                  style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(_quickActions[index]['label']!,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildInspiration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF9933))),
            child: const Text('Daily Inspiration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Text('🛕', style: TextStyle(fontSize: 22)),
        ]),
        const SizedBox(height: 16),
        Text(_todayQuote['quote']!,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic),
            maxLines: 4,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Text('— ${_todayQuote['author']}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildTemples() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Featured Temples',
          onViewAll: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TempleListPage()))),
      const SizedBox(height: 12),
      if (_isLoadingTemples)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFFF9933))))
      else if (_errorMessage.isNotEmpty)
        Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_errorMessage,
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12))),
            ]),
          ),
          ...(_temples.map(
              (t) => _TempleCard(key: ValueKey(t['name']), temple: t))),
        ])
      else if (_apiTemples.isNotEmpty)
        ..._apiTemples.take(3).map((temple) => GestureDetector(
              key: ValueKey(temple.id),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TempleDetailPage(temple: temple))),
              child: _TempleCardAPI(
                  temple: temple,
                  userLat: _userLat,
                  userLon: _userLon,
                  locationGranted: _locationPermissionGranted),
            ))
      else
        ...(_temples.map(
            (t) => _TempleCard(key: ValueKey(t['name']), temple: t))),
    ]);
  }

  Widget _buildBookingModules() {
    final modules = _bookingModules;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Booking Services',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 125,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return InkWell(
            onTap: () {
              if (module['page'] != null) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => module['page'] as Widget));
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: module['color'] as Color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFFFF9933).withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(module['icon'] as String,
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 8),
                  Text(module['label'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(module['description'] as String,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildPrayers() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Prayers',
          onViewAll: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PrayersPage()))),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85),
        itemCount: _prayers.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrayersPage())),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9933)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🙏', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(_prayers[index],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFFF9933),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home),              label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.business),          label: 'Facilities'),
        BottomNavigationBarItem(icon: Icon(Icons.emergency_rounded), label: 'Emergency'),
        BottomNavigationBarItem(icon: Icon(Icons.person),            label: 'Profile'),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All →',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9933))),
          ),
      ],
    );
  }
}

// ── Temple card from API ──────────────────────────────────────────────────────
class _TempleCardAPI extends StatelessWidget {
  const _TempleCardAPI({
    required this.temple,
    this.userLat,
    this.userLon,
    this.locationGranted = false,
  });
  final Temple temple;
  final double? userLat;
  final double? userLon;
  final bool locationGranted;

  @override
  Widget build(BuildContext context) {
    final String distanceText;
    if (locationGranted && userLat != null && userLon != null) {
      final double km = temple.distanceFromUser(userLat!, userLon!);
      distanceText = km < 1
          ? '${(km * 1000).toStringAsFixed(0)} m away'
          : '${km.toStringAsFixed(1)} km away';
    } else {
      distanceText = '📍 Tap to enable location';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Row(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF9933)),
          ),
          child: Center(
              child: Text(temple.icon, style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(temple.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('📍 ${temple.location}',
                style: const TextStyle(fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Icon(
                  locationGranted ? Icons.directions_car : Icons.location_off,
                  size: 13,
                  color: locationGranted ? Colors.black54 : Colors.orange),
              const SizedBox(width: 4),
              Text(distanceText,
                  style: TextStyle(
                      fontSize: 12,
                      color: locationGranted ? Colors.black54 : Colors.orange,
                      fontWeight: locationGranted
                          ? FontWeight.normal
                          : FontWeight.w500)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: temple.isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(temple.isOpen ? 'Open' : 'Closed',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ]),
    );
  }
}

// ── Static temple card (fallback) ─────────────────────────────────────────────
class _TempleCard extends StatelessWidget {
  const _TempleCard({super.key, required this.temple});
  final Map<String, String> temple;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9933)),
      ),
      child: Row(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF9933)),
          ),
          child: Center(
              child: Text(temple['icon'] ?? '🛕',
                  style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(temple['name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('📍 ${temple['location']}',
                style: const TextStyle(fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('🚗 ${temple['distance']} away',
                style: const TextStyle(fontSize: 12)),
          ]),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ]),
    );
  }
}