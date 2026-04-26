
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/models/voice_room.dart';
import 'package:go_social/screens/voice_room_screen.dart';
import 'package:go_social/services/voice_room_service.dart';

class VoiceRoomListScreen extends StatefulWidget {
  const VoiceRoomListScreen({Key? key}) : super(key: key);

  @override
  _VoiceRoomListScreenState createState() => _VoiceRoomListScreenState();
}

class _VoiceRoomListScreenState extends State<VoiceRoomListScreen> {
  final _roomService = VoiceRoomService();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  void _showCreateRoomDialog() {
    final _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a Voice Room'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Room Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _createRoom(_nameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createRoom(String name) async {
    try {
      final roomId = await _roomService.createRoom(name, _currentUser.uid);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VoiceRoomScreen(roomId: roomId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: ${e.toString()}')),
      );
    }
  }

  void _joinRoom(String roomId) {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VoiceRoomScreen(roomId: roomId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Rooms'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _roomService.getRoomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active rooms. Create one!'));
          }

          final rooms = snapshot.data!.docs.map((doc) => VoiceRoom.fromDoc(doc)).toList();

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                title: Text(room.name),
                subtitle: Text('Speakers: ${room.speakers.length}, Listeners: ${room.listeners.length}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _joinRoom(room.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
