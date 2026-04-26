
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'private_chats';

  // Generates a unique, consistent chat room ID for any two users.
  String getChatRoomId(String userId1, String userId2) {
    if (userId1.hashCode <= userId2.hashCode) {
      return '$userId1-$userId2';
    } else {
      return '$userId2-$userId1';
    }
  }

  // Creates a chat room if it doesn't exist.
  Future<String> getOrCreateChatRoom(String userId1, String userId2) async {
    final chatRoomId = getChatRoomId(userId1, userId2);
    final roomRef = _firestore.collection(_collectionPath).doc(chatRoomId);

    final doc = await roomRef.get();
    if (!doc.exists) {
      // Create the chat room with participants info for easy querying later
      await roomRef.set({
        'participants': [userId1, userId2],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }
    return chatRoomId;
  }

  // Send a message in a private chat
  Future<void> sendMessage(String chatRoomId, String senderId, String text) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Add the new message to the messages subcollection
    await _firestore
        .collection(_collectionPath)
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update the last message on the parent chat room document for previews
    await _firestore.collection(_collectionPath).doc(chatRoomId).update({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get a stream of messages for a chat room
  Stream<QuerySnapshot> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection(_collectionPath)
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get a stream of all of a user's chat rooms for a chat list screen
  Stream<QuerySnapshot> getUserChatsStream(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
}
