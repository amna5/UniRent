import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'app_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static Future<bool> hasBeenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('landing_seen') ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('landing_seen', true);
  }

  void _goRegister(BuildContext context) {
    markSeen();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goLogin(BuildContext context) {
    markSeen();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                const UniRentLogo(iconSize: 80, showText: true, onDark: true),

                const SizedBox(height: 12),
                const Text(
                  'Student Rental, Made Easy',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                _Feature(
                  icon: Icons.search_rounded,
                  title: 'Browse Nearby Items',
                  subtitle:
                      'Electronics, books, tools and more from fellow students',
                ),
                const SizedBox(height: 18),
                _Feature(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book in Seconds',
                  subtitle:
                      'Pick dates and pay instantly with TnG, DuitNow or card',
                ),
                const SizedBox(height: 18),
                _Feature(
                  icon: Icons.notifications_active_rounded,
                  title: 'Stay Notified',
                  subtitle:
                      'Real-time alerts for bookings and messages via push API',
                ),

                const Spacer(flex: 3),

                FilledButton(
                  onPressed: () => _goRegister(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () => _goLogin(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: Colors.white38, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
