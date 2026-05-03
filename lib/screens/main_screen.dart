import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'now_playing.dart';
import 'chat_screen.dart';
import 'stats_screen.dart';
import '../widgets/add_song_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/QueueService.dart';
import '../models/QueueItem.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Session state
  String? _activeSessionId;
  String? _activeSessionName;
  List<String> _activeSessionMoods = [];
  bool _isHost = false;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _enterSession(
    String sessionId,
    String sessionName,
    List<String> moods,
    bool isHost,
  ) {
    setState(() {
      _activeSessionId = sessionId;
      _activeSessionName = sessionName;
      _activeSessionMoods = moods;
      _isHost = isHost;
      // Switch to the Now Playing tab when entering a session
      _selectedIndex = 1;
    });
  }

  void _leaveSession() {
    setState(() {
      _activeSessionId = null;
      _activeSessionName = null;
      _activeSessionMoods = [];
      _isHost = false;
      // Go back to Home tab
      _selectedIndex = 0;
    });
  }

  void _showAddSongSheet() {
    if (_activeSessionId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSongSheet(sessionId: _activeSessionId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInSession = _activeSessionId != null;

    return Scaffold(
      // Show session info in app bar when in a session
      appBar: isInSession
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeSessionName ?? 'Session',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_activeSessionMoods.isNotEmpty)
                    Text(
                      _activeSessionMoods.join('  ·  '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
              actions: [
                // Leave session button
                IconButton(
                  icon: const Icon(Icons.exit_to_app_rounded),
                  onPressed: () => _showLeaveDialog(),
                  tooltip: 'Leave Session',
                ),
              ],
            )
          : null,

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab - Shows session list, create/join
          HomeScreen(
            onEnterSession: _enterSession,
            activeSessionId: _activeSessionId,
          ),

          // Now Playing Tab - Shows current queue and now playing
          isInSession
              ? _QueueTab(sessionId: _activeSessionId!, isHost: _isHost)
              : _EmptyState(
                  icon: Icons.music_note_rounded,
                  title: 'No Active Session',
                  message: 'Join or create a session to see what\'s playing',
                  onAction: () => _selectedIndex = 0,
                ),

          // Chat Tab
          isInSession
              ? ChatScreen(sessionId: _activeSessionId!)
              : _EmptyState(
                  icon: Icons.chat_bubble_rounded,
                  title: 'No Active Session',
                  message: 'Join a session to start chatting',
                  onAction: () => _selectedIndex = 0,
                ),

          // Stats Tab
          isInSession
              ? StatsScreen(sessionId: _activeSessionId!)
              : _EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No Active Session',
                  message: 'Join a session to see statistics',
                  onAction: () => _selectedIndex = 0,
                ),

          // You Tab (Profile)
          ProfileScreen(onLeaveSession: _leaveSession),
        ],
      ),

      bottomNavigationBar: VibzBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
        isInSession: isInSession,
      ),

      // FAB for adding songs - only show when in a session and on Now tab
      floatingActionButton: (isInSession && _selectedIndex == 1)
          ? FloatingActionButton.extended(
              onPressed: _showAddSongSheet,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Song',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          _isHost ? 'End session?' : 'Leave session?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _isHost
              ? 'This will end the session for everyone.'
              : 'You can rejoin with the session code.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_isHost) {
                // End session for everyone
                await FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(_activeSessionId)
                    .update({'isActive': false});
              } else {
                // Remove user from session members
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null && _activeSessionId != null) {
                  await FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(_activeSessionId)
                      .update({
                        'memberUids': FieldValue.arrayRemove([userId]),
                      });
                }
              }
              _leaveSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(_isHost ? 'End' : 'Leave'),
          ),
        ],
      ),
    );
  }
}

// Queue Tab Widget for Now Playing screen
class _QueueTab extends StatefulWidget {
  final String sessionId;
  final bool isHost;

  const _QueueTab({required this.sessionId, required this.isHost});

  @override
  State<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<_QueueTab> {
  final QueueService _queueService = QueueService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<QueueItem>>(
      stream: _queueService.streamQueue(widget.sessionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final queue = snapshot.data!;

        if (queue.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  size: 64,
                  color: Colors.white38,
                ),
                SizedBox(height: 16),
                Text(
                  'No songs in queue',
                  style: TextStyle(color: Colors.white60),
                ),
                Text(
                  'Tap the + button to add a song',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final item = queue[index];
            final userVote = item.getUserVote(currentUserId ?? '');

            return _QueueTile(
              sessionId: widget.sessionId,
              queueItem: item,
              userVote: userVote,
            );
          },
        );
      },
    );
  }
}

class _QueueTile extends StatefulWidget {
  final String sessionId;
  final QueueItem queueItem;
  final int userVote;

  const _QueueTile({
    required this.sessionId,
    required this.queueItem,
    required this.userVote,
  });

  @override
  State<_QueueTile> createState() => _QueueTileState();
}

class _QueueTileState extends State<_QueueTile> {
  late int _tempVote;
  final QueueService _queueService = QueueService();

  @override
  void initState() {
    super.initState();
    _tempVote = widget.userVote;
  }

  @override
  void didUpdateWidget(_QueueTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userVote != oldWidget.userVote) {
      _tempVote = widget.userVote;
    }
  }

  Future<void> _handleVote(int voteValue) async {
    final newVote = _tempVote == voteValue ? 0 : voteValue;
    setState(() {
      _tempVote = newVote;
    });
    await _queueService.vote(widget.sessionId, widget.queueItem.id, voteValue);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final displayVotes =
        widget.queueItem.voteScore + (_tempVote - widget.userVote);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.queueItem.isPlaying
            ? primary.withOpacity(0.15)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.queueItem.isPlaying ? primary : Colors.white12,
          width: widget.queueItem.isPlaying ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              image: widget.queueItem.albumArtUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.queueItem.albumArtUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.queueItem.albumArtUrl.isEmpty
                ? Icon(Icons.music_note_rounded, color: primary, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.queueItem.trackTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.queueItem.artistName,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Added by ${widget.queueItem.addedByName}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Column(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_rounded,
                active: _tempVote == 1,
                color: primary,
                onTap: () => _handleVote(1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '$displayVotes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: displayVotes > 0
                        ? primary
                        : displayVotes < 0
                        ? Theme.of(context).colorScheme.error
                        : Colors.white60,
                  ),
                ),
              ),
              _VoteButton(
                icon: Icons.thumb_down_rounded,
                active: _tempVote == -1,
                color: Theme.of(context).colorScheme.error,
                onTap: () => _handleVote(-1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: active ? color : Colors.white38),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white38)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onAction, child: const Text('Go to Home')),
        ],
      ),
    );
  }
}

class VibzBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isInSession;

  const VibzBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isInSession = false,
  });

  static const List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.music_note_rounded, 'label': 'Now'},
    {'icon': Icons.chat_bubble_rounded, 'label': 'Chat'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Stats'},
    {'icon': Icons.person_rounded, 'label': 'You'},
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF7A00);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = selectedIndex == index;
          final iconData = tab['icon'] as IconData;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData,
                    color: isSelected ? activeColor : Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      color: isSelected ? activeColor : Colors.white54,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
