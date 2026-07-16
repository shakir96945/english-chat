import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final String type; // voice or video
  final String status; // missed, outgoing, incoming, active
  final String duration;
  final DateTime timestamp;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.type,
    required this.status,
    required this.duration,
    required this.timestamp,
  });

  factory CallModel.fromMap(Map<String, dynamic> map, String docId) {
    return CallModel(
      id: docId,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerAvatar: map['callerAvatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverAvatar: map['receiverAvatar'] ?? '',
      type: map['type'] ?? 'voice',
      status: map['status'] ?? 'missed',
      duration: map['duration'] ?? '0s',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'type': type,
      'status': status,
      'duration': duration,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
