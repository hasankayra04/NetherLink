import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user_model.dart';

class UserService {
  static const String _base = 'https://eubackend.netherlink.net';
  static const Duration _timeout = Duration(seconds: 8);

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<UserModel?> getMe() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/users/me'), headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return UserModel.fromJson(
            (jsonDecode(res.body) as Map<String, dynamic>)['user']
                as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<({UserModel? user, String? error})> register({
    required String username,
    String? displayName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/users/register'),
            headers: await _headers(),
            body: jsonEncode({
              'username': username,
              if (displayName?.isNotEmpty == true) 'displayName': displayName,
            }),
          )
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        return (
          user: UserModel.fromJson(body['user'] as Map<String, dynamic>),
          error: null,
        );
      }
      return (user: null, error: body['error'] as String?);
    } catch (_) {
      return (user: null, error: 'network_error');
    }
  }

  static Future<UserModel?> updateMe({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_base/api/users/me'),
            headers: await _headers(),
            body: jsonEncode({
              if (displayName != null) 'displayName': displayName,
              if (avatarUrl != null) 'avatarUrl': avatarUrl,
              if (bio != null) 'bio': bio,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return UserModel.fromJson(
            (jsonDecode(res.body) as Map<String, dynamic>)['user']
                as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<FriendModel>> getFriends() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/users/me/friends'),
              headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final list =
            (jsonDecode(res.body) as Map<String, dynamic>)['friends']
                as List<dynamic>;
        return list
            .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/users/me/friend-requests'),
              headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final list =
            (jsonDecode(res.body) as Map<String, dynamic>)['requests']
                as List<dynamic>;
        return list
            .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<String?> sendFriendRequest(String username) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/users/me/friends/$username'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      if (res.statusCode == 201) return null;
      return (jsonDecode(res.body) as Map<String, dynamic>)['error']
          as String?;
    } catch (_) {
      return 'network_error';
    }
  }

  static Future<bool> acceptFriendRequest(String username) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_base/api/users/me/friends/$username/accept'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeFriend(String username) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_base/api/users/me/friends/$username'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<UserModel?> getProfile(String username) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/users/$username'),
              headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return UserModel.fromJson(
            (jsonDecode(res.body) as Map<String, dynamic>)['user']
                as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}