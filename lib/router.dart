import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login.dart';
import 'screens/admin_home.dart';
import 'screens/customer_home.dart';
import 'screens/customer_form.dart';

final db = Supabase.instance.client;
final authProvider = StreamProvider<AuthState>((ref) => db.auth.onAuthStateChange);
final roleProvider = FutureProvider<String?>((ref) async {
  ref.watch(authProvider);
  final u = db.auth.currentUser;
  if (u == null) return null;
  final r = await db.from('profiles').select('role').eq('id', u.id).maybeSingle();
  return r?['role'] as String?;
});

class Gate extends ConsumerWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    if (db.auth.currentSession == null) return const LoginScreen();
    return ref.watch(roleProvider).when(
          data: (r) => r == 'admin' ? const AdminHome() : const CustomerHome(),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
  }
}

final routerProvider = Provider<GoRouter>((ref) => GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Gate()),
      GoRoute(path: '/customer-form', builder: (_, s) => CustomerForm(c: s.extra as Map<String, dynamic>?)),
    ]));
