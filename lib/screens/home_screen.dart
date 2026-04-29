import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'session_screen.dart';

// HomeScreen — create/join session and view recent sessions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, color: primary, size: 22),
            const SizedBox(width: 6),
            Text(
              'Vibzcheck',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openProfile,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: Text(
                  (user?.displayName?.isNotEmpty == true
                      ? user!.displayName![0]
                      : user?.email?[0] ?? '?')
                      .toUpperCase(),
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: const _LobbyTab(),
    );
  }
}

// Lobby — create or join a session
class _LobbyTab extends StatefulWidget {
  const _LobbyTab();

  @override
  State<_LobbyTab> createState() => _LobbyTabState();
}

class _LobbyTabState extends State<_LobbyTab> {
  final _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  void _createSession() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSessionSheet(
        onCreated: (name, moods) {
          // TODO: write Firestore session document before navigating
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SessionScreen(
                sessionName: name,
                moods: moods,
                isHost: true,
              ),
            ),
          );
        },
      ),
    );
  }

  void _joinSession() {
    // TODO: look up Firestore session by code and navigate to SessionScreen
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'there';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Greeting
        _GreetingHeader(displayName: displayName),
        const SizedBox(height: 32),

        // Create session card
        _SectionLabel(label: 'Start a session'),
        const SizedBox(height: 12),
        _CreateSessionCard(onTap: _createSession),
        const SizedBox(height: 28),

        // Join session card
        _SectionLabel(label: 'Join a session'),
        const SizedBox(height: 12),
        _JoinSessionCard(
          controller: _joinCodeController,
          onJoin: _joinSession,
        ),
        const SizedBox(height: 28),

        // Recent sessions
        _SectionLabel(label: 'Recent sessions'),
        const SizedBox(height: 12),
        const _RecentSessionsList(),
        const SizedBox(height: 28),

        const SizedBox(height: 8),
      ],
    );
  }
}

// Greeting header
class _GreetingHeader extends StatelessWidget {
  final String displayName;
  const _GreetingHeader({required this.displayName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $displayName 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to vibe with your crew?',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}

// Section label
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white60,
        letterSpacing: 1.4,
      ),
    );
  }
}

// Create session card
class _CreateSessionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateSessionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.85), primary.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Create New Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Start a collaborative playlist & invite friends',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// Join session card
class _JoinSessionCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onJoin;

  const _JoinSessionCard({
    required this.controller,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_scanner_rounded,
                    color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Enter a session code',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'e.g. VIBE-4829',
                    prefixIcon:
                    Icon(Icons.tag_rounded, color: Colors.white70, size: 20),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => onJoin(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Recent sessions list  (placeholder tiles — replace with Firestore stream)
class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList();

  static const _mock = [
    _MockSession('Friday Night Vibes 🎵', 'VIBE-4829', 6, '2 days ago'),
    _MockSession('Study Beats 📚', 'VIBE-1103', 3, '5 days ago'),
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: replace with StreamBuilder on Firestore
    if (_mock.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text(
            'No recent sessions yet.\nCreate or join one above!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _mock
          .map((s) => _RecentSessionTile(session: s))
          .toList(),
    );
  }
}

class _MockSession {
  final String name;
  final String code;
  final int memberCount;
  final String timeAgo;
  const _MockSession(this.name, this.code, this.memberCount, this.timeAgo);
}

class _RecentSessionTile extends StatelessWidget {
  final _MockSession session;
  const _RecentSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.queue_music_rounded, color: primary, size: 22),
        ),
        title: Text(
          session.name,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 12, color: Colors.white60),
            const SizedBox(width: 4),
            Text(
              '${session.memberCount} members · ${session.timeAgo}',
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: session.code));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code "${session.code}" copied!'),
                duration: const Duration(seconds: 2),
                backgroundColor: primary,
              ),
            );
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              session.code,
              style: TextStyle(
                  fontSize: 11,
                  color: primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}
// Create session bottom sheet
class _CreateSessionSheet extends StatefulWidget {
  final void Function(String name, List<String> moods) onCreated;
  const _CreateSessionSheet({required this.onCreated});

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final Set<String> _selectedMoods = {};

  static const _moods = [
    ('🔥', 'Hype'),
    ('😌', 'Chill'),
    ('💃', 'Party'),
    ('📚', 'Focus'),
    ('💔', 'Sad'),
    ('🌙', 'Late Night'),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus name field after sheet animates in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    // TODO: write Firestore session document here
    Navigator.pop(context);
    widget.onCreated(name, _selectedMoods.toList());
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'New Session',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Give your session a name and set the vibe.',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 24),

          // Session name field
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            decoration: const InputDecoration(
              hintText: 'Session name',
              prefixIcon: Icon(Icons.edit_rounded, color: Colors.white60, size: 20),
            ),
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),

          // Mood tags
          const Text(
            'MOOD TAGS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _moods.map((m) {
              final selected = _selectedMoods.contains(m.$2);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedMoods.remove(m.$2) : _selectedMoods.add(m.$2);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected ? primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${m.$1}  ${m.$2}',
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? primary : Colors.white70,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Create Session'),
            ),
          ),
        ],
      ),
    );
  }
}