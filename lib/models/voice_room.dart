
import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceRoom {
  final String id;
  final String name;
  final String creatorId;
  final String imageUrl;
  final bool isPrivate;
  final List<String> speakers;
  final List<String> listeners;
  final List<String> moderators;
  final List<String> bannedUsers;
  final List<String> raisedHands; // New field for users who want to speak

  VoiceRoom({
    required this.id,
    required this.name,
    required this.creatorId,
    this.imageUrl = '',
    this.isPrivate = false,
    required this.speakers,
    required this.listeners,
    required this.moderators,
    required this.bannedUsers,
    required this.raisedHands, // Add to constructor
  });

  factory VoiceRoom.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoiceRoom(
      id: doc.id,
      name: data['name'] ?? '',
      creatorId: data['creatorId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isPrivate: data['isPrivate'] ?? false,
      speakers: List<String>.from(data['speakers'] ?? []),
      listeners: List<String>.from(data['listeners'] ?? []),
      moderators: List<String>.from(data['moderators'] ?? []),
      bannedUsers: List<String>.from(data['bannedUsers'] ?? []),
      raisedHands: List<String>.from(data['raisedHands'] ?? []), // Initialize from Firestore
    );
  }
}
