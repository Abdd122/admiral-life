
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_social/screens/comments_screen.dart';
import 'package:go_social/screens/profile_screen.dart';
import 'package:go_social/services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late int _likeCount;
  late bool _isLiked;
  late int _commentCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likeCount'] ?? 0;
    _commentCount = widget.post['commentCount'] ?? 0;
    _isLiked = (widget.post['likes'] as Map<String, dynamic>?)?.containsKey(_currentUserId) ?? false;
  }

  Future<void> _handleLikePost() async {
    final String postId = widget.post['postId'];
    final bool currentlyLiked = _isLiked;

    setState(() {
      _isLiked = !currentlyLiked;
      _likeCount += !currentlyLiked ? 1 : -1;
    });

    try {
      await _postService.likePost(
        postId: postId,
        userId: _currentUserId,
        hasLiked: currentlyLiked,
      );
    } catch (e) {
      setState(() {
        _isLiked = currentlyLiked;
        _likeCount += currentlyLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: ${e.toString()}')),
      );
    }
  }

  void _navigateToComments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: widget.post['postId']),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp? timestamp = widget.post['timestamp'] as Timestamp?;
    final String timeAgo = timestamp != null ? timeago.format(timestamp.toDate()) : 'Just now';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildPostImage(),
          _buildActions(context),
          _buildLikeCount(),
          _buildCaption(context),
          _buildCommentLink(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text(timeAgo, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final username = widget.post['username'] ?? 'User';
    final profileImageUrl = widget.post['userProfileImageUrl'];
    final postUserId = widget.post['userId'];

    return InkWell(
      onTap: () => _navigateToProfile(context, postUserId),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
              child: profileImageUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage() {
    final imageUrl = widget.post['imageUrl'];
    return imageUrl != null
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          )
        : const SizedBox(height: 200, child: Center(child: Icon(Icons.image_not_supported)));
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : null,
            ),
            onPressed: _handleLikePost,
          ),
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () => _navigateToComments(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCount() {
    if (_likeCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    final caption = widget.post['caption'] ?? '';
    final username = widget.post['username'] ?? 'User';
    final postUserId = widget.post['userId'];

    if (caption.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$username ',
              style: const TextStyle(fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()..onTap = () => _navigateToProfile(context, postUserId),
            ),
            TextSpan(text: caption),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentLink(BuildContext context) {
    if (_commentCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 0),
      child: InkWell(
        onTap: () => _navigateToComments(context),
        child: Text(
          'View all $_commentCount comments',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}
