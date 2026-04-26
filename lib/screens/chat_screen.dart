
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_social/models/gift.dart';
import 'package:go_social/models/sticker.dart';
import 'package:go_social/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_social/services/gift_service.dart';
import 'package:go_social/services/sticker_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId; // Added receiverId for sending gifts
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _giftService = GiftService();
  final _stickerService = StickerService(); // Instantiate StickerService
  final _textController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  void _sendMessage() {
    _chatService.sendMessage(widget.chatId, _currentUser.uid, _textController.text);
    _textController.clear();
  }

  void _showGiftPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Gift>>(
          future: _giftService.getGifts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No gifts available right now.'));
            }

            final gifts = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return InkWell(
                  onTap: () => _confirmSendGift(gift),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(gift.imageUrl, height: 50, width: 50),
                      const SizedBox(height: 4),
                      Text(gift.name, overflow: TextOverflow.ellipsis),
                      Text('${gift.price} Coins', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmSendGift(Gift gift) {
    Navigator.pop(context); // Close the bottom sheet first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Gift?'),
        content: Text('Do you want to send the ${gift.name} to ${widget.receiverName} for ${gift.price} coins?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Send'),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _sendGift(gift);
            },
          ),
        ],
      ),
    );
  }

  void _sendGift(Gift gift) async {
    try {
      await _giftService.sendGift(
        senderId: _currentUser.uid,
        receiverId: widget.receiverId,
        contextId: widget.chatId,
        contextType: 'chat',
        gift: gift,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully sent ${gift.name}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send gift: ${e.toString()}')),
      );
    }
  }

  void _showStickerPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder<List<StickerPack>>(
              future: _stickerService.getStickerPacks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final packs = snapshot.data!;
                return DefaultTabController(
                  length: packs.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: packs.map((pack) => Tab(text: pack.name)).toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: packs.map((pack) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: _stickerService.getStickersInPack(pack.id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final stickers = snapshot.data!.docs;
                                return GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: stickers.length,
                                  itemBuilder: (context, index) {
                                    final stickerDoc = stickers[index];
                                    final sticker = Sticker.fromDoc(stickerDoc);
                                    return InkWell(
                                      onTap: () => _sendSticker(sticker),
                                      child: Image.network(sticker.imageUrl, height: 80, width: 80),
                                    );
                                  },
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _sendSticker(Sticker sticker) {
    Navigator.pop(context); // Close the bottom sheet
    _chatService.sendSticker(widget.chatId, _currentUser.uid, sticker.imageUrl);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == _currentUser.uid;
                    final type = message['type'] ?? 'text';

                    if (type == 'gift') {
                      return _buildGiftMessage(message, isMe);
                    }
                    if (type == 'sticker') {
                      return _buildStickerMessage(message, isMe);
                    }

                    return _buildTextMessage(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTextMessage(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[600] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildGiftMessage(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text('${isMe ? 'You' : widget.receiverName} sent a ${message['giftName']}', style: const TextStyle(color: Colors.grey)),
            Image.network(message['giftImageUrl'], height: 80, width: 80),
          ],
        ),
      ),
    );
  }

    Widget _buildStickerMessage(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Image.network(message['imageUrl'], height: 100, width: 100),
      ),
    );
  }


  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.redAccent),
            onPressed: _showGiftPanel, // Connect the button
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
            onPressed: _showStickerPanel, // Connect the button
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
