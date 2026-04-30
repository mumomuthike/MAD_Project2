import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session.dart';

// Handles Session related Firestore operations
class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createSession(String name, List<String> moods) async {
    final user = _auth.currentUser!;
    final joinCode = Session.generateJoinCode();

    final session = {
      'name': name,
      'hostUid': user.uid,
      'joinCode': joinCode,
      'moods': moods,
      'memberUids': [user.uid],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('sessions').add(session);
    return docRef.id;
  }

  Future<Session?> joinSession(String joinCode) async {
    final query = await _firestore
        .collection('sessions')
        .where('joinCode', isEqualTo: joinCode.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final session = Session.fromDoc(query.docs.first);

    // Add user as member if not already
    final user = _auth.currentUser!;
    if (!session.memberUids.contains(user.uid)) {
      await query.docs.first.reference.update({
        'memberUids': FieldValue.arrayUnion([user.uid])
      });
    }

    return session;
  }

  Stream<Session> streamSession(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => Session.fromDoc(doc));
  }

  Future<void> endSession(String sessionId) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .update({'isActive': false});
  }
}