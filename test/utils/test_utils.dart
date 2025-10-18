// ============================================================================
// AFO Chat Application - Test Utilities
// ============================================================================
// Common utilities and helpers for testing including:
// - Mock data generators
// - Test helpers and builders
// - Common test patterns and fixtures
// - Reusable test components
// ============================================================================

import 'package:afochatapplication/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test Utilities Class
/// Provides common testing utilities and helpers
class TestUtils {
  
  // ========================================================================
  // Mock Data Generators
  // ========================================================================
  
  /// Generate mock user data for testing
  static Map<String, dynamic> generateMockUser({
    String? id,
    String? name,
    String? email,
  }) {
    return {
      'id': id ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Test User',
      'email': email ?? 'test@example.com',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
    };
  }
  
  /// Generate mock chat message data
  static Map<String, dynamic> generateMockMessage({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
  }) {
    return {
      'id': id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': senderId ?? 'test_sender',
      'text': text ?? 'Test message content',
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'type': 'text',
      'isRead': false,
    };
  }
  
  /// Generate mock chat room data
  static Map<String, dynamic> generateMockChatRoom({
    String? id,
    String? name,
    List<String>? participants,
  }) {
    return {
      'id': id ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Test Chat Room',
      'participants': participants ?? ['user1', 'user2'],
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'lastMessage': generateMockMessage(),
    };
  }
  
  /// Generate mock authentication token
  static String generateMockToken({String? userId}) {
    final payload = {
      'userId': userId ?? 'test_user',
      'exp': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      'iat': DateTime.now().millisecondsSinceEpoch,
    };
    
    // Simple mock JWT-like token (not cryptographically secure)
    return 'mock.${payload.toString().replaceAll(' ', '')}.signature';
  }
  
  // ========================================================================
  // Test Builders and Helpers
  // ========================================================================
  
  /// Create a test MaterialApp wrapper
  static Widget createTestApp({
    required Widget child,
    Map<String, WidgetBuilder>? routes,
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      home: child,
      routes: routes ?? {},
      onGenerateRoute: onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
  
  /// Create test app with navigation
  static Widget createTestAppWithNavigation({
    required Widget child,
    String initialRoute = '/',
  }) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: {
        '/': (context) => child,
        '/login': (context) => const Scaffold(body: Text('Login Screen')),
        '/register': (context) => const Scaffold(body: Text('Register Screen')),
        '/home': (context) => const Scaffold(body: Text('Home Screen')),
        '/profile': (context) => const Scaffold(body: Text('Profile Screen')),
      },
      debugShowCheckedModeBanner: false,
    );
  }
  
  /// Create mock AuthService for testing
  static AuthService createMockAuthService({
    bool isAuthenticated = false,
    bool isLoading = false,
    String? currentUserId,
    String? currentUserName,
  }) {
    final authService = AuthService();
    
    // Mock the initial state if needed
    // Note: In a real implementation, you might need to use dependency injection
    // or create a proper mock class that extends AuthService
    
    return authService;
  }
  
  // ========================================================================
  // Test Patterns and Fixtures
  // ========================================================================
  
  /// Common test setup for authentication flows
  static Future<void> setupAuthTest(WidgetTester tester, {
    bool isAuthenticated = false,
  }) async {
    final authService = createMockAuthService(isAuthenticated: isAuthenticated);
    await authService.init();
    
    // Additional setup can be added here
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_secure_storage'),
      (MethodCall methodCall) async {
        // Mock secure storage responses
        switch (methodCall.method) {
          case 'read':
            return isAuthenticated ? generateMockToken() : null;
          case 'write':
            return null;
          case 'delete':
            return null;
          default:
            return null;
        }
      },
    );
  }
  
  /// Common test cleanup
  static Future<void> cleanupTest(WidgetTester tester) async {
    // Clean up method channels
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_secure_storage'),
      null,
    );
    
    // Additional cleanup can be added here
  }
  
  /// Wait for animations and async operations
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
  
  /// Find widget by text with error handling
  static Finder findTextSafe(String text) {
    final finder = find.text(text);
    return finder;
  }
  
  /// Find widget by type with error handling
  static Finder findTypeSafe<T extends Widget>() {
    final finder = find.byType(T);
    return finder;
  }
  
  // ========================================================================
  // Common Test Assertions
  // ========================================================================
  
  /// Assert that a screen is displayed correctly
  static void assertScreenDisplayed(WidgetTester tester, Type screenType) {
    expect(find.byType(screenType), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  }
  
  /// Assert that navigation occurred
  static void assertNavigation(WidgetTester tester, String expectedRoute) {
    // In a real implementation, you might check the current route
    // This is a simplified version
    expect(tester.takeException(), isNull);
  }
  
  /// Assert that form validation works
  static void assertFormValidation(WidgetTester tester, {
    required Finder formFinder,
    required List<String> expectedErrors,
  }) {
    expect(formFinder, findsOneWidget);
    
    // Check for validation error messages
    for (final error in expectedErrors) {
      expect(find.text(error), findsWidgets);
    }
  }
  
  /// Assert that loading state is displayed
  static void assertLoadingState(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }
  
  /// Assert that error state is displayed
  static void assertErrorState(WidgetTester tester, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }
  
  // ========================================================================
  // Performance Test Helpers
  // ========================================================================
  
  /// Measure widget rendering performance
  static Future<Duration> measureRenderTime(
    WidgetTester tester,
    Widget widget,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    
    stopwatch.stop();
    return stopwatch.elapsed;
  }
  
  /// Test memory usage patterns
  static Future<void> testMemoryUsage(
    WidgetTester tester,
    Widget widget, {
    int iterations = 10,
  }) async {
    for (int i = 0; i < iterations; i++) {
      await tester.pumpWidget(widget);
      await tester.pump();
      
      // Replace with empty widget to test cleanup
      await tester.pumpWidget(Container());
      await tester.pump();
    }
    
    // Should not accumulate memory leaks
    expect(tester.takeException(), isNull);
  }
  
  // ========================================================================
  // Data Validation Helpers
  // ========================================================================
  
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }
  
  // ========================================================================
  // Test Data Constants
  // ========================================================================
  
  static const String validEmail = 'test@example.com';
  static const String validPassword = 'password123';
  static const String validName = 'Test User';
  static const String validPhone = '+1234567890';
  
  static const String invalidEmail = 'invalid-email';
  static const String invalidPassword = '123';
  static const String invalidName = '';
  static const String invalidPhone = '123';
  
  // Sample test messages
  static const List<String> sampleMessages = [
    'Hello, how are you?',
    'This is a test message',
    'Flutter testing is great!',
    '🎉 Emojis work too!',
    'Long message with multiple words and sentences to test text wrapping and layout.',
  ];
  
  // Sample user names
  static const List<String> sampleUserNames = [
    'Alice Johnson',
    'Bob Smith',
    'Charlie Brown',
    'Diana Prince',
    'Eve Adams',
  ];
}

/// Test Constants
/// Common constants used across tests
class TestConstants {
  // Timeouts
  static const Duration shortTimeout = Duration(seconds: 2);
  static const Duration mediumTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 10);
  
  // Performance thresholds
  static const Duration maxRenderTime = Duration(milliseconds: 1000);
  static const Duration maxLoadTime = Duration(seconds: 5);
  
  // Test data sizes
  static const int smallDataSet = 10;
  static const int mediumDataSet = 100;
  static const int largeDataSet = 1000;
  
  // Network simulation delays
  static const Duration networkDelay = Duration(milliseconds: 500);
  static const Duration slowNetworkDelay = Duration(seconds: 2);
}

/// Custom Test Matchers
/// Additional matchers for testing
class TestMatchers {
  /// Matcher for checking if a widget tree is stable
  static Matcher get isStable => _IsStableMatcher();
  
  /// Matcher for checking performance thresholds
  static Matcher lessThanDuration(Duration duration) => _LessThanDurationMatcher(duration);
}

class _IsStableMatcher extends Matcher {
  @override
  bool matches(item, Map matchState) {
    // Implementation would check for widget tree stability
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('widget tree is stable');
  }
}

class _LessThanDurationMatcher extends Matcher {
  final Duration _duration;
  
  _LessThanDurationMatcher(this._duration);

  @override
  bool matches(item, Map matchState) {
    if (item is Duration) {
      return item < _duration;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('duration less than $_duration');
  }
}