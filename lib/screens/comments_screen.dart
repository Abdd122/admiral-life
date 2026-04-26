
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/models/comment.dart';
import 'package:go_social/services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() async {
    final String text = _commentController.text.trim();
    if (text.isNotEmpty) {
      try {
        await _postService.addComment(
          postId: widget.postId,
          userId: _currentUserId,
          text: text,
        );
        _commentController.clear(); // Clear the input field
        // Hide the keyboard
        FocusScope.of(context).unfocus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postService.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                final comments = snapshot.data!.docs.map((doc) => Comment.fromFirestore(doc)).toList();

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentTile(comment);
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment.userProfileImageUrl != null ? NetworkImage(comment.userProfileImageUrl!) : null,
        child: comment.userProfileImageUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(comment.text),
      trailing: Text(
        timeago.format(comment.timestamp.toDate()),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
        BoxShadow(offset: const Offset(0, -1), blurRadius: 2, color: Colors.black.withOpacity(0.1)),
      ]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration.collapsed(hintText: 'Add a comment...'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _postComment,
          ),
        ],
      ),
    );
  }
}
