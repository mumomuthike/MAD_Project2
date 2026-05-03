import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/QueueItem.dart';
import '../models/SpotifyTrack.dart';

class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<QueueItem>> streamQueue(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return QueueItem.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> addToQueue(String sessionId, SpotifyTrack track) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Not logged in');

    final queueRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue');

    // Check if song already exists in queue
    final existing = await queueRef
        .where('trackId', isEqualTo: track.id)
        .where('isPlaying', isEqualTo: false)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Song already in queue');
    }

    await queueRef.add({
      'trackId': track.id,
      'trackTitle': track.title,
      'artistName': track.artist,
      'albumArtUrl': track.albumArtUrl,
      'durationMs': track.durationMs,
      'addedBy': currentUser.uid,
      'addedByName':
          currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'voteScore': 0,
      'votes': {},
      'isPlaying': false,
    });

    // Update activity feed
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('activity')
        .add({
          'type': 'song_added',
          'userId': currentUser.uid,
          'userName':
              currentUser.displayName ??
              currentUser.email?.split('@').first ??
              'Anonymous',
          'trackTitle': track.title,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Update contributor stats
    await _updateContributor(
      sessionId,
      currentUser.uid,
      currentUser.displayName ?? 'Anonymous',
      track.id,
    );
  }

  Future<void> _updateContributor(
    String sessionId,
    String userId,
    String userName,
    String trackId,
  ) async {
    final contributorRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('contributors')
        .doc(userId);

    final doc = await contributorRef.get();
    if (doc.exists) {
      await contributorRef.update({
        'songsAdded': FieldValue.increment(1),
        'lastSongAdded': FieldValue.serverTimestamp(),
      });
    } else {
      await contributorRef.set({
        'userId': userId,
        'userName': userName,
        'songsAdded': 1,
        'totalVotesReceived': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> vote(String sessionId, String queueItemId, int voteValue) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final queueItemRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue')
        .doc(queueItemId);

    final doc = await queueItemRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final Map<String, dynamic> votes = Map.from(data['votes'] ?? {});
    final oldVoteValue = votes[currentUser.uid] ?? 0;

    // Calculate new vote score
    final voteDifference = voteValue - oldVoteValue;
    final newVoteScore = (data['voteScore'] ?? 0) + voteDifference;

    if (voteValue == 0) {
      votes.remove(currentUser.uid);
    } else {
      votes[currentUser.uid] = voteValue;
    }

    await queueItemRef.update({'votes': votes, 'voteScore': newVoteScore});

    // Update activity for vote
    if (voteValue != 0) {
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('activity')
          .add({
            'type': 'vote_cast',
            'userId': currentUser.uid,
            'userName':
                currentUser.displayName ??
                currentUser.email?.split('@').first ??
                'Anonymous',
            'trackTitle': data['trackTitle'],
            'voteValue': voteValue,
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<void> markAsPlaying(String sessionId, String queueItemId) async {
    final batch = _firestore.batch();
    final queueRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue');

    // Unmark current playing
    final currentPlaying = await queueRef
        .where('isPlaying', isEqualTo: true)
        .get();
    for (var doc in currentPlaying.docs) {
      batch.update(doc.reference, {'isPlaying': false});
    }

    // Mark new as playing
    batch.update(queueRef.doc(queueItemId), {'isPlaying': true});

    await batch.commit();
  }

  Future<void> removeFromQueue(String sessionId, String queueItemId) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('queue')
        .doc(queueItemId)
        .delete();
  }
}
