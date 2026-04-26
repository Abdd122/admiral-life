
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/services/post_service.dart';
import 'package:go_social/services/user_service.dart';
import 'package:go_social/widgets/post_card_skeleton.dart'; // Import the skeleton
import 'package:go_social/widgets/post_card_widget.dart';

const int _kFeedPageLimit = 10;

class PostFeedWidget extends StatefulWidget {
  const PostFeedWidget({Key? key}) : super(key: key);

  @override
  _PostFeedWidgetState createState() => _PostFeedWidgetState();
}

class _PostFeedWidgetState extends State<PostFeedWidget> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _scrollController = ScrollController();

  // State for pagination
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasNextPage = true;
  DocumentSnapshot? _lastDocument;
  List<String> _feedUserIds = [];
  final List<QueryDocumentSnapshot> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && _hasNextPage && !_isFetchingMore) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchInitialFeed() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Get the list of users the current user is following.
    List<String> followingIds = await _userService.getFollowingIds();
    
    // 2. Also include the current user's own posts in the feed.
    if (!followingIds.contains(_currentUserId)) {
      followingIds.add(_currentUserId);
    }
    _feedUserIds = followingIds;

    // 3. Fetch the very first page of posts.
    await _fetchMorePosts();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchMorePosts() async {
    if (_isFetchingMore) return;
    
    setState(() {
      _isFetchingMore = true;
    });

    final newPosts = await _postService.getFeedPage(
      userIds: _feedUserIds,
      limit: _kFeedPageLimit,
      lastDoc: _lastDocument,
    );

    if (newPosts.isNotEmpty) {
      _lastDocument = newPosts.last;
      _posts.addAll(newPosts);
    }

    // Check if we've reached the end.
    if (newPosts.length < _kFeedPageLimit) {
      _hasNextPage = false;
    }

    setState(() {
      _isFetchingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show the skeleton loader during the initial loading phase
    if (_isLoading) {
      return ListView.builder(
        itemCount: 3, // Show a few skeleton cards
        itemBuilder: (context, index) => const PostCardSkeleton(),
      );
    }

    if (_posts.isEmpty) {
      return _buildWelcomeMessage();
    }

    return ListView.builder(
      controller: _scrollController,
      // Add 1 to the item count for the loading indicator at the bottom
      itemCount: _posts.length + (_hasNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        // If it's the last item and there's more to fetch, show a loader
        if (index == _posts.length && _hasNextPage) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Otherwise, show the post card
        return PostCardWidget(post: _posts[index]);
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Welcome to GoSocial!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your feed is empty. Start by following people to see their posts here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
