import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../services/queue_service.dart';
import '../services/chat_service.dart';
import '../models/QueueItem.dart';
import '../models/ChatMessage.dart';

// SessionScreen — users can view and add to the queue and vote on songs / chat
class SessionScreen extends StatefulWidget {
  final String sessionId;
  final String sessionName;
  final List<String> moods;
  final bool isHost;

  const SessionScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
    required this.moods,
    required this.isHost,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _selectedTab = 0; // 0 = Queue, 1 = Chat
  final QueueService _queueService = QueueService();
  final ChatService _chatService = ChatService();

  String? _joinCode;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _loadJoinCode();
  }

  Future<void> _loadJoinCode() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();
      if (doc.exists) {
        setState(() {
          _joinCode = doc.data()?['joinCode'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading join code: $e');
    }
  }

  void _copyCode() {
    if (_joinCode == null) return;
    Clipboard.setData(ClipboardData(text: _joinCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session code copied!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Don't show dialog if already leaving
    if (_isLeaving) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          widget.isHost ? 'End session?' : 'Leave session?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          widget.isHost
              ? 'This will end the session for everyone.'
              : 'You can rejoin with the session code.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isHost ? 'End' : 'Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLeaving = true);

      try {
        if (widget.isHost) {
          // End session for everyone
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc(widget.sessionId)
              .update({'isActive': false});
        } else {
          // Remove user from session members
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('sessions')
                .doc(widget.sessionId)
                .update({
              'memberUids': FieldValue.arrayRemove([userId])
            });
          }
        }

        if (mounted) {
          // Clear navigation stack and go to HomeScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error leaving session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
          setState(() => _isLeaving = false);
        }
      }
    }
    return false;
  }

  void _showAddSongSheet() {
    // TODO: Implement Spotify search and add song functionality
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: const Center(
          child: Text('Add Song UI - Coming Soon'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final code = _joinCode ?? 'LOADING...';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sessionName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.moods.isNotEmpty)
                Text(
                  widget.moods.join('  ·  '),
                  style: TextStyle(fontSize: 11, color: primary),
                ),
            ],
          ),
          leading: BackButton(onPressed: () => _onWillPop()),
          actions: [
            // Session code chip — tap to copy
            GestureDetector(
              onTap: _copyCode,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy_rounded, size: 12, color: primary),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Tab bar for Queue / Chat
        body: Column(
          children: [
            _SessionTabBar(
              selected: _selectedTab,
              onTap: (i) => setState(() => _selectedTab = i),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? _QueueTab(sessionId: widget.sessionId)
                  : _ChatTab(sessionId: widget.sessionId),
            ),
          ],
        ),

        // Add song FAB
        floatingActionButton: _selectedTab == 0
            ? FloatingActionButton.extended(
          onPressed: _showAddSongSheet,
          backgroundColor: primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Song',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        )
            : null,
      ),
    );
  }
}

// Tab bar
class _SessionTabBar extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;

  const _SessionTabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          _Tab(label: 'Queue', icon: Icons.queue_music_rounded,
              active: selected == 0, onTap: () => onTap(0)),
          _Tab(label: 'Chat', icon: Icons.chat_bubble_outline_rounded,
              active: selected == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final color = active ? primary : Colors.white60;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Queue Tab with real Firestore data
class _QueueTab extends StatelessWidget {
  final String sessionId;
  const _QueueTab({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final queueService = QueueService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<QueueItem>>(
      stream: queueService.streamQueue(sessionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading queue: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final queue = snapshot.data!;

        if (queue.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.queue_music_rounded, size: 64, color: Colors.white38),
                SizedBox(height: 16),
                Text(
                  'No songs in queue yet.\nTap the + button to add a song!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final item = queue[index];
            final userVote = item.getUserVote(currentUserId ?? '');
            return _QueueTile(
              queueItem: item,
              userVote: userVote,
              onVote: (voteValue) async {
                await queueService.vote(sessionId, item.id, voteValue);
              },
            );
          },
        );
      },
    );
  }
}

class _QueueTile extends StatefulWidget {
  final QueueItem queueItem;
  final int userVote;
  final Function(int) onVote;

  const _QueueTile({
    required this.queueItem,
    required this.userVote,
    required this.onVote,
  });

  @override
  State<_QueueTile> createState() => _QueueTileState();
}

class _QueueTileState extends State<_QueueTile> {
  late int _tempVote;

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

  void _handleVote(int voteValue) {
    setState(() {
      // Optimistic update
      if (_tempVote == voteValue) {
        _tempVote = 0;
      } else {
        _tempVote = voteValue;
      }
    });
    widget.onVote(voteValue);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final displayVotes = widget.queueItem.voteScore + (_tempVote - widget.userVote);

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
          // Album art
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

          // Track info
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
                Row(
                  children: [
                    if (widget.queueItem.isPlaying) ...[
                      Icon(Icons.play_circle_rounded, size: 12, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        'Now Playing',
                        style: TextStyle(fontSize: 11, color: primary),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        'Added by ${widget.queueItem.addedByName}',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vote buttons
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
        child: Icon(
          icon,
          size: 18,
          color: active ? color : Colors.white38,
        ),
      ),
    );
  }
}

// Chat Tab with real Firestore data
class _ChatTab extends StatefulWidget {
  final String sessionId;
  const _ChatTab({required this.sessionId});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await _chatService.sendMessage(widget.sessionId, text);

    // Scroll to bottom after message is sent
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatService.streamMessages(widget.sessionId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading messages: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final messages = snapshot.data!;

              // Auto-scroll to bottom on new messages
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients && messages.isNotEmpty) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });

              if (messages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.white38),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet.\nBe the first to say something!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.userId == currentUserId;
                  return _ChatBubble(
                    message: message,
                    isMe: isMe,
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(
                    hintText: 'Say something...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.black, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: primary.withOpacity(0.2),
              child: Text(
                message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(
                      message.userName,
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? primary.withOpacity(0.85)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}