// ============================================================================
// AFO Chat Application - Authentication Service
// ============================================================================
// This service handles all authentication-related functionality for the
// AFO (Afaan Oromoo Chat Services) application including:
// - User login/logout/registration (mock implementation)
// - Token management and secure storage
// - Google Sign-In integration
// - Session management and automatic token refresh
// - User state management across the application
//
// NOTE: This is a MOCK implementation that doesn't require a real backend.
// For production, replace the mock methods with actual API calls.
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Authentication Service - Manages user authentication state
/// Extends ChangeNotifier for state management with Provider pattern
class AuthService extends ChangeNotifier {
  // ========================================================================
  // Configuration & Dependencies
  // ========================================================================
  
  /// API base URL configuration
  /// NOTE: Change this to your actual server URL for production
  static const String _baseUrl = 'http://localhost:4000'; // For Windows/Desktop (change to your server URL)
  // static const String _baseUrl = 'http://10.0.2.2:4000'; // For Android emulator -> host machine
  
  /// Secure storage instance for token persistence
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Google Sign-In instance for OAuth authentication
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  // ========================================================================
  // State Variables
  // ========================================================================
  
  /// JWT access token for API authentication
  String? _accessToken;
  
  /// JWT refresh token for token renewal
  String? _refreshToken;
  
  /// Current user data
  Map<String, dynamic>? _user;
  
  /// Loading state indicator
  bool isLoading = true;

  /// Token expiry management timer
  Timer? _refreshTimer;

  // ========================================================================
  // Constructor & Initialization
  // ========================================================================
  
  AuthService();

  /// Initialize the authentication service
  /// Loads stored tokens and user data from secure storage
  Future<void> init() async {
    // Load stored authentication data from secure storage
    _accessToken = await _secureStorage.read(key: 'accessToken');
    _refreshToken = await _secureStorage.read(key: 'refreshToken');
    final userJson = await _secureStorage.read(key: 'user');
    
    // Deserialize user data if exists
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
    
    // Update loading state and notify listeners
    isLoading = false;
    notifyListeners();

    // Attempt silent token refresh if refresh token exists but access token doesn't
    if (_refreshToken != null && _accessToken == null) {
      await tryRefresh();
    }
  }

  // ========================================================================
  // Public Getters - Authentication State
  // ========================================================================
  
  /// Check if user is currently authenticated
  bool get isAuthenticated => _accessToken != null && _user != null;
  
  /// Get current user data
  Map<String, dynamic>? get user => _user;
  
  /// Get current access token
  String? get accessToken => _accessToken;

  // ========================================================================
  // Authentication Methods
  // ========================================================================

  /// Register a new user account
  /// NOTE: This is a MOCK implementation for testing without backend
  /// [email] - User's email address
  /// [password] - User's password  
  /// [displayName] - Optional display name
  Future<void> register({required String email, required String password, String? displayName}) async {
    // Mock registration for testing (no backend required)
    try {
      // Simulate realistic network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful registration - in production, make actual API call
      print('✅ Mock registration successful for: $email');
      return;
      
      // Uncomment below and comment above when you have a backend server:
      /*
      final url = Uri.parse('$_baseUrl/auth/register');
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'email': email,
        'password': password,
        'displayName': displayName ?? '',
      }));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return;
      } else {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        final msg = body['message'] ?? 'Registration failed';
        throw Exception(msg);
      }
      */
    } catch (e) {
      print('❌ Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    // Mock login for testing (no backend required)
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful login
      _accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
      _refreshToken = 'mock_refresh_token';
      _user = {
        'id': 'user_123',
        'email': email,
        'displayName': email.split('@')[0],
        'verified': true,
      };

      await _secureStorage.write(key: 'accessToken', value: _accessToken);
      await _secureStorage.write(key: 'refreshToken', value: _refreshToken);
      await _secureStorage.write(key: 'user', value: jsonEncode(_user));
      
      notifyListeners();
      print('✅ Mock login successful for: $email');
      return;
      
      // Uncomment below and comment above when you have a backend server:
      /*
      final url = Uri.parse('$_baseUrl/auth/login');
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}));

      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      if (res.statusCode == 200) {
        _accessToken = body['accessToken'];
        _refreshToken = body['refreshToken'] ?? body['refresh_token'];
        _user = body['user'] != null ? Map<String, dynamic>.from(body['user']) : null;

        await _secureStorage.write(key: 'accessToken', value: _accessToken);
        if (_refreshToken != null) await _secureStorage.write(key: 'refreshToken', value: _refreshToken);
        if (_user != null) await _secureStorage.write(key: 'user', value: jsonEncode(_user));
        notifyListeners();
        _startAutoRefresh();
        return;
      } else {
        final msg = body['message'] ?? 'Login failed';
        throw Exception(msg);
      }
      */
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    try {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      await _secureStorage.delete(key: 'user');
    } catch (_) {}
    _refreshTimer?.cancel();
    notifyListeners();
  }

  Future<bool> tryRefresh() async {
    if (_refreshToken == null) return false;
    final url = Uri.parse('$_baseUrl/auth/refresh');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      _accessToken = body['accessToken'];
      await _secureStorage.write(key: 'accessToken', value: _accessToken);
      notifyListeners();
      _startAutoRefresh();
      return true;
    } else {
      // refresh failed: clear tokens
      await logout();
      return false;
    }
  }

  // Simple auto refresh which calls tryRefresh every N minutes based on typical expiry (optional)
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // schedule a refresh every 10 minutes; in production parse JWT exp and schedule before expiry
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      tryRefresh();
    });
  }

  // Helper for authenticated API calls
  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 401) {
      // try refresh once
      final ok = await tryRefresh();
      if (ok && _accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
        return await http.get(uri, headers: headers);
      }
    }
    return res;
  }

  // Test Google Sign-in without backend (for setup verification)
  Future<void> testGoogleSignInOnly() async {
    try {
      // Sign in with Google SDK to get basic info
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google sign-in was cancelled by user');
      }
      
      print('✅ Google Sign-in successful!');
      print('📧 Email: ${account.email}');
      print('👤 Display Name: ${account.displayName}');
      
      final auth = await account.authentication;
      print('🔑 Has Access Token: ${auth.accessToken != null}');
      print('🎫 Has ID Token: ${auth.idToken != null}');
      
      // For testing, we'll create a mock user without calling backend
      _user = {
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'id': account.id,
      };
      
      // Mock tokens for testing
      _accessToken = 'test_access_token_${DateTime.now().millisecondsSinceEpoch}';
      
      notifyListeners();
      print('🎉 Test authentication complete!');
      
    } catch (e) {
      print('❌ Google Sign-in test failed: $e');
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  // ---------- Google Sign-In ----------
  Future<void> signInWithGoogle() async {
    try {
      // Sign in with Google SDK to get idToken
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google sign-in was cancelled by user');
      }
      
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');

      // Send to backend to exchange for app tokens
      final url = Uri.parse('$_baseUrl/auth/oauth/google');
      final res = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({'idToken': idToken})
      );

      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      if (res.statusCode == 200) {
        _accessToken = body['accessToken'];
        _refreshToken = body['refreshToken'];
        _user = body['user'] != null ? Map<String, dynamic>.from(body['user']) : null;
        
        await _secureStorage.write(key: 'accessToken', value: _accessToken);
        if (_refreshToken != null) await _secureStorage.write(key: 'refreshToken', value: _refreshToken);
        if (_user != null) await _secureStorage.write(key: 'user', value: jsonEncode(_user));
        
        notifyListeners();
        _startAutoRefresh();
        return;
      } else {
        final msg = body['message'] ?? 'Google authentication failed on server';
        throw Exception('$msg (Status: ${res.statusCode})');
      }
    } catch (e) {
      // Make sure to sign out from Google if there was an error
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  Future<void> disconnectGoogle() async {
    await _googleSignIn.disconnect();
  }

  // Password reset / forgot password endpoints can be added similarly...
}
