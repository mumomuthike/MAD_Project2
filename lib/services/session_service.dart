import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Session.dart';

// Handles Session related Firestore operations
class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createSession(String name, List<String> moods) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

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

      print('Creating session with data: $session');

      final docRef = await _firestore.collection('sessions').add(session);
      print('Session created with ID: ${docRef.id}');

      // Increment user's total sessions count
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        await userRef.update({'totalSessions': FieldValue.increment(1)});
      } else {
        // Create user document if it doesn't exist
        await userRef.set({
          'email': user.email,
          'displayName': user.displayName ?? 'Anonymous',
          'createdAt': FieldValue.serverTimestamp(),
          'totalSessions': 1,
          'totalSongsAdded': 0,
          'totalVotesCast': 0,
        });
      }

      return docRef.id;
    } catch (e) {
      print('Error creating session: $e');
      throw Exception('Failed to create session: $e');
    }
  }

  Future<Session?> joinSession(String joinCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Looking for session with code: $joinCode');

      final query = await _firestore
          .collection('sessions')
          .where('joinCode', isEqualTo: joinCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('No session found with code: $joinCode');
        return null;
      }

      final session = Session.fromDoc(query.docs.first);
      print('Found session: ${session.name} (${session.id})');

      // Add user as member if not already
      if (!session.memberUids.contains(user.uid)) {
        print('Adding user ${user.uid} to session members');
        await query.docs.first.reference.update({
          'memberUids': FieldValue.arrayUnion([user.uid]),
        });

        // Increment user's total sessions count for joining a session
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userRef.get();

        if (userDoc.exists) {
          await userRef.update({'totalSessions': FieldValue.increment(1)});
        } else {
          // Create user document if it doesn't exist
          await userRef.set({
            'email': user.email,
            'displayName': user.displayName ?? 'Anonymous',
            'createdAt': FieldValue.serverTimestamp(),
            'totalSessions': 1,
            'totalSongsAdded': 0,
            'totalVotesCast': 0,
          });
        }
      }

      return session;
    } catch (e) {
      print('Error joining session: $e');
      throw Exception('Failed to join session: $e');
    }
  }

  Stream<Session> streamSession(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => Session.fromDoc(doc));
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isActive': false,
      });
      print('Session $sessionId ended');
    } catch (e) {
      print('Error ending session: $e');
      throw Exception('Failed to end session: $e');
    }
  }
}
