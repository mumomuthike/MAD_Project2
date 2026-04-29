import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

// ProfileScreen — view/edit profile, view/edit settings, and view stats
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Re-read user after edits so the UI reflects the latest display name.
  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName =>
      _user?.displayName?.isNotEmpty == true ? _user!.displayName! : 'Anonymous';

  String get _email => _user?.email ?? '';

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  void _showEditName() {
    final ctrl = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Edit Display Name',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await FirebaseAuth.instance.currentUser
                    ?.updateDisplayName(name);
              }
              if (mounted) {
                setState(() {}); // refresh displayed name
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          // Avatar
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: primary.withOpacity(0.2),
                  child: Text(
                    (_displayName.isNotEmpty ? _displayName[0] : '?')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showEditName,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.black, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Name & email
          Center(
            child: Text(
              _displayName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _email,
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ),
          const SizedBox(height: 32),

          // Stats row
          // TODO: replace hardcoded values with Firestore data
          Row(
            children: [
              _StatBox(label: 'Sessions', value: '12'),
              const SizedBox(width: 12),
              _StatBox(label: 'Songs Added', value: '84'),
              const SizedBox(width: 12),
              _StatBox(label: 'Votes Cast', value: '213'),
            ],
          ),
          const SizedBox(height: 28),

          // Settings section
          _SectionLabel(label: 'Account'),
          const SizedBox(height: 10),
          _ProfileTile(
            icon: Icons.edit_outlined,
            label: 'Edit Display Name',
            onTap: _showEditName,
          ),
          _ProfileTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () {}, // TODO
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: 'App'),
          const SizedBox(height: 10),
          _ProfileTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {}, // TODO
          ),
          _ProfileTile(
            icon: Icons.music_note_outlined,
            label: 'Connect Spotify',
            onTap: () {}, // TODO
          ),
          _ProfileTile(
            icon: Icons.bar_chart_rounded,
            label: 'My Stats',
            onTap: () {}, // TODO
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: 'Session'),
          const SizedBox(height: 10),
          _ProfileTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            labelColor: Theme.of(context).colorScheme.error,
            onTap: _signOut,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Helpers
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primary)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: TextStyle(color: color, fontSize: 14))),
            Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}