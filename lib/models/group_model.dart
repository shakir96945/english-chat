import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String name;
  final String description;
  final String avatar;
  final String adminId;
  final List<String> members;
  final DateTime createdAt;

  GroupModel({
    required this.groupId,
    required this.name,
    required this.description,
    required this.avatar,
    required this.adminId,
    required this.members,
    required this.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      groupId: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      avatar: map['avatar'] ?? '',
      adminId: map['adminId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatar': avatar,
      'adminId': adminId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
