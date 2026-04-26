
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_social/models/user.dart' as app_user;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the 'users' collection with a converter
  CollectionReference<app_user.User> get _usersCollection =>
      _firestore.collection('users').withConverter<app_user.User>(
            fromFirestore: (snapshots, _) => app_user.User.fromFirestore(snapshots),
            toFirestore: (user, _) => user.toJson(),
          );

  /// Creates a user document in Firestore if one doesn't already exist.
  /// This is typically called right after a user signs up or signs in for the first time.
  Future<void> createUserDocument({
    required String userId,
    String? email,
    String? phoneNumber,
    String? displayName,
  }) async {
    final docRef = _usersCollection.doc(userId);
    final doc = await docRef.get();

    // If the document does not exist, create it with default values.
    if (!doc.exists) {
      final newUser = app_user.User(
        id: userId,
        username: displayName ?? '', // Default to empty, user can set it up in their profile
        email: email ?? '',
        phoneNumber: phoneNumber ?? '',
        photoUrl: '', // Default empty avatar
        bio: 'Hello! I am new here.',
        followers: [],
        following: [],
        coins: 0,
        avatarIndex: 0,
        role: 'user',
        profileFrameUrl: '',
      );
      await docRef.set(newUser);
    }
  }

  /// Fetches a single user document from Firestore.
  Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }
}
