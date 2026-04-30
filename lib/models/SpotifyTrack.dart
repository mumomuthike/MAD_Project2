// SpotifyTrack is built from the Spotify API response bridged via
// Firebase Cloud Functions — it is NOT stored directly in Firestore.
// It is used in the UI for search results and passed to QueueItem when
// a user adds a song to the session queue.
class SpotifyTrack {
  final String id;             // Spotify track ID
  final String title;
  final String artist;
  final String album;
  final String albumArtUrl;
  final int durationMs;
  final String previewUrl;     // 30-second preview from Spotify

  const SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtUrl,
    required this.durationMs,
    required this.previewUrl,
  });

  // Build a SpotifyTrack from the Spotify API JSON response
  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    // Handle the nested artists array from Spotify's response shape
    final artists = json['artists'] as List<dynamic>? ?? [];
    final artistNames = artists
        .map((a) => a['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');

    // Album art is in images[0].url inside the album object
    final album = json['album'] as Map<String, dynamic>? ?? {};
    final images = album['images'] as List<dynamic>? ?? [];
    final artUrl = images.isNotEmpty
        ? (images[0]['url'] as String? ?? '')
        : '';

    return SpotifyTrack(
      id: json['id'] as String,
      title: json['name'] as String,
      artist: artistNames,
      album: album['name'] as String? ?? '',
      albumArtUrl: artUrl,
      durationMs: json['duration_ms'] as int? ?? 0,
      previewUrl: json['preview_url'] as String? ?? '',
    );
  }
  // Convenience getter — formatted duration e.g. "3:45"
  String get durationFormatted {
    final total = Duration(milliseconds: durationMs);
    final minutes = total.inMinutes;
    final seconds = (total.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  // Convert to the fields QueueItem needs when adding to the Firestore queue
  Map<String, dynamic> toQueueFields() {
    return {
      'spotifyTrackId': id,
      'trackTitle': title,
      'artistName': artist,
      'albumArtUrl': albumArtUrl,
    };
  }
}