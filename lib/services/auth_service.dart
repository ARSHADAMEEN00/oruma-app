import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oruma_app/services/api_config.dart';
import 'package:oruma_app/services/app_cache.dart';

class AuthService with ChangeNotifier {
  // Use ApiConfig to get the correct base URL
  String get _baseUrl => '${ApiConfig.baseUrl}/auth';

  String? _token;
  String? get token => _token;

  String? _role;
  String? get role => _role;

  bool _isFirstLogin = false;
  bool get isFirstLogin => _isFirstLogin;

  bool _isAccessBlocked = false;
  bool get isAccessBlocked => _isAccessBlocked;

  String? _accessBlockedMessage;
  String? get accessBlockedMessage => _accessBlockedMessage;

  Map<String, dynamic>? _accessBlockedSupport;
  Map<String, dynamic>? get accessBlockedSupport => _accessBlockedSupport;

  String? _loginErrorMessage;
  String? get loginErrorMessage => _loginErrorMessage;

  bool get isAuthenticated => _token != null;
  bool get isAdmin => _role == 'admin';
  bool get isStaff => _role == 'staff';
  bool get isUser => _role == 'user';
  bool get isMember => _role == 'member';

  bool get canCreate =>
      _role == 'admin' || _role == 'staff' || _role == 'member';
  bool get canEdit => _role == 'admin' || _role == 'staff' || _role == 'member';
  bool get canDelete => _role == 'admin';
  bool get canAccessMedicine => !isMember;
  bool get canAccessNHC => !isMember;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _role = prefs.getString('auth_role');
    debugPrint('Auth service initialized. Role: $_role');
    if (_token != null) {
      await fetchUserProfile();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isAccessBlocked = false;
        _accessBlockedMessage = null;
        _accessBlockedSupport = null;
        _loginErrorMessage = null;
        _token = data['token'];
        _role = data['role']; // Get role from response

        final prefs = await SharedPreferences.getInstance();

        // Check if this is the first login for this user
        final wasLoggedInBefore = prefs.containsKey('auth_token');
        _isFirstLogin = !wasLoggedInBefore;

        await prefs.setString('auth_token', _token!);
        if (_role != null) {
          await prefs.setString('auth_role', _role!);
        }

        debugPrint('Login Successful. Role: $_role');

        // Fetch user profile after successful login
        await fetchUserProfile();

        notifyListeners();
        return true;
      }
      await _handleAuthFailure(response);
      return false;
    } catch (e) {
      print('Login error: $e');
      _loginErrorMessage = 'Unable to connect. Please try again.';
      return false;
    }
  }

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.meEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data;
        _isAccessBlocked = false;
        _accessBlockedMessage = null;
        _accessBlockedSupport = null;
        notifyListeners();
      } else {
        await _handleAuthFailure(response);
        print('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _user = null;
    _isAccessBlocked = false;
    _accessBlockedMessage = null;
    _accessBlockedSupport = null;
    _loginErrorMessage = null;
    // Clear all cached data so stale data cannot leak to another user session
    AppCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    notifyListeners();
  }

  // Helper to get headers for other services
  Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  void clearAccessBlocked() {
    _isAccessBlocked = false;
    _accessBlockedMessage = null;
    _accessBlockedSupport = null;
    _loginErrorMessage = null;
    notifyListeners();
  }

  Future<void> _handleAuthFailure(http.Response response) async {
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }

    if (response.statusCode == 403 && data['code'] == 'TRIAL_ENDED') {
      _token = null;
      _role = null;
      _user = null;
      _isAccessBlocked = true;
      _accessBlockedMessage =
          data['error']?.toString() ??
          'Trial period is ended. Contact support team to purchase a plan.';
      final support = data['support'];
      _accessBlockedSupport = support is Map
          ? Map<String, dynamic>.from(support)
          : null;
      await _clearStoredCredentials();
      AppCache.clear();
    } else {
      _loginErrorMessage =
          data['error']?.toString() ?? 'Invalid email or password';
    }

    notifyListeners();
  }

  Future<void> _clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
  }
}
