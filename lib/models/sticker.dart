
import 'package:cloud_firestore/cloud_firestore.dart';

class Sticker {
  final String id;
  final String imageUrl;
  final String packId;

  Sticker({
    required this.id,
    required this.imageUrl,
    required this.packId,
  });

  factory Sticker.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sticker(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      packId: data['packId'] ?? '',
    );
  }
}

class StickerPack {
  final String id;
  final String name;
  final String thumbnailUrl;

  StickerPack({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory StickerPack.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StickerPack(
      id: doc.id,
      name: data['name'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
    );
  }
}
