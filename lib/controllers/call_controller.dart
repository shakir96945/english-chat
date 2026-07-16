import 'package:flutter/material';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../models/call_model.dart';

class CallController extends ChangeNotifier {
  Stream<List<CallModel>> getCallHistoryStream(String userId) {
    return FirebaseService.callHistoryCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CallModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((c) => c.callerId == userId || c.receiverId == userId)
              .toList();
        });
  }

  Future<void> logCall(CallModel call) async {
    await FirebaseService.callHistoryCollection.add(call.toMap());
  }
}
