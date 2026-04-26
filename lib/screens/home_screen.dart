
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/screens/auth/auth_screen.dart';
import 'package:go_social/screens/create_post_screen.dart';
import 'package:go_social/screens/profile_screen.dart';
import 'package:go_social/screens/notifications_screen.dart'; // <-- Import notifications screen
import '../widgets/post_feed_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GoSocial'),
        actions: <Widget>[
          // Notification Button
          IconButton(
            icon: const Icon(Icons.notifications_none), // TODO: Add a badge for unread notifications
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          // Profile & Sign Out Menu
          if (currentUser != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.person),
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(userId: currentUser.uid)),
                  );
                } else if (value == 'signOut') {
                  _signOut(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Text('My Profile'),
                ),
                const PopupMenuItem<String>(
                  value: 'signOut',
                  child: Text('Sign Out'),
                ),
              ],
            ),
        ],
      ),
      body: const PostFeedWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
