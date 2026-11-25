import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';

class CustomerForm extends StatefulWidget {
  final Map<String, dynamic>? c;
  const CustomerForm({super.key, this.c});
  @override
  State<CustomerForm> createState() => _FState();
}

class _FState extends State<CustomerForm> {
  late final name = TextEditingController(text: widget.c?['name']);
  late final phone = TextEditingController(text: widget.c?['phone']);
  late final addr = TextEditingController(text: widget.c?['address']);
  late final qty = TextEditingController(text: '${widget.c?['default_qty_litre'] ?? 1}');
  late final rate = TextEditingController(text: '${widget.c?['rate_per_litre'] ?? 60}');

  Future<void> save() async {
    if (name.text.trim().isEmpty || !RegExp(r'^\d{10}$').hasMatch(phone.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter name and a 10-digit phone')));
      return;
    }
    final row = {
      'name': name.text.trim(), 'phone': phone.text.trim(), 'address': addr.text.trim(),
      'default_qty_litre': double.tryParse(qty.text) ?? 1, 'rate_per_litre': double.tryParse(rate.text) ?? 60,
    };
    try {
      if (widget.c == null) { await db.from('customers').insert(row); }
      else { await db.from('customers').update(row).eq('id', widget.c!['id']); }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget f(String l, TextEditingController c, [TextInputType? t]) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, keyboardType: t, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.c == null ? 'Add customer' : 'Edit customer')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          f('Name', name), f('Phone (10 digits)', phone, TextInputType.phone), f('Address', addr),
          f('Daily litres', qty, TextInputType.number), f('Rate per litre (₹)', rate, TextInputType.number),
          FilledButton(onPressed: save, child: const Text('Save')),
        ]),
      );
}
