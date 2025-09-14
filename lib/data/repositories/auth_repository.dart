import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data from cache or Firestore
  Future<UserModel?> getCurrentUserData() async {
    return await _userRepository.getCurrentUserData();
  }

  // User repository getter
  UserRepository get userRepository => _userRepository;

  //user registration method
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else {
        throw Exception('Registration failed. Please try again.');
      }
    } catch (e) {
      print('Error in registration: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Get user data from Firestore and cache it
        final userModel = await _userRepository.getCurrentUserData();

        // Update online status
        if (userModel != null) {
          await _userRepository.updateOnlineStatus(true);
        }

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many failed attempts. Please try again later.');
      } else {
        throw Exception('Sign in failed. Please try again.');
      }
    } catch (e) {
      print('Error in sign in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update offline status before signing out
      await _userRepository.updateOnlineStatus(false);

      // Clear cached user data
      _userRepository.clearCache();

      // Sign out from Firebase Auth
      await _auth.signOut();
    } catch (e) {
      print('Error in sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email address.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else {
        throw Exception('Failed to send reset email. Please try again.');
      }
    } catch (e) {
      print('Error in password reset: $e');
      throw Exception('Failed to send reset email. Please try again.');
    }
  }
}
