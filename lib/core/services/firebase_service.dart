import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Colection endpoints
  static final CollectionReference usersCollection = firestore.collection('users');
  static final CollectionReference chatsCollection = firestore.collection('chats');
  static final CollectionReference groupsCollection = firestore.collection('groups');
  static final CollectionReference requestsCollection = firestore.collection('friend_requests');
  static final CollectionReference friendsCollection = firestore.collection('friends');
  static final CollectionReference callHistoryCollection = firestore.collection('call_history');
  static final CollectionReference notificationsCollection = firestore.collection('notifications');

  static String handleException(dynamic exception) {
    if (exception is FirebaseAuthException) {
      switch (exception.code) {
        case 'user-not-found': return 'No premium profile registered under this email.';
        case 'wrong-password': return 'Invalid secure key code / password.';
        case 'email-already-in-use': return 'Email is already registered on English chat.';
        default: return exception.message ?? 'An auth transaction failure occurred.';
      }
    } else if (exception is FirebaseException) {
      return exception.message ?? 'Database synchronization failed.';
    }
    return exception.toString();
  }
}
