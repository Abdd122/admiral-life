
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_social/screens/profile_screen.dart';
import 'package:go_social/services/user_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  Future<QuerySnapshot>? _searchResultsFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.trim().isNotEmpty) {
        setState(() {
          _searchResultsFuture = _userService.searchUsers(_searchController.text.trim());
        });
      } else {
        setState(() {
          _searchResultsFuture = null; // Clear results if the query is empty
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchResults() {
    if (_searchResultsFuture == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ 
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search for users', style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: _searchResultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final userDoc = snapshot.data!.docs[index];
            final userData = userDoc.data() as Map<String, dynamic>;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userData['profileImageUrl'] != null ? NetworkImage(userData['profileImageUrl']) : null,
                child: userData['profileImageUrl'] == null ? Text(userData['name'][0]) : null,
              ),
              title: Text(userData['name']),
              subtitle: Text(userData['email'] ?? ''),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: userDoc.id)),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for a user...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          )
        ],
      ),
      body: _buildSearchResults(),
    );
  }
}
