import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore path: /sessions/{sessionId}
class Session {
  final String id;
  final String name;
  final String hostUid;
  final String joinCode;
  final List<String> moods;
  final List<String> memberUids;
  final bool isActive;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.name,
    required this.hostUid,
    required this.joinCode,
    required this.moods,
    required this.memberUids,
    required this.isActive,
    required this.createdAt,
  });

  // Build a Session from a Firestore document snapshot
  factory Session.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      name: data['name'] as String,
      hostUid: data['hostUid'] as String,
      joinCode: data['joinCode'] as String,
      moods: List<String>.from(data['moods'] ?? []),
      memberUids: List<String>.from(data['memberUids'] ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  // Serialise to a map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hostUid': hostUid,
      'joinCode': joinCode,
      'moods': moods,
      'memberUids': memberUids,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Return a copy with specific fields changed
  Session copyWith({
    String? name,
    List<String>? moods,
    List<String>? memberUids,
    bool? isActive,
  }) {
    return Session(
      id: id,
      name: name ?? this.name,
      hostUid: hostUid,
      joinCode: joinCode,
      moods: moods ?? this.moods,
      memberUids: memberUids ?? this.memberUids,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  static String generateJoinCode() {
    final random = Random();
    // Generate 4 random digits (0-9)
    final codeDigits = List.generate(4, (_) => random.nextInt(10)).join();
    return 'VIBE-$codeDigits';
  }
}
