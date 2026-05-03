import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../services/spotify_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLeaveSession;

  const ProfileScreen({super.key, this.onLeaveSession});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isConnecting = false;
  bool _isSpotifyConnected = false;
  String? _spotifyUserName;

  @override
  void initState() {
    super.initState();
    _checkSpotifyConnection();
  }

  Future<void> _checkSpotifyConnection() async {
    final connected = await _spotifyService.isConnected();
    if (mounted) {
      setState(() {
        _isSpotifyConnected = connected;
      });
    }
  }

  Future<void> _connectSpotify() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      await _spotifyService.loginWithSpotify();
      await _checkSpotifyConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SPOTIFY CONNECTED!'),
            backgroundColor: AppTheme.primaryOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CONNECTION FAILED: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _disconnectSpotify() async {
    await _spotifyService.disconnect();
    setState(() {
      _isSpotifyConnected = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SPOTIFY DISCONNECTED'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar with glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                child: Text(
                  (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0]
                          : user?.email?[0] ?? '?')
                      .toUpperCase(),
                  style: TextStyle(fontSize: 40, color: AppTheme.primaryOrange),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              (user?.displayName ??
                      user?.email?.split('@').first ??
                      'ANONYMOUS')
                  .toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              user?.email?.toUpperCase() ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),

            // Spotify Connect Button (WORKING VERSION)
            _SpotifyConnectButton(
              isConnecting: _isConnecting,
              isConnected: _isSpotifyConnected,
              spotifyUserName: _spotifyUserName,
              onConnect: _connectSpotify,
              onDisconnect: _disconnectSpotify,
            ),
            const SizedBox(height: 24),

            // Session History
            const _SessionHistory(),
            const SizedBox(height: 16),

            // Sign Out Button
            ElevatedButton(
              onPressed: () async {
                widget.onLeaveSession?.call();
                await FirebaseAuth.instance.signOut();
                await _spotifyService.disconnect();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              child: const Text('SIGN OUT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotifyConnectButton extends StatelessWidget {
  final bool isConnecting;
  final bool isConnected;
  final String? spotifyUserName;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _SpotifyConnectButton({
    required this.isConnecting,
    required this.isConnected,
    required this.spotifyUserName,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isConnecting ? null : (isConnected ? onDisconnect : onConnect),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isConnected
                ? [
                    AppTheme.primaryOrange.withOpacity(0.15),
                    AppTheme.primaryPink.withOpacity(0.05),
                  ]
                : [AppTheme.surfaceDark, AppTheme.surfaceDark],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected ? AppTheme.primaryOrange : Colors.white12,
            width: isConnected ? 1.5 : 1,
          ),
          boxShadow: isConnected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isConnected ? AppGradients.primaryGlow : null,
                color: isConnected ? null : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isConnecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                  : Icon(
                      isConnected
                          ? Icons.check_circle_rounded
                          : Icons.music_note_rounded,
                      color: isConnected
                          ? Colors.black
                          : AppTheme.primaryOrange,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'SPOTIFY CONNECTED' : 'CONNECT SPOTIFY',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected
                        ? (spotifyUserName?.toUpperCase() ?? 'READY TO VIBE')
                        : 'GET PERSONALIZED RECOMMENDATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: isConnected
                          ? AppTheme.primaryOrange
                          : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            // Action button text
            Text(
              isConnected ? 'DISCONNECT' : 'CONNECT →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: isConnected ? AppTheme.primaryOrange : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHistory extends StatelessWidget {
  const _SessionHistory();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT SESSIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions')
              .where('memberUids', arrayContains: userId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data!.docs;

            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'NO SESSIONS YET',
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
                final isActive = data['isActive'] ?? false;
                final createdAt =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'ENDED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} MONTHS AGO';
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()} WEEKS AGO';
    if (diff.inDays > 0) return '${diff.inDays} DAYS AGO';
    if (diff.inHours > 0) return '${diff.inHours} HOURS AGO';
    return 'JUST NOW';
  }
}
