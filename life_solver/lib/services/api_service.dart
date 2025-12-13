import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Desktop
  // If running on real device, you need your PC's LAN IP (e.g. 192.168.x.x)
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    return 'http://127.0.0.1:5000/api';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- Auth & Profile ---
  Future<Map<String, dynamic>> signup(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    print('Signup Response Status: ${response.statusCode}');
    print('Signup Response Body: ${response.body}');

    if (response.statusCode != 201) {
      final error = json.decode(response.body)['error'];
      throw error ?? 'Signup failed';
    }
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('Attempting login for: $email');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw json.decode(response.body)['error'];
      }
      return json.decode(response.body);
    } catch (e) {
      print('Login Exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': idToken}),
    );
    if (response.statusCode != 200) throw Exception('Google Login Failed');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'username': username, 'avatarUrl': avatarUrl}),
    );
    if (response.statusCode != 200) {
      print('Update Profile Error: ${response.body}');
      throw Exception('Failed to update profile: ${response.body}');
    }
    return json.decode(response.body);
  }

  Future<void> deleteAccount() async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to delete account');
  }

  // --- Habits ---
  Future<List<dynamic>> getHabits() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/habits'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch habits');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> createHabit(
    String title,
    String description,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/habits'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'title': title, 'description': description}),
    );
    if (response.statusCode != 201) throw Exception('Failed to create habit');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateHabit(
    String id,
    String title,
    String description,
  ) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/habits/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'title': title, 'description': description}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update habit');
    return json.decode(response.body);
  }

  Future<void> deleteHabit(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/habits/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to delete habit');
  }

  Future<Map<String, dynamic>> completeHabit(String habitId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/habits/$habitId/complete'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final error =
          json.decode(response.body)['message'] ?? 'Failed to complete habit';
      throw Exception(error);
    }
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> failHabit(String habitId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/habits/$habitId/fail'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200)
      throw Exception('Failed to update habit status');
    return json.decode(response.body);
  }

  // --- Notes ---
  Future<List<dynamic>> getNotes() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/notes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch notes');
    return json.decode(response.body);
  }

  Future<void> createNote(String title, String content) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'title': title, 'content': content}),
    );
    if (response.statusCode != 201) {
      print('Create Note Error: ${response.body}');
      throw Exception('Failed to create note');
    }
  }

  Future<void> deleteNote(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/notes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to delete note');
  }

  // --- Tasks ---
  Future<List<dynamic>> getTasks() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch tasks');
    return json.decode(response.body);
  }

  Future<void> createTask(String title, {String? dueTime}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'title': title, 'dueTime': dueTime}),
    );
    if (response.statusCode != 201) {
      print('Create Task Error: ${response.body}');
      throw Exception('Failed to create task');
    }
  }

  Future<void> toggleTask(String id, bool done) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'done': done}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update task');
  }

  Future<void> deleteTask(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to delete task');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<List<dynamic>> getLeaderboard() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/leaderboard'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200)
      throw Exception('Failed to fetch leaderboard');
    return json.decode(response.body);
  }
}
