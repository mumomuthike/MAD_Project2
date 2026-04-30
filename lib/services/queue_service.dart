import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/QueueItem.dart';
import '../models/SpotifyTrack.dart';

class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<QueueItem>> streamQueue(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue')
        .orderBy('position')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => QueueItem.fromDoc(doc))
        .toList());
  }

  Future<void> addToQueue(String sessionId, SpotifyTrack track) async {
    final user = _auth.currentUser!;
    final queueRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue');

    // Get current count for position
    final count = await queueRef.count().get();
    final position = count.count ?? 0;

    final queueItem = {
      'addedByUid': user.uid,
      'addedByName': user.displayName ?? 'Anonymous',
      'spotifyTrackId': track.id,
      'trackTitle': track.title,
      'artistName': track.artist,
      'albumArtUrl': track.albumArtUrl,
      'voteScore': 0,
      'userVotes': {},
      'addedAt': FieldValue.serverTimestamp(),
      'isPlaying': false,
      'position': position,
    };

    await queueRef.add(queueItem);

    // Increment user's songs added count
    await _firestore.collection('users').doc(user.uid).update({
      'totalSongsAdded': FieldValue.increment(1)
    });
  }

  Future<void> vote(String sessionId, String queueItemId, int voteValue) async {
    final user = _auth.currentUser!;
    final docRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue')
        .doc(queueItemId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final userVotes = Map<String, int>.from(doc.data()?['userVotes'] ?? {});
      final previousVote = userVotes[user.uid] ?? 0;

      if (previousVote == voteValue) {
        // Remove vote
        userVotes.remove(user.uid);
        transaction.update(docRef, {
          'voteScore': FieldValue.increment(-voteValue),
          'userVotes': userVotes,
        });
      } else {
        // Change vote
        userVotes[user.uid] = voteValue;
        transaction.update(docRef, {
          'voteScore': FieldValue.increment(voteValue - previousVote),
          'userVotes': userVotes,
        });
      }
    });

    // Increment user's votes cast count only for new votes
    if (voteValue != 0) {
      await _firestore.collection('users').doc(user.uid).update({
        'totalVotesCast': FieldValue.increment(1)
      });
    }
  }
}