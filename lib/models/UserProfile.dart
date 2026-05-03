import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int totalSessions;
  final int totalSongsAdded;
  final int totalVotesCast;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.totalSessions = 0,
    this.totalSongsAdded = 0,
    this.totalVotesCast = 0,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      totalSessions: data['totalSessions'] as int? ?? 0,
      totalSongsAdded: data['totalSongsAdded'] as int? ?? 0,
      totalVotesCast: data['totalVotesCast'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalSessions': totalSessions,
      'totalSongsAdded': totalSongsAdded,
      'totalVotesCast': totalVotesCast,
    };
  }
}
