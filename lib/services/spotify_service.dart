import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/SpotifyTrack.dart';

class SpotifyService {
  static const String clientId = 'af4db2557d024966bd989b82ad714671';
  static const String redirectUri = 'vibzcheck://spotify-callback';
  static const String authEndpoint = 'https://accounts.spotify.com/authorize';
  static const String tokenEndpoint = 'https://accounts.spotify.com/api/token';

  static const _storage = FlutterSecureStorage();

  // Keys for storage
  static const String _accessTokenKey = 'spotify_access_token';
  static const String _refreshTokenKey = 'spotify_refresh_token';
  static const String _tokenExpiryKey = 'spotify_token_expiry';

  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> loginWithSpotify() async {
    try {
      final verifier = _generateCodeVerifier();
      final challenge = _generateCodeChallenge(verifier);

      await _storage.write(key: 'spotify_code_verifier', value: verifier);

      final authUrl = Uri.parse(authEndpoint).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'code_challenge_method': 'S256',
          'code_challenge': challenge,
          'scope': 'user-read-private user-read-email streaming',
        },
      );

      print('Opening Spotify auth URL: $authUrl');

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'vibzcheck',
      );

      print('Auth result: $result');

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        throw Exception('Spotify login failed: No code returned');
      }

      await _exchangeCodeForToken(code);
      print('Spotify login successful!');
    } catch (e) {
      print('Spotify login error: $e');
      rethrow;
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    try {
      final verifier = await _storage.read(key: 'spotify_code_verifier');

      if (verifier == null) {
        throw Exception('Code verifier not found');
      }

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': verifier,
        },
      );

      print('Token response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Spotify token error: ${response.body}');
      }

      final data = jsonDecode(response.body);

      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final expiresIn = data['expires_in'] as int;

      // Calculate expiry time
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

      // Save tokens
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.toIso8601String(),
      );

      print('Tokens saved. Access token: ${accessToken.substring(0, 20)}...');
      print('Token expires at: $expiryTime');
    } catch (e) {
      print('Token exchange error: $e');
      rethrow;
    }
  }

  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final expiryStr = await _storage.read(key: _tokenExpiryKey);

      if (accessToken == null) {
        print('No access token found');
        return null;
      }

      // Check if token is expired
      if (expiryStr != null) {
        final expiryTime = DateTime.parse(expiryStr);
        if (DateTime.now().isBefore(expiryTime)) {
          print('Access token is still valid');
          return accessToken;
        }
      }

      print('Access token expired, trying to refresh...');

      // Try to refresh the token
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        return await _refreshAccessToken(refreshToken);
      }

      return null;
    } catch (e) {
      print('Error getting valid access token: $e');
      return null;
    }
  }

  Future<String?> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode != 200) {
        print('Refresh token failed: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      final newAccessToken = data['access_token'];
      final expiresIn = data['expires_in'] as int;
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

      // Save new tokens
      await _storage.write(key: _accessTokenKey, value: newAccessToken);
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.toIso8601String(),
      );

      // Some responses include a new refresh token
      if (data['refresh_token'] != null) {
        await _storage.write(
          key: _refreshTokenKey,
          value: data['refresh_token'],
        );
      }

      print('Token refreshed successfully');
      return newAccessToken;
    } catch (e) {
      print('Refresh token error: $e');
      return null;
    }
  }

  // Legacy method - keep for compatibility
  Future<String?> getAccessToken() async {
    return await getValidAccessToken();
  }

  Future<bool> isConnected() async {
    final token = await getValidAccessToken();
    return token != null;
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: 'spotify_code_verifier');
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    final accessToken = await getValidAccessToken();

    if (accessToken == null) {
      throw Exception('Not connected to Spotify. Please connect first.');
    }

    print('🔍 Searching for: $query');
    print('🔑 Using token: ${accessToken.substring(0, 20)}...');

    try {
      // Build query parameters as Map<String, String>
      final queryParams = <String, String>{
        'q': query.trim(),
        'type': 'track',
        'limit': '20',
        'offset': '0', // String is actually fine for Uri.https
      };
      final searchUri = Uri.https('api.spotify.com', 'v1/search', {
        'q': query.trim(),
        'type': 'track',
        'limit': '10',
        'offset': '0',
      });

      print('🌍 FINAL SPOTIFY URL: $searchUri');

      final response = await http.get(
        searchUri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 401) {
        print('🔄 Token expired, attempting refresh...');
        final newToken = await getValidAccessToken();
        if (newToken != null && newToken != accessToken) {
          print('🔄 Retrying with new token...');
          final retryResponse = await http.get(
            Uri.https('api.spotify.com', '/v1/search', {
              'q': query,
              'type': 'track',
              'limit': '10',
              'offset': '0',
            }),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
          );

          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            final tracks = data['tracks']['items'] as List;
            return tracks
                .map(
                  (track) =>
                      SpotifyTrack.fromJson(track as Map<String, dynamic>),
                )
                .toList();
          }
        }
        throw Exception(
          'Spotify authentication failed. Please reconnect your account.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Spotify search failed: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final tracks = data['tracks']['items'] as List;

      print('✅ Found ${tracks.length} tracks');

      if (tracks.isEmpty) {
        return [];
      }

      return tracks
          .map((track) => SpotifyTrack.fromJson(track as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Search error: $e');
      rethrow;
    }
  }
}
