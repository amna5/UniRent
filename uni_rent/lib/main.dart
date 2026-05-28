import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'landing_screen.dart';
import 'app_logo.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await NotificationService.init();
  runApp(const UniRentApp());
}

class UniRentApp extends StatelessWidget {
  const UniRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniRent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _Splash(),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    // show landing only on first launch
    final prefs = await SharedPreferences.getInstance();
    final landingSeen = prefs.getBool('landing_seen') ?? false;
    if (!landingSeen) {
      _go(const LandingScreen());
      return;
    }

    final loggedIn = await SessionService.isLoggedIn();
    if (!loggedIn) {
      _go(const LoginScreen());
      return;
    }
    final role = await SessionService.getUserRole();
    _go(role == 'admin' ? const AdminDashboardScreen() : const HomeScreen());
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, Color(0xFF3D1C08)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UniRentLogo(iconSize: 88, showText: true, onDark: true),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Colors.white38,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
