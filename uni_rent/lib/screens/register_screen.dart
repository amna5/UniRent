// register_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/user_model.dart';
import '../theme.dart';

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
      Navigator.pop(context);
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
