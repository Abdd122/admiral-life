
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_social/widgets/post_card_widget.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').doc(postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
             return const Center(child: Text('Post not found. It may have been deleted.'));
          }

          final post = snapshot.data!;
          // Use a ListView to ensure the content is scrollable and avoid overflow
          return ListView(
            children: [
              PostCardWidget(post: post),
            ],
          );
        },
      ),
    );
  }
}
