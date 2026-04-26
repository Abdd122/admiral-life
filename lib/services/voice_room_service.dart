
import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceRoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'voice_rooms';

  Stream<QuerySnapshot> getRoomsStream() {
    return _firestore.collection(_collectionPath).where('isPrivate', isEqualTo: false).orderBy('createdAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection(_collectionPath).doc(roomId).snapshots();
  }

  Future<String> createRoom(String name, String creatorId) async {
    final roomRef = await _firestore.collection(_collectionPath).add({
      'name': name,
      'creatorId': creatorId,
      'imageUrl': '',
      'isPrivate': false,
      'speakers': [creatorId],
      'listeners': [],
      'moderators': [creatorId], // Creator is the first moderator
      'bannedUsers': [],
      'raisedHands': [], // Initialize the new field
      'createdAt': FieldValue.serverTimestamp(),
    });
    return roomRef.id;
  }

  // --- Participant Management ---
  Future<void> joinRoom(String roomId, String userId) async {
    final roomDoc = await _firestore.collection(_collectionPath).doc(roomId).get();
    final bannedUsers = List<String>.from(roomDoc.data()?['bannedUsers'] ?? []);
    if (bannedUsers.contains(userId)) {
      throw Exception('You are banned from this room.');
    }
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'listeners': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'listeners': FieldValue.arrayRemove([userId]),
      'speakers': FieldValue.arrayRemove([userId]),
      'raisedHands': FieldValue.arrayRemove([userId]), // Also remove from raised hands on leave
    });
  }

  // --- Hand Raise Management ---
  Future<void> raiseHand(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'raisedHands': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> lowerHand(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'raisedHands': FieldValue.arrayRemove([userId])
    });
  }

  Future<void> acceptHandRaise(String roomId, String userId) async {
    // Move user from listeners to speakers and remove from raised hands
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'listeners': FieldValue.arrayRemove([userId]),
      'speakers': FieldValue.arrayUnion([userId]),
      'raisedHands': FieldValue.arrayRemove([userId]),
    });
  }

  // --- Room Administration ---
  Future<void> updateRoomDetails(String roomId, {String? name, String? imageUrl}) async {
    final Map<String, dynamic> dataToUpdate = {};
    if (name != null) dataToUpdate['name'] = name;
    if (imageUrl != null) dataToUpdate['imageUrl'] = imageUrl;
    if (dataToUpdate.isNotEmpty) {
      await _firestore.collection(_collectionPath).doc(roomId).update(dataToUpdate);
    }
  }

  Future<void> setRoomPrivacy(String roomId, bool isPrivate) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({'isPrivate': isPrivate});
  }

  Future<void> addModerator(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'moderators': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> removeModerator(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'moderators': FieldValue.arrayRemove([userId])
    });
  }
  
  Future<void> toggleModerator(String roomId, String userId) async {
    final doc = await _firestore.collection(_collectionPath).doc(roomId).get();
    final moderators = List<String>.from(doc.data()?['moderators'] ?? []);
    if (moderators.contains(userId)) {
      await removeModerator(roomId, userId);
    } else {
      await addModerator(roomId, userId);
    }
  }

  Future<void> banUser(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'bannedUsers': FieldValue.arrayUnion([userId]),
      'speakers': FieldValue.arrayRemove([userId]),
      'listeners': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> unbanUser(String roomId, String userId) async {
    await _firestore.collection(_collectionPath).doc(roomId).update({
      'bannedUsers': FieldValue.arrayRemove([userId])
    });
  }

  // --- In-Room Events ---
  Stream<QuerySnapshot> getRoomEventsStream(String roomId) {
    return _firestore.collection(_collectionPath).doc(roomId).collection('events').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> sendRoomMessage(String roomId, String senderId, String text) async {
    await _firestore.collection(_collectionPath).doc(roomId).collection('events').add({
      'type': 'chat',
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendStickerEvent({required String roomId, required String senderId, required String stickerUrl}) async {
    await _firestore.collection(_collectionPath).doc(roomId).collection('events').add({
      'type': 'sticker',
      'senderId': senderId,
      'stickerUrl': stickerUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendGiftEvent({
    required String roomId,
    required String senderId,
    required List<String> receiverIds,
    required String giftName,
    required String giftImageUrl,
    required int quantity,
  }) async {
    await _firestore.collection(_collectionPath).doc(roomId).collection('events').add({
      'type': 'gift',
      'senderId': senderId,
      'receiverIds': receiverIds,
      'giftName': giftName,
      'giftImageUrl': giftImageUrl,
      'quantity': quantity, // Save the quantity
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
