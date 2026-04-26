import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String details;
  final bool isActive;
  final Timestamp createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.details,
    required this.isActive,
    required this.createdAt,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      name: data['name'] ?? '',
      details: data['details'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'details': details,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}