
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImageUrl;
  final String text;
  final Timestamp timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImageUrl,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown User',
      userProfileImageUrl: data['userProfileImageUrl'],
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
