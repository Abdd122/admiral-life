import 'package:flutter/material.dart';
import 'admin_payment_requests_screen.dart';
import 'admin_gifts_screen.dart';
import 'admin_packages_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("لوحة التحكم الإدارية")),
      body: GridView.count(
        padding: EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _adminCard(context, "طلبات الشحن", Icons.payment, AdminPaymentRequestsScreen()),
          _adminCard(context, "إدارة الهدايا", Icons.card_giftcard, AdminGiftsScreen()),
          _adminCard(context, "باقات الكوينز", Icons.monetization_on, AdminPackagesScreen()),
          _adminCard(context, "المستخدمين", Icons.people, AdminUsersScreen()),
        ],
      ),
    );
  }

  Widget _adminCard(BuildContext context, String title, IconData icon, Widget? targetScreen) {
    return InkWell(
      onTap: targetScreen != null 
        ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen))
        : null,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blueAccent),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}