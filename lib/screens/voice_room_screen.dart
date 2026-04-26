
// TODO (Next Steps):
// 1. [High Priority] Implement a secure Token Server for Agora to replace the
//    current insecure channel joining method. This is crucial for production.
// 2. Consider adding room categories/tags for better discovery.
// 3. Enhance user profiles with more details (bio, social links, etc.).
//
// --- Last Session Summary ---
// - Implemented the complete "Raise Hand" feature (UI, Service, Model).
// - Added the `audioplayers` package for sound effects.
// - Implemented a sound effect when a user sends a gift.

import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/models/gift.dart';
import 'package:go_social/models/user_model.dart';
import 'package:go_social/models/voice_room.dart';
import 'package:go_social/services/agora_service.dart';
import 'package:go_social/services/gift_service.dart';
import 'package:go_social/services/user_service.dart';
import 'package:go_social/services/voice_room_service.dart';
import 'package:go_social/widgets/quantity_input_dialog.dart';
import 'package:go_social/widgets/user_profile_dialog.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String roomId;

  const VoiceRoomScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _VoiceRoomScreenState createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final _roomService = VoiceRoomService();
  final _userService = UserService();
  final _giftService = GiftService();
  final _agoraService = AgoraService();
  final _audioPlayer = AudioPlayer(); // Create an audio player instance
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _textController = TextEditingController();
  bool _isSendingGift = false;

  @override
  void initState() {
    super.initState();
    _joinRoom();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _agoraService.addListener(_onAgoraStateChanged);
    await _agoraService.initialize();
    await _agoraService.joinChannel(widget.roomId);
  }

  void _onAgoraStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _joinRoom() async {
    try {
      await _roomService.joinRoom(widget.roomId, _currentUser.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _agoraService.removeListener(_onAgoraStateChanged);
    _agoraService.dispose();
    _audioPlayer.dispose(); // Dispose the audio player
    _roomService.leaveRoom(widget.roomId, _currentUser.uid);
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      _roomService.sendRoomMessage(widget.roomId, _currentUser.uid, _textController.text.trim());
      _textController.clear();
    }
  }
  
  // ... build methods are unchanged ...

    @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _roomService.getRoomStream(widget.roomId),
      builder: (context, roomSnapshot) {
        if (!roomSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final room = VoiceRoom.fromDoc(roomSnapshot.data!);
        final isModerator = room.moderators.contains(_currentUser.uid);

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (isModerator)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () => _showAdminMenu(room),
                ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              // ... (UI remains the same)
               if (room.imageUrl.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(image: NetworkImage(room.imageUrl), fit: BoxFit.cover),
                  ),
                )
              else
                Container(height: 100, color: Colors.grey[200]),

              _buildParticipantsSection('Speakers', room.speakers, room, isModerator),
              _buildParticipantsSection('Listeners', room.listeners, room, isModerator),
              _buildEventsList(),
              _buildInputBar(room),
            ],
          ),
        );
      },
    );
  }

   Widget _buildParticipantsSection(String title, List<String> userIds, VoiceRoom room, bool isModerator) {
    if (userIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                return _buildParticipantAvatar(userIds[index], room, isModerator);
              },
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(String userId, VoiceRoom room, bool isModerator) {
    final bool isCurrentUser = userId == _currentUser.uid;
    final bool isSpeaking = isCurrentUser && (_agoraService.activeSpeakerUid == null || _agoraService.activeSpeakerUid == 0) && !_agoraService.isMuted;

    return FutureBuilder<UserModel?>(
      future: _userService.getUser(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: CircleAvatar(radius: 30));
        }
        final user = snapshot.data!;
        final bool isTargetModerator = room.moderators.contains(userId);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              GestureDetector(
                 onTap: () {
                  if (!isCurrentUser) {
                    showDialog(
                      context: context,
                      builder: (_) => UserProfileDialog(user: user),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSpeaking
                      ? Border.all(color: Colors.green, width: 3)
                      : null,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(radius: 30, backgroundImage: NetworkImage(user.profileImageUrl)),
                      if (isCurrentUser && _agoraService.isMuted)
                        const Positioned(bottom: 0, right: 0, child: Icon(Icons.mic_off, color: Colors.red, size: 20)),
                      if (isTargetModerator) const Positioned(top: 0, left: 0, child: Icon(Icons.shield, color: Colors.blue, size: 20)),
                      if (isModerator && !isCurrentUser)
                        Positioned(top:0, right:0, child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          onSelected: (value) => _onParticipantAction(value, userId, room),
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(value: 'toggle_moderator', child: Text('Toggle Moderator')),
                            const PopupMenuItem<String>(value: 'ban', child: Text('Ban from Room', style: TextStyle(color: Colors.red))),
                          ],
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(user.username, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }


  Widget _buildInputBar(VoiceRoom room) {
    final bool isListener = room.listeners.contains(_currentUser.uid);
    final bool hasRaisedHand = room.raisedHands.contains(_currentUser.uid);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Row(
          children: [
            // Show Mute/Unmute for speakers, or Hand-Raise for listeners
            if (isListener)
              IconButton(
                icon: Icon(Icons.pan_tool, color: hasRaisedHand ? Colors.amber : Colors.grey),
                tooltip: hasRaisedHand ? 'Lower Hand' : 'Raise Hand to Speak',
                onPressed: () {
                  if (hasRaisedHand) {
                    _roomService.lowerHand(widget.roomId, _currentUser.uid);
                  } else {
                    _roomService.raiseHand(widget.roomId, _currentUser.uid);
                  }
                },
              )
            else // User is a speaker
              IconButton(
                icon: Icon(_agoraService.isMuted ? Icons.mic_off : Icons.mic, color: _agoraService.isMuted ? Colors.red : null),
                onPressed: () => _agoraService.toggleMute(),
              ),
            
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                 decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.sticky_note_2_outlined), onPressed: _showStickerSheet),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration.collapsed(hintText: 'Send a message...'),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 28),
              onPressed: () => _showRecipientPicker(room),
            ),
          ],
        ),
      ),
    );
  }

   void _showAdminMenu(VoiceRoom room) {
    showModalBottomSheet(context: context, builder: (context) {
      final handRaiseCount = room.raisedHands.length;
      return Wrap(
        children: [
          if (handRaiseCount > 0)
            ListTile(
              leading: Badge(label: Text(handRaiseCount.toString()), child: const Icon(Icons.pan_tool)),
              title: const Text('Speaking Requests'),
              onTap: () {
                Navigator.pop(context);
                _showHandRaiseRequests(room);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Change Room Name'),
            onTap: () {
              Navigator.pop(context);
              _showUpdateRoomNameDialog(room);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Change Room Image'),
            onTap: () {
              Navigator.pop(context);
              _showUpdateRoomImageDialog(room);
            },
          ),
          ListTile(
            leading: Icon(room.isPrivate ? Icons.lock_open : Icons.lock),
            title: Text(room.isPrivate ? 'Make Room Public' : 'Make Room Private'),
            onTap: () {
              Navigator.pop(context);
              _roomService.setRoomPrivacy(widget.roomId, !room.isPrivate);
            },
          ),
        ],
      );
    });
  }

  void _showHandRaiseRequests(VoiceRoom room) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Speaking Requests', style: Theme.of(context).textTheme.headline6),
              ),
              if (room.raisedHands.isEmpty)
                const ListTile(title: Text('No requests at the moment.')),
              Expanded(
                child: ListView.builder(
                  itemCount: room.raisedHands.length,
                  itemBuilder: (context, index) {
                    final userId = room.raisedHands[index];
                    return FutureBuilder<UserModel?>(
                      future: _userService.getUser(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const ListTile(title: Text('Loading...'));
                        final user = snapshot.data!;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(user.profileImageUrl)),
                          title: Text(user.username),
                          trailing: ElevatedButton(
                            child: const Text('Accept'),
                            onPressed: () {
                              _roomService.acceptHandRaise(widget.roomId, userId);
                              if (room.raisedHands.length == 1) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSendGift(Gift gift, int quantity, List<String> receiverIds) async {
    if (_isSendingGift) return;

    if (mounted) setState(() { _isSendingGift = true; });

    try {
      final totalCost = gift.cost * quantity;
      await _userService.updateUserCoins(_currentUser.uid, -totalCost);

      for (final receiverId in receiverIds) {
        await _userService.updateUserCoins(receiverId, gift.cost * quantity);
      }

      await _roomService.sendGiftEvent(
        roomId: widget.roomId,
        senderId: _currentUser.uid,
        receiverIds: receiverIds,
        giftName: gift.name,
        giftImageUrl: gift.imageUrl,
        quantity: quantity,
      );
      
      // Play sound effect!
      _audioPlayer.play(AssetSource('sounds/gift_sent.mp3'));

      if (mounted) {
        Navigator.pop(context); // Close the gift sheet
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending gift: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isSendingGift = false; });
      }
    }
  }

  // ... (rest of the file is unchanged)
   void _showStickerSheet() {
      final List<String> _stickers = ['https://media.giphy.com/media/l0HlJzN6m2fA0j2Jq/giphy.gif', 'https://media.giphy.com/media/3o7WTxyMSHRaV2nvrG/giphy.gif', 'https://media.giphy.com/media/3o6ZtpxS4iB4A9gV4A/giphy.gif', 'https://media.giphy.com/media/l41lWdY0A4ElWkO3e/giphy.gif'];
      showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _stickers.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                _roomService.sendStickerEvent(
                  roomId: widget.roomId,
                  senderId: _currentUser.uid,
                  stickerUrl: _stickers[index],
                );
                Navigator.pop(context); // Close the sheet
              },
              child: Image.network(_stickers[index]),
            );
          },
        ),
      ),
    );
  }

   void _showRecipientPicker(VoiceRoom room) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final allParticipants = (room.speakers + room.listeners).toSet().toList();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Send Gift To:', style: Theme.of(context).textTheme.headline6),
              ),
              if (room.speakers.length > 1) 
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.blue),
                  title: const Text('All Speakers'),
                  onTap: () {
                    Navigator.pop(context);
                    final recipients = room.speakers.where((id) => id != _currentUser.uid).toList();
                    if (recipients.isNotEmpty) {
                       _showGiftSelectionSheet(recipients);
                    }
                  },
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: allParticipants.length,
                  itemBuilder: (context, index) {
                    final userId = allParticipants[index];
                    if (userId == _currentUser.uid) return const SizedBox.shrink();

                    return FutureBuilder<UserModel?>(
                      future: _userService.getUser(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const ListTile(title: Text('Loading...'));
                        final user = snapshot.data!;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(user.profileImageUrl)),
                          title: Text(user.username),
                          onTap: () {
                            Navigator.pop(context);
                            _showGiftSelectionSheet([userId]);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGiftSelectionSheet(List<String> receiverIds) {
    showModalBottomSheet(
      context: context,
      isScrollcontrolled: true, 
      builder: (context) {
        return StreamBuilder<List<Gift>>(
          stream: _giftService.getGifts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final gifts = snapshot.data!;
            final categories = gifts.map((g) => g.category).toSet().toList();

            return DefaultTabController(
              length: categories.length,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: categories.map((c) => Tab(text: c)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: categories.map((category) {
                          final categoryGifts = gifts.where((g) => g.category == category).toList();
                          return GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16,
                            ),
                            itemCount: categoryGifts.length,
                            itemBuilder: (context, index) {
                              final gift = categoryGifts[index];
                              return GestureDetector(
                                onTap: () => _handleSendGift(gift, 1, receiverIds),
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => QuantityInputDialog(
                                      giftName: gift.name,
                                      onConfirm: (quantity) {
                                        _handleSendGift(gift, quantity, receiverIds);
                                      },
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(gift.imageUrl, height: 40, fit: BoxFit.contain),
                                    const SizedBox(height: 4),
                                    Text(gift.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    Text(gift.cost.toString(), style: const TextStyle(fontSize: 10, color: Colors.amber)),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

   Widget _buildEventsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _roomService.getRoomEventsStream(widget.roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              final type = event['type'] ?? 'chat';

              if (type == 'chat') return _buildChatEvent(event);
              if (type == 'sticker') return _buildStickerEvent(event);
              if (type == 'gift') return _buildGiftEvent(event);
              
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

   Widget _buildChatEvent(Map<String, dynamic> event) {
    return FutureBuilder<UserModel?>(
        future: _userService.getUser(event['senderId']),
        builder: (context, userSnapshot) {
          if(!userSnapshot.hasData) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(text: '${userSnapshot.data!.username}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: event['text']),
                ],
              ),
            ),
          );
        }
    );
  }

   Widget _buildStickerEvent(Map<String, dynamic> event) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUser(event['senderId']),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(userSnapshot.data!.profileImageUrl),
                radius: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userSnapshot.data!.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
                    child: Image.network(event['stickerUrl']),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftEvent(Map<String, dynamic> event) {
    final List<String> receiverIds = List<String>.from(event['receiverIds'] ?? []);
    final int quantity = event['quantity'] ?? 1;
    if (receiverIds.isEmpty) return const SizedBox.shrink();

    return FutureBuilder(
      future: Future.wait([
         _userService.getUser(event['senderId']),
         ...receiverIds.map((id) => _userService.getUser(id))
      ]),
      builder: (context, AsyncSnapshot<List<UserModel?>> snapshot) {
         if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final sender = snapshot.data![0];
        final receivers = snapshot.data!.sublist(1).where((u) => u != null).cast<UserModel>().toList();

        if (sender == null || receivers.isEmpty) return const SizedBox.shrink();

        String receiverText;
        if (receivers.length > 2) {
           receiverText = '${receivers[0].username}, ${receivers[1].username} & ${receivers.length - 2} others';
        } else {
           receiverText = receivers.map((u) => u.username).join(', ');
        }

        final giftText = '${sender.username} sent ${quantity > 1 ? '$quantity ' : ''}${event['giftName']}${quantity > 1 ? 's' : ''} to ${receiverText}!';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(event['giftImageUrl'], height: 40, width: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(giftText, textAlign: TextAlign.center,),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showUpdateRoomNameDialog(VoiceRoom room) {
    final _nameController = TextEditingController(text: room.name);
     showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Change Room Name'),
        content: TextField(controller: _nameController), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
               if (_nameController.text.isNotEmpty) {
                  _roomService.updateRoomDetails(widget.roomId, name: _nameController.text);
                  Navigator.pop(context);
               }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUpdateRoomImageDialog(VoiceRoom room) {
    final _imageUrlController = TextEditingController(text: room.imageUrl);
     showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Change Room Image'),
        content: TextField(
          controller: _imageUrlController,
          decoration: const InputDecoration(hintText: 'Enter Image URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
               _roomService.updateRoomDetails(widget.roomId, imageUrl: _imageUrlController.text);
               Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _onParticipantAction(String action, String targetUserId, VoiceRoom room) {
    if (action == 'toggle_moderator') {
      _roomService.toggleModerator(room.id, targetUserId);
    } else if (action == 'ban') {
      _roomService.banUser(widget.roomId, targetUserId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User has been banned.')));
    }
  }
}
