import 'dart:io';
import 'package:flutter/material';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../models/group_model.dart';

class GroupController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<GroupModel>> getGroupsStream() {
    return FirebaseService.groupsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<bool> createGroup({
    required String name,
    required String description,
    required String creatorUid,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final docRef = FirebaseService.groupsCollection.doc();
      final newGroup = GroupModel(
        groupId: docRef.id,
        name: name,
        description: description,
        avatar: 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=100&h=100&fit=crop',
        adminId: creatorUid,
        members: [creatorUid],
        createdAt: DateTime.now(),
      );

      await docRef.set(newGroup.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await FirebaseService.groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await FirebaseService.groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }
}
