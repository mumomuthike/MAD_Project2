import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../services/QueueService.dart';
import '../models/SpotifyTrack.dart';

class AddSongSheet extends StatefulWidget {
  final String sessionId;

  const AddSongSheet({super.key, required this.sessionId});

  @override
  State<AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<AddSongSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SpotifyService _spotifyService = SpotifyService();
  final QueueService _queueService = QueueService();

  List<SpotifyTrack> _searchResults = [];
  bool _isSearching = false;
  bool _isAdding = false;
  String? _errorMessage;
  bool _isSpotifyConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkSpotifyConnection();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkSpotifyConnection() async {
    final token = await _spotifyService.getAccessToken();

    if (!mounted) return;

    setState(() {
      _isSpotifyConnected = token != null;
    });
  }

  Future<void> _connectSpotify() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await _spotifyService.loginWithSpotify();

      if (!mounted) return;

      setState(() {
        _isSpotifyConnected = true;
        _isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully connected to Spotify!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to connect to Spotify: ${e.toString()}';
        _isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchSongs() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    if (!_isSpotifyConnected) {
      setState(() {
        _errorMessage = 'Please connect to Spotify first';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final results = await _spotifyService.searchTracks(query);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No songs found. Try a different search.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to search songs: ${e.toString()}';
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _addToQueue(SpotifyTrack track) async {
    setState(() {
      _isAdding = true;
    });

    try {
      await _queueService.addToQueue(widget.sessionId, track);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${track.title}" to queue!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAdding = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add song: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Add a Song',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              if (!_isSpotifyConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.music_note_rounded,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect to Spotify',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Search and add songs from Spotify',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isConnecting ? null : _connectSpotify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Connect'),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_isSpotifyConnected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search for a song...',
                            hintStyle: TextStyle(color: Colors.white60),
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchSongs(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchSongs,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),

              if (_searchResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEARCH RESULTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final track = _searchResults[index];

                          return _SearchResultTile(
                            track: track,
                            onAdd: () => _addToQueue(track),
                            isAdding: _isAdding,
                          );
                        },
                      ),
                    ],
                  ),
                ),

              if (_searchResults.isEmpty &&
                  !_isSearching &&
                  _searchController.text.isNotEmpty &&
                  _isSpotifyConnected)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 48,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No songs found',
                        style: TextStyle(color: Colors.white60),
                      ),
                      Text(
                        'Try a different search term',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              if (_searchResults.isEmpty &&
                  _searchController.text.isEmpty &&
                  _isSpotifyConnected)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 48,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Search for a song to add to the queue',
                        style: TextStyle(color: Colors.white60),
                      ),
                      Text(
                        'Search by song name or artist',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SpotifyTrack track;
  final VoidCallback onAdd;
  final bool isAdding;

  const _SearchResultTile({
    required this.track,
    required this.onAdd,
    required this.isAdding,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              image: track.albumArtUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(track.albumArtUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: track.albumArtUrl.isEmpty
                ? Icon(Icons.album_rounded, color: primary, size: 24)
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
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
                  track.artist,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.formattedDuration,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: isAdding ? null : onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isAdding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
