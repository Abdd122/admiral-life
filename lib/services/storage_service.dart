
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a user's profile image and return the download URL
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create a reference to the location you want to upload to
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      // Upload the file
      final uploadTask = ref.putFile(imageFile);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => {});

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow; // Rethrow the error to be handled by the caller
    }
  }
}
