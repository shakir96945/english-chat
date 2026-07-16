import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String replyToId;
  final String replyToText;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final String type; // text, image, file, voice
  final String mediaUrl;
  final String fileName;
  final int durationSeconds;
  final Map<String, String> reactions; // userUid -> emoji

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.replyToId = '',
    this.replyToText = '',
    required this.timestamp,
    required this.isRead,
    this.isDelivered = true,
    this.type = 'text',
    this.mediaUrl = '',
    this.fileName = '',
    this.durationSeconds = 0,
    this.reactions = const {},
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      replyToId: map['replyToId'] ?? '',
      replyToText: map['replyToText'] ?? '',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? true,
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      reactions: map['reactions'] != null 
          ? Map<String, String>.from(map['reactions']) 
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'durationSeconds': durationSeconds,
      'reactions': reactions,
    };
  }
}
