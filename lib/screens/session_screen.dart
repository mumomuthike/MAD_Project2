import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

// SessionScreen — users can view and add to the queue and vote on songs / chat
class SessionScreen extends StatefulWidget {
  final String sessionName;
  final List<String> moods;
  final bool isHost;

  // TODO: add sessionId once Firestore is wired up
  const SessionScreen({
    super.key,
    required this.sessionName,
    required this.moods,
    required this.isHost,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _selectedTab = 0; // 0 = Queue, 1 = Chat

  // Placeholder session code — replace with real Firestore doc ID
  static const _sessionCode = 'VIBE-0000';

  void _copyCode() {
    Clipboard.setData(const ClipboardData(text: _sessionCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session code copied!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
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
    if (confirmed == true && mounted) { // return to HomeScreen when session is abandoned
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
                      _sessionCode,
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
                  ? const _QueueTab()
                  : const _ChatTab(),
            ),
          ],
        ),

        // Add song FAB
        floatingActionButton: _selectedTab == 0
            ? FloatingActionButton.extended(
          onPressed: () {
            // TODO: open search-and-add song sheet
          },
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

// Queue Tab — placeholder until Firestore is wired
class _QueueTab extends StatelessWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // TODO: replace with StreamBuilder on Firestore queue subcollection
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _QueuePlaceholderTile(
          title: 'Blinding Lights',
          artist: 'The Weeknd',
          votes: 4,
          addedBy: 'Mumo',
          primary: primary,
        ),
        _QueuePlaceholderTile(
          title: 'As It Was',
          artist: 'Harry Styles',
          votes: 2,
          addedBy: 'William',
          primary: primary,
        ),
        _QueuePlaceholderTile(
          title: 'Levitating',
          artist: 'Dua Lipa',
          votes: 1,
          addedBy: 'Mumo',
          primary: primary,
        ),
        const SizedBox(height: 80), // space above FAB
      ],
    );
  }
}

class _QueuePlaceholderTile extends StatefulWidget {
  final String title;
  final String artist;
  final int votes;
  final String addedBy;
  final Color primary;

  const _QueuePlaceholderTile({
    required this.title,
    required this.artist,
    required this.votes,
    required this.addedBy,
    required this.primary,
  });

  @override
  State<_QueuePlaceholderTile> createState() => _QueuePlaceholderTileState();
}

class _QueuePlaceholderTileState extends State<_QueuePlaceholderTile> {
  int _vote = 0; // -1, 0, or 1

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final primary = widget.primary;
    final displayVotes = widget.votes + _vote;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Album art placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.music_note_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: 12),

          // Title + artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.artist,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 2),
                Text(
                  'Added by ${widget.addedBy}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),

          // Vote buttons
          Column(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_rounded,
                active: _vote == 1,
                color: primary,
                onTap: () => setState(() => _vote = _vote == 1 ? 0 : 1),
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
                active: _vote == -1,
                color: Theme.of(context).colorScheme.error,
                onTap: () => setState(() => _vote = _vote == -1 ? 0 : -1),
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

// Chat Tab — placeholder until Firestore is wired
class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  // Placeholder messages — replace with Firestore stream
  final List<_ChatMessage> _messages = [
    _ChatMessage(author: 'William', text: 'Let\'s get this going! 🎵', isMe: false),
    _ChatMessage(author: 'Me', text: 'Added a few songs, check the queue', isMe: true),
    _ChatMessage(author: 'William', text: 'Love the picks 🔥', isMe: false),
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(author: 'Me', text: text, isMe: true));
      _msgController.clear();
    });
    // TODO: write message to Firestore chat subcollection
    Future.delayed(const Duration(milliseconds: 50), () {
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

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
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
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
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

class _ChatMessage {
  final String author;
  final String text;
  final bool isMe;
  const _ChatMessage({
    required this.author,
    required this.text,
    required this.isMe,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: primary.withOpacity(0.2),
              child: Text(
                message.author[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(
                      message.author,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white60),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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