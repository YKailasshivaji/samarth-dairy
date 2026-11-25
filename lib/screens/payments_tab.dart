import 'package:flutter/material.dart';
import '../router.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});
  @override
  State<PaymentsTab> createState() => _PState();
}

class _PState extends State<PaymentsTab> {
  List<Map<String, dynamic>> rows = [];
  Map<String, String> names = {};

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final p = await db.from('payments').select().order('paid_on', ascending: false).limit(100);
    final c = await db.from('customers').select('id,name');
    if (mounted) setState(() {
      rows = List<Map<String, dynamic>>.from(p);
      names = {for (final x in c) x['id'] as String: x['name'] as String};
    });
  }

  Future<void> set(Map<String, dynamic> p, String st) async {
    await db.from('payments').update({'status': st, 'confirmed_by': db.auth.currentUser!.id}).eq('id', p['id']);
    load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(children: [
        for (final p in rows)
          ListTile(
            title: Text('${names[p['customer_id']] ?? '-'} · ₹${p['amount']}'),
            subtitle: Text('${p['paid_on']} · ${p['mode']} · ${p['status']}'),
            trailing: p['status'] == 'pending'
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.check), onPressed: () => set(p, 'confirmed')),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => set(p, 'rejected')),
                  ])
                : null,
          ),
      ]));
}
