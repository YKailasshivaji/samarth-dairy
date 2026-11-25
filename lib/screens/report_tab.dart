import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../router.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});
  @override
  State<ReportTab> createState() => _RState();
}

class _RState extends State<ReportTab> {
  DateTime m = DateTime(DateTime.now().year, DateTime.now().month);
  List<List<String>> rows = [];
  double tl = 0, ta = 0, tp = 0, tb = 0;
  static const head = ['Customer', 'Days', 'Litres', 'Bill', 'Paid', 'Due'];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final bills = await db.from('monthly_bills').select().eq('month', DateFormat('yyyy-MM-01').format(m));
    final cs = await db.from('customers').select('id,name');
    final names = {for (final c in cs) c['id'] as String: c['name'] as String};
    double l = 0, a = 0, p = 0, b = 0;
    final r = <List<String>>[];
    for (final x in bills) {
      l += (x['total_litres'] as num).toDouble();
      a += (x['total_amount'] as num).toDouble();
      p += (x['paid_amount'] as num).toDouble();
      b += (x['balance'] as num).toDouble();
      r.add([names[x['customer_id']] ?? '-', '${x['days']}', '${x['total_litres']}', '₹${x['total_amount']}', '₹${x['paid_amount']}', '₹${x['balance']}']);
    }
    r.add(['Total', '', '$l', '₹$a', '₹$p', '₹$b']);
    if (mounted) setState(() { rows = r; tl = l; ta = a; tp = p; tb = b; });
  }

  Future<void> pdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Samarth Dairy - ${DateFormat('MMMM yyyy').format(m)}', style: const pw.TextStyle(fontSize: 18)),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(headers: head, data: rows.map((r) => r.map((s) => s.replaceAll('₹', 'Rs ')).toList()).toList()),
    ])));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { m = DateTime(m.year, m.month - 1); load(); }),
          Expanded(child: Center(child: Text(DateFormat('MMMM yyyy').format(m), style: const TextStyle(fontSize: 18)))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { m = DateTime(m.year, m.month + 1); load(); }),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: pdf),
        ]),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          columns: [for (final h in head) DataColumn(label: Text(h))],
          rows: [for (final r in rows) DataRow(cells: [for (final c in r) DataCell(Text(c))])])),
      ]);
}
