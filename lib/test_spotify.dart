import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../theme.dart';

class TestSpotifyScreen extends StatefulWidget {
  const TestSpotifyScreen({super.key});

  @override
  State<TestSpotifyScreen> createState() => _TestSpotifyScreenState();
}

class _TestSpotifyScreenState extends State<TestSpotifyScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isConnected = false;
  String _status = 'Not connected';
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connected = await _spotifyService.isConnected();
    setState(() {
      _isConnected = connected;
      _status = connected ? 'Connected to Spotify' : 'Not connected';
    });
  }

  Future<void> _connectSpotify() async {
    setState(() {
      _status = 'Connecting to Spotify...';
    });

    try {
      await _spotifyService.loginWithSpotify();
      await _checkConnection();
      setState(() {
        _status = 'Connected successfully!';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spotify Connected!')));
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  Future<void> _disconnectSpotify() async {
    await _spotifyService.disconnect();
    await _checkConnection();
    setState(() {
      _searchResults = [];
      _status = 'Disconnected';
    });
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _status = 'Searching...';
    });

    try {
      final results = await _spotifyService.searchTracks(query);
      setState(() {
        _searchResults = results;
        _status = 'Found ${results.length} songs';
      });
    } catch (e) {
      setState(() {
        _status = 'Search error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SPOTIFY TEST'),
        backgroundColor: AppTheme.darkBg,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.cardGlow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isConnected ? AppTheme.primaryOrange : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isConnected)
                    ElevatedButton(
                      onPressed: _connectSpotify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('CONNECT SPOTIFY'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _disconnectSpotify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('DISCONNECT'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search Section (only if connected)
            if (_isConnected) ...[
              const Text(
                'SEARCH SONGS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onSubmitted: _searchSongs,
                      decoration: const InputDecoration(
                        hintText: 'Enter song name...',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _searchSongs(
                      (context.findRenderObject() as TextField?)
                              ?.controller
                              ?.text ??
                          '',
                    ),
                    icon: Icon(Icons.search, color: AppTheme.primaryOrange),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Results
              Expanded(
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'SEARCH FOR SONGS ABOVE',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final track = _searchResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                if (track.albumArtUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      track.albumArtUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.white12,
                                        child: const Icon(Icons.music_note),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.trackTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        track.artistName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
