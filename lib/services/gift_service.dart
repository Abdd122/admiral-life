import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_social/models/gift.dart';
import 'package:go_social/services/user_service.dart';

class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'gifts';

  // Get a stream of all gifts from the Firestore collection.
  Stream<List<Gift>> getGifts() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('cost', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Gift.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> sendGift({
    required String senderId,
    required String receiverId,
    required String contextId, // This can be a chatId or a roomId
    required String contextType, // 'chat' or 'voice_room'
    required Gift gift,
  }) async {
    final senderRef = _firestore.collection('users').doc(senderId);
    final userService = UserService();

    await _firestore.runTransaction((transaction) async {
      final senderDoc = await transaction.get(senderRef);

      if (!senderDoc.exists) {
        throw Exception("Sender does not exist!");
      }

      final senderData = senderDoc.data() as Map<String, dynamic>? ?? {};
      final senderCoins = senderData['coins'] as int? ?? 0;

      if (senderCoins < gift.cost) {
        throw Exception("Insufficient coins!");
      }

      // 1. Deduct coins from the sender
      transaction.update(senderRef, {'coins': FieldValue.increment(-gift.cost)});

      // 2. Reward the sender with XP equal to the gift price
      // Note: Since addExperience uses its own transaction internally, 
      // in a real production app we'd integrate the XP logic directly here 
      // to keep it within a single atomic transaction.
      await userService.addExperience(senderId, gift.cost);

      // 3. Create a gift event/message within the given context
      if (contextType == 'chat') {
        final messageRef = _firestore.collection('chats').doc(contextId).collection('messages').doc();
        transaction.set(messageRef, {
          'senderId': senderId,
          'receiverId': receiverId,
          'text': 'sent a ${gift.name}!',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'gift',
          'giftImageUrl': gift.imageUrl,
          'giftName': gift.name,
        });

        final chatRef = _firestore.collection('chats').doc(contextId);
        transaction.update(chatRef, {
          'lastMessage': '🎁 Sent a ${gift.name}',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      } else if (contextType == 'voice_room') {
        final eventRef = _firestore.collection('voice_rooms').doc(contextId).collection('events').doc();
        transaction.set(eventRef, {
          'type': 'gift_sent',
          'senderId': senderId,
          'receiverId': receiverId,
          'gift': {
            'name': gift.name,
            'imageUrl': gift.imageUrl,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 4. Send a notification to the receiver
      final receiverRef = _firestore.collection('users').doc(receiverId);
      final notificationRef = receiverRef.collection('notifications').doc();
      transaction.set(notificationRef, {
        'type': 'gift',
        'fromUserId': senderId,
        'fromUserName': senderData['name'] ?? 'Someone',
        'fromUserImageUrl': senderData['profileImageUrl'],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'giftName': gift.name,
        'giftImageUrl': gift.imageUrl,
      });
    });
  }
}