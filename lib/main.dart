import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/bakthi_padal.dart';
import 'screens/settings.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayer.global.setAudioContext(
    AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {},
      ),
    ),
  );

  final prefs     = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('dark_mode') ?? false;

  runApp(GodsConnectApp(initialDarkMode: savedDark));
}

// ─────────────────────────────────────────────────────────────────
//  Root app — StatefulWidget so ThemeMode can be toggled globally.
//  Any widget can call: GodsConnectApp.of(context).toggleTheme()
// ─────────────────────────────────────────────────────────────────
class GodsConnectApp extends StatefulWidget {
  final bool initialDarkMode;
  const GodsConnectApp({super.key, this.initialDarkMode = false});

  // FIX: suppress library_private_types_in_public_api — this pattern is
  // intentional; _GodsConnectAppState must be accessible via findAncestorStateOfType.
  // ignore: library_private_types_in_public_api
  static _GodsConnectAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_GodsConnectAppState>()!;

  @override
  State<GodsConnectApp> createState() => _GodsConnectAppState();
}

class _GodsConnectAppState extends State<GodsConnectApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // ── Light theme ──────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF9933),
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9933),
          primary:   const Color(0xFFFF9933),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF9933),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
      ),

      // ── Dark theme ───────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF9933),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor:  const Color(0xFFFF9933),
          primary:    const Color(0xFFFF9933),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),

      home: const SplashScreenPage(),
      routes: {
        '/login':        (context) => const LoginPage(),
        '/bakthi_padal': (context) => const BakthiPadalPage(),
        '/settings':     (context) => const SettingsPage(),
      },
    );
  }
}