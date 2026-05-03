import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';

class HomeScreen extends StatelessWidget {
  final Function(String, String, List<String>, bool) onEnterSession;
  final String? activeSessionId;

  const HomeScreen({
    super.key,
    required this.onEnterSession,
    this.activeSessionId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.displayName ?? user?.email?.split('@').first ?? 'there'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to vibe?',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 24),

            _CreateJoinSection(onEnterSession: onEnterSession),
            const SizedBox(height: 24),

            const Text(
              'ACTIVE SESSIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            _ActiveSessions(onEnterSession: onEnterSession),
            const SizedBox(height: 24),

            const Text(
              'PAST SESSIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            const _PastSessions(),
          ],
        ),
      ),
    );
  }
}

class _CreateJoinSection extends StatefulWidget {
  final Function(String, String, List<String>, bool) onEnterSession;

  const _CreateJoinSection({required this.onEnterSession});

  @override
  State<_CreateJoinSection> createState() => _CreateJoinSectionState();
}

class _CreateJoinSectionState extends State<_CreateJoinSection> {
  final TextEditingController _joinCodeController = TextEditingController();
  final SessionService _sessionService = SessionService();

  bool _isJoining = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    final nameController = TextEditingController();
    final selectedMoods = <String>[];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text(
                'Create Session',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Session name',
                      hintStyle: TextStyle(color: Colors.white60),
                    ),
                    style: const TextStyle(color: Colors.white),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Moods (tap to select)',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['🔥 Hype', '😌 Chill', '💃 Party', '📚 Focus']
                        .map((mood) {
                          final isSelected = selectedMoods.contains(mood);

                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                if (isSelected) {
                                  selectedMoods.remove(mood);
                                } else {
                                  selectedMoods.add(mood);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                mood,
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(context);

                    final sessionId = await _sessionService.createSession(
                      name,
                      selectedMoods,
                    );

                    if (!context.mounted) return;

                    widget.onEnterSession(sessionId, name, selectedMoods, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _joinSession() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final session = await _sessionService.joinSession(code);

      if (!mounted) return;

      if (session != null) {
        widget.onEnterSession(
          session.id,
          session.name,
          session.moods,
          session.hostUid == FirebaseAuth.instance.currentUser?.uid,
        );

        _joinCodeController.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid session code')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        GestureDetector(
          onTap: _createSession,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withOpacity(0.8), primary.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Start a new listening party',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _joinCodeController,
                  decoration: const InputDecoration(
                    hintText: 'Enter session code',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isJoining ? null : _joinSession,
                child: _isJoining
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveSessions extends StatelessWidget {
  final Function(String, String, List<String>, bool) onEnterSession;

  const _ActiveSessions({required this.onEnterSession});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final primary = Theme.of(context).colorScheme.primary;

    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('memberUids', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'Could not load sessions: ${snapshot.error}',
              style: const TextStyle(color: Colors.white60),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs;

        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 48,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No active sessions',
                    style: TextStyle(color: Colors.white60),
                  ),
                  Text(
                    'Create or join a session to get started',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: sessions.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final sessionId = doc.id;
            final name = data['name'] ?? 'Untitled';
            final moods = List<String>.from(data['moods'] ?? []);
            final memberCount = (data['memberUids'] as List?)?.length ?? 0;
            final isHost = data['hostUid'] == userId;
            final joinCode = data['joinCode'] ?? '';

            return GestureDetector(
              onTap: () {
                onEnterSession(sessionId, name, moods, isHost);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(
                                Icons.people_rounded,
                                size: 12,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$memberCount members',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                              if (isHost) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'HOST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (joinCode.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: primary.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                'Code: $joinCode',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],

                          if (moods.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: moods.take(3).map((mood) {
                                return Text(
                                  mood,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: primary,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PastSessions extends StatelessWidget {
  const _PastSessions();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('memberUids', arrayContains: userId)
          .where('isActive', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'Could not load past sessions: ${snapshot.error}',
              style: const TextStyle(color: Colors.white60),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs;

        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 48, color: Colors.white38),
                  SizedBox(height: 12),
                  Text(
                    'No past sessions',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: sessions.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'Untitled';
            final createdAt =
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.lock_clock_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    }

    if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    }

    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    }

    if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    }

    return 'Just now';
  }
}
