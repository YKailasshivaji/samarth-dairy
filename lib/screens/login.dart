import 'package:flutter/material.dart';
import '../router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final a = TextEditingController(), b = TextEditingController();
  bool admin = false, busy = false;

  Future<void> go() async {
    setState(() => busy = true);
    try {
      final id = a.text.trim();
      if (!admin && !RegExp(r'^\d{10}$').hasMatch(id)) throw 'Enter a 10-digit phone number';
      await db.auth.signInWithPassword(
          email: admin ? id : '$id@samarthdairy.app', password: b.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 40),
            const Text('🥛 Samarth Dairy', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: false, label: Text('Customer')), ButtonSegment(value: true, label: Text('Admin'))],
              selected: {admin},
              onSelectionChanged: (s) => setState(() { admin = s.first; a.clear(); b.clear(); }),
            ),
            const SizedBox(height: 16),
            TextField(controller: a, keyboardType: admin ? TextInputType.emailAddress : TextInputType.phone,
                decoration: InputDecoration(labelText: admin ? 'Email' : 'Phone number', border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: b, obscureText: true,
                keyboardType: admin ? TextInputType.visiblePassword : TextInputType.number,
                decoration: InputDecoration(labelText: admin ? 'Password' : '6-digit PIN', border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: busy ? null : go, child: const Text('Login')),
          ]),
        ),
      );
}
