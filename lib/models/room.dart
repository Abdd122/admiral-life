
import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String ownerId;
  final String ownerName;
  final String roomName;
  final bool isActive;
  final List<String> speakerIds; // List of user IDs on seats
  final Timestamp createdAt;

  Room({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.roomName,
    required this.isActive,
    required this.speakerIds,
    required this.createdAt,
  });

  // Factory constructor to create a Room from a Firestore document
  factory Room.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      roomName: data['roomName'] ?? '',
      isActive: data['isActive'] ?? false,
      speakerIds: List<String>.from(data['speakerIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Method to convert a Room object to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'roomName': roomName,
      'isActive': isActive,
      'speakerIds': speakerIds,
      'createdAt': createdAt,
    };
  }
}
