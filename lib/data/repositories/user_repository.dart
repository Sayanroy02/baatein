import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user data cache
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get current user data and cache it
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userModel = await getUserById(user.uid);
      _currentUser = userModel;
      return userModel;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  // Update user data in Firestore and cache
  Future<bool> updateUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .update(userModel.toMap());

      // Update cache
      _currentUser = userModel;
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  // Create new user document
  Future<bool> createUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .set(userModel.toMap());

      // Update cache
      _currentUser = userModel;
      return true;
    } catch (e) {
      print('Error creating user data: $e');
      return false;
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Update cache
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  // Check if username exists
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final user = await getUserByUsername(username);
      return user == null;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Search users by name or username
  Future<List<UserModel>> searchUsers(String query, {int limit = 10}) async {
    try {
      final results = <UserModel>[];

      // Search by name
      final nameQuery = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(limit)
          .get();

      for (var doc in nameQuery.docs) {
        results.add(UserModel.fromFirestore(doc));
      }

      // Search by username (if not enough results)
      if (results.length < limit) {
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
            .where('username', isLessThan: query.toLowerCase() + 'z')
            .limit(limit - results.length)
            .get();

        for (var doc in usernameQuery.docs) {
          final user = UserModel.fromFirestore(doc);
          // Avoid duplicates
          if (!results.any((existing) => existing.uid == user.uid)) {
            results.add(user);
          }
        }
      }

      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      final users = <UserModel>[];

      // Firestore 'in' query limit is 10, so batch if needed
      const batchSize = 10;
      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final query = await _firestore
            .collection('users')
            .where('uid', whereIn: batch)
            .get();

        for (var doc in query.docs) {
          users.add(UserModel.fromFirestore(doc));
        }
      }

      return users;
    } catch (e) {
      print('Error getting users by IDs: $e');
      return [];
    }
  }

  // Listen to user data changes
  Stream<UserModel?> watchCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);
        _currentUser = userModel; // Update cache
        return userModel;
      }
      return null;
    });
  }

  // Clear cached user data (on logout)
  void clearCache() {
    _currentUser = null;
  }

  // Listen to online users
  Stream<List<UserModel>> watchOnlineUsers() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }
}
