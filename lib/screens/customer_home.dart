import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CHState();
}

class _CHState extends State<CustomerHome> {
  Map<String, dynamic>? c, bill;
  List<Map<String, dynamic>> pays = [];
  final amt = TextEditingController();
  static const ownerUpi = String.fromEnvironment('OWNER_UPI');

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final me = await db.from('customers').select().maybeSingle(); // RLS returns only own row
    if (me == null) { if (mounted) setState(() => c = null); return; }
    final b = await db.from('monthly_bills').select().eq('customer_id', me['id'])
        .eq('month', DateFormat('yyyy-MM-01').format(DateTime.now())).maybeSingle();
    final p = await db.from('payments').select().order('paid_on', ascending: false);
    if (!mounted) return;
    setState(() { c = me; bill = b; pays = List<Map<String, dynamic>>.from(p); amt.text = '${b?['balance'] ?? ''}'; });
  }

  Future<void> pay(String mode) async {
    final a = double.tryParse(amt.text);
    if (a == null || a <= 0) return;
    if (mode == 'upi') {
      await launchUrl(Uri.parse('upi://pay?pa=$ownerUpi&pn=Samarth%20Dairy&am=$a&cu=INR&tn=Milk%20bill'),
          mode: LaunchMode.externalApplication);
    }
    await db.from('payments').insert({'customer_id': c!['id'], 'amount': a, 'mode': mode, 'status': 'pending'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to Samarth Dairy for confirmation')));
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Samarth Dairy'),
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())]),
        body: c == null
            ? const Center(child: Text('No customer record linked to this phone.\nAsk the dairy owner.', textAlign: TextAlign.center))
            : RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
                Text('Hello ${c!['name']}', style: Theme.of(context).textTheme.titleLarge),
                Card(child: ListTile(
                  title: Text('${DateFormat('MMMM').format(DateTime.now())}: ${bill?['total_litres'] ?? 0} L (${bill?['days'] ?? 0} days)'),
                  subtitle: Text('Bill ₹${bill?['total_amount'] ?? 0} · Paid ₹${bill?['paid_amount'] ?? 0}'),
                  trailing: Text('Due ₹${bill?['balance'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)))),
                TextField(controller: amt, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: FilledButton(onPressed: () => pay('upi'), child: const Text('Pay by UPI'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () => pay('cash'), child: const Text('Paid cash'))),
                ]),
                const Divider(height: 32),
                for (final p in pays) ListTile(title: Text('₹${p['amount']} · ${p['mode']}'), subtitle: Text('${p['paid_on']}'), trailing: Text('${p['status']}')),
              ])),
      );
}
