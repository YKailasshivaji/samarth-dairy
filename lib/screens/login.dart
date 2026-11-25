import 'package:flutter/material.dart';
import '../router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final a = TextEditingController(), b = TextEditingController();
  bool admin = false, otpSent = false, busy = false;

  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> go() async {
    setState(() => busy = true);
    try {
      if (admin) {
        await db.auth.signInWithPassword(email: a.text.trim(), password: b.text);
      } else if (!otpSent) {
        if (!RegExp(r'^\d{10}$').hasMatch(a.text.trim())) throw 'Enter a 10-digit phone number';
        await db.auth.signInWithOtp(phone: '+91${a.text.trim()}');
        setState(() => otpSent = true);
      } else {
        await db.auth.verifyOTP(phone: '+91${a.text.trim()}', token: b.text.trim(), type: OtpType.sms);
      }
    } catch (e) {
      msg('$e');
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
              onSelectionChanged: (s) => setState(() { admin = s.first; otpSent = false; a.clear(); b.clear(); }),
            ),
            const SizedBox(height: 16),
            TextField(controller: a, keyboardType: admin ? TextInputType.emailAddress : TextInputType.phone,
                decoration: InputDecoration(labelText: admin ? 'Email' : 'Phone number', border: const OutlineInputBorder())),
            if (admin || otpSent) ...[
              const SizedBox(height: 12),
              TextField(controller: b, obscureText: admin,
                  decoration: InputDecoration(labelText: admin ? 'Password' : 'OTP', border: const OutlineInputBorder())),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: busy ? null : go, child: Text(admin ? 'Login' : otpSent ? 'Verify OTP' : 'Send OTP')),
          ]),
        ),
      );
}
