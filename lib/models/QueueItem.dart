import 'package:cloud_firestore/cloud_firestore.dart';

class QueueItem {
  final String id;
  final String trackId;
  final String trackTitle;
  final String artistName;
  final String albumArtUrl;
  final int durationMs;
  final String addedBy;
  final String addedByName;
  final DateTime timestamp;
  final int voteScore;
  final Map<String, dynamic> votes;
  final bool isPlaying;

  QueueItem({
    required this.id,
    required this.trackId,
    required this.trackTitle,
    required this.artistName,
    required this.albumArtUrl,
    required this.durationMs,
    required this.addedBy,
    required this.addedByName,
    required this.timestamp,
    required this.voteScore,
    required this.votes,
    required this.isPlaying,
  });

  factory QueueItem.fromMap(String id, Map<String, dynamic> map) {
    return QueueItem(
      id: id,
      trackId: map['trackId'] ?? '',
      trackTitle: map['trackTitle'] ?? '',
      artistName: map['artistName'] ?? '',
      albumArtUrl: map['albumArtUrl'] ?? '',
      durationMs: map['durationMs'] ?? 0,
      addedBy: map['addedBy'] ?? '',
      addedByName: map['addedByName'] ?? 'Anonymous',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voteScore: map['voteScore'] ?? 0,
      votes: Map<String, dynamic>.from(map['votes'] ?? {}),
      isPlaying: map['isPlaying'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'trackTitle': trackTitle,
      'artistName': artistName,
      'albumArtUrl': albumArtUrl,
      'durationMs': durationMs,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'timestamp': Timestamp.fromDate(timestamp),
      'voteScore': voteScore,
      'votes': votes,
      'isPlaying': isPlaying,
    };
  }

  int getUserVote(String userId) {
    return votes[userId] ?? 0;
  }

  String get formattedDuration {
    final minutes = (durationMs / 60000).floor();
    final seconds = ((durationMs % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
