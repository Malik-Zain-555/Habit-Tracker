import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ...

  // ...

  bool _isAuthenticated = false;
  String? _username;
  String? _avatarUrl;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get avatarUrl => _avatarUrl;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token');
      _username = prefs.getString('username');
      _avatarUrl = prefs.getString('avatarUrl');
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      _username = response['username'];
      _avatarUrl = response['avatarUrl'];
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (_username != null) await prefs.setString('username', _username!);
      if (_avatarUrl != null) await prefs.setString('avatarUrl', _avatarUrl!);

      print('AuthProvider: Login successful for $email. Notifying listeners.');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Login failed. Error: $e');
      rethrow;
    }
  }

  Future<void> signup(String username, String email, String password) async {
    try {
      final response = await _apiService.signup(username, email, password);
      _token = response['token'];
      _username =
          username; // Signup usually returns generic msg or token, we can assume username or fetch it
      // Actually backend signup doesn't return token/user in my code?
      // Wait, let's checking backend auth.js: headers: ... res.status(201).json({ message: 'User created', userId: docRef.id });
      // Backend /signup DOES NOT return token currently! It forces login.
      // So signup here shouldn't set isAuthenticated. It should just return.
      // Modifying to match backend behavior: Signup -> Login implicitly or explicitly.
      // User likely expects auto-login.

      // Let's AUTO LOGIN after signup for better UX, or just return.
      // Current AuthProvider code assumes it sets token.
      // Backend: auth.js:38 res.status(201).json({ message: 'User created', userId: docRef.id });
      // It DOES NOT return token.

      // Fix: Auto-login after signup
      await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    // await _googleSignIn.signOut();
    await _apiService.logout();
    _isAuthenticated = false;
    _username = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');

    print('AuthProvider: Logout called. Notifying listeners.');
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    final response = await _apiService.updateProfile(
      username: username,
      avatarUrl: avatarUrl,
    );
    _username = response['username'];
    if (response['avatarUrl'] != null) _avatarUrl = response['avatarUrl'];

    final prefs = await SharedPreferences.getInstance();
    if (_username != null) await prefs.setString('username', _username!);
    if (_avatarUrl != null) await prefs.setString('avatarUrl', _avatarUrl!);

    notifyListeners();
  }
}
