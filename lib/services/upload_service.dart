
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final String filePath = 'profile_images/$userId.jpg';
      final UploadTask uploadTask = _storage.ref().child(filePath).putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase upload error: ${e.message}');
      rethrow;
    }
  }

  Future<String> uploadPostImage({
    required String userId,
    required File file,
  }) async {
    try {
      // Generate a unique ID for the post image
      final String postId = _uuid.v4();
      final String filePath = 'post_images/$userId/$postId.jpg';

      final UploadTask uploadTask = _storage.ref().child(filePath).putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase post image upload error: ${e.message}');
      rethrow;
    }
  }

  // This should be the address of your VPS
  static const String _baseUrl = "http://188.40.225.17:3000";

  Future<String?> uploadFile(File file) async {
    final uri = Uri.parse("$_baseUrl/upload");
    var request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseBody);

      if (response.statusCode == 200 && decodedResponse['status'] == 'success') {
        final filePath = decodedResponse['filePath'];
        return filePath;
      } else {
        final message = decodedResponse['message'] ?? 'Unknown error';
        print('Upload failed: $message');
        return null;
      }
    } catch (e) {
      print('An error occurred during upload: $e');
      return null;
    }
  }

  String getFullUrl(String filePath) {
    if (!filePath.startsWith('/')) {
      filePath = '/$filePath';
    }
    return _baseUrl + filePath;
  }
}
