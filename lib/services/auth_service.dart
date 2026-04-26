
import 'package:firebase_auth/firebase_auth.dart';
import './firestore_service.dart'; // We need this to create the user document

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService(); // Service to interact with Firestore

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _firestoreService.createUserDocument(
          userId: userCredential.user!.uid,
          email: email,
          displayName: email.split('@')[0], // a simple default display name
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException on sign up: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred on sign up: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException on sign in: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred on sign in: $e');
      rethrow;
    }
  }

  /// Initiates phone number verification.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Signs in the user with the provided verification ID and SMS code.
  /// Also creates a user document in Firestore if it's the first sign-in.
  Future<UserCredential?> signInWithPhoneCredential(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _firestoreService.createUserDocument(
          userId: userCredential.user!.uid,
          phoneNumber: userCredential.user!.phoneNumber, // Pass the phone number
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException on phone sign in: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred on phone sign in: $e');
      rethrow;
    }
  }


  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('An error occurred on sign out: $e');
      rethrow;
    }
  }
}
