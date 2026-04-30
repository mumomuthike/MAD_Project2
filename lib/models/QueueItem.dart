import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore path: /sessions/{sessionId}/queue/{queueItemId}
class QueueItem {
  final String id;
  final String addedByUid;
  final String addedByName;
  final String spotifyTrackId;
  final String trackTitle;
  final String artistName;
  final String albumArtUrl;
  final int voteScore;
  final Map<String, int> userVotes;
  final DateTime addedAt;
  final bool isPlaying;
  final int position;

  const QueueItem({
    required this.id,
    required this.addedByUid,
    required this.addedByName,
    required this.spotifyTrackId,
    required this.trackTitle,
    required this.artistName,
    required this.albumArtUrl,
    required this.voteScore,
    required this.userVotes,
    required this.addedAt,
    required this.isPlaying,
    required this.position,
  });

  // Build a QueueItem from a Firestore document snapshot
  factory QueueItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueItem(
      id: doc.id,
      addedByUid: data['addedByUid'] as String,
      addedByName: data['addedByName'] as String,
      spotifyTrackId: data['spotifyTrackId'] as String,
      trackTitle: data['trackTitle'] as String,
      artistName: data['artistName'] as String,
      albumArtUrl: data['albumArtUrl'] as String? ?? '',
      voteScore: data['voteScore'] as int? ?? 0,
      userVotes: Map<String, int>.from(data['userVotes'] ?? {}),
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      isPlaying: data['isPlaying'] as bool? ?? false,
      position: data['position'] as int? ?? 0,
    );
  }

  // Serialise to a map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'spotifyTrackId': spotifyTrackId,
      'trackTitle': trackTitle,
      'artistName': artistName,
      'albumArtUrl': albumArtUrl,
      'voteScore': voteScore,
      'userVotes': userVotes,
      'addedAt': Timestamp.fromDate(addedAt),
      'isPlaying': isPlaying,
      'position': position,
    };
  }
  // Return a copy with specific fields changed
  QueueItem copyWith({
    int? voteScore,
    Map<String, int>? userVotes,
    bool? isPlaying,
    int? position,
  }) {
    return QueueItem(
      id: id,
      addedByUid: addedByUid,
      addedByName: addedByName,
      spotifyTrackId: spotifyTrackId,
      trackTitle: trackTitle,
      artistName: artistName,
      albumArtUrl: albumArtUrl,
      voteScore: voteScore ?? this.voteScore,
      userVotes: userVotes ?? this.userVotes,
      addedAt: addedAt,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
    );
  }

  int getUserVote(String userId) {
    return userVotes[userId] ?? 0;
  }
}