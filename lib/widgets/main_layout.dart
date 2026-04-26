
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/screens/add_post_screen.dart';
import 'package:go_social/screens/feed_screen.dart';
import 'package:go_social/screens/profile_screen.dart';
import 'package:go_social/screens/search_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _pageIndex = 0;
  late PageController _pageController;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _pageIndex = pageIndex;
    });
  }

  void _onTabTapped(int index) {
    if (index == 2) { // The "Add Post" button
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPostScreen()),
      );
    } else {
      _pageController.jumpToPage(index > 2 ? index - 1 : index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          const FeedScreen(), // Index 0
          const SearchScreen(), // Index 1
          // Index 2 is the AddPostScreen modal
          const Center(child: Text('Notifications - Coming Soon!')), // Index 3 (will be 2 in PageView)
          ProfileScreen(userId: _currentUserId), // Index 4 (will be 3 in PageView)
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _pageIndex > 1 ? _pageIndex + 1 : _pageIndex, // Adjust for the gap
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 32),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
