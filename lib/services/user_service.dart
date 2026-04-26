import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_social/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  // Get user details as a future
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(_collectionPath).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDoc(doc);
    }
    return null;
  }

  // Get user details as a stream
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection(_collectionPath).doc(uid).snapshots();
  }

  // Create a new user document
  Future<void> createUser(String uid, String username) async {
    await _firestore.collection(_collectionPath).doc(uid).set({
      'username': username,
      'uid': uid,
      // A default profile image
      'profileImageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/009/292/244/small/default-avatar-icon-of-social-media-user-vector.jpg',
      'coins': 100, // Starting coins
      'xp': 0, // Initial experience points
      'level': 1, // Initial level
    });
  }

  // Update a user's profile image URL
  Future<void> updateUserProfileImage(String uid, String newImageUrl) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'profileImageUrl': newImageUrl,
    });
  }
  
  // Add or subtract coins from a user's balance
  Future<void> updateUserCoins(String uid, int amount) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'coins': FieldValue.increment(amount),
    });
  }

  // Add experience and update level accordingly
  Future<void> addExperience(String userId, int amount) async {
    final userRef = _firestore.collection(_collectionPath).doc(userId);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception("User does not exist!");
      }

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      int currentXp = data['xp'] ?? 0;
      int currentLevel = data['level'] ?? 1;

      int newXp = currentXp + amount;
      int newLevel = (sqrt(newXp / 100).floor()) + 1;

      if (newLevel > currentLevel) {
        transaction.update(userRef, {
          'xp': newXp,
          'level': newLevel,
        });
      } else {
        transaction.update(userRef, {
          'xp': newXp,
        });
      }
    });
  }
}