import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ChatMessage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ChatMessage>> streamMessages(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromDoc(doc))
        .toList());
  }

  Future<void> sendMessage(String sessionId, String text) async {
    final user = _auth.currentUser!;
    final message = ChatMessage(
      id: '', // Firestore will generate
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      text: text,
      sentAt: DateTime.now(),
    );

    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .add(message.toMap());
  }
}