import 'package:flutter/material.dart';
import '../services/QueueService.dart';
import '../models/QueueItem.dart';

class NowPlayingScreen extends StatelessWidget {
  final String sessionId;

  const NowPlayingScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final queueService = QueueService();
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<List<QueueItem>>(
      stream: queueService.streamQueue(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final queue = snapshot.data!;
        final song = queue.isEmpty
            ? null
            : queue.firstWhere(
                (item) => item.isPlaying,
                orElse: () => queue.first,
              );

        if (song == null) {
          return const Center(
            child: Text(
              'No song playing yet',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(
              'NOW PLAYING',
              style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  image: song.albumArtUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(song.albumArtUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: song.albumArtUrl.isEmpty
                    ? Icon(Icons.music_note_rounded, size: 88, color: primary)
                    : null,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              song.trackTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              song.artistName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Added by',
                    value: song.addedByName,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.how_to_vote_rounded,
                    label: 'Vote score',
                    value: '${song.voteScore}',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white60)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
