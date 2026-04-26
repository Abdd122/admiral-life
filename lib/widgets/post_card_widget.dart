
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/screens/comments_screen.dart';
import 'package:go_social/screens/profile_screen.dart';
import 'package:go_social/services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCardWidget extends StatefulWidget {
  final QueryDocumentSnapshot post;

  const PostCardWidget({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardWidgetState createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late Map<String, dynamic> _postData;

  // For the double-tap like animation
  bool _isLikeAnimationVisible = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _postData = widget.post.data() as Map<String, dynamic>;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final currentLikes = Map<String, dynamic>.from(_postData['likes'] ?? {});
    final bool isCurrentlyLiked = currentLikes[_currentUserId] == true;

    // Optimistic UI update
    setState(() {
      if (isCurrentlyLiked) {
        currentLikes.remove(_currentUserId);
        _postData['likeCount'] = (_postData['likeCount'] ?? 1) - 1;
      } else {
        currentLikes[_currentUserId] = true;
        _postData['likeCount'] = (_postData['likeCount'] ?? 0) + 1;
      }
      _postData['likes'] = currentLikes;
    });

    try {
      await _postService.toggleLikeStatus(widget.post.id, Map<String, dynamic>.from(widget.post['likes'] ?? {}));
    } catch (e) {
      // Revert UI on error if needed
      print("Error toggling like: $e");
    }
  }

  void _handleDoubleTap() {
    final currentLikes = Map<String, dynamic>.from(_postData['likes'] ?? {});
    if (currentLikes[_currentUserId] != true) {
      _toggleLike();
    }
    
    // Trigger the heart animation
    setState(() => _isLikeAnimationVisible = true);
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        setState(() => _isLikeAnimationVisible = false);
      });
    });
  }

  void _deletePost() async {
    try {
      await _postService.deletePost(widget.post.id, _postData['imageUrl']);
      // Optionally, show a confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = _postData['likes'][_currentUserId] == true;
    final int likeCount = _postData['likeCount'] ?? 0;
    final Timestamp timestamp = _postData['createdAt'] ?? Timestamp.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildHeader(),
          // Post Image (with double tap detector)
          if (_postData['imageUrl'] != null)
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(_postData['imageUrl'], width: double.infinity, fit: BoxFit.cover),
                  if (_isLikeAnimationVisible)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: const Icon(Icons.favorite, color: Colors.white, size: 80),
                    ),
                ],
              ),
            ),
          // Action Buttons (Like, Comment)
          _buildActionButtons(isLiked, likeCount),
          // Post Text & Details
          _buildPostDetails(likeCount, timestamp),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: _postData['authorId']))),
            child: CircleAvatar(
              backgroundImage: _postData['authorImageUrl'] != null ? NetworkImage(_postData['authorImageUrl']) : null,
              child: _postData['authorImageUrl'] == null ? Text(_postData['authorName'][0]) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _postData['authorName'] ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (_postData['authorId'] == _currentUserId)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _deletePost();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isLiked, int likeCount) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
          onPressed: _toggleLike,
        ),
        IconButton(
          icon: const Icon(Icons.comment_outlined, color: Colors.grey),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommentsScreen(postId: widget.post.id)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostDetails(int likeCount, Timestamp timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likeCount > 0)
            Text('$likeCount likes', style: const TextStyle(fontWeight: FontWeight.bold)),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(text: _postData['authorName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' '),
                TextSpan(text: _postData['text'] ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeago.format(timestamp.toDate()),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
