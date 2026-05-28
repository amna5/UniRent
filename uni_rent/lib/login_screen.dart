import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'theme.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await DatabaseHelper.instance.getUserByEmail(email);

    if (user == null || user.password != password) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or password. Please try again.';
      });
      return;
    }

    if (user.isActive != 1) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Your account has been suspended. Contact admin.';
      });
      return;
    }

    await SessionService.saveSession(
      userId: user.id!,
      role: user.role,
      name: user.name,
      email: user.email,
    );

    if (!mounted) return;

    // send admin to dashboard, regular user to home
    if (user.isAdmin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'UniRent',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Campus Peer-to-Peer Rental Platform',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 48),

              const Text(
                'University Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'student@university.edu.my',
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 24),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text(
                    'New user? Create an account',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Verified Student Community',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _university = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_name.text.isEmpty || _email.text.isEmpty ||
        _password.text.isEmpty || _university.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await DatabaseHelper.instance.insertUser(UserModel(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        university: _university.text.trim(),
        memberSince: DateTime.now().toIso8601String(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please login.'),
            backgroundColor: Colors.green));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      setState(() { _loading = false; _error = 'Email already registered.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 14),
            TextField(controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'University Email',
                    hintText: 'student@university.edu.my')),
            const SizedBox(height: 14),
            TextField(controller: _university,
                decoration: const InputDecoration(labelText: 'University')),
            const SizedBox(height: 14),
            TextField(controller: _password, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator(color: AppTheme.primary)
                : ElevatedButton(onPressed: _register,
                    child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
