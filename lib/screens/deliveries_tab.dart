import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router.dart';

class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key});
  @override
  State<DeliveriesTab> createState() => _DState();
}

class _DState extends State<DeliveriesTab> {
  DateTime day = DateTime.now();
  List<Map<String, dynamic>> cust = [];
  Map<String, Map<String, dynamic>> del = {};
  String get d => DateFormat('yyyy-MM-dd').format(day);

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final c = await db.from('customers').select().eq('is_active', true).order('name');
    final x = await db.from('deliveries').select().eq('date', d);
    if (!mounted) return;
    setState(() {
      cust = List<Map<String, dynamic>>.from(c);
      del = {for (final r in x) r['customer_id'] as String: Map<String, dynamic>.from(r)};
    });
  }

  Future<void> toggle(Map<String, dynamic> c) async {
    final id = c['id'] as String;
    if (del.containsKey(id)) {
      await db.from('deliveries').delete().eq('id', del[id]!['id']);
    } else {
      final row = await db.from('deliveries')
          .insert({'customer_id': id, 'date': d, 'qty_litre': c['default_qty_litre']}).select().single();
      await notify(row['id'] as String, c, c['default_qty_litre']);
    }
    load();
  }

  Future<void> notify(String deliveryId, Map<String, dynamic> c, Object qty) async {
    try {
      final r = await db.functions.invoke('send-whatsapp', body: {'delivery_id': deliveryId});
      if (r.status != 200) throw 'failed';
    } catch (_) {
      final t = Uri.encodeComponent('Samarth Dairy: Hello ${c['name']}, $qty L milk delivered on $d. Thank you!');
      await launchUrl(Uri.parse('https://wa.me/91${c['phone']}?text=$t'), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> editQty(Map<String, dynamic> c) async {
    final row = del[c['id']];
    if (row == null) return;
    final ctl = TextEditingController(text: '${row['qty_litre']}');
    final v = await showDialog<double>(context: context, builder: (_) => AlertDialog(
      title: Text('Litres for ${c['name']}'),
      content: TextField(controller: ctl, keyboardType: TextInputType.number),
      actions: [TextButton(onPressed: () => Navigator.pop(context, double.tryParse(ctl.text)), child: const Text('Save'))]));
    if (v != null && v > 0) { await db.from('deliveries').update({'qty_litre': v}).eq('id', row['id']); load(); }
  }

  @override
  Widget build(BuildContext context) {
    final litres = del.values.fold<double>(0, (a, r) => a + (r['qty_litre'] as num).toDouble());
    return Column(children: [
      ListTile(
        title: Text(DateFormat('EEE, d MMM yyyy').format(day)),
        subtitle: Text('Delivered ${del.length}/${cust.length} · ${litres.toStringAsFixed(1)} L'),
        trailing: const Icon(Icons.calendar_month),
        onTap: () async {
          final p = await showDatePicker(context: context, initialDate: day, firstDate: DateTime(2024), lastDate: DateTime(2100));
          if (p != null) { day = p; load(); }
        },
      ),
      Expanded(child: RefreshIndicator(onRefresh: load, child: ListView(children: [
        for (final c in cust)
          ListTile(
            title: Text(c['name']),
            subtitle: Text('${del[c['id']]?['qty_litre'] ?? c['default_qty_litre']} L · ${c['address'] ?? ''}'),
            onLongPress: () => editQty(c),
            trailing: IconButton.filled(
              isSelected: del.containsKey(c['id']),
              icon: const Icon(Icons.check),
              onPressed: () => toggle(c),
            ),
          ),
      ]))),
    ]);
  }
}
