import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore path: /sessions/{sessionId}/messages/{messageId}
class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.sentAt,
  });

  // Build a ChatMessage from a Firestore document snapshot
  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      text: data['text'] as String,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }

  // Serialise to a map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  // Return a copy with specific fields changed (optional but recommended)
  ChatMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? sentAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
