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
  final pin = TextEditingController();

  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> save() async {
    if (name.text.trim().isEmpty || !RegExp(r'^\d{10}$').hasMatch(phone.text.trim())) {
      return msg('Enter name and a 10-digit phone');
    }
    if (pin.text.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pin.text)) return msg('PIN must be 6 digits');
    final phoneChanged = widget.c != null && widget.c!['phone'] != phone.text.trim();
    if ((widget.c == null || phoneChanged) && pin.text.isEmpty) return msg('Set a 6-digit PIN for login');

    final row = {
      'name': name.text.trim(), 'phone': phone.text.trim(), 'address': addr.text.trim(),
      'default_qty_litre': double.tryParse(qty.text) ?? 1, 'rate_per_litre': double.tryParse(rate.text) ?? 60,
    };
    try {
      String id;
      if (widget.c == null) {
        final r = await db.from('customers').insert(row).select().single();
        id = r['id'] as String;
      } else {
        await db.from('customers').update(row).eq('id', widget.c!['id']);
        id = widget.c!['id'] as String;
      }
      if (pin.text.isNotEmpty) {
        await db.functions.invoke('set-customer-pin', body: {'customer_id': id, 'pin': pin.text});
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) msg('$e');
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
          f(widget.c == null ? 'Login PIN (6 digits)' : 'New login PIN (leave blank to keep)', pin, TextInputType.number),
          FilledButton(onPressed: save, child: const Text('Save')),
        ]),
      );
}
