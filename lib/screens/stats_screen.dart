import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/QueueService.dart';
import '../models/QueueItem.dart';

class StatsScreen extends StatelessWidget {
  final String sessionId;

  const StatsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SESSION STATS',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Top Contributors
            _TopContributors(sessionId: sessionId),
            const SizedBox(height: 24),

            // Top Tracks
            _TopTracks(sessionId: sessionId),
            const SizedBox(height: 24),

            // Top Genres
            _TopGenres(sessionId: sessionId),
          ],
        ),
      ),
    );
  }
}

// Top Contributors Widget
class _TopContributors extends StatelessWidget {
  final String sessionId;

  const _TopContributors({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('contributors')
          .orderBy('songsAdded', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contributors = snapshot.data!.docs;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TOP CONTRIBUTORS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (contributors.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No contributors yet',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                ...contributors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value.data() as Map<String, dynamic>;
                  final userName = data['userName'] ?? 'Anonymous';
                  final songsAdded = data['songsAdded'] ?? 0;
                  final isYou = data['userId'] == currentUserId;

                  return _ContributorTile(
                    rank: index + 1,
                    name: userName,
                    songsAdded: songsAdded,
                    isYou: isYou,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ContributorTile extends StatelessWidget {
  final int rank;
  final String name;
  final int songsAdded;
  final bool isYou;

  const _ContributorTile({
    required this.rank,
    required this.name,
    required this.songsAdded,
    this.isYou = false,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Rank medal
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (isYou) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(fontSize: 9, color: primary),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Song count
          Text(
            '$songsAdded songs',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// Top Tracks Widget
class _TopTracks extends StatelessWidget {
  final String sessionId;

  const _TopTracks({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final queueService = QueueService();

    return StreamBuilder<List<QueueItem>>(
      stream: queueService.streamQueue(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final queue = snapshot.data!;

        // Sort by vote score and take top 3
        final topTracks = [...queue]
          ..sort((a, b) => b.voteScore.compareTo(a.voteScore));
        final top3 = topTracks.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.queue_music_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'TOP TRACKS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (top3.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No tracks yet',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                ...top3.asMap().entries.map((entry) {
                  final index = entry.key;
                  final track = entry.value;
                  return _TrackTile(
                    rank: index + 1,
                    title: track.trackTitle,
                    artist: track.artistName,
                    votes: track.voteScore,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  final int rank;
  final String title;
  final String artist;
  final int votes;

  const _TrackTile({
    required this.rank,
    required this.title,
    required this.artist,
    required this.votes,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.amber : Colors.white54,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Vote score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: votes > 0
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  votes > 0 ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                  size: 12,
                  color: votes > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  votes > 0 ? '+$votes' : '$votes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: votes > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Top Genres Widget
class _TopGenres extends StatelessWidget {
  final String sessionId;

  const _TopGenres({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // Get session moods as genres
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final moods = List<String>.from(data?['moods'] ?? []);

        // Display top 3 moods (or all if less than 3)
        final topGenres = moods.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.music_note_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'TOP VIBES',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (topGenres.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No vibes selected',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: topGenres.map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.whatshot_rounded,
                            color: primary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            genre,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
