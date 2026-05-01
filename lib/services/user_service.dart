import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Call this when user logs in to ensure user document exists
  Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'email': user.email,
        'displayName': user.displayName ?? 'Anonymous',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'totalSessions': 0,
        'totalSongsAdded': 0,
        'totalVotesCast': 0,
      });
      print('Created user document for ${user.uid}');
    }
  }

  // Update user profile
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(displayName);
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
    });
  }

  // Get user stats stream
  Stream<DocumentSnapshot> getUserStats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();

    return _firestore.collection('users').doc(user.uid).snapshots();
  }
}