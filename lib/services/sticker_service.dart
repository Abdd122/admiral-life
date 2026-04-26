
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_social/models/sticker.dart';

class StickerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches the list of available sticker packs
  Future<List<StickerPack>> getStickerPacks() async {
    try {
      final querySnapshot = await _firestore.collection('sticker_packs').get();
      return querySnapshot.docs.map((doc) => StickerPack.fromDoc(doc)).toList();
    } catch (e) {
      print("Error fetching sticker packs: $e");
      return [];
    }
  }

  // Fetches all stickers within a specific pack
  Stream<QuerySnapshot> getStickersInPack(String packId) {
    return _firestore
        .collection('sticker_packs')
        .doc(packId)
        .collection('stickers')
        .snapshots();
  }
}
