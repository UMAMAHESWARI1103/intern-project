import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class UserService {
  static const String _userKey       = 'logged_in_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user data after login
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get current logged in user
  static Future<User?> getUser() async {
    final prefs      = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);

    if (userString != null) {
      try {
        final userJson = json.decode(userString);
        return User.fromJson(userJson);
      } catch (e) {
        // FIX line 26: replaced print() with debugPrint() — safe for production
        debugPrint('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update user data
  static Future<void> updateUser(User user) async {
    await saveUser(user);
  }
}