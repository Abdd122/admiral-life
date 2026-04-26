
import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');

  Future<void> createPost({
    required String userId,
    required String caption,
    required String imageUrl,
  }) async {
    final DocumentReference postRef = _postsCollection.doc();
    final DocumentReference userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw Exception("User does not exist!");
      }

      transaction.set(postRef, {
        'postId': postRef.id,
        'userId': userId,
        'username': userSnapshot.data()?['name'] ?? 'Unknown User',
        'userProfileImageUrl': userSnapshot.data()?['profileImageUrl'],
        'caption': caption,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': {},
        'likeCount': 0,
        'commentCount': 0,
      });

      transaction.update(userRef, {
        'postCount': FieldValue.increment(1),
      });
    });
  }

  Future<void> likePost({
    required String postId,
    required String userId,
    required bool hasLiked,
  }) async {
    final DocumentReference postRef = _postsCollection.doc(postId);

    return _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) {
        throw Exception("Post does not exist!");
      }

      if (hasLiked) {
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(-1),
          'likes.$userId': FieldValue.delete(),
        });
      } else {
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(1),
          'likes.$userId': true,
        });
      }
    });
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    final DocumentReference postRef = _postsCollection.doc(postId);
    final DocumentReference userRef = _firestore.collection('users').doc(userId);
    final DocumentReference commentRef = postRef.collection('comments').doc();

    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw Exception("User does not exist!");
      }
      final userData = userSnapshot.data() as Map<String, dynamic>;

      transaction.set(commentRef, {
        'commentId': commentRef.id,
        'userId': userId,
        'username': userData['name'] ?? 'Unknown User',
        'userProfileImageUrl': userData['profileImageUrl'],
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Atomically increment the post's comment count
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPostsForUserStream(String userId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getFeedStream(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.empty();
    }
    return _postsCollection
        .where('userId', whereIn: userIds)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }
}
