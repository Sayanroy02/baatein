import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String username;
  final String? phone;
  final String? description;
  final String? profileImageBase64;
  final String? profileImageName;
  final bool hasProfileImage;
  final bool isProfileComplete;
  final String? platform;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.username,
    this.phone,
    this.description,
    this.profileImageBase64,
    this.profileImageName,
    this.hasProfileImage = false,
    this.isProfileComplete = false,
    this.platform,
    this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'],
      description: data['description'],
      profileImageBase64: data['profileImageBase64'],
      profileImageName: data['profileImageName'],
      hasProfileImage: data['hasProfileImage'] ?? false,
      isProfileComplete: data['isProfileComplete'] ?? false,
      platform: data['platform'],
      createdAt: data['createdAt']?.toDate(),
      lastSeen: data['lastSeen']?.toDate(),
      isOnline: data['isOnline'] ?? false,
    );
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'],
      description: data['description'],
      profileImageBase64: data['profileImageBase64'],
      profileImageName: data['profileImageName'],
      hasProfileImage: data['hasProfileImage'] ?? false,
      isProfileComplete: data['isProfileComplete'] ?? false,
      platform: data['platform'],
      createdAt: data['createdAt']?.toDate(),
      lastSeen: data['lastSeen']?.toDate(),
      isOnline: data['isOnline'] ?? false,
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'username': username,
      'phone': phone,
      'description': description,
      'profileImageBase64': profileImageBase64,
      'profileImageName': profileImageName,
      'hasProfileImage': hasProfileImage,
      'isProfileComplete': isProfileComplete,
      'platform': platform,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? username,
    String? phone,
    String? description,
    String? profileImageBase64,
    String? profileImageName,
    bool? hasProfileImage,
    bool? isProfileComplete,
    String? platform,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      profileImageName: profileImageName ?? this.profileImageName,
      hasProfileImage: hasProfileImage ?? this.hasProfileImage,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  // Get display name (prefer name, fallback to username)
  String get displayName => name.isNotEmpty ? name : username;

  // Get initials for avatar
  String get initials {
    if (name.isEmpty)
      return username.isNotEmpty ? username[0].toUpperCase() : '?';

    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    name,
    username,
    phone,
    description,
    profileImageBase64,
    profileImageName,
    hasProfileImage,
    isProfileComplete,
    platform,
    createdAt,
    lastSeen,
    isOnline,
  ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, username: $username, email: $email)';
  }
}
