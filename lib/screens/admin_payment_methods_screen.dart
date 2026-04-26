import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method.dart';

class AdminPaymentMethodsScreen extends StatefulWidget {
  const AdminPaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  _AdminPaymentMethodsScreenState createState() => _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState extends State<AdminPaymentMethodsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  Future<void> _deleteMethod(String id) async {
    try {
      await _firestore.collection('paymentMethods').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف طريقة الدفع بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddMethodDialog() {
    _nameController.clear();
    _detailsController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة طريقة دفع جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الطريقة (مثلاً: فودافون كاش)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'التفاصيل / رقم الحساب (سيتمكن المستخدم من نسخه)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty && _detailsController.text.trim().isNotEmpty) {
                try {
                  await _firestore.collection('paymentMethods').add({
                    'name': _nameController.text.trim(),
                    'details': _detailsController.text.trim(),
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة طريقة الدفع بنجاح'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في الإضافة: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة طرق الدفع'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('paymentMethods')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ ما: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طرق دفع مضافة'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var method = PaymentMethod.fromFirestore(doc);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(method.details),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMethod(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMethodDialog,
        child: const Icon(Icons.add),
        tooltip: 'إضافة طريقة دفع',
      ),
    );
  }
}