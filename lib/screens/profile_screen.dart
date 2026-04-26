
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_social/models/user_model.dart';
import 'package:go_social/services/storage_service.dart';
import 'package:go_social/services/user_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _storageService = StorageService();
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser(widget.userId);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        File imageFile = File(pickedFile.path);
        // 1. Upload to Storage
        String downloadUrl = await _storageService.uploadProfileImage(_currentUser.uid, imageFile);

        // 2. Update user's profileImageUrl in Firestore
        await _userService.updateUserProfileImage(_currentUser.uid, downloadUrl);

        // 3. Refresh the UI
        setState(() {
          _userFuture = _userService.getUser(widget.userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = _currentUser.uid == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('User not found.'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(user.profileImageUrl),
                    ),
                    if (isCurrentUser)
                      Material(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _pickAndUploadImage,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                Text(user.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('@${user.username}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                _buildStatsRow(user.coins),
                const SizedBox(height: 20),
                const Divider(),
                // Placeholder for user content (e.g., posts, rooms)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(int coins) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Coins', coins.toString()),
        _buildStatItem('Following', '0'), // Placeholder
        _buildStatItem('Followers', '0'), // Placeholder
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
