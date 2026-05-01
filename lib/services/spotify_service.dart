import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/SpotifyTrack.dart';

class SpotifyService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  String? _accessToken;

  // For development without Spotify API, use mock data
  // Set this to false when you have actual Spotify credentials
  static const bool useMockData = true;

  Future<String?> getAccessToken() async {
    if (useMockData) return 'mock_token';

    // TODO: Implement actual Spotify token retrieval
    // You'll need to set up OAuth flow or use Firebase Cloud Functions
    // For now, return null to use mock data
    return null;
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    if (useMockData) {
      return _getMockSearchResults(query);
    }

    try {
      final token = await getAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query&type=track&limit=20'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['items'] as List;
        return tracks.map((track) => SpotifyTrack.fromJson(track)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }

  List<SpotifyTrack> _getMockSearchResults(String query) {
    // Mock data for development/testing
    final mockTracks = [
      SpotifyTrack(
        id: 'mock1',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        albumArtUrl: '',
        durationMs: 200000,
        previewUrl: '',
      ),
      SpotifyTrack(
        id: 'mock2',
        title: 'As It Was',
        artist: 'Harry Styles',
        album: "Harry's House",
        albumArtUrl: '',
        durationMs: 167000,
        previewUrl: '',
      ),
      SpotifyTrack(
        id: 'mock3',
        title: 'Levitating',
        artist: 'Dua Lipa',
        album: 'Future Nostalgia',
        albumArtUrl: '',
        durationMs: 203000,
        previewUrl: '',
      ),
      SpotifyTrack(
        id: 'mock4',
        title: 'Flowers',
        artist: 'Miley Cyrus',
        album: 'Endless Summer Vacation',
        albumArtUrl: '',
        durationMs: 196000,
        previewUrl: '',
      ),
      SpotifyTrack(
        id: 'mock5',
        title: 'Cruel Summer',
        artist: 'Taylor Swift',
        album: 'Lover',
        albumArtUrl: '',
        durationMs: 178000,
        previewUrl: '',
      ),
    ];

    // Filter mock tracks based on search query
    return mockTracks
        .where((track) =>
    track.title.toLowerCase().contains(query.toLowerCase()) ||
        track.artist.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}