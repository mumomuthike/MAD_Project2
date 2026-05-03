class SpotifyTrack {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final int durationMs;

  SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.durationMs,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'],
      title: json['name'],
      artist: (json['artists'] as List).map((a) => a['name']).join(', '),
      albumArtUrl: json['album']['images'].isNotEmpty
          ? json['album']['images'][0]['url']
          : '',
      durationMs: json['duration_ms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArtUrl': albumArtUrl,
      'durationMs': durationMs,
    };
  }

  String get formattedDuration {
    final minutes = (durationMs / 60000).floor();
    final seconds = ((durationMs % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
