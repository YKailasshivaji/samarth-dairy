import 'package:flutter/material.dart';
import 'deliveries_tab.dart';
import 'customers_tab.dart';
import 'report_tab.dart';
import 'payments_tab.dart';
import '../router.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Samarth Dairy'),
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())]),
        body: [const DeliveriesTab(), const CustomersTab(), const ReportTab(), const PaymentsTab()][i],
        bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Payments'),
        ]),
      );
}
