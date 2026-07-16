import 'dart:io';
import 'package:flutter/material';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/services/firebase_service.dart';
import '../models/message_model.dart';

class ChatController extends ChangeNotifier {
  String? _currentUserId;

  void updateUserId(String? uid) {
    _currentUserId = uid;
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return FirebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<DocumentSnapshot> getChatRoomStream(String chatId) {
    return FirebaseService.chatsCollection.doc(chatId).snapshots();
  }

  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    if (_currentUserId == null) return;
    await FirebaseService.chatsCollection.doc(chatId).set({
      'typingStatus': {
        _currentUserId!: isTyping,
      }
    }, SetOptions(merge: true));
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String text,
    String replyToId = '',
    String replyToText = '',
    String type = 'text',
    String mediaUrl = '',
    String fileName = '',
    int durationSeconds = 0,
  }) async {
    if (_currentUserId == null || (text.trim().isEmpty && mediaUrl.isEmpty)) return;

    final messageData = MessageModel(
      id: '',
      senderId: _currentUserId!,
      text: text,
      replyToId: replyToId,
      replyToText: replyToText,
      timestamp: DateTime.now(),
      isRead: false,
      isDelivered: true,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      durationSeconds: durationSeconds,
    ).toMap();

    await FirebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    await FirebaseService.chatsCollection.doc(chatId).set({
      'lastMessage': type == 'text' ? text : 'Shared a luxury media file',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'senderId': _currentUserId,
    }, SetOptions(merge: true));
  }

  Future<String> uploadSharedMedia(File file, String chatId, String type) async {
    final fileId = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseService.storage
        .ref()
        .child('shared_files')
        .child(chatId)
        .child('$fileId.${file.path.split('.').last}');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    await FirebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': '🚫 This message was deleted.',
      'type': 'text',
      'mediaUrl': '',
    });
  }

  Future<void> markMessagesAsRead(String chatId, String peerId) async {
    final query = await FirebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: peerId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseService.firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> editChatMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await FirebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
    });
  }

  Future<void> addMessageReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await FirebaseService.chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'reactions': {
        userId: emoji,
      }
    }, SetOptions(merge: true));
  }
}
