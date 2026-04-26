
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftCategory {
  final String id;
  final String name;

  GiftCategory({required this.id, required this.name});

  factory GiftCategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GiftCategory(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
