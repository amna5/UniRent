import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'services/session_service.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise DB on first launch (creates tables + seeds admin + sample data)
  await DatabaseHelper.instance.database;
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

/// Checks for existing session and routes accordingly
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
    await Future.delayed(const Duration(milliseconds: 300));
    final loggedIn = await SessionService.isLoggedIn();
    if (!loggedIn) {
      _go(const LoginScreen());
      return;
    }
    final role = await SessionService.getUserRole();
    _go(role == 'admin'
        ? const AdminDashboardScreen()
        : const HomeScreen());
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text('UniRent',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            CircularProgressIndicator(
                color: Colors.white60, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
