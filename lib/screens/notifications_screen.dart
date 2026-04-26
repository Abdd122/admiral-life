
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_social/screens/post_detail_screen.dart';
import 'package:go_social/screens/profile_screen.dart';
import 'package:go_social/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  void _navigateToContent(DocumentSnapshot notificationDoc) {
    final notification = notificationDoc.data() as Map<String, dynamic>;
    final String type = notification['type'];

    // Mark as read first
    if (!(notification['isRead'] ?? false)) {
      _notificationService.markNotificationAsRead(notificationDoc.id);
    }

    // Navigate based on type
    if (type == 'follow') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(userId: notification['fromUserId'])),
      );
    } else if (type == 'like' || type == 'comment') {
      if (notification['postId'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailScreen(postId: notification['postId'])),
        );
      }
    }
  }

  Widget _buildListTile(DocumentSnapshot notificationDoc) {
    final notification = notificationDoc.data() as Map<String, dynamic>;
    final String type = notification['type'];
    final String fromUserName = notification['fromUserName'] ?? 'Someone';
    final bool isRead = notification['isRead'] ?? false;

    String title;
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'like':
        title = '$fromUserName liked your post.';
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        title = '$fromUserName commented on your post.';
        iconData = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'follow':
        title = '$fromUserName started following you.';
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      default:
        title = 'You have a new notification.';
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    final time = notification['timestamp'] as Timestamp?;
    final timeString = time != null ? time.toDate().toLocal().toString().substring(0, 16) : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(timeString),
      tileColor: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
      onTap: () => _navigateToContent(notificationDoc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              _notificationService.markAllNotificationsAsRead();
              ScaffoldMessenger.of(body.context).showSnackBar(
                const SnackBar(content: Text('Marked all as read.'), duration: Duration(seconds: 1)),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildListTile(notifications[index]);
            },
          );
        },
      ),
    );
  }
}
