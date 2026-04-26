
import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final String? numericId;

  UserData({
    required this.uid,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.numericId,
  });

  factory UserData.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      numericId: data['numericId'],
    );
  }
}
