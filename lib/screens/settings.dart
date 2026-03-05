import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── Colors ────────────────────────────────────────────────────
  static const Color _primary  = Color(0xFFFF9933);
  static const Color _accent   = Color(0xFFFFE0B2);
  static const Color _textDark = Color(0xFF3E1F00);
  static const Color _textGrey = Color(0xFF9E7A50);

  // ── Controllers ───────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────
  bool _editingProfile = false;
  bool _savingProfile  = false;
  bool _isLoggedIn     = false;
  bool _isLoadingUser  = true;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoad();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Load user from API / cache ────────────────────────────────
  Future<void> _checkLoginAndLoad() async {
    try {
      final data = await ApiService.getUserProfile();
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _isLoggedIn = true; _isLoadingUser = false;
          _nameCtrl.text  = data['name']  ?? '';
          _phoneCtrl.text = data['phone'] ?? '';
          _emailCtrl.text = data['email'] ?? '';
        });
      } else {
        setState(() { _isLoggedIn = false; _isLoadingUser = false; });
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        setState(() {
          _isLoggedIn = true; _isLoadingUser = false;
          _nameCtrl.text  = prefs.getString('user_name')  ?? '';
          _phoneCtrl.text = prefs.getString('user_phone') ?? '';
          _emailCtrl.text = prefs.getString('user_email') ?? '';
        });
      } else {
        setState(() { _isLoggedIn = false; _isLoadingUser = false; });
      }
    }
  }

  // ── Save profile ──────────────────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await ApiService.updateUserProfile({
        'name':  _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name',  _nameCtrl.text.trim());
      await prefs.setString('user_phone', _phoneCtrl.text.trim());
      await prefs.setString('user_email', _emailCtrl.text.trim());
      if (!mounted) return;
      setState(() { _editingProfile = false; _savingProfile = false; });
      _snack('Profile updated ✓', _primary);
    } catch (_) {
      if (!mounted) return;
      setState(() { _editingProfile = false; _savingProfile = false; });
      _snack('Save failed. Please try again.', Colors.red);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ApiService.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  DARK MODE
  // ─────────────────────────────────────────────────────────────
  void _toggleDarkMode(bool _) {
    GodsConnectApp.of(context).toggleTheme();
  }

  // ─────────────────────────────────────────────────────────────
  //  HELP CENTER
  // ─────────────────────────────────────────────────────────────
  void _openHelpCenter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqs = [
      {
        'q': 'How do I book a darshan?',
        'a': 'Go to Home → Booking Services → Darshan. Select your temple, date, and number of persons.',
      },
      {
        'q': 'How do I cancel a booking?',
        'a': 'Go to Profile → Bookings, find your booking and tap Cancel. Cancellations are allowed up to 24 hours before.',
      },
      {
        'q': 'Is my payment secure?',
        'a': 'Yes! We use Razorpay — a trusted payment gateway with 256-bit SSL encryption.',
      },
      {
        'q': 'How do I update my profile?',
        'a': 'Go to Settings → Account → tap the edit icon to update your name, phone, or email.',
      },
      {
        'q': 'Can I use the app without logging in?',
        'a': 'Yes! Browse temples, view events, and access prayers freely. Bookings and donations require login.',
      },
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
            Center(child: _sheetHandle(isDark)),
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
              Text('Help Center',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _textDark)),
            ]),
            const SizedBox(height: 20),
            ...faqs.map((faq) => _faqTile(faq['q']!, faq['a']!, isDark)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _launchEmail('support@godsconnect.app'),
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

  Widget _faqTile(String q, String a, bool isDark) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(q, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : _textDark)),
      iconColor: _primary,
      collapsedIconColor: Colors.grey,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(a,
              style: TextStyle(fontSize: 13, height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────────────────────
  //  CONTACT US
  // ─────────────────────────────────────────────────────────────
  void _openContactUs() {
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
          _sheetHandle(isDark),
          const SizedBox(height: 20),
          Text('Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _textDark)),
          const SizedBox(height: 8),
          Text("We're here to help! Reach us through any channel below.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 24),
          _contactTile(Icons.email_outlined, Colors.blue,
              'Email Support', 'support@godsconnect.app',
              () => _launchEmail('support@godsconnect.app'), isDark),
          const SizedBox(height: 12),
          _contactTile(Icons.phone_outlined, Colors.green,
              'Call Us', '+91 98765 43210',
              () => _launchPhone('+919876543210'), isDark),
          const SizedBox(height: 12),
          _contactTile(Icons.chat_outlined, Colors.teal,
              'WhatsApp', 'Chat with us',
              () => _launchUrl('https://wa.me/919876543210'), isDark),
        ]),
      ),
    );
  }

  Widget _contactTile(IconData icon, Color color, String title, String subtitle,
      VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                      color: isDark ? Colors.white : _textDark)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ]),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  RATE US
  // ─────────────────────────────────────────────────────────────
  void _openRateUs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int rating = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(isDark),
            const SizedBox(height: 20),
            const Text('🛕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Enjoying GodsConnect?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : _textDark)),
            const SizedBox(height: 8),
            Text('Your rating helps us serve devotees better',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setSheet(() => rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 44,
                    color: i < rating ? Colors.amber : Colors.grey[400],
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: rating == 0 ? null : () {
                  Navigator.pop(ctx);
                  _launchUrl('https://play.google.com/store/apps');
                  _snack('Thank you for your $rating★ rating! 🙏', Colors.green);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: rating == 0 ? Colors.grey[300] : _primary,
                  foregroundColor: rating == 0 ? Colors.grey : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Rating',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SHARE APP
  // ─────────────────────────────────────────────────────────────
  void _shareApp() {
    Share.share(
      '🛕 Discover GodsConnect — Your complete temple companion!\n\n'
      '✨ Book darshan, homam, prasadam & more\n'
      '📅 Stay updated on temple events\n'
      '🙏 Access prayers & devotional content\n\n'
      'Download: https://play.google.com/store/apps/godsconnect',
      subject: 'GodsConnect - Temple Companion App',
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PRIVACY POLICY & TERMS
  // ─────────────────────────────────────────────────────────────
  void _openPrivacyPolicy() => _openTextContent(
    title: 'Privacy Policy',
    icon: Icons.privacy_tip_outlined,
    iconColor: Colors.purple,
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

**6. Cookies & Local Storage**
The app uses minimal local storage to remember your preferences such as theme.

**7. Contact**
privacy@godsconnect.app
    ''',
  );

  void _openTerms() => _openTextContent(
    title: 'Terms & Conditions',
    icon: Icons.description_outlined,
    iconColor: Colors.indigo,
    content: '''
**GodsConnect Terms & Conditions**
Last updated: January 2025

**1. Acceptance of Terms**
By using GodsConnect, you agree to these terms. If you disagree, please discontinue use.

**2. User Accounts**
You are responsible for maintaining the confidentiality of your credentials. Provide accurate information during registration.

**3. Booking Policy**
• Bookings are subject to temple availability
• Cancellations must be made 24 hours in advance for a full refund
• No-shows are non-refundable
• GodsConnect is a facilitator — final services are provided by temples

**4. Payments**
All payments are processed securely via Razorpay. GodsConnect does not store card details. Refunds are processed within 5-7 business days.

**5. Prohibited Use**
You may not use this app for fraudulent bookings, misrepresentation, or any illegal activity.

**6. Intellectual Property**
All content, logos, and features are owned by GodsConnect and protected by copyright law.

**7. Limitation of Liability**
GodsConnect is not liable for indirect or consequential damages arising from use of the app.

**8. Contact**
legal@godsconnect.app
    ''',
  );

  void _openTextContent({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
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
                _sheetHandle(isDark),
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
                  Flexible(
                    child: Text(title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : _textDark)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: isDark ? Colors.grey[400] : Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                Divider(color: isDark ? Colors.grey[800] : _accent),
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
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : _textDark)),
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

  // ─────────────────────────────────────────────────────────────
  //  URL / EMAIL / PHONE HELPERS
  // ─────────────────────────────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open link', Colors.red);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email, query: 'subject=GodsConnect Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: email));
      _snack('Email copied: $email', _primary);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F0);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textDark  = isDark ? Colors.white : _textDark;
    final textGrey  = isDark ? Colors.grey[400]! : _textGrey;
    final divColor  = isDark ? Colors.grey[800]! : _accent;

    if (_isLoadingUser) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── ACCOUNT ─────────────────────────────────────────
          _sectionLabel('Account', textGrey),
          _card(cardColor, divColor,
              child: _isLoggedIn
                  ? _profileContent(isDark, textDark, textGrey)
                  : _guestTile(isDark, textDark, textGrey)),
          const SizedBox(height: 16),

          // ── PREFERENCES ─────────────────────────────────────
          _sectionLabel('Preferences', textGrey),
          _card(cardColor, divColor, child: Column(children: [
            _prefRow(
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              iconColor: isDark ? Colors.indigo : Colors.amber,
              label: 'Dark Mode',
              textColor: textDark,
              trailing: Switch(
                value: isDark,
                onChanged: _toggleDarkMode,
                activeThumbColor: _primary,
              ),
            ),
          ])),
          const SizedBox(height: 16),

          // ── SUPPORT ─────────────────────────────────────────
          _sectionLabel('Support', textGrey),
          _card(cardColor, divColor, child: Column(children: [
            _prefRow(
                icon: Icons.help_outline, iconColor: Colors.blue,
                label: 'Help Center', textColor: textDark,
                trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                onTap: _openHelpCenter),
            Divider(height: 1, color: divColor, indent: 56),
            _prefRow(
                icon: Icons.headset_mic_outlined, iconColor: Colors.green,
                label: 'Contact Us', textColor: textDark,
                trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                onTap: _openContactUs),
            Divider(height: 1, color: divColor, indent: 56),
            _prefRow(
                icon: Icons.star_outline, iconColor: Colors.amber,
                label: 'Rate Us', textColor: textDark,
                trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                onTap: _openRateUs),
            Divider(height: 1, color: divColor, indent: 56),
            _prefRow(
                icon: Icons.share_outlined, iconColor: Colors.teal,
                label: 'Share App', textColor: textDark,
                trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                onTap: _shareApp),
          ])),
          const SizedBox(height: 16),

          // ── LEGAL ────────────────────────────────────────────
          _sectionLabel('Legal', textGrey),
          _card(cardColor, divColor, child: Column(children: [
            _prefRow(
                icon: Icons.privacy_tip_outlined, iconColor: Colors.purple,
                label: 'Privacy Policy', textColor: textDark,
                trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                onTap: _openPrivacyPolicy),
            Divider(height: 1, color: divColor, indent: 56),
            _prefRow(
                icon: Icons.description_outlined, iconColor: Colors.indigo,
                label: 'Terms & Conditions', textColor: textDark,
                trailing: Icon(Icons.chevron_right, color: textGrey, size: 20),
                onTap: _openTerms),
          ])),
          const SizedBox(height: 20),

          // ── SIGN OUT ─────────────────────────────────────────
          if (_isLoggedIn) ...[
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── FOOTER ───────────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.temple_hindu, color: _primary, size: 30),
              ),
              const SizedBox(height: 10),
              Text('GodsConnect',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17, color: textDark)),
              const SizedBox(height: 4),
              Text('Version 1.0.0', style: TextStyle(color: textGrey, fontSize: 12)),
              Text('Built with ❤️ for Devotees',
                  style: TextStyle(color: textGrey, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  PROFILE CONTENT (logged-in)
  // ═══════════════════════════════════════════════
  Widget _profileContent(bool isDark, Color textDark, Color textGrey) {
    return Column(children: [
      Row(children: [
        CircleAvatar(
          radius: 28, backgroundColor: _accent,
          child: Text(
            _nameCtrl.text.isNotEmpty
                ? _nameCtrl.text[0].toUpperCase()
                : (_emailCtrl.text.isNotEmpty
                    ? _emailCtrl.text[0].toUpperCase()
                    : 'U'),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
            ),
            if (_emailCtrl.text.isNotEmpty)
              Text(_emailCtrl.text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textGrey, fontSize: 12)),
            if (_phoneCtrl.text.isNotEmpty)
              Text(_phoneCtrl.text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textGrey, fontSize: 12)),
          ]),
        ),
        IconButton(
          icon: Icon(
              _editingProfile ? Icons.close : Icons.edit_outlined,
              color: _primary),
          onPressed: () => setState(() => _editingProfile = !_editingProfile),
        ),
      ]),
      if (_editingProfile) ...[
        const SizedBox(height: 14),
        const Divider(color: _accent),
        const SizedBox(height: 10),
        _inputField('Full Name', _nameCtrl, Icons.person_outline),
        const SizedBox(height: 10),
        _inputField('Mobile Number', _phoneCtrl, Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        _inputField('Email', _emailCtrl, Icons.email_outlined),
        const SizedBox(height: 14),
        _fullBtn(
          _savingProfile ? '' : 'Save Changes',
          _savingProfile ? null : _saveProfile,
          loading: _savingProfile,
        ),
      ],
    ]);
  }

  // ═══════════════════════════════════════════════
  //  GUEST TILE
  // ═══════════════════════════════════════════════
  Widget _guestTile(bool isDark, Color textDark, Color textGrey) {
    return Column(children: [
      Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.person_outline, color: _primary, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Guest User',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
            Text('Login to access your account',
                style: TextStyle(color: textGrey, fontSize: 12)),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      _fullBtn('Login / Sign Up',
          () => Navigator.of(context).pushNamed('/login')),
    ]);
  }

  // ═══════════════════════════════════════════════
  //  SHARED UI HELPERS
  // ═══════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
    elevation: 0,
  );

  Widget _sectionLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.2)),
  );

  Widget _card(Color cardColor, Color divColor, {required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor),
          boxShadow: [
            BoxShadow(
                color: _primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _prefRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required Widget trailing,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor)),
            ),
            trailing,
          ]),
        ),
      );

  Widget _inputField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textGrey, fontSize: 13),
          prefixIcon: Icon(icon, color: _primary, size: 20),
          filled: true,
          fillColor: const Color(0xFFFFF8F0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  Widget _fullBtn(String label, VoidCallback? onTap, {bool loading = false}) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );

  Widget _sheetHandle(bool isDark) => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(2)),
  );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }
}