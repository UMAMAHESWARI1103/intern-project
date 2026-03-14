import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'https://godsconnect-backend.onrender.com/api';
  static String? _token;

  // ════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ════════════════════════════════════════════

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> setToken(String token) => saveToken(token);

  static Future<String?> loadToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static String? getToken() => _token;

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('userEmail');
  }

  // ════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token'] as String);
      // ✅ Save email for ML recommendations
      final prefs = await SharedPreferences.getInstance();
      final userEmail = (data['user']?['email'] ?? email).toString();
      if (userEmail.isNotEmpty) {
        await prefs.setString('userEmail', userEmail);
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> signUp(
      String name, String email, String password, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name':     name,
        'email':    email,
        'password': password,
        'phone':    phone,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['token'] != null) {
      await saveToken(data['token'] as String);
      // ✅ Save email for ML recommendations
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email);
    }
    return data;
  }

  // ════════════════════════════════════════════
  // USER PROFILE
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await loadToken();
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    final token = await loadToken();
    if (token == null) return false;
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // PRIESTS — PUBLIC (user side)
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getPriests({String? homamType}) async {
    try {
      final token = await loadToken();
      final uri = homamType != null && homamType.isNotEmpty
          ? Uri.parse('$baseUrl/priests?homamType=${Uri.encodeComponent(homamType)}')
          : Uri.parse('$baseUrl/priests');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['priests'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('getPriests error: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════
  // PRIESTS — ADMIN CRUD
  // ════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getAdminPriests() async {
    try {
      final token = await loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/priests'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['priests'] ?? []);
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getAdminPriests error: $e');
      return [];
    }
  }

  static Future<bool> adminAddPriest(Map<String, dynamic> data) async {
    try {
      final token = await loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/priests'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('adminAddPriest error: $e');
      return false;
    }
  }

  static Future<bool> updatePriestApproval(String id, bool approved) async {
    try {
      final token = await loadToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/priests/$id/approve'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isApproved': approved}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updatePriestApproval error: $e');
      return false;
    }
  }

  static Future<bool> updatePriestAvailability(String id, bool available) async {
    try {
      final token = await loadToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/priests/$id/availability'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isAvailable': available}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updatePriestAvailability error: $e');
      return false;
    }
  }

  static Future<bool> deletePriest(String id) async {
    try {
      final token = await loadToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/priests/$id'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deletePriest error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // PRIESTS — PRIEST SELF-PORTAL
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> priestLogin(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/priests/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['token'] != null) {
      await saveToken(data['token'] as String);
    }
    return data;
  }

  static Future<Map<String, dynamic>?> getPriestProfile() async {
    try {
      final token = await loadToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/priests/profile/me'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['priest'] ?? data;
      }
      return null;
    } catch (e) {
      debugPrint('getPriestProfile error: $e');
      return null;
    }
  }

  static Future<bool> updatePriestProfile(String id, Map<String, dynamic> data) async {
    try {
      final token = await loadToken();
      final response = await http.put(
        Uri.parse('$baseUrl/priests/$id'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updatePriestProfile error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getPriestBookings() async {
    try {
      final token = await loadToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse('$baseUrl/priests/my-bookings'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['bookings'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('getPriestBookings error: $e');
      return [];
    }
  }

  static Future<bool> updatePriestBookingStatus(String bookingId, String status) async {
    try {
      final token = await loadToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/priests/bookings/$bookingId/status'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updatePriestBookingStatus error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // ADMIN — STATS
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> getAdminStats() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['stats'] ?? data;
    }
    return {};
  }

  // ════════════════════════════════════════════
  // ADMIN — REPORTS
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> getAdminReports({String period = 'month'}) async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/reports?period=$period'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reports'] ?? data;
    }
    return {};
  }

  // ════════════════════════════════════════════
  // ADMIN — BOOKINGS
  // ════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getAdminBookings({
    String status = 'all',
    String type   = 'all',
    String search = '',
  }) async {
    final token  = await loadToken();
    final params = <String, String>{};
    if (status != 'all')   params['status'] = status;
    if (type   != 'all')   params['type']   = type;
    if (search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$baseUrl/admin/bookings')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List raw = data['bookings'] ?? [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<bool> updateBookingStatus(String id, String type, String status) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/bookings/$id/status'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'type': type, 'status': status}),
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // ADMIN — DONATIONS
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> getAdminDonations({
    String status   = 'all',
    String category = 'all',
    String search   = '',
  }) async {
    final token  = await loadToken();
    final params = <String, String>{};
    if (status   != 'all') params['status']   = status;
    if (category != 'all') params['category'] = category;
    if (search.isNotEmpty) params['search']   = search;
    final uri = Uri.parse('$baseUrl/admin/donations')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List raw = data['donations'] ?? [];
      return {
        'donations':   raw.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        'total':       data['total']       ?? 0,
        'totalAmount': data['totalAmount'] ?? 0,
      };
    }
    return {'donations': [], 'total': 0, 'totalAmount': 0};
  }

  static Future<bool> updateDonationStatus(String id, String status) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/donations/$id/status'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // ADMIN — ORDERS
  // ════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getAdminOrders({
    String status = 'all',
    String search = '',
  }) async {
    final token = await loadToken();
    final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: {
      if (status != 'all')   'status': status,
      if (search.isNotEmpty) 'search': search,
    });
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data['orders'] ?? [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<bool> updateOrderStatus(String id, String status, {String? trackingId}) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        if (trackingId != null) 'trackingId': trackingId,
      }),
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // ADMIN — USERS
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getAllUsers() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['users'] ?? []);
    }
    return [];
  }

  static Future<bool> toggleBlockUser(String userId) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/users/$userId/toggle-block'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  static Future<bool> changeUserRole(String userId, String role) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': role}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteUser(String userId) async {
    final token = await loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // TEMPLES
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getAllTemples() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/temples'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['temples'] ?? []);
    }
    return [];
  }

  static Future<List<dynamic>> searchTemples(String query) async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/temples/search?q=${Uri.encodeComponent(query)}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['temples'] ?? []);
    }
    return [];
  }

  static Future<List<dynamic>> getAdminTemples() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/temples'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['temples'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>> addTemple(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/temples'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<bool> updateTemple(String id, Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/temples/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteTemple(String id) async {
    final token = await loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/temples/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // EVENTS
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getAllEvents() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['events'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>> registerForEvent(
      String eventId, Map<String, dynamic> userData) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/register'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Registration failed');
    }
    return data;
  }

  static Future<Map<String, dynamic>> registerSampleEvent(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/events/sample-register'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(body['message'] ?? 'Sample registration failed');
    }
    return body;
  }

  static Future<Map<String, dynamic>> addEvent(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/events'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(body['message'] ?? 'Failed to add event');
    }
    return body;
  }

  static Future<bool> updateEvent(String id, Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/events/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update event');
    }
    return true;
  }

  static Future<bool> deleteEvent(String id) async {
    final token = await loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/events/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to delete event');
    }
    return true;
  }

  // ════════════════════════════════════════════
  // PRAYERS / MANTRAS
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getAllPrayers() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/prayers'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['prayers'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addPrayer(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/prayers'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> updatePrayer(String id, Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/prayers/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deletePrayer(String id) async {
    final token = await loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/prayers/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // ADMIN — PRAYER REQUESTS
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getAdminPrayerRequests({
    String status = 'all',
    String type   = 'all',
    String search = '',
  }) async {
    final token  = await loadToken();
    final params = <String, String>{};
    if (status != 'all')   params['status'] = status;
    if (type   != 'all')   params['type']   = type;
    if (search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$baseUrl/admin/prayer-requests')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['requests'] ?? data['prayerRequests'] ?? []);
    }
    return [];
  }

  static Future<bool> updatePrayerRequestStatus(String id, String status) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/prayer-requests/$id/status'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // ADMIN — PRAYER SCHEDULES
  // ════════════════════════════════════════════

  static Future<List<dynamic>> getAdminPrayerSchedules() async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/prayer-schedules'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['schedules'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addPrayerSchedule(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/prayer-schedules'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> updatePrayerScheduleStatus(String id, String status) async {
    final token = await loadToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/prayer-schedules/$id/status'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // PRODUCTS — USER SIDE
  // ════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getProducts({
    String category = 'all',
    String search   = '',
  }) async {
    final token  = await loadToken();
    final params = <String, String>{};
    if (category != 'all') params['category'] = category;
    if (search.isNotEmpty) params['search']   = search;
    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data is List ? data : (data['products'] ?? []);
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ════════════════════════════════════════════
  // PRODUCTS — ADMIN CRUD
  // ════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getAdminProducts({
    String category = 'all',
    String search   = '',
  }) async {
    final token  = await loadToken();
    final params = <String, String>{};
    if (category != 'all') params['category'] = category;
    if (search.isNotEmpty) params['search']   = search;
    final uri = Uri.parse('$baseUrl/admin/products')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data is List ? data : (data['products'] ?? []);
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addProduct(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/products'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final errBody = jsonDecode(response.body);
    throw Exception(errBody['message'] ?? 'Server error ${response.statusCode}');
  }

  static Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return true;
    final errBody = jsonDecode(response.body);
    throw Exception(errBody['message'] ?? 'Update failed ${response.statusCode}');
  }

  static Future<bool> deleteProduct(String id) async {
    final token = await loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/products/$id'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // ════════════════════════════════════════════
  // PAYMENTS
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> createRazorpayOrder(
      double amountInRupees, String receipt, Map<String, dynamic> notes) async {
    final token         = await loadToken();
    final amountInPaise = (amountInRupees * 100).toInt();
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount':   amountInPaise,
        'currency': 'INR',
        'receipt':  receipt,
        'notes':    notes,
      }),
    );
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Payment server returned unexpected response (status ${response.statusCode}).');
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final errBody = jsonDecode(response.body);
    throw Exception(errBody['message'] ?? 'Failed to create Razorpay order (${response.statusCode})');
  }

  // ════════════════════════════════════════════
  // BOOKINGS (USER SIDE)
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> saveDarshanBooking(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/darshan'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> savePrasadamOrder(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/prasadam'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> saveHomamBooking(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/homam'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> saveMarriageBooking(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/marriage'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getUserBookings() async {
    final token = await loadToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/my-bookings'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data is List ? data : (data['bookings'] ?? []);
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getUserEventRegistrations() async {
    final token = await loadToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/events/my-registrations'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data is List ? data : (data['registrations'] ?? []);
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAdminEventRegistrations({
    String status = 'all',
    String search = '',
  }) async {
    final token  = await loadToken();
    final params = <String, String>{};
    if (status != 'all')   params['status'] = status;
    if (search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$baseUrl/admin/event-registrations')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data is List
          ? data
          : (data['registrations'] ?? data['eventRegistrations'] ?? []);
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ════════════════════════════════════════════
  // DONATIONS (USER SIDE)
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> saveDonation(Map<String, dynamic> data) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/donations'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ════════════════════════════════════════════
  // GENERIC HELPERS
  // ════════════════════════════════════════════

  static Future<dynamic> get(String endpoint) async {
    final token = await loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('GET $endpoint failed: ${response.statusCode}');
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final token = await loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('POST $endpoint failed: ${response.statusCode}');
  }
}