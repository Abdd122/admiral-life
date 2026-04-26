
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/models/user_model.dart';
import 'package:go_social/screens/private_chat_screen.dart';
import 'package:go_social/services/chat_service.dart';

class UserProfileDialog extends StatelessWidget {
  final UserModel user;

  const UserProfileDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _chatService = ChatService();
    final _currentUser = FirebaseAuth.instance.currentUser!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.profileImageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Coins: ${user.coins}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.amber),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Private Chat'),
              onPressed: () async {
                // 1. Get or create the chat room
                final chatRoomId = await _chatService.getOrCreateChatRoom(_currentUser.uid, user.id);
                
                // 2. Close the dialog
                Navigator.pop(context);

                // 3. Navigate to the chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivateChatScreen(
                      chatRoomId: chatRoomId,
                      otherUserId: user.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
