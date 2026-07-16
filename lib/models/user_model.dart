import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String profilePic;
  final String bio;
  final String country;
  final String gender;
  final String dateOfBirth;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime dateJoined;
  final List<String> blockedUsers;
  final bool showOnlinePresence;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.profilePic,
    required this.bio,
    required this.country,
    required this.gender,
    required this.dateOfBirth,
    required this.isOnline,
    required this.lastSeen,
    required this.dateJoined,
    this.blockedUsers = const [],
    this.showOnlinePresence = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profilePic: map['profilePic'] ?? '',
      bio: map['bio'] ?? '',
      country: map['country'] ?? '',
      gender: map['gender'] ?? 'Not Specified',
      dateOfBirth: map['dateOfBirth'] ?? 'Not Specified',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null 
          ? (map['lastSeen'] as Timestamp).toDate() 
          : DateTime.now(),
      dateJoined: map['dateJoined'] != null 
          ? (map['dateJoined'] as Timestamp).toDate() 
          : DateTime.now(),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      showOnlinePresence: map['showOnlinePresence'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'username': username,
      'email': email,
      'profilePic': profilePic,
      'bio': bio,
      'country': country,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'dateJoined': Timestamp.fromDate(dateJoined),
      'blockedUsers': blockedUsers,
      'showOnlinePresence': showOnlinePresence,
    };
  }
}
