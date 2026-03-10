import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'signup_page.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart';
import 'priest/priest_dashboard.dart'; // ← NEW

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey             = GlobalKey<FormState>();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;
  bool _isAdminMode     = false;

  static const Color _orange = Color(0xFFFF9933);
  static const Color _purple = Color(0xFF6C63FF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIN ────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final token    = result['token'];
      final role     = result['role']?.toString() ?? '';
      final rawUser  = result['user'];
      final rawPriest= result['priest'];

      if (token == null) {
        // Login failed — show backend message (including "pending approval")
        _snack(result['message'] ?? 'Login failed. Check credentials.', Colors.red);
        return;
      }

      await ApiService.setToken(token as String);
      if (!mounted) return;

      // ── Admin mode (pill toggled ON) ───────────────────────
      if (_isAdminMode) {
        if (role == 'admin') {
          _snack('Admin login successful!', Colors.green);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AdminDashboard(
                adminUser: rawUser != null
                    ? Map<String, dynamic>.from(rawUser)
                    : null,
              ),
            ),
          );
        } else {
          // Priest or normal user tried admin mode
          await ApiService.clearToken();
          _snack('Access denied. Admin privileges required.', Colors.red);
        }
        return;
      }

      // ── Normal login mode — route by role ──────────────────
      if (role == 'admin') {
        _snack('Welcome Admin!', Colors.green);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AdminDashboard(
              adminUser: rawUser != null
                  ? Map<String, dynamic>.from(rawUser)
                  : null,
            ),
          ),
        );

      } else if (role == 'priest') {
        // ── PRIEST → PriestDashboard ─────────────────────────
        _snack('Welcome, ${rawPriest?['name'] ?? 'Pandit'}!', Colors.green);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PriestDashboard(
              priestUser: rawPriest != null
                  ? Map<String, dynamic>.from(rawPriest)
                  : null,
            ),
          ),
        );

      } else {
        // ── Normal user → HomeScreen ─────────────────────────
        _snack(result['message'] ?? 'Login successful!', Colors.green);
        final user = User(
          id: rawUser?['id'] != null
              ? int.tryParse(rawUser!['id'].toString())
              : null,
          name:  rawUser?['name']  ?? '',
          email: rawUser?['email'] ?? _emailController.text.trim(),
          phone: rawUser?['phone'] ?? '',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
        );
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Login failed: ${e.toString()}', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final activeColor = _isAdminMode ? _purple : _orange;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Top row ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Admin toggle pill
                      GestureDetector(
                        onTap: () => setState(() {
                          _isAdminMode = !_isAdminMode;
                          _emailController.clear();
                          _passwordController.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _isAdminMode ? _purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _purple, width: 1.5),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              _isAdminMode
                                  ? Icons.admin_panel_settings
                                  : Icons.admin_panel_settings_outlined,
                              size: 15,
                              color: _isAdminMode ? Colors.white : _purple,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isAdminMode ? 'Admin Mode' : 'Admin Login',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isAdminMode ? Colors.white : _purple,
                              ),
                            ),
                          ]),
                        ),
                      ),

                      // Skip button
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen())),
                        child: const Text('Skip →',
                            style: TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Logo ─────────────────────────────────────
                  Center(
                    child: Column(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                        ),
                        child: Center(
                          child: Icon(
                            _isAdminMode
                                ? Icons.admin_panel_settings
                                : Icons.account_balance,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('GodsConnect',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _isAdminMode ? '🔐 Admin Portal' : 'Welcome Back!',
                          key: ValueKey(_isAdminMode),
                          style: TextStyle(
                            fontSize: 16,
                            color: _isAdminMode ? _purple : Colors.grey,
                            fontWeight: _isAdminMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 40),

                  // ── Admin warning banner ──────────────────────
                  if (_isAdminMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _purple.withValues(alpha: 0.4)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, size: 16, color: _purple),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin credentials required. Unauthorized access is prohibited.',
                            style: TextStyle(fontSize: 12, color: _purple),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  // ── Email ─────────────────────────────────────
                  Text(_isAdminMode ? 'Admin Email' : 'Email',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDeco(
                      hint: _isAdminMode
                          ? 'Enter admin email'
                          : 'Enter your email',
                      icon: _isAdminMode
                          ? Icons.admin_panel_settings_outlined
                          : Icons.email_outlined,
                      activeColor: activeColor,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Password ──────────────────────────────────
                  const Text('Password',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDeco(
                      hint: 'Enter your password',
                      icon: Icons.lock_outlined,
                      activeColor: activeColor,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter password';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Login Button ──────────────────────────────
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isAdminMode) ...[
                                const Icon(Icons.admin_panel_settings, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _isAdminMode ? 'Login as Admin' : 'Login',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ── Switch to user (admin mode only) ──────────
                  if (_isAdminMode)
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _isAdminMode = false),
                        icon: const Icon(Icons.person_outline,
                            size: 15, color: Colors.grey),
                        label: const Text('Switch to User Login',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),

                  // ── Sign Up link (user mode only) ─────────────
                  if (!_isAdminMode) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SignUpPage())),
                          child: const Text('Sign Up',
                              style: TextStyle(
                                  color: _orange,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Input Decoration Helper ───────────────────────────────────
  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    required Color activeColor,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _orange)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeColor, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      );
}