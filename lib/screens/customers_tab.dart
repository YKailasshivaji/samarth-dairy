import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});
  @override
  State<CustomersTab> createState() => _CState();
}

class _CState extends State<CustomersTab> {
  String q = '';
  bool inactive = false;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final r = await db.from('customers').select().eq('is_active', !inactive).order('name');
    if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(r));
  }

  Future<void> setActive(Map<String, dynamic> c, bool v) async {
    if (!v) {
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('Delete customer?'),
        content: const Text('Delivery history is kept. You can restore later.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
      if (ok != true) return;
    }
    await db.from('customers').update({'is_active': v}).eq('id', c['id']);
    load();
  }

  @override
  Widget build(BuildContext context) {
    final list = rows.where((c) => '${c['name']} ${c['phone']}'.toLowerCase().contains(q.toLowerCase()));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async { await context.push('/customer-form'); load(); }, child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => q = v))),
        SwitchListTile(title: const Text('Show inactive'), value: inactive, onChanged: (v) { inactive = v; load(); }),
        Expanded(child: RefreshIndicator(onRefresh: load, child: ListView(children: [
          for (final c in list)
            ListTile(
              title: Text(c['name']),
              subtitle: Text('${c['phone']} · ${c['default_qty_litre']} L × ₹${c['rate_per_litre']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') { await context.push('/customer-form', extra: c); load(); }
                  else { setActive(c, inactive); }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'toggle', child: Text(inactive ? 'Restore' : 'Delete')),
                ]),
            ),
        ]))),
      ]),
    );
  }
}
