
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_social/services/post_service.dart';
import 'package:go_social/services/user_service.dart';
import 'package:go_social/widgets/post_card.dart'; // We will create this widget next

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  Future<Stream<QuerySnapshot>>? _feedStreamFuture;

  @override
  void initState() {
    super.initState();
    _feedStreamFuture = _getFeedStream();
  }

  Future<Stream<QuerySnapshot>> _getFeedStream() async {
    // First, get the list of users the current user is following.
    List<String> followingIds = await _userService.getFollowingIds();

    // Then, return the stream of posts from those users.
    return _postService.getFeedStream(followingIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoSocial'),
        // Optional: Add actions like a refresh button
      ),
      body: FutureBuilder<Stream<QuerySnapshot>>(
        future: _feedStreamFuture,
        builder: (context, futureSnapshot) {
          if (futureSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (futureSnapshot.hasError || !futureSnapshot.hasData) {
            return const Center(child: Text('Could not load feed. Please try again.'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: futureSnapshot.data,
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Your feed is empty! Follow some users to see their posts.'),
                );
              }

              final posts = streamSnapshot.data!.docs;

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  // You need a PostCard widget to display the post nicely.
                  // We'll create a placeholder for now.
                  return PostCard(post: post.data() as Map<String, dynamic>);
                },
              );
            },
          );
        },
      ),
    );
  }
}
