
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRequest {
  final String id;
  final String userId;
  final String packageId;
  final String receiptImageUrl;
  final String status; // e.g., 'pending', 'approved', 'rejected'
  final Timestamp timestamp;

  PaymentRequest({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.receiptImageUrl,
    required this.status,
    required this.timestamp,
  });

  factory PaymentRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      packageId: data['packageId'] ?? '',
      receiptImageUrl: data['receiptImageUrl'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'packageId': packageId,
      'receiptImageUrl': receiptImageUrl,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
