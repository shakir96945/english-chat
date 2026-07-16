import 'package:flutter/material';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../models/user_model.dart';

class FriendController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await FirebaseService.usersCollection
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendFriendRequest({required String senderId, required String receiverId}) async {
    final id = '${senderId}_${receiverId}';
    await FirebaseService.requestsCollection.doc(id).set({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest({required String requestId, required String userA, required String userB}) async {
    await FirebaseService.requestsCollection.doc(requestId).update({'status': 'accepted'});
    
    final friendshipId = userA.compareTo(userB) < 0 ? '${userA}_${userB}' : '${userB}_${userA}';
    await FirebaseService.friendsCollection.doc(friendshipId).set({
      'users': [userA, userB],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFriend({required String userA, required String userB}) async {
    final friendshipId = userA.compareTo(userB) < 0 ? '${userA}_${userB}' : '${userB}_${userA}';
    await FirebaseService.friendsCollection.doc(friendshipId).delete();
  }
}
